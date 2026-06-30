-- Demo seed data for controlled local beta testing.
--
-- Important:
-- 1. Create Supabase Auth users first with these fake emails:
--    demo.pet.owner@example.com
--    demo.clinic.owner@example.com
--    demo.vet@example.com
--    demo.manager@example.com
--    demo.platform.admin@example.com
-- 2. Do not commit or document real passwords.
-- 3. This seed uses auth.users IDs by email after users exist locally.

with demo_users as (
  select id, email
  from auth.users
  where email in (
    'demo.pet.owner@example.com',
    'demo.clinic.owner@example.com',
    'demo.vet@example.com',
    'demo.manager@example.com',
    'demo.platform.admin@example.com'
  )
)
insert into profiles (id, email, full_name, role)
select id,
       email,
       case email
         when 'demo.pet.owner@example.com' then 'Demo Pet Owner'
         when 'demo.clinic.owner@example.com' then 'Demo Clinic Owner'
         when 'demo.vet@example.com' then 'Demo Veterinarian'
         when 'demo.manager@example.com' then 'Demo Clinic Manager'
         else 'Demo Platform Admin'
       end,
       case email
         when 'demo.pet.owner@example.com' then 'pet_owner'
         when 'demo.clinic.owner@example.com' then 'clinic_owner'
         when 'demo.vet@example.com' then 'veterinarian'
         when 'demo.manager@example.com' then 'clinic_manager'
         else 'platform_admin'
       end
from demo_users
on conflict (id) do update
set full_name = excluded.full_name,
    role = excluded.role,
    updated_at = now();

insert into clinics (id, name, legal_name, description, phone, email, city, country, address, status, published, created_by)
select '11111111-1111-4111-8111-111111111111',
       'Beta Vet Clinic',
       'Beta Vet Clinic LLC',
       'Демо-клініка для контрольованого beta-тестування записів, медичних карток і документів.',
       '+380 44 000 00 00',
       'demo.clinic@example.com',
       'Київ',
       'Україна',
       'Beta Street, 10',
       'published',
       true,
       id
from profiles
where email = 'demo.clinic.owner@example.com'
on conflict (id) do update
set name = excluded.name,
    description = excluded.description,
    status = excluded.status,
    published = excluded.published,
    updated_at = now();

insert into clinic_members (clinic_id, user_id, role, status)
select '11111111-1111-4111-8111-111111111111',
       id,
       case email
         when 'demo.clinic.owner@example.com' then 'clinic_owner'
         when 'demo.vet@example.com' then 'veterinarian'
         else 'clinic_manager'
       end,
       'active'
from profiles
where email in ('demo.clinic.owner@example.com', 'demo.vet@example.com', 'demo.manager@example.com')
on conflict do nothing;

insert into doctors (id, clinic_id, profile_id, full_name, specialization, bio, experience_years, status, is_public)
values
  ('21111111-1111-4111-8111-111111111111', '11111111-1111-4111-8111-111111111111', (select id from profiles where email = 'demo.vet@example.com'), 'Лікар Олена Бета', 'Терапія', 'Профілактика, вакцинація та перші візити.', 8, 'active', true),
  ('21111111-1111-4111-8111-111111111112', '11111111-1111-4111-8111-111111111111', null, 'Лікар Максим Демо', 'Діагностика', 'УЗД, лабораторна діагностика та план лікування.', 11, 'active', true),
  ('21111111-1111-4111-8111-111111111113', '11111111-1111-4111-8111-111111111111', null, 'Лікар Софія Тест', 'Стоматологія', 'Профілактика та лікування зубів.', 6, 'active', true)
on conflict (id) do update
set full_name = excluded.full_name,
    specialization = excluded.specialization,
    status = excluded.status,
    is_public = excluded.is_public,
    updated_at = now();

insert into services (id, clinic_id, name, category, description, duration_minutes, price_amount, is_public, status)
values
  ('31111111-1111-4111-8111-111111111111', '11111111-1111-4111-8111-111111111111', 'Загальна консультація', 'Консультація', 'Огляд і рекомендації.', 30, 650, true, 'active'),
  ('31111111-1111-4111-8111-111111111112', '11111111-1111-4111-8111-111111111111', 'Вакцинація', 'Профілактика', 'Планова вакцинація.', 30, 900, true, 'active'),
  ('31111111-1111-4111-8111-111111111113', '11111111-1111-4111-8111-111111111111', 'Діагностика', 'Діагностика', 'Базова діагностична консультація.', 45, 850, true, 'active'),
  ('31111111-1111-4111-8111-111111111114', '11111111-1111-4111-8111-111111111111', 'Стоматологічний огляд', 'Стоматологія', 'Огляд ротової порожнини.', 30, 700, true, 'active'),
  ('31111111-1111-4111-8111-111111111115', '11111111-1111-4111-8111-111111111111', 'Повторний візит', 'Контроль', 'Контроль після лікування.', 30, 500, true, 'active')
on conflict (id) do update
set name = excluded.name,
    status = excluded.status,
    is_public = excluded.is_public,
    updated_at = now();

insert into doctor_schedules (clinic_id, doctor_id, day_of_week, start_time, end_time, break_start_time, break_end_time, slot_duration_minutes, is_active)
values
  ('11111111-1111-4111-8111-111111111111', '21111111-1111-4111-8111-111111111111', 1, '09:00', '17:00', '13:00', '14:00', 30, true),
  ('11111111-1111-4111-8111-111111111111', '21111111-1111-4111-8111-111111111111', 3, '09:00', '17:00', '13:00', '14:00', 30, true),
  ('11111111-1111-4111-8111-111111111111', '21111111-1111-4111-8111-111111111112', 2, '10:00', '18:00', '14:00', '15:00', 45, true),
  ('11111111-1111-4111-8111-111111111111', '21111111-1111-4111-8111-111111111113', 4, '09:30', '16:30', null, null, 30, true)
on conflict do nothing;

insert into pets (id, name, species, breed, sex, birth_date, weight_kg, notes)
values
  ('41111111-1111-4111-8111-111111111111', 'Luna Demo', 'dog', 'Коргі', 'female', '2022-04-12', 11.8, 'Демо-тварина для beta-тесту.'),
  ('41111111-1111-4111-8111-111111111112', 'Milo Demo', 'cat', 'Британська короткошерста', 'male', '2020-09-05', 6.2, 'Демо-тварина для beta-тесту.')
on conflict (id) do update
set name = excluded.name,
    updated_at = now();

insert into pet_owners (pet_id, user_id, relationship, relationship_type, is_primary)
select pet_id, owner_id, 'owner', 'owner', true
from (
  values
    ('41111111-1111-4111-8111-111111111111'::uuid, (select id from profiles where email = 'demo.pet.owner@example.com')),
    ('41111111-1111-4111-8111-111111111112'::uuid, (select id from profiles where email = 'demo.pet.owner@example.com'))
) as rows(pet_id, owner_id)
where owner_id is not null
on conflict do nothing;

insert into appointments (id, clinic_id, doctor_id, service_id, pet_id, owner_id, appointment_date, start_time, end_time, status, owner_note)
select id, clinic_id, doctor_id, service_id, pet_id, owner_id, appointment_date, start_time, end_time, status, owner_note
from (
  values
    ('51111111-1111-4111-8111-111111111111'::uuid, '11111111-1111-4111-8111-111111111111'::uuid, '21111111-1111-4111-8111-111111111111'::uuid, '31111111-1111-4111-8111-111111111111'::uuid, '41111111-1111-4111-8111-111111111111'::uuid, (select id from profiles where email = 'demo.pet.owner@example.com'), current_date + 2, '10:00'::time, '10:30'::time, 'pending', 'Демо pending запис'),
    ('51111111-1111-4111-8111-111111111112'::uuid, '11111111-1111-4111-8111-111111111111'::uuid, '21111111-1111-4111-8111-111111111112'::uuid, '31111111-1111-4111-8111-111111111113'::uuid, '41111111-1111-4111-8111-111111111112'::uuid, (select id from profiles where email = 'demo.pet.owner@example.com'), current_date + 4, '12:00'::time, '12:45'::time, 'confirmed', 'Демо confirmed запис'),
    ('51111111-1111-4111-8111-111111111113'::uuid, '11111111-1111-4111-8111-111111111111'::uuid, '21111111-1111-4111-8111-111111111111'::uuid, '31111111-1111-4111-8111-111111111112'::uuid, '41111111-1111-4111-8111-111111111111'::uuid, (select id from profiles where email = 'demo.pet.owner@example.com'), current_date - 7, '11:00'::time, '11:30'::time, 'completed', 'Демо completed запис')
) as rows(id, clinic_id, doctor_id, service_id, pet_id, owner_id, appointment_date, start_time, end_time, status, owner_note)
where owner_id is not null
on conflict (id) do update
set status = excluded.status,
    updated_at = now();

insert into visit_records (id, appointment_id, clinic_id, doctor_id, pet_id, owner_id, created_by, visit_date, reason_for_visit, diagnosis, treatment_notes, recommendations, next_visit_recommended, next_visit_date, status)
select '61111111-1111-4111-8111-111111111111',
       '51111111-1111-4111-8111-111111111113',
       '11111111-1111-4111-8111-111111111111',
       '21111111-1111-4111-8111-111111111111',
       '41111111-1111-4111-8111-111111111111',
       (select id from profiles where email = 'demo.pet.owner@example.com'),
       (select id from profiles where email = 'demo.vet@example.com'),
       current_date - 7,
       'Плановий огляд',
       'Гострих проблем не виявлено.',
       'Огляд завершено, стан стабільний.',
       'Повторний контроль через місяць.',
       true,
       current_date + 30,
       'published'
where exists (select 1 from profiles where email = 'demo.pet.owner@example.com')
on conflict (id) do update
set status = excluded.status,
    updated_at = now();

insert into visit_documents (id, visit_record_id, clinic_id, pet_id, uploaded_by, document_type, title, file_name, file_type, file_size, storage_bucket, storage_path, description, is_visible_to_owner)
select '71111111-1111-4111-8111-111111111111',
       '61111111-1111-4111-8111-111111111111',
       '11111111-1111-4111-8111-111111111111',
       '41111111-1111-4111-8111-111111111111',
       (select id from profiles where email = 'demo.vet@example.com'),
       'certificate',
       'Демо-довідка',
       'demo-certificate.pdf',
       'application/pdf',
       128000,
       'visit-documents',
       'demo/beta-vet/demo-certificate.pdf',
       'Видимий власнику demo-документ.',
       true
where exists (select 1 from profiles where email = 'demo.vet@example.com')
on conflict (id) do update
set title = excluded.title,
    is_visible_to_owner = excluded.is_visible_to_owner,
    updated_at = now();

insert into visit_documents (id, visit_record_id, clinic_id, pet_id, uploaded_by, document_type, title, file_name, file_type, file_size, storage_bucket, storage_path, description, is_visible_to_owner)
select '71111111-1111-4111-8111-111111111112',
       '61111111-1111-4111-8111-111111111111',
       '11111111-1111-4111-8111-111111111111',
       '41111111-1111-4111-8111-111111111111',
       (select id from profiles where email = 'demo.vet@example.com'),
       'other',
       'Внутрішня нотатка',
       'internal-note.pdf',
       'application/pdf',
       64000,
       'visit-documents',
       'demo/beta-vet/internal-note.pdf',
       'Приклад документа, прихованого від власника.',
       false
where exists (select 1 from profiles where email = 'demo.vet@example.com')
on conflict (id) do update
set title = excluded.title,
    is_visible_to_owner = excluded.is_visible_to_owner,
    updated_at = now();

insert into reviews (id, clinic_id, doctor_id, appointment_id, visit_record_id, pet_id, owner_id, rating, doctor_rating, clinic_rating, service_quality_rating, comment, is_published, status, is_anonymous)
select '81111111-1111-4111-8111-111111111111',
       '11111111-1111-4111-8111-111111111111',
       '21111111-1111-4111-8111-111111111111',
       '51111111-1111-4111-8111-111111111113',
       '61111111-1111-4111-8111-111111111111',
       '41111111-1111-4111-8111-111111111111',
       (select id from profiles where email = 'demo.pet.owner@example.com'),
       5,
       5,
       5,
       5,
       'Спокійний прийом і зрозумілі рекомендації.',
       true,
       'published',
       false
where exists (select 1 from profiles where email = 'demo.pet.owner@example.com')
on conflict (id) do update
set rating = excluded.rating,
    status = excluded.status,
    updated_at = now();

insert into notifications (recipient_user_id, clinic_id, pet_id, appointment_id, visit_record_id, document_id, review_id, type, title, body, status)
select owner_profile.id,
       '11111111-1111-4111-8111-111111111111',
       '41111111-1111-4111-8111-111111111111',
       '51111111-1111-4111-8111-111111111112',
       null,
       null,
       null,
       'appointment_confirmed',
       'Запис підтверджено',
       'Клініка підтвердила ваш запис.',
       'unread'
from profiles owner_profile
where owner_profile.email = 'demo.pet.owner@example.com';

insert into notifications (recipient_user_id, clinic_id, appointment_id, type, title, body, status)
select clinic_profile.id,
       '11111111-1111-4111-8111-111111111111',
       '51111111-1111-4111-8111-111111111111',
       'new_appointment_request',
       'Новий запит на запис',
       'Власник тварини надіслав запит на прийом.',
       'unread'
from profiles clinic_profile
where clinic_profile.email = 'demo.clinic.owner@example.com';

insert into clinic_subscriptions (clinic_id, plan_id, status, billing_period, current_period_start)
select '11111111-1111-4111-8111-111111111111',
       subscription_plans.id,
       'manual',
       'manual',
       now()
from subscription_plans
where subscription_plans.code = 'pro'
on conflict do nothing;
