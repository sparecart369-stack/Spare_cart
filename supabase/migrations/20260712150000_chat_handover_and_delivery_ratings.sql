-- Post-delivery handover tracking and delivery partner ratings

create type public.chat_fulfillment_mode as enum ('doorstep', 'pickup');

create type public.chat_transaction_status as enum (
  'pending_handoff',
  'dispatched',
  'buyer_confirmed',
  'seller_confirmed',
  'completed',
  'dispute',
  'refund_requested'
);

create table public.chat_transactions (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null unique references public.message_threads (id) on delete cascade,
  buyer_id uuid not null references public.profiles (id) on delete restrict,
  seller_id uuid not null references public.profiles (id) on delete restrict,
  advance_payment_id uuid references public.chat_payments (id) on delete set null,
  fulfillment_mode public.chat_fulfillment_mode not null,
  agreed_price numeric(12, 2) not null check (agreed_price > 0),
  token_amount numeric(12, 2) not null check (token_amount >= 0),
  remaining_amount numeric(12, 2) not null check (remaining_amount >= 0),
  status public.chat_transaction_status not null default 'pending_handoff',
  delivery_partner_name text,
  dispute_reason text,
  seller_dispatched_at timestamptz,
  buyer_confirmed_at timestamptz,
  seller_confirmed_at timestamptz,
  completed_at timestamptz,
  refund_requested_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index chat_transactions_thread_id_idx on public.chat_transactions (thread_id);
create index chat_transactions_buyer_id_idx on public.chat_transactions (buyer_id);
create index chat_transactions_seller_id_idx on public.chat_transactions (seller_id);
create index chat_transactions_status_idx on public.chat_transactions (status);

create trigger chat_transactions_updated_at
  before update on public.chat_transactions
  for each row execute function public.set_updated_at();

alter table public.chat_transactions enable row level security;

create policy "Participants view own chat transactions"
  on public.chat_transactions for select to authenticated
  using (
    buyer_id = auth.uid()
    or seller_id = auth.uid()
    or public.is_profile_admin(auth.uid())
  );

create policy "Participants insert chat transactions"
  on public.chat_transactions for insert to authenticated
  with check (buyer_id = auth.uid() or seller_id = auth.uid());

create policy "Participants update own chat transactions"
  on public.chat_transactions for update to authenticated
  using (buyer_id = auth.uid() or seller_id = auth.uid())
  with check (buyer_id = auth.uid() or seller_id = auth.uid());

create policy "Admins manage chat transactions"
  on public.chat_transactions for update to authenticated
  using (public.is_profile_admin(auth.uid()))
  with check (public.is_profile_admin(auth.uid()));

create table public.delivery_partner_ratings (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references public.chat_transactions (id) on delete cascade,
  thread_id uuid not null references public.message_threads (id) on delete cascade,
  buyer_id uuid not null references public.profiles (id) on delete restrict,
  seller_id uuid not null references public.profiles (id) on delete restrict,
  delivery_partner_name text not null,
  rating int not null check (rating between 1 and 5),
  review_text text,
  created_at timestamptz not null default now(),
  unique (transaction_id, buyer_id)
);

create index delivery_partner_ratings_thread_id_idx on public.delivery_partner_ratings (thread_id);
create index delivery_partner_ratings_seller_id_idx on public.delivery_partner_ratings (seller_id);
create index delivery_partner_ratings_partner_name_idx on public.delivery_partner_ratings (delivery_partner_name);

alter table public.delivery_partner_ratings enable row level security;

create policy "Participants view delivery partner ratings"
  on public.delivery_partner_ratings for select to authenticated
  using (
    buyer_id = auth.uid()
    or seller_id = auth.uid()
    or public.is_profile_admin(auth.uid())
  );

create policy "Buyers submit delivery partner ratings"
  on public.delivery_partner_ratings for insert to authenticated
  with check (buyer_id = auth.uid());

do $$
begin
  alter publication supabase_realtime add table public.chat_transactions;
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.delivery_partner_ratings;
exception
  when duplicate_object then null;
end $$;
