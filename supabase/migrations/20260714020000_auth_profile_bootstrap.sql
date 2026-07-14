alter table public.profiles
  add column if not exists city text;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (
    id,
    email,
    full_name,
    phone,
    city,
    role
  )
  values (
    new.id,
    coalesce(new.email, new.id::text || '@auth.local'),
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Pet owner'
    ),
    nullif(trim(new.raw_user_meta_data ->> 'phone'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'city'), ''),
    case
      when new.raw_user_meta_data ->> 'role' in ('pet_owner', 'clinic_owner')
        then new.raw_user_meta_data ->> 'role'
      else 'pet_owner'
    end
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

insert into public.profiles (
  id,
  email,
  full_name,
  phone,
  city,
  role
)
select
  auth_user.id,
  coalesce(auth_user.email, auth_user.id::text || '@auth.local'),
  coalesce(
    nullif(trim(auth_user.raw_user_meta_data ->> 'full_name'), ''),
    nullif(trim(auth_user.raw_user_meta_data ->> 'name'), ''),
    nullif(split_part(coalesce(auth_user.email, ''), '@', 1), ''),
    'Pet owner'
  ),
  nullif(trim(auth_user.raw_user_meta_data ->> 'phone'), ''),
  nullif(trim(auth_user.raw_user_meta_data ->> 'city'), ''),
  case
    when auth_user.raw_user_meta_data ->> 'role' in ('pet_owner', 'clinic_owner')
      then auth_user.raw_user_meta_data ->> 'role'
    else 'pet_owner'
  end
from auth.users auth_user
on conflict (id) do nothing;
