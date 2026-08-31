import { useState } from "react";
import { Link, NavLink, useNavigate } from "react-router-dom";
import { Menu, Search, ShoppingBag, User, X } from "lucide-react";

export function Header({count,user,role}:{count:number,user:any,role:string|null}){
  const [open,setOpen]=useState(false);
  const [search,setSearch]=useState("");
  const nav=useNavigate();
  const close=()=>setOpen(false);
  const submit=(e:any)=>{e.preventDefault();const q=search.trim();if(q)nav("/collections?search="+encodeURIComponent(q));close()};
  const links=[["/","الرئيسية"],["/collections","المجموعات"],["/faq","الأسئلة الشائعة"],["/contact","اتصل بنا"]] as const;
  return <header className="header">
    <Link to="/" className="logo" onClick={close}>مسار<span>MASAR</span></Link>
    <nav className={open?"nav open":"nav"} aria-label="التنقل الرئيسي">
      {links.map(([to,label])=><NavLink key={to} to={to} onClick={close}>{label}</NavLink>)}
      {(role==="admin"||role==="owner")&&<NavLink to="/admin" onClick={close}>لوحة التحكم</NavLink>}
    </nav>
    <form className="header-search" onSubmit={submit} role="search">
      <Search size={17}/>
      <input value={search} onChange={e=>setSearch(e.target.value)} placeholder="ابحث عن منتج..." aria-label="البحث عن منتج"/>
    </form>
    <div className="actions">
      <Link to="/account" aria-label={user?"حسابي":"تسجيل الدخول"} onClick={close}><User size={19}/></Link>
      <Link to="/cart" className="cart-icon" aria-label={`السلة، ${count} منتجات`} onClick={close}><ShoppingBag size={20}/>{count>0&&<b>{count}</b>}</Link>
      <button type="button" className="mobile-menu" onClick={()=>setOpen(v=>!v)} aria-label={open?"إغلاق القائمة":"فتح القائمة"} aria-expanded={open}>{open?<X/>:<Menu/>}</button>
    </div>
  </header>
}
