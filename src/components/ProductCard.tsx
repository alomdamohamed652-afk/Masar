import { Link } from "react-router-dom";
import { Heart } from "lucide-react";
import type { Product } from "../data";

const money = (n:number) => new Intl.NumberFormat("ar-EG",{style:"currency",currency:"EGP",maximumFractionDigits:0}).format(n);

function ProductCard({p}:{p:Product}){return <Link to={"/product/"+p.id} className="product-card"><div className="product-image"><img loading="lazy" src={p.image} alt={p.name}/><span aria-label="المفضلة"><Heart size={18}/></span></div><div className="product-meta"><div><h3>{p.name}</h3><span>{p.collection}</span></div><strong>{money(p.price)}</strong></div></Link>}
