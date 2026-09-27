-- Add verified pet events and shop offers for the remainder of 2026.
-- Sources checked on 27 September 2026:
--   https://www.uku.com.ua/shows_champ/kalend_show.html
--   https://www.uku.com.ua/shows_champ/kalend_sport.html
--   https://zoomarket24.com.ua/promotions
--   https://zoomarket24.com.ua/subscriptions
--   https://zoobro.club/sale/
--   https://all4terr.com.ua/

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
    raise notice 'Verified 2026 announcements were not added: platform owner is absent.';
    return;
  end if;

  insert into public.announcements (
    id, owner_id, announcement_type, title, address, city, description,
    event_date, contact_info, website, offer_text, offer_category,
    valid_from, valid_until, status, moderation_status,
    publication_source, publication_tier, published_at, created_at, updated_at
  )
  values
    (
      'c8a57401-3701-4b4e-b0d8-000000000313', platform_owner_id,
      'event', 'САС «Чарівний поділ-2026»', 'ВДНГ, Київ', 'Київ',
      'Виставка собак КСУ 03.10.2026 у виставковому центрі ВДНГ. Реєстрацію, час і правила відвідування перевірте в організатора перед поїздкою.',
      '2026-10-03 10:00:00+03', '+380679659799',
      'https://www.uku.com.ua/shows_champ/kalend_show.html', null, null,
      null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000314', platform_owner_id,
      'event', 'САС «Кубок Києва-2026»', 'ВДНГ, Київ', 'Київ',
      'Спеціалізовані ринги КСУ 04.10.2026 у межах київських виставкових заходів. Уточніть програму та умови реєстрації в організатора.',
      '2026-10-04 10:00:00+03', '+380679659799',
      'https://www.uku.com.ua/shows_champ/kalend_show.html', null, null,
      null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000315', platform_owner_id,
      'event', 'САС «Оксамитовий сезон-2026»', 'Догтаун, вул. Миколи Троїцького, 1-с', 'Одеса',
      'Виставка собак КСУ 17.10.2026 у спортивно-дресирувальному центрі «Догтаун».',
      '2026-10-17 10:00:00+03', '+380487287411 · +380487286687',
      'https://www.uku.com.ua/shows_champ/kalend_show.html', null, null,
      null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000316', platform_owner_id,
      'event', 'САС «Південна Пальміра-2026»', 'Догтаун, вул. Миколи Троїцького, 1-с', 'Одеса',
      'Виставка собак КСУ 18.10.2026. Перед поїздкою перевірте розклад, породи та умови участі.',
      '2026-10-18 10:00:00+03', '+380675590084',
      'https://www.uku.com.ua/shows_champ/kalend_show.html', null, null,
      null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000317', platform_owner_id,
      'event', '«Багряна осінь» — аджиліті КСУ', 'Бровари, Київська область', 'Бровари',
      'Відкриті змагання КСУ з аджиліті 24.10.2026: CACAg, A1, A2 та Open. Локацію і час підтвердіть у організатора.',
      '2026-10-24 10:00:00+03', '+380633425055',
      'https://www.uku.com.ua/shows_champ/kalend_sport.html', null, null,
      null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000318', platform_owner_id,
      'event', '«Золотий бум» — аджиліті КСУ', 'Бровари, Київська область', 'Бровари',
      'Відкриті змагання КСУ з аджиліті 25.10.2026: CACAg, A1, A2 та Open. Локацію і час підтвердіть у організатора.',
      '2026-10-25 10:00:00+03', '+380633425055',
      'https://www.uku.com.ua/shows_champ/kalend_sport.html', null, null,
      null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000319', platform_owner_id,
      'event', 'Відкриті міські змагання Rally Obedience', 'Харків', 'Харків',
      'Змагання КСУ ROB-1, ROB-2, ROB-3 та FCI 01.11.2026. Уточніть місце проведення та реєстрацію в організатора.',
      '2026-11-01 10:00:00+02', '+380669598486 · +380669454784',
      'https://www.uku.com.ua/shows_champ/kalend_sport.html', null, null,
      null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000320', platform_owner_id,
      'event', 'Відкриті змагання КСУ з аджиліті', 'Одеса', 'Одеса',
      'Змагання з аджиліті A1, A2 та дебют 07.11.2026. Контакт оргкомітету вказаний у календарі КСУ.',
      '2026-11-07 10:00:00+02', '+380638404714',
      'https://www.uku.com.ua/shows_champ/kalend_sport.html', null, null,
      null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000321', platform_owner_id,
      'event', 'Турнір з Obedience «Рідна природа»', 'Одеса', 'Одеса',
      'Турнір КСУ з Obedience 22.11.2026. Перед візитом перевірте актуальність статусу та розклад.',
      '2026-11-22 10:00:00+02', '+380679320649 · +380487251578',
      'https://www.uku.com.ua/shows_champ/kalend_sport.html', null, null,
      null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000322', platform_owner_id,
      'event', '«Хрустальний кубок» — Obedience Rally', 'Київ', 'Київ',
      'Змагання КСУ з Obedience Rally 13.12.2026, відбір до чемпіонату світу FCI 2027. Реєстрацію і час перевірте в КСУ.',
      '2026-12-13 10:00:00+02', '+380505734946',
      'https://www.uku.com.ua/shows_champ/kalend_sport.html', null, null,
      null, null, 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000507', platform_owner_id,
      'offer', 'ZooMarket24 — промокод AUTUMN −5%', 'Онлайн · доставка по Україні', 'Онлайн',
      'Знижка на замовлення зоотоварів у ZooMarket24. Мінімальна сума замовлення — 500 грн; перевірте умови застосування промокоду перед оплатою.',
      null, null,
      'https://zoomarket24.com.ua/promotions', '−5% на замовлення від 500 грн за промокодом AUTUMN.', 'shop',
      '2026-09-27', '2026-10-31', 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000508', platform_owner_id,
      'offer', 'ZooMarket24 — −5% на автодоставку корму', 'Онлайн · доставка по Україні', 'Онлайн',
      'Підписка на регулярну доставку корму з постійною знижкою 5% на кожне авто-замовлення. Пауза та скасування доступні в кабінеті.',
      null, null,
      'https://zoomarket24.com.ua/subscriptions', '−5% на кожну автодоставку корму; умови перевірені 27.09.2026.', 'shop',
      '2026-09-27', '2026-12-31', 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000509', platform_owner_id,
      'offer', 'ЗООБРО — до −33% на корм Hillʼs', 'Онлайн та магазини ЗООБРО', 'Онлайн',
      'Пропозиція для корму Hillʼs: різні фасування можна придбати за ціною меншої ваги. Діє до 31.12.2026 або до закінчення запасів.',
      null, '068 035 33 55',
      'https://zoobro.club/sale/', 'До −33% на корм Hillʼs за умовами акції магазину.', 'shop',
      '2026-08-01', '2026-12-31', 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000510', platform_owner_id,
      'offer', 'All4Terr — ласощі «Тимофіївка» та «Пирій»', 'Онлайн · доставка по Україні', 'Онлайн',
      'Пропозиція магазину All4Terr на новинки для гризунів. На сайті вказано, що пропозиція діє до 31.12.2026; перевірте наявність перед замовленням.',
      null, null,
      'https://all4terr.com.ua/', 'Актуальна пропозиція на ласощі для гризунів до 31.12.2026.', 'shop',
      '2026-09-27', '2026-12-31', 'active', 'published', 'platform_curated', 'standard', now(), now(), now()
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
    website = excluded.website,
    offer_text = excluded.offer_text,
    offer_category = excluded.offer_category,
    valid_from = excluded.valid_from,
    valid_until = excluded.valid_until,
    status = excluded.status,
    moderation_status = excluded.moderation_status,
    publication_source = 'platform_curated',
    publication_tier = 'standard',
    published_at = excluded.published_at,
    updated_at = now();
end;
$$;
