-- Expand chat_payments into full Razorpay payment ledger

comment on table public.chat_payments is
  'Razorpay payment ledger for chat advance token (1% of agreed price).';

alter table public.chat_payments
  add column if not exists listing_id uuid references public.listings (id) on delete set null,
  add column if not exists part_title text not null default '',
  add column if not exists buyer_name text not null default '',
  add column if not exists seller_name text not null default '',
  add column if not exists token_percent numeric(5, 4) not null default 0.01,
  add column if not exists razorpay_receipt text,
  add column if not exists payment_method text,
  add column if not exists razorpay_payment_status text,
  add column if not exists razorpay_order_response jsonb not null default '{}'::jsonb,
  add column if not exists razorpay_payment_response jsonb not null default '{}'::jsonb,
  add column if not exists razorpay_webhook_events jsonb not null default '[]'::jsonb,
  add column if not exists razorpay_refund_response jsonb,
  add column if not exists failure_code text,
  add column if not exists failure_description text;

create index if not exists chat_payments_listing_id_idx on public.chat_payments (listing_id);
create index if not exists chat_payments_created_at_idx on public.chat_payments (created_at desc);
