import { useEffect, useState } from "react";
import { supabase } from "../../lib/supabase";
import { money, Empty } from "../../AppHelpers";

export function AdminRecentOrders(){const [orders,setOrders]=useState<any[]>([]);useEffect(()=>{if(!supabase)return;supabase.from("orders").select("order_number,customer_name,total,status,created_at").order("created_at",{ascending:false}).limit(5).then(({data})=>setOrders(data||[]))},[]);const labels:any={confirmed:"مؤكد",preparing:"جاري التجهيز",ready:"جاهز للشحن",shipped:"تم الشحن",delivered:"تم التسليم",cancelled:"ملغي",returned:"مرتجع"};return orders.length?<div className="admin-table">{orders.map(o=><article className="admin-row"><div><b>{o.order_number}</b><span>{o.customer_name}</span></div><strong>{money(o.total)}</strong><span>{labels[o.status]||o.status}</span></article>)}</div>:<Empty title="لا توجد طلبات بعد" text="ستظهر الطلبات الجديدة هنا فور وصولها."/>}
