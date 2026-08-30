import { useEffect, useMemo, useState } from "react";
import { Link, NavLink, Route, Routes, useLocation, useNavigate, useParams } from "react-router-dom";
import { ArrowLeft, ArrowRight, ChevronDown, Heart, Instagram, Menu, Minus, Plus, Search, ShoppingBag, User, X, ShieldCheck, Truck, RotateCcw, Leaf, Mail, MapPin, Phone, LogOut, Package, Users, Settings, LayoutDashboard, Boxes, UserPlus } from "lucide-react";
import { supabase } from "./lib/supabase";
import { collections as fallbackCollections, products as fallbackProducts, type Product } from "./data";

type CartItem = { product: Product; size: string; qty: number };
const money = (n:number) => new Intl.NumberFormat("ar-EG",{style:"currency",currency:"EGP",maximumFractionDigits:0}).format(n);

function App(){
  const [products,setProducts]=useState<Product[]>(fallbackProducts);
  const [collections,setCollections]=useState<any[]>(fallbackCollections);
  const [cart,setCart]=useState<CartItem[]>(()=>JSON.parse(localStorage.getItem("masar-cart")||"[]"));
  const [user,setUser]=useState<any>(null);
  const [role,setRole]=useState<string|null>(null);
  useEffect(()=>{localStorage.setItem("masar-cart",JSON.stringify(cart))},[cart]);
  useEffect(()=>{
    if(!supabase)return;
    supabase.auth.getSession().then(({data})=>setUser(data.session?.user??null));
    const {data}=supabase.auth.onAuthStateChange((_e,s)=>{setUser(s?.user??null);setRole(null)});
    return()=>data.subscription.unsubscribe()
  },[]);
  useEffect(()=>{
    if(!supabase)return;
    (async()=>{
      const [{data:ps},{data:cs}] = await Promise.all([
        supabase.from("products").select("id,name,slug,description,price,stock,sizes,colors,image_url,is_active,collections(name)").eq("is_active",true).order("created_at",{ascending:false}),
        supabase.from("collections").select("id,name,slug,description,image_url,sort_order,is_active").eq("is_active",true).order("sort_order")
      ]);
      if(ps?.length)setProducts(ps.map((p:any)=>({...p,id:p.slug||p.id,image:p.image_url,collection:p.collections?.name||"",sizes:p.sizes||[],colors:p.colors||[]})));
      if(cs?.length)setCollections(cs.map((c:any)=>({id:c.slug||c.id,name:c.name,subtitle:c.description||"",image:c.image_url})));
    })();
  },[]);
  const add=(product:Product,size:string)=>setCart(c=>{const i=c.findIndex(x=>x.product.id===product.id&&x.size===size);if(i<0)return [...c,{product,size,qty:1}];const n=[...c];n[i]={...n[i],qty:n[i].qty+1};return n});
  const update=(id:string,size:string,d:number)=>setCart(c=>c.map(x=>x.product.id===id&&x.size===size?{...x,qty:Math.max(1,x.qty+d)}:x));
  const remove=(id:string,size:string)=>setCart(c=>c.filter(x=>!(x.product.id===id&&x.size===size)));
  const count=cart.reduce((s,x)=>s+x.qty,0);
  useEffect(()=>{if(!user||!supabase){setRole(null);return}supabase.rpc("get_my_role").then(({data})=>setRole(data??null))},[user]);
  return <><TopBar/><Header count={count} user={user} role={role}/><Routes>
    <Route path="/" element={<Home products={products}/>}/><Route path="/collections" element={<Collections collections={collections}/>}/><Route path="/collections/:id" element={<Collection collections={collections} products={products}/>}/>
    <Route path="/product/:id" element={<ProductPage products={products} add={add}/>}/><Route path="/cart" element={<Cart cart={cart} update={update} remove={remove}/>}/>
    <Route path="/checkout" element={<Checkout cart={cart} user={user} clearCart={()=>setCart([])}/>}/><Route path="/contact" element={<Contact/>}/><Route path="/faq" element={<FAQ/>}/>
    <Route path="/shipping" element={<Policy title="سياسة الشحن" sections={[["مدة التجهيز","نقوم بتجهيز طلبك خلال يوم إلى يوم عمل من تأكيد الطلب واستلام الدفع."],["خيارات التوصيل والتكلفة","الشحن مجاني للطلبات فوق ١٥٠٠ ج.م وتطبق الرسوم على الطلبات الأقل."],["تتبع الطلب","بعد شحن طلبك نرسل رقم التتبع عبر قنوات التواصل."],["المناطق غير المغطاة","سنتواصل معك لتنسيق بديل مناسب."]]}/>} />
    <Route path="/returns" element={<Policy title="سياسة الإرجاع والاستبدال" sections={[["مدة الإرجاع","يمكن طلب الإرجاع أو الاستبدال خلال ١٤ يومًا وفق الشروط المنشورة."],["شروط الإرجاع","يشترط أن يكون المنتج بحالته الأصلية."],["عملية الإرجاع","تواصل معنا برقم الطلب وسبب الإرجاع."],["استرداد المبلغ","يتم وفق وسيلة الدفع وسياسة المتجر."]]}/>} />
    <Route path="/login" element={<Auth mode="login"/>}/><Route path="/signup" element={<Auth mode="signup"/>}/><Route path="/forgot-password" element={<Auth mode="forgot"/>}/><Route path="/reset-password" element={<Auth mode="reset"/>}/>
    <Route path="/account" element={<Account user={user}/>}/><Route path="/admin/*" element={<Admin user={user}/>}/><Route path="*" element={<NotFound/>}/>
  </Routes><Footer/></>
};