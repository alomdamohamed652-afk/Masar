import { useEffect, useState } from "react";
import { Heart } from "lucide-react";
import { Link } from "react-router-dom";
import type { Product } from "../data";
const money=(n:number)=>new Intl.NumberFormat("ar-EG",{style:"currency",currency:"EGP",maximumFractionDigits:0}).format(n);
export function ProductCard({p}:{p:Product}){
 const [fav,setFav]=useState(()=>{try{return JSON.parse(localStorage.getItem("masar-wishlist")||"[]").includes(p.id)}catch{return false}});
 const toggle=(e:React.MouseEvent)=>{e.preventDefault();e.stopPropagation();let ids:string[]=[];try{ids=JSON.parse(localStorage.getItem("masar-wishlist")||"[]")}catch{};const next=ids.includes(p.id)?ids.filter(x=>x!==p.id):[...ids,p.id];localStorage.setItem("masar-wishlist",JSON.stringify(next));setFav(!fav);window.dispatchEvent(new Event("masar-wishlist-change"))};
 useEffect(()=>{const sync=()=>{try{setFav(JSON.parse(localStorage.getItem("masar-wishlist")||"[]").includes(p.id))}catch{}};window.addEventListener("masar-wishlist-change",sync);return()=>window.removeEventListener("masar-wishlist-change",sync)},[p.id]);
 return <Link to={"/product/"+(p.slug||p.id)} className="product-card"><div className="product-image"><img loading="lazy" src={p.image} alt={p.name}/><button type="button" className={fav?"favorite active":"favorite"} aria-label={fav?"إزالة من المفضلة":"إضافة إلى المفضلة"} aria-pressed={fav} onClick={toggle}><Heart size={18} fill={fav?"currentColor":"none"}/></button>{p.stock<=5&&<span className="stock-badge">باقي {p.stock} فقط</span>}</div><div className="product-meta"><div><h3>{p.name}</h3><span>{p.collection}</span></div><strong>{money(p.price)}</strong></div></Link>
}
