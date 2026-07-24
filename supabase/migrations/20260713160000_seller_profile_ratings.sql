-- Seller profile stats and reviews (pickup-mode buyer ratings of sellers)

create or replace function public.fetch_seller_profile_stats(p_seller_id uuid)
returns json
language sql
security definer
set search_path = public
stable
as $$
  with seller_ratings as (
    select r.rating
    from public.delivery_partner_ratings r
    inner join public.chat_transactions ct on ct.id = r.transaction_id
    where r.seller_id = p_seller_id
      and ct.fulfillment_mode = 'pickup'
  ),
  rating_agg as (
    select
      count(*)::int as rating_count,
      coalesce(avg(rating), 0)::numeric(3, 2) as avg_rating,
      coalesce(
        round(100.0 * count(*) filter (where rating >= 4) / nullif(count(*), 0)),
        0
      )::int as positive_pct
    from seller_ratings
  )
  select json_build_object(
    'rating_count', ra.rating_count,
    'avg_rating', ra.avg_rating,
    'positive_pct', ra.positive_pct,
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
    'seller_name', (select name from public.profiles where id = p_seller_id)
  )
  from rating_agg ra;
$$;

create or replace function public.fetch_seller_reviews(p_seller_id uuid)
returns json
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(
    json_agg(row_to_json(t) order by t.created_at desc),
    '[]'::json
  )
  from (
    select
      r.id,
      r.rating,
      r.review_text,
      r.created_at,
      p.name as buyer_name,
      l.id as listing_id,
      l.name as listing_name,
      l.make as listing_make,
      l.model as listing_model,
      l.year as listing_year,
      (
        select li.url
        from public.listing_images li
        where li.listing_id = l.id
        order by li.sort_order
        limit 1
      ) as listing_image_url
    from public.delivery_partner_ratings r
    inner join public.chat_transactions ct
      on ct.id = r.transaction_id
      and ct.fulfillment_mode = 'pickup'
    inner join public.profiles p on p.id = r.buyer_id
    left join public.message_threads mt on mt.id = r.thread_id
    left join public.listings l on l.id = mt.listing_id
    where r.seller_id = p_seller_id
  ) t;
$$;

grant execute on function public.fetch_seller_profile_stats(uuid) to authenticated;
grant execute on function public.fetch_seller_reviews(uuid) to authenticated;
