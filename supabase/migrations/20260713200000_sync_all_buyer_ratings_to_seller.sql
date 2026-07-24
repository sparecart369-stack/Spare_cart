-- Seller profile ratings were only synced for pickup / name-matched delivery ratings.
-- Doorstep buyers rate after delivery; those scores should update the seller profile too.

create or replace function public.sync_seller_rating_from_delivery_rating()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.upsert_seller_rating(
    new.transaction_id,
    new.rating,
    new.review_text
  );

  return new;
end;
$$;

drop trigger if exists delivery_partner_ratings_sync_seller_rating
  on public.delivery_partner_ratings;

create trigger delivery_partner_ratings_sync_seller_rating
  after insert or update on public.delivery_partner_ratings
  for each row execute function public.sync_seller_rating_from_delivery_rating();

-- Backfill seller ratings from existing buyer post-delivery ratings.
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
left join public.message_threads mt on mt.id = r.thread_id
on conflict (transaction_id, buyer_id) do update
set
  rating = excluded.rating,
  review_text = excluded.review_text,
  listing_id = coalesce(excluded.listing_id, public.seller_ratings.listing_id);

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
