-- MASAR database foundation
-- Run in Supabase SQL Editor after creating the project.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  phone text,
  role text not null default 'customer' check (role in ('customer','admin','owner')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.profiles add column if not exists email text;

create table if not exists public.collections (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text,
  image_url text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  collection_id uuid references public.collections(id) on delete set null,
  name text not null,
  slug text not null unique,
  description text,
  price numeric(12,2) not null check (price >= 0),
  stock integer not null default 0 check (stock >= 0),
  sizes text[] not null default '{}',
  colors text[] not null default '{}',
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique default ('MS-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,10))),
  customer_id uuid references public.profiles(id) on delete set null,
  customer_name text not null,
  email text,
  phone text not null,
  city text not null,
  address text not null,
  payment_method text not null check (payment_method in ('cod','bank','online')),
  payment_status text not null default 'pending' check (payment_status in ('pending','paid','failed','refunded')),
  status text not null default 'confirmed' check (status in ('confirmed','preparing','ready','shipped','delivered','cancelled','returned')),
  subtotal numeric(12,2) not null check (subtotal >= 0),
  shipping_fee numeric(12,2) not null default 0 check (shipping_fee >= 0),
  total numeric(12,2) not null check (total >= 0),
  tracking_number text,
  gift_note text default 'هدية مميزة من مسار',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  size text,
  color text,
  quantity integer not null check (quantity > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.admin_activity (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text,
  entity_id uuid,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.collections enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.admin_activity enable row level security;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.profiles where id=auth.uid() and role in ('admin','owner')); $$;

create or replace function public.is_owner()
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.profiles where id=auth.uid() and role='owner'); $$;

create policy "profiles own read" on public.profiles for select using (id=auth.uid() or public.is_admin());
create policy "profiles own update" on public.profiles for update using (id=auth.uid() or public.is_owner()) with check (id=auth.uid() or public.is_owner());

create policy "public active collections read" on public.collections for select using (is_active=true or public.is_admin());
create policy "admins manage collections" on public.collections for all using (public.is_admin()) with check (public.is_admin());

create policy "public active products read" on public.products for select using (is_active=true or public.is_admin());
create policy "admins manage products" on public.products for all using (public.is_admin()) with check (public.is_admin());

create policy "customer own orders" on public.orders for select using (customer_id=auth.uid() or public.is_admin());
create policy "customer create orders" on public.orders for insert with check (customer_id=auth.uid() or customer_id is null);
create policy "admins manage orders" on public.orders for all using (public.is_admin()) with check (public.is_admin());

create policy "customer own order items" on public.order_items for select using (
  exists (select 1 from public.orders o where o.id=order_id and (o.customer_id=auth.uid() or public.is_admin()))
);
create policy "admins manage order items" on public.order_items for all using (public.is_admin()) with check (public.is_admin());

create policy "admins read activity" on public.admin_activity for select using (public.is_admin());
create policy "admins insert activity" on public.admin_activity for insert with check (public.is_admin());

-- Create the profile automatically when a customer signs up.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles(id, full_name, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), new.email);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Promote the first/primary account manually, from the SQL editor:
-- update public.profiles p
-- set role='owner', updated_at=now()
-- from auth.users u
-- where p.id=u.id and u.email='YOUR_EMAIL_HERE';


-- Transactional order creation: validates stock, calculates totals, inserts order/items,
-- and decrements inventory atomically. Shipping is free at 1500 EGP and 60 EGP otherwise.
create or replace function public.create_order(
  p_customer_id uuid,
  p_customer_name text,
  p_email text,
  p_phone text,
  p_city text,
  p_address text,
  p_payment_method text,
  p_items jsonb
)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders;
  v_item jsonb;
  v_product public.products;
  v_qty integer;
  v_size text;
  v_subtotal numeric(12,2) := 0;
  v_shipping numeric(12,2);
begin
  if p_customer_id is not null and p_customer_id <> auth.uid() and not public.is_admin() then
    raise exception 'not authorized';
  end if;

  if jsonb_array_length(coalesce(p_items,'[]'::jsonb)) = 0 then
    raise exception 'cart is empty';
  end if;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_qty := greatest(1, (v_item->>'quantity')::integer);
    v_size := nullif(v_item->>'size','');

    select * into v_product
    from public.products
    where slug = (v_item->>'product_id')
      and is_active = true
    for update;

    if not found then raise exception 'product not found'; end if;
    if v_product.stock < v_qty then raise exception 'insufficient stock for %', v_product.name; end if;
    if v_size is not null and not (v_size = any(v_product.sizes)) then
      raise exception 'invalid size for %', v_product.name;
    end if;

    v_subtotal := v_subtotal + (v_product.price * v_qty);
  end loop;

  v_shipping := case when v_subtotal >= 1500 then 0 else 60 end;

  insert into public.orders (
    customer_id, customer_name, email, phone, city, address,
    payment_method, subtotal, shipping_fee, total, gift_note
  )
  values (
    p_customer_id, trim(p_customer_name), nullif(trim(p_email),''),
    trim(p_phone), trim(p_city), trim(p_address),
    p_payment_method, v_subtotal, v_shipping, v_subtotal + v_shipping,
    'هدية مميزة من مسار'
  )
  returning * into v_order;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_qty := greatest(1, (v_item->>'quantity')::integer);
    v_size := nullif(v_item->>'size','');

    select * into v_product from public.products
    where slug = (v_item->>'product_id') for update;

    insert into public.order_items (
      order_id, product_id, product_name, size, color, quantity, unit_price
    )
    values (
      v_order.id, v_product.id, v_product.name, v_size,
      nullif(v_item->>'color',''), v_qty, v_product.price
    );

    update public.products
    set stock = stock - v_qty, updated_at = now()
    where id = v_product.id;
  end loop;

  return v_order;
end;
$$;

revoke all on function public.create_order(uuid,text,text,text,text,text,text,jsonb) from public;
grant execute on function public.create_order(uuid,text,text,text,text,text,text,jsonb) to authenticated, anon;


-- Initial catalog seed matching the approved storefront reference.
insert into public.collections (name, slug, description, image_url, sort_order)
values
  ('الإصدار الأسود','black','قطع سوداء بتصميم جريء','https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&w=900&q=85',1),
  ('الأخضر الشرقي','olive','هدوء مستوحى من البيئة','https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=900&q=85',2),
  ('الأبيض النقي','white','أناقة بسيطة ونظيفة','https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?auto=format&fit=crop&w=900&q=85',3)
on conflict (slug) do update set
  name=excluded.name, description=excluded.description, image_url=excluded.image_url, sort_order=excluded.sort_order, updated_at=now();

insert into public.products (collection_id,name,slug,description,price,stock,sizes,colors,image_url,is_active)
values
  ((select id from public.collections where slug='black'),'هودي مسار الأسود','p1','هودي بقصة نظيفة وخامة ثقيلة مصمم للاستخدام اليومي.',1290,24,array['S','M','L','XL'],array['أسود'],'https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&w=900&q=85',true),
  ((select id from public.collections where slug='olive'),'بنطال مسار الزيتوني','p2','بنطال عملي بتفاصيل هادئة وقصة مريحة.',990,18,array['S','M','L','XL'],array['زيتوني'],'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=900&q=85',true),
  ((select id from public.collections where slug='white'),'قميص مسار الأبيض','p3','قميص أبيض بسيط يركز على الخامة والتفاصيل.',890,31,array['S','M','L','XL'],array['أبيض'],'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?auto=format&fit=crop&w=900&q=85',true)
on conflict (slug) do update set
  collection_id=excluded.collection_id, name=excluded.name, description=excluded.description,
  price=excluded.price, sizes=excluded.sizes, colors=excluded.colors, image_url=excluded.image_url,
  updated_at=now();


-- Backfill email for profiles created before the email column was added.
update public.profiles p
set email = u.email
from auth.users u
where p.id = u.id and (p.email is null or p.email <> u.email);
