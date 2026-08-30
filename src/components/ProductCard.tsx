import type { Product } from "../data";

function ProductCard({p}:{p:Product}){return <Link to={"/product/"+p.id} className="product-card"><div className="product-image"><img loading="lazy" src={p.image} alt={p.name}/><span aria-label="المفضلة"><Heart size={18}/></span></div><div className="product-meta"><div><h3>{p.name}</h3><span>{p.collection}</span></div><strong>{money(p.price)}</strong></div></Link>}
