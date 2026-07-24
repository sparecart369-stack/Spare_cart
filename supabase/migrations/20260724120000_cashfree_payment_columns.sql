-- Rename Razorpay payment ledger columns to Cashfree equivalents.

alter table public.chat_payments
  rename column razorpay_order_id to cashfree_order_id;

alter table public.chat_payments
  rename column razorpay_payment_id to cashfree_payment_id;

alter table public.chat_payments
  rename column razorpay_receipt to cashfree_order_note;

alter table public.chat_payments
  rename column razorpay_signature to cashfree_payment_session_id;

alter table public.chat_payments
  rename column razorpay_payment_status to cashfree_payment_status;

alter table public.chat_payments
  rename column razorpay_refund_id to cashfree_refund_id;

alter table public.chat_payments
  rename column razorpay_order_response to cashfree_order_response;

alter table public.chat_payments
  rename column razorpay_payment_response to cashfree_payment_response;

alter table public.chat_payments
  rename column razorpay_webhook_events to cashfree_webhook_events;

alter table public.chat_payments
  rename column razorpay_refund_response to cashfree_refund_response;

alter index if exists chat_payments_razorpay_order_id_idx
  rename to chat_payments_cashfree_order_id_idx;

comment on table public.chat_payments is
  'Cashfree payment ledger for chat advance token (1% of agreed price).';
