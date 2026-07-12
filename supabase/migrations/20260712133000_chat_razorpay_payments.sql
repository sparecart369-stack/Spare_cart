-- Razorpay token payments for guided chat checkout (1% of agreed price)

create type public.chat_payment_status as enum (
  'pending',
  'paid',
  'failed',
  'refund_requested',
  'refunded'
);

create table public.chat_payments (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.message_threads (id) on delete cascade,
  buyer_id uuid not null references public.profiles (id) on delete restrict,
  seller_id uuid not null references public.profiles (id) on delete restrict,
  agreed_price numeric(12, 2) not null check (agreed_price > 0),
  token_amount numeric(12, 2) not null check (token_amount > 0),
  amount_paise int not null check (amount_paise >= 100),
  currency text not null default 'INR',
  razorpay_order_id text unique,
  razorpay_payment_id text,
  razorpay_signature text,
  status public.chat_payment_status not null default 'pending',
  refund_requested_at timestamptz,
  refund_reason text,
  refund_approved_by uuid references public.profiles (id) on delete set null,
  refund_approved_at timestamptz,
  razorpay_refund_id text,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index chat_payments_thread_id_idx on public.chat_payments (thread_id);
create index chat_payments_buyer_id_idx on public.chat_payments (buyer_id);
create index chat_payments_status_idx on public.chat_payments (status);
create index chat_payments_razorpay_order_id_idx on public.chat_payments (razorpay_order_id);

create trigger chat_payments_updated_at
  before update on public.chat_payments
  for each row execute function public.set_updated_at();

alter table public.chat_payments enable row level security;

create or replace function public.is_profile_admin(profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = profile_id and role = 'admin'
  );
$$;

create policy "Buyers and sellers view own chat payments"
  on public.chat_payments for select to authenticated
  using (
    buyer_id = auth.uid()
    or seller_id = auth.uid()
    or public.is_profile_admin(auth.uid())
  );

create policy "Buyers create pending chat payments"
  on public.chat_payments for insert to authenticated
  with check (buyer_id = auth.uid());

create policy "Buyers request refunds on paid payments"
  on public.chat_payments for update to authenticated
  using (buyer_id = auth.uid())
  with check (buyer_id = auth.uid());

create policy "Admins manage chat payment refunds"
  on public.chat_payments for update to authenticated
  using (public.is_profile_admin(auth.uid()))
  with check (public.is_profile_admin(auth.uid()));

do $$
begin
  alter publication supabase_realtime add table public.chat_payments;
exception
  when duplicate_object then null;
end $$;
