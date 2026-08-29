-- Adds 15 deterministic demo pets to nagornyi1103@icloud.com.
-- Run once in Supabase SQL Editor. Safe to run repeatedly.
begin;

do $$
declare
  target_user_id uuid;
  pet_id uuid;
  pet_names text[] := array[
    'Барсик', 'Мурка', 'Рекс', 'Белла', 'Чарли',
    'Лаки', 'Нора', 'Оскар', 'Соня', 'Боня',
    'Тоша', 'Луна', 'Макс', 'Жужа', 'Арчи'
  ];
  pet_species text[] := array[
    'cat', 'cat', 'dog', 'dog', 'rabbit',
    'bird', 'rodent', 'reptile', 'cat', 'dog',
    'rabbit', 'bird', 'dog', 'rodent', 'cat'
  ];
  pet_breeds text[] := array[
    'Британська короткошерста', 'Шотландська висловуха', 'Лабрадор ретрівер',
    'Мальтезе', 'Рекс', 'Корела', 'Сирійський хом’як', 'Бородата агама',
    'Сіамська', 'Пудель', 'Нідерландський карлик', 'Хвилястий папужка',
    'Золотистий ретрівер', 'Шиншила', 'Мейн-кун'
  ];
begin
  select id into target_user_id from auth.users
    where lower(email) = 'nagornyi1103@icloud.com' limit 1;
  if target_user_id is null then
    raise exception 'USER_NOT_FOUND: nagornyi1103@icloud.com';
  end if;

  for i in 1..15 loop
    pet_id := ('78000000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid;
    insert into public.pets (id, owner_id, name, species, breed, sex)
    values (pet_id, target_user_id, pet_names[i], pet_species[i], pet_breeds[i],
            case when i % 2 = 0 then 'female' else 'male' end)
    on conflict (id) do update set
      owner_id = excluded.owner_id, name = excluded.name,
      species = excluded.species, breed = excluded.breed,
      sex = excluded.sex;

    insert into public.pet_owners (pet_id, user_id, relationship, relationship_type, is_primary)
    values (pet_id, target_user_id, 'primary_owner', 'primary_owner', true)
    on conflict (pet_id, user_id) do update set is_primary = true;
  end loop;
end $$;

commit;
