-- MASAR database foundation
-- Run in Supabase SQL Editor after creating the project.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  role text not null default 'customer' check (role in ('customer','admin','owner')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

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
  insert into public.profiles(id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''));
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
