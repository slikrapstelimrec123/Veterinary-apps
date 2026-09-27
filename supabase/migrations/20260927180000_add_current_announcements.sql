-- Add more verified announcements for the coming month (27 September – 27 October 2026).
-- Sources checked on 27 September 2026:
--   https://www.uku.com.ua/shows_champ/kalend_show.html
--   https://www.uku.com.ua/shows_champ/kalend_sport.html
--   https://luckydog.kiev.ua/
--   https://www.oliviadoghotel.com/
--   https://rozetka.com.ua/news-articles-promotions/promotions/330466_sale_vet/
--   https://rozetka.com.ua/ua/news-articles-promotions/promotions/330465_sale_pets/

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
    raise notice 'Additional curated announcements were not added: platform owner is absent.';
    return;
  end if;

  -- Correct details in the previous refresh where the official pages provide
  -- more precise contact, coverage, or pricing wording.
  update public.announcements
  set address = 'просп. Академіка Глушкова, 1, ВДНГ',
      contact_info = '(067) 904-94-64 · (050) 923-97-44',
      updated_at = now()
  where id = 'c8a57401-3701-4b4e-b0d8-000000000001';

  update public.announcements
  set address = 'Київ та Київська область',
      description = 'Дресирування собак, корекція поведінки, підготовка до спорту й виставок та консультації для власників. Вартість залежить від обраної послуги.',
      updated_at = now()
  where id = 'c8a57401-3701-4b4e-b0d8-000000000102';

  update public.announcements
  set description = 'Окремі кімнати, територія для вигулу, триразовий вигул, пансіон із дресируванням та додатковий догляд. Ціни на проживання — від 350 грн; вільні місця потрібно уточнити перед бронюванням.',
      updated_at = now()
  where id = 'c8a57401-3701-4b4e-b0d8-000000000104';

  insert into public.announcements (
    id, owner_id, announcement_type, title, address, city, description,
    event_date, contact_info, service_category, offer_category, price_amount,
    website, offer_text, valid_from, valid_until, status, moderation_status,
    publication_source, publication_tier, published_at, created_at, updated_at
  )
  values
    (
      'c8a57401-3701-4b4e-b0d8-000000000301',
      platform_owner_id,
      'event',
      'САС «Кубок Києва-2026»',
      'Київ (локацію уточнюйте у КСУ)',
      'Київ',
      'Кінологічна виставка КСУ 04.10.2026. Перелік порід, реєстрацію та точне місце проведення перевіряйте на календарі організатора.',
      '2026-10-04 10:00:00+03',
      'Деталі та реєстрація — на сайті КСУ',
      null,
      null,
      null,
      'https://www.uku.com.ua/shows_champ/kalend_show.html',
      null,
      null,
      null,
      'active',
      'published',
      'platform_curated',
      'standard',
      now(),
      now(),
      now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000302',
      platform_owner_id,
      'event',
      'Кваліфікаційні змагання з танців із собаками',
      'Київ',
      'Київ',
      'Змагання з танців із собаками та кінологічного фрістайлу 17.10.2026. Відбір до чемпіонату світу FCI 2026.',
      '2026-10-17 10:00:00+03',
      '+380 44 296 71 38 · +380 50 356 13 63',
      null,
      null,
      null,
      'https://www.uku.com.ua/shows_champ/kalend_sport.html',
      null,
      null,
      null,
      'active',
      'published',
      'platform_curated',
      'standard',
      now(),
      now(),
      now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000303',
      platform_owner_id,
      'event',
      '«Багряна осінь» — змагання з аджиліті',
      'Бровари, Київська область',
      'Бровари',
      'Відкриті змагання КСУ з аджиліті 24.10.2026: CACAg, A1, A2 та Open. Перед поїздкою перевірте розклад і місце на сторінці організатора.',
      '2026-10-24 10:00:00+03',
      '+380 66 724 50 23',
      null,
      null,
      null,
      'https://www.uku.com.ua/shows_champ/kalend_sport.html',
      null,
      null,
      null,
      'active',
      'published',
      'platform_curated',
      'standard',
      now(),
      now(),
      now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000401',
      platform_owner_id,
      'service',
      'LuckyDOG — грумінг собак і котів',
      'вул. Княжий Затон, 21',
      'Київ',
      'Гігієнічний і комплексний догляд, грумінг цуценят і котів, тримінг, догляд за зубами та кігтями. Прийом щодня 10:00–20:00; ціна залежить від розміру та стану шерсті.',
      null,
      '+380 93 337 30 30 · +380 96 337 30 30 · kiev.lucky.dog@gmail.com',
      'groomer',
      null,
      600,
      'https://luckydog.kiev.ua/',
      null,
      null,
      null,
      'active',
      'published',
      'platform_curated',
      'standard',
      now(),
      now(),
      now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000402',
      platform_owner_id,
      'service',
      'Olivia Dog Hotel — готель і грумінг для собак',
      'с. Погреби, Київська область',
      'Київська область',
      'Сімейний готель для собак із доглядом та індивідуальним розміщенням. Перетримка — від 500 грн за добу, купання та стрижка — від 700 грн; точну ціну узгоджують перед заселенням.',
      null,
      'Запис і умови — на oliviadoghotel.com',
      'dog_hotel',
      null,
      500,
      'https://www.oliviadoghotel.com/',
      null,
      null,
      null,
      'active',
      'published',
      'platform_curated',
      'standard',
      now(),
      now(),
      now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000501',
      platform_owner_id,
      'offer',
      'ROZETKA — до −20% на догляд і гігієну',
      'Онлайн по Україні',
      'Онлайн',
      'Знижки на товари для догляду та гігієни домашніх улюбленців. Асортимент і залишки перевіряйте на сторінці акції.',
      null,
      'Умови та товари — на сторінці акції',
      null,
      'shop',
      null,
      'https://rozetka.com.ua/news-articles-promotions/promotions/330466_sale_vet/',
      'Знижки до 20% на товари для догляду та гігієни; діє до 30.09.2026 включно.',
      '2026-09-10',
      '2026-09-30',
      'active',
      'published',
      'platform_curated',
      'standard',
      now(),
      now(),
      now()
    ),
    (
      'c8a57401-3701-4b4e-b0d8-000000000502',
      platform_owner_id,
      'offer',
      'ROZETKA — до −40% на наповнювачі та аксесуари',
      'Онлайн по Україні',
      'Онлайн',
      'Акція на наповнювачі та аксесуари для домашніх улюбленців. Кількість акційних товарів обмежена.',
      null,
      'Умови та товари — на сторінці акції',
      null,
      'shop',
      null,
      'https://rozetka.com.ua/ua/news-articles-promotions/promotions/330465_sale_pets/',
      'Знижки до 40% на наповнювачі та аксесуари; діє до 30.09.2026 включно.',
      '2026-09-10',
      '2026-09-30',
      'active',
      'published',
      'platform_curated',
      'standard',
      now(),
      now(),
      now()
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
