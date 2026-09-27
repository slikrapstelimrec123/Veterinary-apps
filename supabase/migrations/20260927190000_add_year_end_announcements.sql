-- Add verified events and grooming offers through the end of 2026.
-- Sources checked on 27 September 2026:
--   https://www.uku.com.ua/shows_champ/kalend_show.html
--   https://www.uku.com.ua/shows_champ/kalend_sport.html
--   https://www.rimore-grooming.com/
--   https://luckydog.kiev.ua/
--
-- The 31 December date on offers is the catalogue review horizon. Where the
-- provider does not publish an end date, the card tells users to re-check the
-- terms before booking or purchase.

do $$
declare
  platform_owner_id uuid;
begin
  select profile.id
    into platform_owner_id
  from public.profiles profile
  where lower(profile.email) = 'slikrapstelimrec123@gmail.com'
     or profile.role = 'platform_admin'
  order by case
    when lower(profile.email) = 'slikrapstelimrec123@gmail.com' then 0
    else 1
  end, profile.created_at
  limit 1;

  if platform_owner_id is null then
    raise notice 'Year-end curated announcements were not added: platform owner is absent.';
    return;
  end if;

  insert into public.announcements (
    id, owner_id, announcement_type, title, address, city, description,
    event_date, contact_info, service_category, offer_category, price_amount,
    website, offer_text, valid_from, valid_until, status, moderation_status,
    publication_source, publication_tier, published_at, created_at, updated_at
  )
  values
    (
      'c8a57401-3701-4b4e-b0d8-000000000304',
      platform_owner_id,
      'event',
      '«Кубок Києва-2026» — мондіоринг',
      'Київ',
      'Київ',
      'Кваліфікаційні змагання КСУ з Mondioring рівнів I–III 07–08.11.2026. Перед поїздкою перевірте точну локацію та регламент на сайті організатора.',
      '2026-11-07 10:00:00+02',
      '+38 (044) 296-71-38 · +38 050-356-13-63',
      null, null, null,
      'https://www.uku.com.ua/shows_champ/kalend_sport.html',
      null, null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000305',
      platform_owner_id,
      'event',
      '«Кубок SARCAN-2026» — змагання рятувальних собак',
      'Київська область',
      'Київська область',
      'Кваліфікаційні змагання 07–08.11.2026 для рятувальних собак та бельгійських вівчарок. Точне місце проведення й умови участі уточнюйте в організатора.',
      '2026-11-07 10:00:00+02',
      '+38 (044) 296-71-38 · +38 050-356-13-63',
      null, null, null,
      'https://www.uku.com.ua/shows_champ/kalend_sport.html',
      null, null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000306',
      platform_owner_id,
      'event',
      '«Run for it Open» — аджиліті',
      'Київ',
      'Київ',
      'Відкриті змагання КСУ з аджиліті 21–22.11.2026: класи A1, A2, A3 та Open. Перед візитом перевірте розклад і локацію на календарі КСУ.',
      '2026-11-21 10:00:00+02',
      '+38 (098) 543-02-12 · +38 (093) 280-28-65',
      null, null, null,
      'https://www.uku.com.ua/shows_champ/kalend_sport.html',
      null, null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000307',
      platform_owner_id,
      'event',
      '«Чемпіонат Харкова-2026» — obedience',
      'Харків',
      'Харків',
      'Відкриті міські змагання КСУ з Obedience 28–29.11.2026. Уточніть статус заходу та місце проведення перед поїздкою.',
      '2026-11-28 10:00:00+02',
      '+38 (066) 959-84-86 · +38 (066) 945-47-84',
      null, null, null,
      'https://www.uku.com.ua/shows_champ/kalend_sport.html',
      null, null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000308',
      platform_owner_id,
      'event',
      'Чемпіонат України-2026 з танців із собаками',
      'Бровари, Київська область',
      'Бровари',
      'Кваліфікаційні змагання з танців із собаками та кінологічного фрістайлу 05.12.2026. Місце проведення в календарі КСУ вказане як Київ; час і реєстрацію перевіряйте в організатора.',
      '2026-12-05 10:00:00+02',
      '+38 (097) 230-51-81',
      null, null, null,
      'https://www.uku.com.ua/shows_champ/kalend_sport.html',
      null, null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000309',
      platform_owner_id,
      'event',
      'CACIB «Кришталевий кубок»',
      'Міжнародний виставковий центр, Лівобережна, Київ',
      'Київ',
      'Міжнародна виставка собак CACIB 12.12.2026 за офіційним календарем КСУ. Програму, реєстрацію та правила відвідування перевіряйте на сайті організатора.',
      '2026-12-12 10:00:00+02',
      'Деталі та реєстрація — на сайті КСУ',
      null, null, null,
      'https://uku.com.ua/shows_champ/kalend_show.html',
      null, null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000310',
      platform_owner_id,
      'event',
      'CACIB «Київська Русь»',
      'Міжнародний виставковий центр, Лівобережна, Київ',
      'Київ',
      'Міжнародна виставка собак CACIB 13.12.2026 за офіційним календарем КСУ. Актуальні умови участі та розклад перевіряйте перед поїздкою.',
      '2026-12-13 10:00:00+02',
      'Деталі та реєстрація — на сайті КСУ',
      null, null, null,
      'https://uku.com.ua/shows_champ/kalend_show.html',
      null, null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000311',
      platform_owner_id,
      'event',
      '«Кубок Одеського Санти» — аджиліті',
      'Одеса',
      'Одеса',
      'Відкриті змагання КСУ з аджиліті 27.12.2026: A1, A2, дебют та Open. Перед поїздкою перевірте розклад і локацію у організатора.',
      '2026-12-27 10:00:00+02',
      '+38 (073) 474-50-50',
      null, null, null,
      'https://www.uku.com.ua/shows_champ/kalend_sport.html',
      null, null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000312',
      platform_owner_id,
      'event',
      '«Харків Залізобетон-2026» — робочі випробування',
      'Харків',
      'Харків',
      'Відкриті змагання КСУ 26–27.12.2026 з BH/VT, IBGH, СК та ЗКД. Статус, час і точну локацію перевіряйте в організатора перед поїздкою.',
      '2026-12-26 10:00:00+02',
      '+38 (066) 959-84-86 · +38 (066) 945-47-84',
      null, null, null,
      'https://www.uku.com.ua/shows_champ/kalend_sport.html',
      null, null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000503',
      platform_owner_id,
      'offer',
      'Rimoré — −15% на перше відвідування',
      'вул. Малопідвальна, 6',
      'Київ',
      'Грумінг-студія в центрі Києва для собак і котів. На офіційному сайті вказана знижка 15% на перше відвідування; умови уточніть під час запису.',
      null,
      '+38 (096) 000-60-51 · rimore-grooming@outlook.com',
      null,
      'other',
      null,
      'https://www.rimore-grooming.com/',
      '−15% на перше відвідування. Актуальність пропозиції перевірена 27.09.2026; умови можуть змінюватися, уточніть їх перед записом.',
      '2026-09-27',
      '2026-12-31',
      'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000504',
      platform_owner_id,
      'offer',
      'Rimoré — −30% на друге відвідування',
      'вул. Малопідвальна, 6',
      'Київ',
      'Грумінг-студія в центрі Києва для собак і котів. На офіційному сайті вказана знижка 30% на друге відвідування; умови уточніть під час запису.',
      null,
      '+38 (096) 000-60-51 · rimore-grooming@outlook.com',
      null,
      'other',
      null,
      'https://www.rimore-grooming.com/',
      '−30% на друге відвідування. Актуальність пропозиції перевірена 27.09.2026; умови можуть змінюватися, уточніть їх перед записом.',
      '2026-09-27',
      '2026-12-31',
      'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000505',
      platform_owner_id,
      'offer',
      'LuckyDOG — −5% на перше відвідування',
      'вул. Княжий Затон, 21',
      'Київ',
      'Грумінг-салон LuckyDOG у Києві. На офіційній сторінці вказана знижка 5% на перше відвідування; умови та доступні години потрібно уточнити перед записом.',
      null,
      '+38 (093) 337-30-30 · +38 (096) 337-30-30',
      null,
      'other',
      null,
      'https://luckydog.kiev.ua/',
      '−5% на перше відвідування. Актуальність пропозиції перевірена 27.09.2026; сайт не вказує дату завершення, тому перевірте умови перед записом.',
      '2026-09-27',
      '2026-12-31',
      'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000506',
      platform_owner_id,
      'offer',
      'LuckyDOG — −10% на кожне п’яте замовлення',
      'вул. Княжий Затон, 21',
      'Київ',
      'Програма знижок LuckyDOG для постійних клієнтів. На офіційній сторінці вказана знижка 10% на кожне п’яте замовлення; умови уточніть перед записом.',
      null,
      '+38 (093) 337-30-30 · +38 (096) 337-30-30',
      null,
      'other',
      null,
      'https://luckydog.kiev.ua/',
      '−10% на кожне п’яте замовлення. Актуальність пропозиції перевірена 27.09.2026; сайт не вказує дату завершення, тому перевірте умови перед записом.',
      '2026-09-27',
      '2026-12-31',
      'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    )
  on conflict (id) do update set
    owner_id = excluded.owner_id,
    announcement_type = excluded.announcement_type,
    title = excluded.title,
    address = excluded.address,
    city = excluded.city,
    description = excluded.description,
    event_date = excluded.event_date,
    contact_info = excluded.contact_info,
    service_category = excluded.service_category,
    offer_category = excluded.offer_category,
    price_amount = excluded.price_amount,
    website = excluded.website,
    offer_text = excluded.offer_text,
    valid_from = excluded.valid_from,
    valid_until = excluded.valid_until,
    status = 'active',
    moderation_status = 'published',
    publication_source = 'platform_curated',
    publication_tier = 'standard',
    updated_at = now();
end
$$;

notify pgrst, 'reload schema';
