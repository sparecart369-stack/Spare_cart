-- Operating countries: where the user buys, sells, and distributes spares.

alter table public.profiles
  add column if not exists operating_countries text[] not null default '{}',
  add column if not exists operates_globally boolean not null default false;

comment on column public.profiles.operating_countries is
  'ISO 3166-1 alpha-2 country codes where the user operates.';
comment on column public.profiles.operates_globally is
  'When true, the user operates in all countries (operating_countries is ignored).';

-- Keep trigger-created profiles in sync with signup metadata.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  global_flag boolean := coalesce((meta ->> 'operates_globally')::boolean, false);
  country_codes text[];
begin
  if meta ? 'operating_countries' and jsonb_typeof(meta -> 'operating_countries') = 'array' then
    select coalesce(array_agg(elem), '{}')
    into country_codes
    from jsonb_array_elements_text(meta -> 'operating_countries') as elem
    where char_length(elem) = 2;
  else
    country_codes := '{}';
  end if;

  insert into public.profiles (id, name, phone, operating_countries, operates_globally)
  values (
    new.id,
    coalesce(meta ->> 'name', ''),
    coalesce(meta ->> 'phone', new.email),
    country_codes,
    global_flag
  );
  insert into public.carts (user_id) values (new.id);
  return new;
end;
$$;
