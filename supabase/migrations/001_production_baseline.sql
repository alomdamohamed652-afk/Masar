-- MASAR initial production data + admin role helper
create or replace function public.get_my_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid() limit 1;
$$;

grant execute on function public.get_my_role() to authenticated;

insert into public.collections (name, slug, description, image_url, sort_order, is_active)
values
('الإصدار الأسود','black','قطع سوداء بتصميم جريء','https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&w=900&q=85',1,true),
('الأخضر الشرقي','olive','هدوء مستوحى من البيئة','https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=900&q=85',2,true),
('الأبيض النقي','white','أناقة بسيطة ونظيفة','https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?auto=format&fit=crop&w=900&q=85',3,true)
on conflict (slug) do update set name=excluded.name,image_url=excluded.image_url,is_active=true;

insert into public.products
(collection_id,name,slug,description,price,stock,sizes,colors,image_url,is_active)
select c.id,'هودي مسار الأسود','p1','هودي بقصة نظيفة وخامة ثقيلة مصمم للاستخدام اليومي.',1290,24,array['S','M','L','XL'],array['أسود'],'https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&w=900&q=85',true
from public.collections c where c.slug='black'
on conflict (slug) do update set collection_id=excluded.collection_id,name=excluded.name,price=excluded.price,stock=excluded.stock,image_url=excluded.image_url,is_active=true;

insert into public.products
(collection_id,name,slug,description,price,stock,sizes,colors,image_url,is_active)
select c.id,'بنطال مسار الزيتوني','p2','بنطال عملي بتفاصيل هادئة وقصة مريحة.',990,18,array['S','M','L','XL'],array['زيتوني'],'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=900&q=85',true
from public.collections c where c.slug='olive'
on conflict (slug) do update set collection_id=excluded.collection_id,name=excluded.name,price=excluded.price,stock=excluded.stock,image_url=excluded.image_url,is_active=true;

insert into public.products
(collection_id,name,slug,description,price,stock,sizes,colors,image_url,is_active)
select c.id,'قميص مسار الأبيض','p3','قميص أبيض بسيط يركز على الخامة والتفاصيل.',890,31,array['S','M','L','XL'],array['أبيض'],'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?auto=format&fit=crop&w=900&q=85',true
from public.collections c where c.slug='white'
on conflict (slug) do update set collection_id=excluded.collection_id,name=excluded.name,price=excluded.price,stock=excluded.stock,image_url=excluded.image_url,is_active=true;

notify pgrst, 'reload schema';
