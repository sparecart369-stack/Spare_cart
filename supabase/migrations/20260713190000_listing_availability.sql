-- Allow sellers to mark listings as temporarily unavailable without archiving them.

alter table public.listings
  add column if not exists is_available boolean not null default true;

create index if not exists listings_is_available_idx
  on public.listings (is_available)
  where status = 'active';
