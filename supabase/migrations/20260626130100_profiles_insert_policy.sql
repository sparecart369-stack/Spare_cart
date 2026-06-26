-- Allow authenticated users to create their own profile when the auth trigger
-- did not run (e.g. duplicate phone from a prior orphaned profile).

create policy "Users can insert own profile"
  on public.profiles for insert to authenticated
  with check (auth.uid() = id);

-- Remove profiles left behind when auth users were deleted from the dashboard.
delete from public.profiles p
where not exists (
  select 1 from auth.users u where u.id = p.id
);
