-- Cached seller rating aggregates on profiles (pickup-mode buyer ratings)

alter table public.profiles
  add column if not exists seller_avg_rating numeric(3, 2),
  add column if not exists seller_rating_count int not null default 0;

create or replace function public.refresh_seller_rating_stats(p_seller_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
  v_avg numeric(3, 2);
  v_positive int;
begin
  select count(*)::int, coalesce(avg(r.rating), 0)::numeric(3, 2)
  into v_count, v_avg
  from public.delivery_partner_ratings r
  inner join public.chat_transactions ct on ct.id = r.transaction_id
  where r.seller_id = p_seller_id
    and ct.fulfillment_mode = 'pickup';

  if v_count > 0 then
    select coalesce(
      round(100.0 * count(*) filter (where r.rating >= 4) / v_count),
      0
    )::int
    into v_positive
    from public.delivery_partner_ratings r
    inner join public.chat_transactions ct on ct.id = r.transaction_id
    where r.seller_id = p_seller_id
      and ct.fulfillment_mode = 'pickup';
  else
    v_positive := null;
  end if;

  update public.profiles
  set
    seller_avg_rating = case when v_count > 0 then v_avg else null end,
    seller_rating_count = v_count,
    positive_feedback_pct = coalesce(v_positive, positive_feedback_pct)
  where id = p_seller_id;
end;
$$;

create or replace function public.on_delivery_partner_rating_changed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    perform public.refresh_seller_rating_stats(old.seller_id);
    return old;
  end if;

  perform public.refresh_seller_rating_stats(new.seller_id);
  return new;
end;
$$;

drop trigger if exists delivery_partner_ratings_refresh_seller_stats
  on public.delivery_partner_ratings;

create trigger delivery_partner_ratings_refresh_seller_stats
  after insert or update or delete on public.delivery_partner_ratings
  for each row execute function public.on_delivery_partner_rating_changed();

-- Backfill existing seller ratings
do $$
declare
  seller_row record;
begin
  for seller_row in
    select distinct r.seller_id
    from public.delivery_partner_ratings r
    inner join public.chat_transactions ct on ct.id = r.transaction_id
    where ct.fulfillment_mode = 'pickup'
  loop
    perform public.refresh_seller_rating_stats(seller_row.seller_id);
  end loop;
end $$;

-- Prefer cached profile stats in seller profile RPC
create or replace function public.fetch_seller_profile_stats(p_seller_id uuid)
returns json
language sql
security definer
set search_path = public
stable
as $$
  select json_build_object(
    'rating_count', coalesce(p.seller_rating_count, 0),
    'avg_rating', coalesce(p.seller_avg_rating, 0),
    'positive_pct', coalesce(p.positive_feedback_pct, 0)::int,
    'listings_count', (
      select count(*)::int
      from public.listings
      where seller_id = p_seller_id
        and status = 'active'
    ),
    'orders_count', (
      select count(*)::int
      from public.chat_transactions
      where seller_id = p_seller_id
        and status = 'completed'
    ),
    'seller_name', p.name
  )
  from public.profiles p
  where p.id = p_seller_id;
$$;
