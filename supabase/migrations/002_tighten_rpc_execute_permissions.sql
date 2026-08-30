-- Restrict privileged RPC endpoints to the roles that actually need them.
revoke execute on function public.create_order(uuid,text,text,text,text,text,text,jsonb) from anon, authenticated;
revoke execute on function public.get_my_role() from anon;
revoke execute on function public.handle_new_user() from anon, authenticated;
revoke execute on function public.is_admin() from anon, authenticated;
revoke execute on function public.is_owner() from anon, authenticated;
revoke execute on function public.update_order_status(uuid,text,text) from anon, authenticated;
grant execute on function public.get_my_role() to authenticated;
