create table if not exists public.pet_reminders (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  reminder_date date not null,
  created_at timestamptz not null default now()
);

alter table public.pet_reminders enable row level security;

create policy "owners manage pet reminders" on public.pet_reminders
  for all using (public.owns_pet(pet_id))
  with check (public.owns_pet(pet_id));

create index if not exists pet_reminders_pet_date_idx
  on public.pet_reminders (pet_id, reminder_date);
