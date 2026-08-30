# MASAR — مسار

Premium Arabic-first fashion storefront built from the approved MASAR visual reference.

## Stack
- React + TypeScript + Vite
- Supabase Auth + PostgreSQL + RLS
- Responsive RTL UI
- Lucide icons

## Included foundation
- Homepage / brand story / values
- Collections and product detail
- Cart with local persistence
- Checkout UX with gift message
- Login / signup / forgot password / reset password flows
- Customer account
- FAQ / contact / shipping / returns pages
- Admin shell: dashboard, orders, products, customers, admins, settings
- Supabase schema with customer/admin/owner roles and Row Level Security

## Run
1. npm install
2. Copy .env.example to .env
3. Add Supabase URL and anon key
4. Run npm run dev

## Database
Run supabase/schema.sql in the Supabase SQL editor.

Then promote the primary account to owner with the commented SQL at the bottom of the schema.

## Next implementation pass
Connect products, collections, orders, customers and admin actions to Supabase; add real payment integration, image storage, order status history, admin invitation flow and production-grade authorization.
