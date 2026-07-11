-- Optional chassis and part numbers on listings
alter table public.listings
  add column if not exists chassis_number text,
  add column if not exists part_number text;

create index if not exists listings_chassis_number_idx
  on public.listings (chassis_number)
  where chassis_number is not null;

create index if not exists listings_part_number_idx
  on public.listings (part_number)
  where part_number is not null;
