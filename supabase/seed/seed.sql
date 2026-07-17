-- Owner-only demo data for local testing.
--
-- Create a fake Supabase Auth user with email
-- demo.pet.owner@example.com before running this seed.
-- Never use real user, pet, or medical data.

insert into public.profiles (id, email, full_name, role)
select id, email, 'Demo Pet Owner', 'pet_owner'
from auth.users
where email = 'demo.pet.owner@example.com'
on conflict (id) do update
set full_name = excluded.full_name,
    role = excluded.role,
    updated_at = now();

insert into public.pets (
  id, owner_id, name, species, breed, sex, birth_date, weight_kg, color, notes
)
select
  '41111111-1111-4111-8111-111111111111',
  profile.id,
  'Луна',
  'dog',
  'Коргі',
  'female',
  '2022-04-12',
  11.8,
  'рудий',
  'Демонстраційна тварина для локального тестування.'
from public.profiles profile
where profile.email = 'demo.pet.owner@example.com'
on conflict (id) do update
set owner_id = excluded.owner_id,
    name = excluded.name,
    updated_at = now();

insert into public.pet_owners (
  pet_id, user_id, relationship, relationship_type, is_primary
)
select
  '41111111-1111-4111-8111-111111111111',
  profile.id,
  'owner',
  'owner',
  true
from public.profiles profile
where profile.email = 'demo.pet.owner@example.com'
on conflict do nothing;

insert into public.visit_records (
  id, pet_id, owner_id, created_by, visit_date, provider_name,
  reason, reason_for_visit, symptoms, diagnosis, treatment_notes,
  recommendations, next_visit_recommended, status
)
select
  '61111111-1111-4111-8111-111111111111',
  '41111111-1111-4111-8111-111111111111',
  profile.id,
  profile.id,
  current_date - 14,
  'Ветеринарний фахівець',
  'Плановий огляд',
  'Плановий огляд',
  'Без скарг',
  'Дані внесені власником',
  'Спостереження за самопочуттям',
  'Дотримуватися звичного режиму',
  false,
  'self_reported'
from public.profiles profile
where profile.email = 'demo.pet.owner@example.com'
on conflict (id) do update
set provider_name = excluded.provider_name,
    reason_for_visit = excluded.reason_for_visit,
    updated_at = now();
