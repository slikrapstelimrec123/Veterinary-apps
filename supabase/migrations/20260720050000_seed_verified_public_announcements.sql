-- Adds a small verified starter catalogue so the community sections are not
-- empty. Curated rows are owned by the platform administrator, never consume a
-- customer listing credit, and can only be inserted from a privileged database
-- session (auth.uid() is null).

alter table public.announcements
  drop constraint if exists announcements_publication_source_check;

alter table public.announcements
  add constraint announcements_publication_source_check check (
    publication_source is null
    or publication_source in (
      'free_quota',
      'subscription_quota',
      'event_free',
      'paid_credit',
      'platform_curated'
    )
  );

create or replace function public.reserve_announcement_publication()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  plan_data jsonb;
  plan_code text;
  period_start timestamptz;
  category_limit integer;
  used_count integer;
  credit public.owner_listing_credits;
begin
  if new.owner_id is null then
    raise exception 'Authentication required';
  end if;

  perform pg_advisory_xact_lock(hashtext(new.owner_id::text));
  new.published_at := coalesce(new.published_at, now());
  new.ranking_at := coalesce(new.ranking_at, new.published_at);
  new.publication_expires_at := new.published_at + interval '30 days';
  new.delete_after := new.published_at + interval '60 days';

  if new.publication_source = 'platform_curated' then
    if auth.uid() is not null then
      raise exception 'PLATFORM_CURATED_REQUIRES_PRIVILEGED_SESSION';
    end if;
    new.publication_tier := 'standard';
    new.promoted_until := null;
    new.bumps_remaining := 0;
    new.next_bump_at := null;
    return new;
  end if;

  if new.announcement_type = 'event' then
    new.publication_source := 'event_free';
    new.publication_tier := 'standard';
    return new;
  end if;

  if new.listing_credit_id is not null then
    select *
    into credit
    from public.owner_listing_credits
    where id = new.listing_credit_id
      and user_id = new.owner_id
      and status = 'available'
    for update;

    if credit.id is null then
      raise exception 'LISTING_CREDIT_REQUIRED';
    end if;

    new.publication_source := 'paid_credit';
    new.publication_tier := credit.tier;
    if credit.tier = 'top_7' then
      new.promoted_until := new.published_at + interval '7 days';
      new.bumps_remaining := 3;
      new.next_bump_at := new.published_at + interval '2 days';
    elsif credit.tier = 'top_15' then
      new.promoted_until := new.published_at + interval '15 days';
      new.bumps_remaining := 5;
      new.next_bump_at := new.published_at + interval '3 days';
    end if;
    return new;
  end if;

  if new.announcement_type in ('service', 'offer') then
    raise exception 'LISTING_CREDIT_REQUIRED';
  end if;

  select public.get_my_owner_plan() into plan_data;
  plan_code := coalesce(plan_data->>'code', 'free');
  period_start := date_trunc('month', now());

  if plan_code = 'free' then
    select count(*)
    into used_count
    from public.announcements announcement
    where announcement.owner_id = new.owner_id
      and announcement.announcement_type in ('sale', 'breeding')
      and announcement.created_at >= period_start;
    category_limit := 1;
  else
    category_limit := case
      when new.announcement_type = 'sale'
        then (plan_data->>'sale_monthly_limit')::integer
      else (plan_data->>'breeding_monthly_limit')::integer
    end;
    select count(*)
    into used_count
    from public.announcements announcement
    where announcement.owner_id = new.owner_id
      and announcement.announcement_type = new.announcement_type
      and announcement.created_at >= period_start;
  end if;

  if used_count >= category_limit then
    raise exception using
      errcode = 'P0001',
      message = 'ANNOUNCEMENT_PLAN_LIMIT_REACHED',
      detail = jsonb_build_object(
        'limit', category_limit,
        'used', used_count,
        'plan', plan_code,
        'type', new.announcement_type
      )::text;
  end if;

  new.publication_source := case
    when plan_code = 'free' then 'free_quota'
    else 'subscription_quota'
  end;
  new.publication_tier := 'standard';
  return new;
end;
$$;

do $$
declare
  platform_owner_id uuid;
begin
  select profile.id
  into platform_owner_id
  from public.profiles profile
  where lower(profile.email) = 'slikrapstelimrec123@gmail.com'
     or profile.role = 'platform_admin'
  order by
    case
      when lower(profile.email) = 'slikrapstelimrec123@gmail.com' then 0
      else 1
    end,
    profile.created_at
  limit 1;

  if platform_owner_id is null then
    raise notice 'Verified announcements were not seeded: platform owner is absent.';
    return;
  end if;

  insert into public.announcements (
    id,
    owner_id,
    announcement_type,
    title,
    address,
    city,
    description,
    event_date,
    contact_info,
    service_category,
    offer_category,
    price_amount,
    website,
    offer_text,
    valid_from,
    valid_until,
    status,
    moderation_status,
    publication_source,
    publication_tier,
    published_at,
    created_at,
    updated_at
  )
  values
    (
      'b8d57401-3701-4b4e-b0d8-000000000001',
      platform_owner_id,
      'service',
      'Професійна підготовка собак Kinolog',
      'Виїзд по Києву та Київській області',
      'Київ',
      'Заняття з послуху, корекція поведінки, консультації для власників та підготовка собак до спорту і виставок. Команда зазначає понад 20 років досвіду.',
      null,
      '+380 93 145 55 50 · kinologvkiev@gmail.com',
      'dog_trainer',
      null,
      700,
      'https://kinolog.net.ua/',
      null,
      null,
      null,
      'active',
      'published',
      'platform_curated',
      'standard',
      '2026-07-10 09:00:00+03',
      '2026-07-10 09:00:00+03',
      '2026-07-10 09:00:00+03'
    ),
    (
      'b8d57401-3701-4b4e-b0d8-000000000002',
      platform_owner_id,
      'service',
      'PUGGI Grooming Salon',
      'просп. Павла Тичини, 18/1',
      'Київ',
      'Грумінг для собак і котів на Березняках: комплексний та гігієнічний догляд, SPA-процедури й робота з тваринами різних порід та розмірів.',
      null,
      '+380 96 793 01 71',
      'groomer',
      null,
      null,
      'https://puggi-grooming.kyiv.ua/',
      null,
      null,
      null,
      'active',
      'published',
      'platform_curated',
      'standard',
      '2026-07-12 12:30:00+03',
      '2026-07-12 12:30:00+03',
      '2026-07-12 12:30:00+03'
    ),
    (
      'b8d57401-3701-4b4e-b0d8-000000000003',
      platform_owner_id,
      'service',
      'Мамій — салон професійного грумінгу',
      'вул. Салютна, 10-73',
      'Київ',
      'Комплексний, гігієнічний та адаптивний грумінг, експрес-линька, тримінг і догляд за різними домашніми тваринами. Вартість залежить від породи та комплексу.',
      null,
      '+380 66 267 15 68 · Instagram: @mamiy_groom_kyiv',
      'groomer',
      null,
      850,
      'https://mamiy.easyweek.com.ua/',
      null,
      null,
      null,
      'active',
      'published',
      'platform_curated',
      'standard',
      '2026-07-14 10:15:00+03',
      '2026-07-14 10:15:00+03',
      '2026-07-14 10:15:00+03'
    ),
    (
      'b8d57401-3701-4b4e-b0d8-000000000004',
      platform_owner_id,
      'service',
      'Dog Hotel — готель для собак',
      'просп. Відрадний, 31',
      'Київ',
      'Приватний готель із цілодобовим наглядом і ветеринарною підтримкою. Доступне проживання з харчуванням готелю або з кормом власника.',
      null,
      '+380 67 917 95 85 · +380 99 459 44 51',
      'dog_hotel',
      null,
      750,
      'https://www.doghotel.com.ua/',
      null,
      null,
      null,
      'active',
      'published',
      'platform_curated',
      'standard',
      '2026-07-15 15:40:00+03',
      '2026-07-15 15:40:00+03',
      '2026-07-15 15:40:00+03'
    ),
    (
      'b8d57401-3701-4b4e-b0d8-000000000005',
      platform_owner_id,
      'service',
      'INNIKOS Club Hotel',
      'с. Зазим’я, 15 хвилин від Троєщини',
      'Київська область',
      'Готель для собак і котів з окремими кімнатами, великою територією для вигулу та триразовим вигулом. Є пансіон із дресируванням і додатковий догляд.',
      null,
      '+380 93 055 59 11 · innikos.club@gmail.com',
      'dog_hotel',
      null,
      350,
      'https://innikos.com/hotel',
      null,
      null,
      null,
      'active',
      'published',
      'platform_curated',
      'standard',
      '2026-07-16 11:20:00+03',
      '2026-07-16 11:20:00+03',
      '2026-07-16 11:20:00+03'
    ),
    (
      'b8d57401-3701-4b4e-b0d8-000000000006',
      platform_owner_id,
      'service',
      'VOINOVA DOG SCHOOL',
      'Солом’янка та Поділ, відкриті тренувальні майданчики',
      'Київ',
      'Індивідуальні й групові заняття з професійним кінологом: базовий послух, соціалізація, корекція агресії, страхів і складної поведінки. Тренер зазначає понад 15 років практичного досвіду.',
      null,
      '+380 68 240 35 55 · Telegram: @VoinovaDogSchool',
      'dog_trainer',
      null,
      null,
      'https://voinovadogschool.com/',
      null,
      null,
      null,
      'active',
      'published',
      'platform_curated',
      'standard',
      '2026-07-11 10:30:00+03',
      '2026-07-11 10:30:00+03',
      '2026-07-11 10:30:00+03'
    ),
    (
      'b8d57401-3701-4b4e-b0d8-000000000007',
      platform_owner_id,
      'service',
      'Школа дресирування «Альфа»',
      'вул. Полковника Потєхіна, Голосіївський район',
      'Київ',
      'Групове та індивідуальне дресирування, курси для цуценят, слухняність, психологічна і спеціальна підготовка. Школа працює у Києві понад 30 років.',
      null,
      '+380 67 502 92 40',
      'dog_trainer',
      null,
      null,
      'https://alfadog.com.ua/',
      null,
      null,
      null,
      'active',
      'published',
      'platform_curated',
      'standard',
      '2026-07-13 11:45:00+03',
      '2026-07-13 11:45:00+03',
      '2026-07-13 11:45:00+03'
    ),
    (
      'b8d57401-3701-4b4e-b0d8-000000000008',
      platform_owner_id,
      'service',
      'StarDog — кінолог із виїздом',
      'Виїзд за адресою клієнта у Києві',
      'Київ',
      'Індивідуальне дресирування собак і цуценят, курс слухняності, корекція поведінки та домашня перетримка. Заняття проводяться без вихідних за погодженим графіком.',
      null,
      '+380 98 376 57 56 · info@stardog.com.ua',
      'dog_trainer',
      null,
      1300,
      'https://stardog.com.ua/',
      null,
      null,
      null,
      'active',
      'published',
      'platform_curated',
      'standard',
      '2026-07-18 12:20:00+03',
      '2026-07-18 12:20:00+03',
      '2026-07-18 12:20:00+03'
    ),
    (
      'b8d57401-3701-4b4e-b0d8-000000000101',
      platform_owner_id,
      'offer',
      'ROZETKA — знижки до 40% на зоотовари',
      'Онлайн по Україні',
      'Онлайн',
      'Акційна добірка товарів для домашніх тварин зі знижками до 40%. Кількість акційних товарів обмежена.',
      null,
      'Умови та наявність — на сторінці акції',
      null,
      'shop',
      null,
      'https://rozetka.com.ua/news-articles-promotions/promotions/326054_sale_petproducts/',
      'Знижки до 40% на вибрані товари для домашніх тварин.',
      '2026-07-01',
      '2026-07-31',
      'active',
      'published',
      'platform_curated',
      'standard',
      '2026-07-11 13:00:00+03',
      '2026-07-11 13:00:00+03',
      '2026-07-11 13:00:00+03'
    ),
    (
      'b8d57401-3701-4b4e-b0d8-000000000102',
      platform_owner_id,
      'offer',
      'E-zoo для учасників Плюхс',
      'Магазини та сайт E-zoo',
      'Онлайн',
      'Пропозиція партнера програми Плюхс: балобонуси на неакційні консерви для котів і собак. Не поширюється на лікувальні корми.',
      null,
      'Детальні умови — у програмі Плюхс та на сайті E-zoo',
      null,
      'shop',
      null,
      'https://e-zoo.ua/',
      '18% балобонусами на неакційні консерви для котів і собак.',
      '2026-05-20',
      '2026-12-31',
      'active',
      'published',
      'platform_curated',
      'standard',
      '2026-07-13 16:10:00+03',
      '2026-07-13 16:10:00+03',
      '2026-07-13 16:10:00+03'
    ),
    (
      'b8d57401-3701-4b4e-b0d8-000000000103',
      platform_owner_id,
      'offer',
      'The PET — знижка на перший грумінг малечі',
      'вул. Маршала Тимошенка, 21, корпус 14',
      'Київ',
      'Знижка на гігієнічний догляд для цуценят і кошенят віком до 6 місяців. Перед записом уточніть актуальність і доступний час у салоні.',
      null,
      '+380 50 056 02 34',
      null,
      'other',
      null,
      'https://thepet.kyiv.ua/',
      '15% знижки на гігієнічний догляд для цуценят і кошенят до 6 місяців.',
      '2026-07-17',
      '2026-08-19',
      'active',
      'published',
      'platform_curated',
      'standard',
      '2026-07-17 10:00:00+03',
      '2026-07-17 10:00:00+03',
      '2026-07-17 10:00:00+03'
    ),
    (
      'b8d57401-3701-4b4e-b0d8-000000000104',
      platform_owner_id,
      'offer',
      'PUGGI — знижки на перше відвідування',
      'просп. Павла Тичини, 18/1',
      'Київ',
      'Грумінг-салон PUGGI публікує кілька постійних пропозицій: знижка для нових клієнтів, знижка у день народження улюбленця та винагорода за рекомендацію другові.',
      null,
      '+380 96 793 01 71',
      null,
      'other',
      null,
      'https://puggi-grooming.kyiv.ua/',
      '-10% новим клієнтам і в день народження улюбленця; -20% за приведеного друга. Перед записом уточніть актуальні умови.',
      '2026-07-20',
      '2026-08-19',
      'active',
      'published',
      'platform_curated',
      'standard',
      '2026-07-16 13:25:00+03',
      '2026-07-16 13:25:00+03',
      '2026-07-16 13:25:00+03'
    ),
    (
      'b8d57401-3701-4b4e-b0d8-000000000105',
      platform_owner_id,
      'offer',
      '«Альфа» — перше заняття безкоштовно',
      'вул. Полковника Потєхіна, Голосіївський район',
      'Київ',
      'Школа охоронних собак «Альфа» запрошує власників із собаками на перше безкоштовне заняття. Місце й час групи школа підтверджує після реєстрації.',
      null,
      '+380 67 502 92 40',
      null,
      'other',
      null,
      'https://alfadog.com.ua/',
      'Перше ознайомче заняття безкоштовне за попереднім записом. Уточніть наявність місць у школі.',
      '2026-07-20',
      '2026-08-19',
      'active',
      'published',
      'platform_curated',
      'standard',
      '2026-07-18 09:10:00+03',
      '2026-07-18 09:10:00+03',
      '2026-07-18 09:10:00+03'
    ),
    (
      'b8d57401-3701-4b4e-b0d8-000000000106',
      platform_owner_id,
      'offer',
      'MasterZoo — дисконтна програма',
      'Магазини MasterZoo та інтернет-магазин',
      'Онлайн',
      'Офіційна накопичувальна програма лояльності MasterZoo для покупок у магазинах мережі, грумінг-салонах та на сайті. На частину брендів і акційних товарів діють винятки.',
      null,
      '0 800 212 002',
      null,
      'shop',
      null,
      'https://masterzoo.ua/ua/pravila-diskontnoi-programi-loyalnosti/',
      'Базова знижка 5% після приєднання до дисконтної програми; розмір може зростати відповідно до офіційних правил.',
      '2026-07-20',
      '2026-08-19',
      'active',
      'published',
      'platform_curated',
      'standard',
      '2026-07-19 09:50:00+03',
      '2026-07-19 09:50:00+03',
      '2026-07-19 09:50:00+03'
    ),
    (
      'b8d57401-3701-4b4e-b0d8-000000000201',
      platform_owner_id,
      'event',
      'Київські зустрічі-2026',
      'Концертно-танцювальний зал «Ровесник», парк «Перемога»',
      'Київ',
      'Всеукраїнська виставка собак і блок монопородних виставок. Організатор публікує реєстрацію та актуальні списки учасників на офіційній сторінці.',
      '2026-07-25 10:00:00+03',
      'Реєстрація та деталі — на сайті Київського міського відділення КСУ',
      null,
      null,
      null,
      'https://www.uku.kyiv.ua/2026/07/16/%d0%ba%d0%b8%d1%97%d0%b2%d1%81%d1%8c%d0%ba%d1%96-%d0%b7%d1%83%d1%81%d1%82%d1%80%d1%96%d1%87%d1%96-2026-%d0%ba%d1%83%d0%b1%d0%be%d0%ba-%d0%b5%d1%82%d0%b0%d0%bb%d0%be%d0%bd%d1%83-2026-%d1%82/',
      null,
      null,
      null,
      'active',
      'published',
      'platform_curated',
      'standard',
      '2026-07-18 09:30:00+03',
      '2026-07-18 09:30:00+03',
      '2026-07-18 09:30:00+03'
    ),
    (
      'b8d57401-3701-4b4e-b0d8-000000000202',
      platform_owner_id,
      'event',
      'PesDay Festival 2026',
      'Арт-завод «Платформа», вул. Якова Гніздовського, 1-А',
      'Київ',
      'Дводенний фестиваль для власників собак: зона без повідків, активності, знайомства, Dog Spa та тематичні локації для улюбленців.',
      '2026-09-12 10:00:00+03',
      '12–13 вересня 2026 · деталі та квитки на сторінці події',
      null,
      null,
      null,
      'https://kyivmaps.com/en/events/pesday',
      null,
      null,
      null,
      'active',
      'published',
      'platform_curated',
      'standard',
      '2026-07-19 14:00:00+03',
      '2026-07-19 14:00:00+03',
      '2026-07-19 14:00:00+03'
    )
  on conflict (id) do nothing;
end;
$$;

notify pgrst, 'reload schema';
