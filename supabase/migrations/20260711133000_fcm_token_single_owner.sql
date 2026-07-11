-- A device FCM token should belong to only one logged-in user at a time.
-- When a user registers a token, remove it from every other profile first.

create or replace function public.add_fcm_token(token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized text := trim(token);
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  if normalized is null or length(normalized) = 0 then
    return;
  end if;

  -- This device is active for the current user; detach it from other accounts.
  update public.profiles
  set
    fcm_tokens = coalesce(array_remove(fcm_tokens, normalized), '{}'),
    updated_at = now()
  where id <> auth.uid()
    and normalized = any(fcm_tokens);

  update public.profiles
  set
    fcm_tokens = (
      select coalesce(array_agg(distinct t), '{}')
      from unnest(coalesce(fcm_tokens, '{}') || array[normalized]) as t
      where length(t) > 0
    ),
    updated_at = now()
  where id = auth.uid();
end;
$$;
