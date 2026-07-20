-- Keep the active owner plan in sync across the admin panel and mobile app.
-- Row Level Security on owner_entitlements remains the access boundary.
do $$
begin
  if exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'owner_entitlements'
  ) then
    alter publication supabase_realtime
      add table public.owner_entitlements;
  end if;
end
$$;
