-- Break infinite recursion between orders <-> order_items RLS policies.
-- Cross-table EXISTS checks re-enter RLS; security definer helpers bypass it.

create or replace function public.is_buyer_for_order(order_uuid uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.orders
    where id = order_uuid and buyer_id = auth.uid()
  );
$$;

create or replace function public.is_seller_for_order(order_uuid uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.order_items
    where order_id = order_uuid and seller_id = auth.uid()
  );
$$;

drop policy if exists "Sellers view orders with their items" on public.orders;
create policy "Sellers view orders with their items"
  on public.orders for select to authenticated
  using (public.is_seller_for_order(id));

drop policy if exists "Order items readable by participants" on public.order_items;
create policy "Order items readable by participants"
  on public.order_items for select to authenticated
  using (
    seller_id = auth.uid()
    or public.is_buyer_for_order(order_id)
  );

drop policy if exists "Buyers create order items" on public.order_items;
create policy "Buyers create order items"
  on public.order_items for insert to authenticated
  with check (public.is_buyer_for_order(order_id));
