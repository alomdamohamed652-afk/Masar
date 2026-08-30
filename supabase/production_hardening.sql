-- MASAR production hardening migration
-- Applied to production on 2026-08-30.
-- Safe to review/reapply; statements are idempotent where practical.

create table if not exists public.order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  from_status text,
  to_status text not null,
  changed_by uuid references public.profiles(id) on delete set null,
  note text,
  created_at timestamptz not null default now()
);
alter table public.order_status_history enable row level security;

create index if not exists idx_orders_customer_id_created_at on public.orders(customer_id, created_at desc);
create index if not exists idx_orders_status_created_at on public.orders(status, created_at desc);
create index if not exists idx_order_items_order_id on public.order_items(order_id);
create index if not exists idx_order_items_product_id on public.order_items(product_id);
create index if not exists idx_products_collection_id on public.products(collection_id);
create index if not exists idx_admin_activity_actor_id on public.admin_activity(actor_id);
create index if not exists idx_order_status_history_order_id_created_at on public.order_status_history(order_id, created_at desc);

-- Internal authorization helpers must never be exposed to anonymous callers.
revoke all on function public.get_my_role() from public;
grant execute on function public.get_my_role() to authenticated;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;
revoke all on function public.is_owner() from public;
grant execute on function public.is_owner() to authenticated;
revoke all on function public.handle_new_user() from public;

-- Guest checkout remains intentionally available through the transactional RPC.
revoke all on function public.create_order(uuid,text,text,text,text,text,text,jsonb) from public;
grant execute on function public.create_order(uuid,text,text,text,text,text,text,jsonb) to anon, authenticated;

-- Order status changes are admin-only and audited.
revoke all on function public.update_order_status(uuid,text,text) from public;
grant execute on function public.update_order_status(uuid,text,text) to authenticated;
