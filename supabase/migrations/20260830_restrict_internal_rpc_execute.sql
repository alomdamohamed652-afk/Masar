-- MASAR database migration
-- Restrict internal SECURITY DEFINER helpers to signed-in users.
-- Guest checkout intentionally keeps create_order executable by anon.
revoke all on function public.get_my_role() from public;
grant execute on function public.get_my_role() to authenticated;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

revoke all on function public.is_owner() from public;
grant execute on function public.is_owner() to authenticated;

revoke all on function public.update_order_status(uuid,text,text) from public;
grant execute on function public.update_order_status(uuid,text,text) to authenticated;

revoke all on function public.create_order(uuid,text,text,text,text,text,text,jsonb) from public;
grant execute on function public.create_order(uuid,text,text,text,text,text,text,jsonb) to anon, authenticated;
