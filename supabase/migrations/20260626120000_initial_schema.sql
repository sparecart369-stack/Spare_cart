-- SpareKart production schema
-- Marketplace: listings, cart, orders, messaging, notifications

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
create type public.user_role as enum ('buyer', 'seller', 'admin');
create type public.part_condition as enum ('used', 'refurbished', 'new_part');
create type public.listing_fulfillment as enum ('doorstep_delivery', 'in_store_pickup');
create type public.listing_status as enum ('draft', 'active', 'sold', 'archived');
create type public.order_status as enum ('paid', 'shipped', 'delivered', 'cancelled');
create type public.notification_type as enum ('order', 'message', 'listing', 'system');

-- ---------------------------------------------------------------------------
-- Profiles (extends auth.users)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null default '',
  phone text not null unique,
  avatar_url text,
  positive_feedback_pct numeric(5, 2) not null default 98.00,
  role public.user_role not null default 'buyer',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index profiles_phone_idx on public.profiles (phone);

-- ---------------------------------------------------------------------------
-- Seller bank accounts
-- ---------------------------------------------------------------------------
create table public.seller_bank_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles (id) on delete cascade,
  upi_id text not null,
  bank_name text not null,
  account_number text not null,
  account_name text not null,
  ifsc_code text not null,
  is_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Addresses
-- ---------------------------------------------------------------------------
create table public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  label text not null default 'Home',
  full_name text not null,
  street text not null,
  city text not null,
  state text not null,
  zip text not null,
  country text not null default 'IN',
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index addresses_user_id_idx on public.addresses (user_id);

-- ---------------------------------------------------------------------------
-- Catalog reference data
-- ---------------------------------------------------------------------------
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  icon text,
  sort_order int not null default 0
);

create table public.vehicle_makes (
  id uuid primary key default gen_random_uuid(),
  name text not null unique
);

create table public.vehicle_models (
  id uuid primary key default gen_random_uuid(),
  make_id uuid not null references public.vehicle_makes (id) on delete cascade,
  name text not null,
  unique (make_id, name)
);

-- ---------------------------------------------------------------------------
-- Listings
-- ---------------------------------------------------------------------------
create table public.listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  category text not null,
  make text not null,
  model text not null,
  year int not null check (year >= 1900 and year <= 2100),
  condition public.part_condition not null default 'used',
  price numeric(12, 2) not null check (price >= 0),
  location text not null,
  description text not null default '',
  fulfillment public.listing_fulfillment not null default 'doorstep_delivery',
  pickup_address text,
  status public.listing_status not null default 'active',
  is_admin_listing boolean not null default false,
  seller_rating numeric(3, 2) not null default 4.80,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index listings_seller_id_idx on public.listings (seller_id);
create index listings_status_idx on public.listings (status);
create index listings_category_idx on public.listings (category);
create index listings_make_model_idx on public.listings (make, model);

create table public.listing_images (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings (id) on delete cascade,
  url text not null,
  sort_order int not null default 0
);

create index listing_images_listing_id_idx on public.listing_images (listing_id);

create table public.listing_compatibility (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings (id) on delete cascade,
  vehicle_label text not null
);

create index listing_compatibility_listing_id_idx on public.listing_compatibility (listing_id);

create table public.saved_listings (
  user_id uuid not null references public.profiles (id) on delete cascade,
  listing_id uuid not null references public.listings (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);

-- ---------------------------------------------------------------------------
-- Cart
-- ---------------------------------------------------------------------------
create table public.carts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles (id) on delete cascade,
  updated_at timestamptz not null default now()
);

create table public.cart_items (
  id uuid primary key default gen_random_uuid(),
  cart_id uuid not null references public.carts (id) on delete cascade,
  listing_id uuid not null references public.listings (id) on delete cascade,
  quantity int not null default 1 check (quantity > 0),
  unique (cart_id, listing_id)
);

create index cart_items_cart_id_idx on public.cart_items (cart_id);

-- ---------------------------------------------------------------------------
-- Orders
-- ---------------------------------------------------------------------------
create table public.orders (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references public.profiles (id) on delete restrict,
  status public.order_status not null default 'paid',
  subtotal numeric(12, 2) not null default 0,
  shipping numeric(12, 2) not null default 0,
  total numeric(12, 2) not null default 0,
  tracking_number text,
  shipping_method text,
  payment_method text,
  shipping_address_id uuid references public.addresses (id) on delete set null,
  placed_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index orders_buyer_id_idx on public.orders (buyer_id);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  listing_id uuid not null references public.listings (id) on delete restrict,
  seller_id uuid not null references public.profiles (id) on delete restrict,
  quantity int not null default 1 check (quantity > 0),
  unit_price numeric(12, 2) not null check (unit_price >= 0)
);

create index order_items_order_id_idx on public.order_items (order_id);

-- ---------------------------------------------------------------------------
-- Messaging
-- ---------------------------------------------------------------------------
create table public.message_threads (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid references public.listings (id) on delete set null,
  buyer_id uuid not null references public.profiles (id) on delete cascade,
  seller_id uuid not null references public.profiles (id) on delete cascade,
  part_title text not null default '',
  last_message_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (listing_id, buyer_id, seller_id)
);

create index message_threads_buyer_id_idx on public.message_threads (buyer_id);
create index message_threads_seller_id_idx on public.message_threads (seller_id);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.message_threads (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  text text not null check (char_length(trim(text)) > 0),
  created_at timestamptz not null default now()
);

create index messages_thread_id_idx on public.messages (thread_id);

create table public.message_read_receipts (
  message_id uuid not null references public.messages (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

-- ---------------------------------------------------------------------------
-- Notifications
-- ---------------------------------------------------------------------------
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  body text not null,
  is_read boolean not null default false,
  type public.notification_type not null default 'system',
  reference_id uuid,
  created_at timestamptz not null default now()
);

create index notifications_user_id_idx on public.notifications (user_id);

-- ---------------------------------------------------------------------------
-- Updated-at trigger
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger seller_bank_accounts_updated_at before update on public.seller_bank_accounts
  for each row execute function public.set_updated_at();
create trigger addresses_updated_at before update on public.addresses
  for each row execute function public.set_updated_at();
create trigger listings_updated_at before update on public.listings
  for each row execute function public.set_updated_at();
create trigger orders_updated_at before update on public.orders
  for each row execute function public.set_updated_at();
create trigger carts_updated_at before update on public.carts
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Auto-create profile on signup
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', ''),
    coalesce(new.raw_user_meta_data ->> 'phone', new.email)
  );
  insert into public.carts (user_id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.seller_bank_accounts enable row level security;
alter table public.addresses enable row level security;
alter table public.categories enable row level security;
alter table public.vehicle_makes enable row level security;
alter table public.vehicle_models enable row level security;
alter table public.listings enable row level security;
alter table public.listing_images enable row level security;
alter table public.listing_compatibility enable row level security;
alter table public.saved_listings enable row level security;
alter table public.carts enable row level security;
alter table public.cart_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.message_threads enable row level security;
alter table public.messages enable row level security;
alter table public.message_read_receipts enable row level security;
alter table public.notifications enable row level security;

-- Profiles
create policy "Profiles are viewable by everyone"
  on public.profiles for select using (true);
create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);

-- Seller bank accounts
create policy "Users manage own bank account"
  on public.seller_bank_accounts for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Addresses
create policy "Users manage own addresses"
  on public.addresses for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Catalog (read-only for all authenticated)
create policy "Categories readable by authenticated"
  on public.categories for select to authenticated using (true);
create policy "Makes readable by authenticated"
  on public.vehicle_makes for select to authenticated using (true);
create policy "Models readable by authenticated"
  on public.vehicle_models for select to authenticated using (true);

-- Listings
create policy "Active listings readable by authenticated"
  on public.listings for select to authenticated
  using (status = 'active' or seller_id = auth.uid());
create policy "Sellers manage own listings"
  on public.listings for insert to authenticated
  with check (seller_id = auth.uid());
create policy "Sellers update own listings"
  on public.listings for update to authenticated
  using (seller_id = auth.uid());
create policy "Sellers delete own listings"
  on public.listings for delete to authenticated
  using (seller_id = auth.uid());

-- Listing images & compatibility (via listing ownership)
create policy "Listing images readable"
  on public.listing_images for select to authenticated using (true);
create policy "Sellers manage listing images"
  on public.listing_images for all to authenticated
  using (exists (
    select 1 from public.listings l
    where l.id = listing_id and l.seller_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.listings l
    where l.id = listing_id and l.seller_id = auth.uid()
  ));

create policy "Listing compatibility readable"
  on public.listing_compatibility for select to authenticated using (true);
create policy "Sellers manage listing compatibility"
  on public.listing_compatibility for all to authenticated
  using (exists (
    select 1 from public.listings l
    where l.id = listing_id and l.seller_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.listings l
    where l.id = listing_id and l.seller_id = auth.uid()
  ));

-- Saved listings
create policy "Users manage saved listings"
  on public.saved_listings for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Cart
create policy "Users manage own cart"
  on public.carts for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
create policy "Users manage own cart items"
  on public.cart_items for all
  using (exists (
    select 1 from public.carts c
    where c.id = cart_id and c.user_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.carts c
    where c.id = cart_id and c.user_id = auth.uid()
  ));

-- Orders
create policy "Buyers view own orders"
  on public.orders for select to authenticated
  using (buyer_id = auth.uid());
create policy "Buyers create orders"
  on public.orders for insert to authenticated
  with check (buyer_id = auth.uid());
create policy "Sellers view orders with their items"
  on public.orders for select to authenticated
  using (exists (
    select 1 from public.order_items oi
    where oi.order_id = id and oi.seller_id = auth.uid()
  ));
create policy "Order items readable by participants"
  on public.order_items for select to authenticated
  using (
    exists (select 1 from public.orders o where o.id = order_id and o.buyer_id = auth.uid())
    or seller_id = auth.uid()
  );
create policy "Buyers create order items"
  on public.order_items for insert to authenticated
  with check (exists (
    select 1 from public.orders o where o.id = order_id and o.buyer_id = auth.uid()
  ));

-- Messaging
create policy "Participants view threads"
  on public.message_threads for select to authenticated
  using (buyer_id = auth.uid() or seller_id = auth.uid());
create policy "Buyers create threads"
  on public.message_threads for insert to authenticated
  with check (buyer_id = auth.uid());
create policy "Participants view messages"
  on public.messages for select to authenticated
  using (exists (
    select 1 from public.message_threads t
    where t.id = thread_id and (t.buyer_id = auth.uid() or t.seller_id = auth.uid())
  ));
create policy "Participants send messages"
  on public.messages for insert to authenticated
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.message_threads t
      where t.id = thread_id and (t.buyer_id = auth.uid() or t.seller_id = auth.uid())
    )
  );
create policy "Users manage read receipts"
  on public.message_read_receipts for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Notifications
create policy "Users manage own notifications"
  on public.notifications for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Storage buckets
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('listing-images', 'listing-images', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('avatars', 'avatars', true, 2097152, array['image/jpeg', 'image/png', 'image/webp']),
  ('ai-part-finder', 'ai-part-finder', false, 10485760, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

create policy "Authenticated users upload listing images"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'listing-images' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "Listing images are public"
  on storage.objects for select using (bucket_id = 'listing-images');
create policy "Users update own listing images"
  on storage.objects for update to authenticated
  using (bucket_id = 'listing-images' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "Users delete own listing images"
  on storage.objects for delete to authenticated
  using (bucket_id = 'listing-images' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Users upload own avatar"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "Avatars are public"
  on storage.objects for select using (bucket_id = 'avatars');
create policy "Users manage own avatar"
  on storage.objects for all to authenticated
  using (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Users upload AI finder images"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'ai-part-finder' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "Users read own AI finder images"
  on storage.objects for select to authenticated
  using (bucket_id = 'ai-part-finder' and auth.uid()::text = (storage.foldername(name))[1]);

-- ---------------------------------------------------------------------------
-- Seed catalog data
-- ---------------------------------------------------------------------------
insert into public.categories (name, icon, sort_order) values
  ('Engine', 'engine', 1),
  ('Transmission', 'transmission', 2),
  ('Body Parts', 'body', 3),
  ('Lighting', 'lighting', 4),
  ('Brakes', 'brakes', 5),
  ('Suspension', 'suspension', 6),
  ('Electrical', 'electrical', 7),
  ('Interior', 'interior', 8)
on conflict (name) do nothing;

insert into public.vehicle_makes (name) values
  ('Toyota'), ('Honda'), ('Ford'), ('BMW'), ('Mercedes-Benz'),
  ('Hyundai'), ('Kia'), ('Maruti Suzuki'), ('Tata'), ('Mahindra')
on conflict (name) do nothing;
