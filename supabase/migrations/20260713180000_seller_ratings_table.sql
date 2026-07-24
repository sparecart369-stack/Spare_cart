-- Dedicated seller ratings (decoupled from delivery partner ratings + fulfillment_mode bugs)

create table if not exists public.seller_ratings (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references public.chat_transactions (id) on delete cascade,
  thread_id uuid not null references public.message_threads (id) on delete cascade,
  buyer_id uuid not null references public.profiles (id) on delete restrict,
  seller_id uuid not null references public.profiles (id) on delete restrict,
  listing_id uuid references public.listings (id) on delete set null,
  rating int not null check (rating between 1 and 5),
  review_text text,
  created_at timestamptz not null default now(),
  unique (transaction_id, buyer_id)
);

create index if not exists seller_ratings_seller_id_idx on public.seller_ratings (seller_id);
create index if not exists seller_ratings_listing_id_idx on public.seller_ratings (listing_id);
create index if not exists seller_ratings_created_at_idx on public.seller_ratings (created_at desc);

alter table public.seller_ratings enable row level security;

create policy "Authenticated users view seller ratings"
  on public.seller_ratings for select to authenticated
  using (true);

create policy "Buyers submit seller ratings"
  on public.seller_ratings for insert to authenticated
  with check (buyer_id = auth.uid());

create policy "Buyers update own seller ratings"
  on public.seller_ratings for update to authenticated
  using (buyer_id = auth.uid())
  with check (buyer_id = auth.uid());

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
  from public.seller_ratings r
  where r.seller_id = p_seller_id;

  if v_count > 0 then
    select coalesce(
      round(100.0 * count(*) filter (where r.rating >= 4) / v_count),
      0
    )::int
    into v_positive
    from public.seller_ratings r
    where r.seller_id = p_seller_id;
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

create or replace function public.upsert_seller_rating(
  p_transaction_id uuid,
  p_rating int,
  p_review_text text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tx public.chat_transactions%rowtype;
  v_listing_id uuid;
begin
  select * into v_tx
  from public.chat_transactions
  where id = p_transaction_id;

  if not found then
    return;
  end if;

  select listing_id into v_listing_id
  from public.message_threads
  where id = v_tx.thread_id;

  insert into public.seller_ratings (
    transaction_id,
    thread_id,
    buyer_id,
    seller_id,
    listing_id,
    rating,
    review_text
  )
  values (
    v_tx.id,
    v_tx.thread_id,
    v_tx.buyer_id,
    v_tx.seller_id,
    v_listing_id,
    p_rating,
    nullif(trim(p_review_text), '')
  )
  on conflict (transaction_id, buyer_id) do update
  set
    rating = excluded.rating,
    review_text = excluded.review_text,
    listing_id = coalesce(excluded.listing_id, public.seller_ratings.listing_id);

  perform public.refresh_seller_rating_stats(v_tx.seller_id);
end;
$$;

grant execute on function public.upsert_seller_rating(uuid, int, text) to authenticated;
grant execute on function public.refresh_seller_rating_stats(uuid) to authenticated;

create or replace function public.sync_seller_rating_from_delivery_rating()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_fulfillment public.chat_fulfillment_mode;
  v_seller_name text;
  v_is_seller_rating boolean := false;
begin
  select ct.fulfillment_mode into v_fulfillment
  from public.chat_transactions ct
  where ct.id = new.transaction_id;

  select p.name into v_seller_name
  from public.profiles p
  where p.id = new.seller_id;

  v_is_seller_rating := v_fulfillment = 'pickup'
    or (
      v_seller_name is not null
      and lower(trim(new.delivery_partner_name)) = lower(trim(v_seller_name))
    );

  if v_is_seller_rating then
    perform public.upsert_seller_rating(
      new.transaction_id,
      new.rating,
      new.review_text
    );
  end if;

  return new;
end;
$$;

drop trigger if exists delivery_partner_ratings_sync_seller_rating
  on public.delivery_partner_ratings;

create or replace function public.on_seller_rating_changed()
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

create trigger delivery_partner_ratings_sync_seller_rating
  after insert or update on public.delivery_partner_ratings
  for each row execute function public.sync_seller_rating_from_delivery_rating();

drop trigger if exists seller_ratings_refresh_seller_stats
  on public.seller_ratings;

create trigger seller_ratings_refresh_seller_stats
  after insert or update or delete on public.seller_ratings
  for each row execute function public.on_seller_rating_changed();

-- Backfill seller ratings from existing delivery partner ratings
insert into public.seller_ratings (
  transaction_id,
  thread_id,
  buyer_id,
  seller_id,
  listing_id,
  rating,
  review_text,
  created_at
)
select
  r.transaction_id,
  r.thread_id,
  r.buyer_id,
  r.seller_id,
  mt.listing_id,
  r.rating,
  r.review_text,
  r.created_at
from public.delivery_partner_ratings r
inner join public.chat_transactions ct on ct.id = r.transaction_id
left join public.message_threads mt on mt.id = r.thread_id
left join public.profiles p on p.id = r.seller_id
where ct.fulfillment_mode = 'pickup'
   or (
     p.name is not null
     and lower(trim(r.delivery_partner_name)) = lower(trim(p.name))
   )
on conflict (transaction_id, buyer_id) do nothing;

-- Refresh all sellers with ratings
do $$
declare
  seller_row record;
begin
  for seller_row in
    select distinct seller_id from public.seller_ratings
  loop
    perform public.refresh_seller_rating_stats(seller_row.seller_id);
  end loop;
end $$;

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
    from public.seller_ratings r
    inner join public.profiles p on p.id = r.buyer_id
    left join public.listings l on l.id = r.listing_id
    where r.seller_id = p_seller_id
  ) t;
$$;

create or replace function public.fetch_seller_profile_stats(p_seller_id uuid)
returns json
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(
    json_build_object(
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
    ),
    json_build_object(
      'rating_count', 0,
      'avg_rating', 0,
      'positive_pct', 0,
      'listings_count', 0,
      'orders_count', 0,
      'seller_name', null
    )
  )
  from public.profiles p
  where p.id = p_seller_id;
$$;

-- Remove old trigger that only refreshed from delivery_partner_ratings directly
drop trigger if exists delivery_partner_ratings_refresh_seller_stats
  on public.delivery_partner_ratings;
