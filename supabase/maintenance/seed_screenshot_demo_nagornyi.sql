-- Temporary screenshot data for nagornyi1103@icloud.com.
-- Run manually in the Supabase SQL Editor for the Lappo project.
-- The fixed UUIDs make this script idempotent and allow precise cleanup later.

begin;

do $$
declare
  target_email constant text := 'nagornyi1103@icloud.com';
  target_user_id uuid;
  target_pet_id uuid;
begin
  select id
  into target_user_id
  from auth.users
  where lower(email) = target_email
  limit 1;

  if target_user_id is null then
    raise exception 'USER_NOT_FOUND: %', target_email;
  end if;

  insert into public.profiles (id, email, full_name, role)
  values (target_user_id, target_email, 'Демо власник', 'pet_owner')
  on conflict (id) do nothing;

  select pet.id
  into target_pet_id
  from public.pets pet
  join public.pet_owners ownership on ownership.pet_id = pet.id
  where ownership.user_id = target_user_id
  order by coalesce(ownership.is_primary, true) desc, pet.created_at
  limit 1;

  if target_pet_id is null then
    target_pet_id := '77000000-0000-4000-8000-000000000001';

    insert into public.pets (
      id, owner_id, name, species, breed, sex, birth_date, weight_kg,
      color, microchip_number, avatar_url, notes, is_neutered
    ) values (
      target_pet_id,
      target_user_id,
      'Луна',
      'dog',
      'Золотистий ретривер',
      'female',
      current_date - interval '3 years 4 months',
      27.4,
      'золотистий',
      '990000123456789',
      'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=900&q=85',
      'Активна, лагідна, любить тривалі прогулянки.',
      true
    )
    on conflict (id) do update set
      owner_id = excluded.owner_id,
      name = excluded.name,
      avatar_url = excluded.avatar_url,
      updated_at = now();

    insert into public.pet_owners (
      pet_id, user_id, relationship, relationship_type, is_primary
    ) values (
      target_pet_id, target_user_id, 'primary_owner', 'primary_owner', true
    )
    on conflict (pet_id, user_id) do update set is_primary = true;
  end if;

  insert into public.visit_records (
    id, pet_id, owner_id, created_by, visit_date, provider_name,
    reason, reason_for_visit, symptoms, diagnosis, procedures_performed,
    treatment_notes, prescribed_medications, recommendations,
    next_visit_recommended, next_visit_date, status
  ) values
    (
      '77000000-0000-4000-8000-000000000101', target_pet_id,
      target_user_id, target_user_id, now() - interval '12 days',
      'Ветеринарна клініка «Добрий хвіст»', 'Плановий огляд',
      'Щорічний профілактичний огляд', 'Скарг немає',
      'Клінічно здорова', 'Огляд, аускультація, контроль ваги',
      'Продовжити звичний режим активності', null,
      'Контроль ваги раз на місяць', true, current_date + 80,
      'self_reported'
    ),
    (
      '77000000-0000-4000-8000-000000000102', target_pet_id,
      target_user_id, target_user_id, now() - interval '4 months',
      'Ветеринарний кабінет «Лапка»', 'Вакцинація',
      'Планова комплексна вакцинація', 'Без скарг',
      'Протипоказань до вакцинації немає', 'Комплексна вакцинація',
      'Спокійний режим протягом доби', null,
      'Наступна вакцинація через 12 місяців', false, null,
      'self_reported'
    ),
    (
      '77000000-0000-4000-8000-000000000103', target_pet_id,
      target_user_id, target_user_id, now() - interval '8 months',
      'Власний запис', 'Сезонна алергія',
      'Почервоніння шкіри після прогулянки', 'Свербіж, почервоніння',
      'Ймовірна сезонна реакція', 'Огляд шкіри',
      'Догляд за шкірою за призначенням', 'Антигістамінний препарат',
      'Уникати високої трави, спостерігати за станом', false, null,
      'self_reported'
    )
  on conflict (id) do update set
    pet_id = excluded.pet_id,
    owner_id = excluded.owner_id,
    created_by = excluded.created_by,
    provider_name = excluded.provider_name,
    reason = excluded.reason,
    updated_at = now();

  insert into public.visit_documents (
    id, visit_record_id, clinic_id, pet_id, uploaded_by, document_type,
    title, storage_bucket, storage_path, mime_type, file_size_bytes,
    is_visible_to_owner
  ) values
    (
      '77000000-0000-4000-8000-000000000201',
      '77000000-0000-4000-8000-000000000101', null, target_pet_id,
      target_user_id, 'lab_result', 'Результати аналізу крові.pdf',
      'visit-documents', target_pet_id || '/demo/blood-test.pdf',
      'application/pdf', 248000, true
    ),
    (
      '77000000-0000-4000-8000-000000000202',
      '77000000-0000-4000-8000-000000000102', null, target_pet_id,
      target_user_id, 'certificate', 'Відмітка про вакцинацію.pdf',
      'visit-documents', target_pet_id || '/demo/vaccination.pdf',
      'application/pdf', 186000, true
    )
  on conflict (id) do update set
    pet_id = excluded.pet_id,
    uploaded_by = excluded.uploaded_by,
    title = excluded.title,
    updated_at = now();

  insert into public.pet_medications (
    id, pet_id, name, given_date, dosage, category, notes,
    next_dose_date, reminder_enabled
  ) values
    (
      '77000000-0000-4000-8000-000000000301', target_pet_id,
      'Simparica', current_date - 20, '1 таблетка', 'parasite',
      'Захист від кліщів і бліх', current_date + 10, false
    ),
    (
      '77000000-0000-4000-8000-000000000302', target_pet_id,
      'Омега-3', current_date - 7, '1 капсула щодня', 'supplement',
      'Підтримка шкіри та шерсті', current_date + 23, false
    ),
    (
      '77000000-0000-4000-8000-000000000303', target_pet_id,
      'Drontal', current_date - 65, 'За вагою', 'deworming',
      'Планова дегельмінтизація', current_date + 25, false
    )
  on conflict (id) do update set
    pet_id = excluded.pet_id,
    name = excluded.name,
    next_dose_date = excluded.next_dose_date,
    updated_at = now();

  insert into public.pet_feedings (
    id, pet_id, food_name, brand, food_type, start_date, end_date,
    notes, rating
  ) values
    (
      '77000000-0000-4000-8000-000000000401', target_pet_id,
      'Adult Medium', 'Royal Canin', 'dry', current_date - 90, null,
      'Добре підходить, стабільна вага', 5
    ),
    (
      '77000000-0000-4000-8000-000000000402', target_pet_id,
      'Індичка з овочами', 'Домашній раціон', 'natural',
      current_date - 30, current_date - 15,
      'Додавали як різноманіття до основного раціону', 4
    ),
    (
      '77000000-0000-4000-8000-000000000403', target_pet_id,
      'Dental Care', 'Brit', 'treat', current_date - 14, null,
      'Ласощі для догляду за зубами', 5
    )
  on conflict (id) do update set
    pet_id = excluded.pet_id,
    food_name = excluded.food_name,
    updated_at = now();

  insert into public.pet_achievements (
    id, pet_id, title, event_date, end_date, event_type, location,
    result, award_title, notes
  ) values
    (
      '77000000-0000-4000-8000-000000000501', target_pet_id,
      'Базовий курс слухняності', current_date - 300, null, 'training',
      'Київ', 'Курс завершено', 'Сертифікат учасника',
      'Впевнено виконує базові команди'
    ),
    (
      '77000000-0000-4000-8000-000000000502', target_pet_id,
      'Благодійний забіг із собакою', current_date - 120, null, 'competition',
      'ВДНГ, Київ', '5 км', 'Медаль фінішера',
      'Перший спільний забіг'
    ),
    (
      '77000000-0000-4000-8000-000000000503', target_pet_id,
      'Перша подорож до моря', current_date - 45, current_date - 38,
      'travel', 'Одеса', 'Чудова подорож', null,
      'Спокійно перенесла дорогу та полюбила пляж'
    )
  on conflict (id) do update set
    pet_id = excluded.pet_id,
    title = excluded.title,
    updated_at = now();

  insert into public.notifications (
    id, user_id, pet_id, type, title, body, data, status, created_at
  ) values
    (
      '77000000-0000-4000-8000-000000000601', target_user_id, target_pet_id,
      'medication_reminder', 'Нагадування про препарат',
      'Незабаром час дати Simparica',
      jsonb_build_object('demo_screenshot', true), 'unread', now() - interval '2 hours'
    ),
    (
      '77000000-0000-4000-8000-000000000602', target_user_id, target_pet_id,
      'next_visit_recommended', 'Заплануйте контрольний огляд',
      'Для Луни рекомендовано повторний огляд',
      jsonb_build_object('demo_screenshot', true), 'unread', now() - interval '1 day'
    ),
    (
      '77000000-0000-4000-8000-000000000603', target_user_id, target_pet_id,
      'document_uploaded', 'Новий документ',
      'До картки додано результати аналізу крові',
      jsonb_build_object('demo_screenshot', true), 'read', now() - interval '3 days'
    ),
    (
      '77000000-0000-4000-8000-000000000604', target_user_id, target_pet_id,
      'visit_record_published', 'Запис прийому збережено',
      'Плановий огляд додано до медичної історії',
      jsonb_build_object('demo_screenshot', true), 'read', now() - interval '5 days'
    )
  on conflict (id) do update set
    user_id = excluded.user_id,
    pet_id = excluded.pet_id,
    title = excluded.title,
    body = excluded.body,
    status = excluded.status,
    updated_at = now();

  insert into public.announcements (
    id, owner_id, pet_id, announcement_type, contact_name, contact_phone,
    breed, pet_name, gender, birth_date, age_years, price_amount,
    cover_photo_url, color, has_vaccinations, has_pedigree, has_chip,
    desired_breed, conditions, title, address, event_date, contact_info,
    service_category, offer_category, offer_text, valid_from, valid_until,
    promo_code, description, city, status, moderation_status,
    publication_source
  ) values
    (
      '77000000-0000-4000-8000-000000000701', target_user_id, target_pet_id,
      'sale', 'Олександр', '+380000000000', 'Золотистий ретривер',
      'Сонні', 'male', current_date - 75, null, 18000,
      'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=900&q=85',
      'золотистий', true, true, true, null, null, null, null, null, null,
      null, null, null, null, null, null,
      'Здорове та активне цуценя, має ветеринарний паспорт.', 'Київ',
      'active', 'published', 'platform_curated'
    ),
    (
      '77000000-0000-4000-8000-000000000702', target_user_id, target_pet_id,
      'breeding', 'Олександр', '+380000000000', 'Золотистий ретривер',
      'Луна', 'female', null, 3, null,
      'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=900&q=85',
      'золотистий', true, true, true, 'Золотистий ретривер',
      'Ветеринарний паспорт та необхідні обстеження', null, null, null, null,
      null, null, null, null, null, null,
      'Лагідна, здорова та соціалізована собака.', 'Київ',
      'active', 'published', 'platform_curated'
    ),
    (
      '77000000-0000-4000-8000-000000000703', target_user_id, null,
      'event', null, null, null, null, null, null, null, null,
      'https://images.unsplash.com/photo-1558788353-f76d92427f16?auto=format&fit=crop&w=900&q=85',
      null, null, null, null, null, null, 'Прогулянка з улюбленцями',
      'Парк Наталка, Оболонська набережна', now() + interval '8 days',
      '@lappo.community', null, null, null, null, null, null,
      'Дружня зустріч власників собак та спільна прогулянка парком.',
      'Київ', 'active', 'published', 'platform_curated'
    ),
    (
      '77000000-0000-4000-8000-000000000704', target_user_id, null,
      'event', null, null, null, null, null, null, null, null,
      'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?auto=format&fit=crop&w=900&q=85',
      null, null, null, null, null, null, 'День відповідального власника',
      'Міський сад, центральний вхід', now() + interval '16 days',
      'lappo.apps@gmail.com', null, null, null, null, null, null,
      'Лекції про догляд, корисні знайомства та подарунки для улюбленців.',
      'Київ', 'active', 'published', 'platform_curated'
    ),
    (
      '77000000-0000-4000-8000-000000000705', target_user_id, null,
      'service', null, null, null, null, null, null, null, 650,
      'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&w=900&q=85',
      null, null, null, null, null, null, 'Дбайливий грумінг',
      'вул. Велика Васильківська, 72', null, '+380000000000',
      'groomer', null, null, null, null, null,
      'Комплексний догляд за шерстю та кігтями у спокійній атмосфері.',
      'Київ', 'active', 'published', 'platform_curated'
    )
  on conflict (id) do update set
    owner_id = excluded.owner_id,
    pet_id = excluded.pet_id,
    title = excluded.title,
    description = excluded.description,
    status = excluded.status,
    moderation_status = excluded.moderation_status,
    updated_at = now();
end
$$;

commit;

select
  (select count(*) from public.visit_records where id::text like '77000000-0000-4000-8000-0000000001%') as visits,
  (select count(*) from public.visit_documents where id::text like '77000000-0000-4000-8000-0000000002%') as documents,
  (select count(*) from public.pet_medications where id::text like '77000000-0000-4000-8000-0000000003%') as medications,
  (select count(*) from public.pet_feedings where id::text like '77000000-0000-4000-8000-0000000004%') as feedings,
  (select count(*) from public.pet_achievements where id::text like '77000000-0000-4000-8000-0000000005%') as achievements,
  (select count(*) from public.notifications where id::text like '77000000-0000-4000-8000-0000000006%') as notifications,
  (select count(*) from public.announcements where id::text like '77000000-0000-4000-8000-0000000007%') as announcements;
