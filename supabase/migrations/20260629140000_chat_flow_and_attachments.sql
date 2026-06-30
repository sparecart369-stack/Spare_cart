-- Guided chat flow state, read tracking, message attachments, realtime

alter table public.message_threads
  add column if not exists flow_step text not null default 'started',
  add column if not exists blocked_until timestamptz,
  add column if not exists agreed_price numeric(12, 2),
  add column if not exists availability_date timestamptz,
  add column if not exists list_price numeric(12, 2) not null default 0,
  add column if not exists pickup_location text not null default '',
  add column if not exists seller_replied_after_token boolean not null default false,
  add column if not exists delivery_choice_made boolean not null default false,
  add column if not exists buyer_last_read_at timestamptz,
  add column if not exists seller_last_read_at timestamptz,
  add column if not exists is_guided boolean not null default true;

alter table public.messages
  add column if not exists image_url text;

create or replace function public.touch_thread_last_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.message_threads
  set last_message_at = new.created_at
  where id = new.thread_id;
  return new;
end;
$$;

drop trigger if exists messages_touch_thread on public.messages;
create trigger messages_touch_thread
  after insert on public.messages
  for each row execute function public.touch_thread_last_message();

create policy "Participants update threads"
  on public.message_threads for update to authenticated
  using (buyer_id = auth.uid() or seller_id = auth.uid())
  with check (buyer_id = auth.uid() or seller_id = auth.uid());

do $$
begin
  alter publication supabase_realtime add table public.messages;
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.message_threads;
exception
  when duplicate_object then null;
end $$;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'chat-attachments',
  'chat-attachments',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

create policy "Users upload chat attachments"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'chat-attachments'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Chat attachments are public"
  on storage.objects for select using (bucket_id = 'chat-attachments');

create policy "Users delete own chat attachments"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'chat-attachments'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
