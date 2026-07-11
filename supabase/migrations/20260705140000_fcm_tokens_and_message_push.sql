-- FCM device tokens on profiles + in-app notification rows for new chat messages

alter table public.profiles
  add column if not exists fcm_tokens text[] not null default '{}';

create index if not exists profiles_fcm_tokens_idx on public.profiles using gin (fcm_tokens);

-- ---------------------------------------------------------------------------
-- FCM token helpers (users manage only their own tokens)
-- ---------------------------------------------------------------------------
create or replace function public.add_fcm_token(token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  if token is null or length(trim(token)) = 0 then
    return;
  end if;
  update public.profiles
  set
    fcm_tokens = (
      select coalesce(array_agg(distinct t), '{}')
      from unnest(coalesce(fcm_tokens, '{}') || array[trim(token)]) as t
      where length(t) > 0
    ),
    updated_at = now()
  where id = auth.uid();
end;
$$;

create or replace function public.remove_fcm_token(token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  if token is null or length(trim(token)) = 0 then
    return;
  end if;
  update public.profiles
  set
    fcm_tokens = coalesce(
      array_remove(fcm_tokens, trim(token)),
      '{}'
    ),
    updated_at = now()
  where id = auth.uid();
end;
$$;

grant execute on function public.add_fcm_token(text) to authenticated;
grant execute on function public.remove_fcm_token(text) to authenticated;

-- ---------------------------------------------------------------------------
-- Create an in-app notification when a chat message is sent
-- ---------------------------------------------------------------------------
create or replace function public.notify_on_new_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  thread_row public.message_threads%rowtype;
  recipient_id uuid;
  sender_name text;
  preview text;
begin
  select * into thread_row
  from public.message_threads
  where id = new.thread_id;

  if not found then
    return new;
  end if;

  if new.sender_id = thread_row.buyer_id then
    recipient_id := thread_row.seller_id;
  else
    recipient_id := thread_row.buyer_id;
  end if;

  if recipient_id is null or recipient_id = new.sender_id then
    return new;
  end if;

  select name into sender_name
  from public.profiles
  where id = new.sender_id;

  preview := left(trim(coalesce(new.text, '')), 120);
  if preview = '' and new.image_url is not null then
    preview := 'Sent an image';
  end if;
  if preview = '' then
    preview := 'New message';
  end if;

  insert into public.notifications (
    user_id,
    title,
    body,
    type,
    reference_id,
    is_read
  ) values (
    recipient_id,
    coalesce(nullif(trim(sender_name), ''), 'New message'),
    preview,
    'message',
    new.thread_id,
    false
  );

  return new;
end;
$$;

drop trigger if exists messages_notify_recipient on public.messages;
create trigger messages_notify_recipient
  after insert on public.messages
  for each row
  execute function public.notify_on_new_message();
