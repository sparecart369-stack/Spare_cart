-- Optional subcategory on listings for finer part taxonomy.
alter table public.listings
  add column if not exists subcategory text;

create index if not exists listings_subcategory_idx
  on public.listings (subcategory)
  where subcategory is not null;
