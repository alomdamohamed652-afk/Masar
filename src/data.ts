export type Product = {
  id: string; slug?: string; name: string; price: number; image: string; collection: string;
  sizes: string[]; colors: string[]; description: string; stock: number;
};

export const products: Product[] = [
  { id:"p1", name:"هودي مسار الأسود", price:1290, image:"https://images.unsplash.com/photo-1556821840-3a63f95609a7?auto=format&fit=crop&w=900&q=85", collection:"الإصدار الأسود", sizes:["S","M","L","XL"], colors:["أسود"], description:"هودي بقصة نظيفة وخامة ثقيلة مصمم للاستخدام اليومي.", stock:24 },
  { id:"p2", name:"بنطال مسار الزيتوني", price:990, image:"https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=900&q=85", collection:"الأخضر الشرقي", sizes:["S","M","L","XL"], colors:["زيتوني"], description:"بنطال عملي بتفاصيل هادئة وقصة مريحة.", stock:18 },
  { id:"p3", name:"قميص مسار الأبيض", price:890, image:"https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?auto=format&fit=crop&w=900&q=85", collection:"الأبيض النقي", sizes:["S","M","L","XL"], colors:["أبيض"], description:"قميص أبيض بسيط يركز على الخامة والتفاصيل.", stock:31 }
];

export const collections = [
  { id:"black", name:"الإصدار الأسود", subtitle:"قطع سوداء بتصميم جريء", image:products[0].image },
  { id:"olive", name:"الأخضر الشرقي", subtitle:"هدوء مستوحى من البيئة", image:products[1].image },
  { id:"white", name:"الأبيض النقي", subtitle:"أناقة بسيطة ونظيفة", image:products[2].image }
];