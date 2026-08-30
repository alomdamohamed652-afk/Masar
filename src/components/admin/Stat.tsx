import React from "react";
import { Package } from "lucide-react";

export function Stat({title,value,icon:Icon}:{title:string,value:string,icon?:React.ComponentType<{size?:number}>}){return <article className="stat-card"><div className="stat-icon">{Icon?<Icon size={20}/>:<Package size={20}/>}</div><span>{title}</span><strong>{value}</strong></article>}
