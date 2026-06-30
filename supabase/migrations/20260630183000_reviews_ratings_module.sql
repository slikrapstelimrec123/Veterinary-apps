-- Reviews, clinic ratings, doctor ratings, and post-appointment feedback.
-- MVP scope: published immediately, no payments/subscriptions/chat/push/AI/ranking.

alter table reviews add column if not exists visit_record_id uuid references visit_records(id);
alter table reviews add column if not exists pet_id uuid references pets(id);
alter table reviews add column if not exists doctor_rating integer;
alter table reviews add column if not exists clinic_rating integer;
alter table reviews add column if not exists service_quality_rating integer;
alter table reviews add column if not exists status text not null default 'published';
alter table reviews add column if not exists is_anonymous boolean not null default false;
alter table reviews add column if not exists updated_at timestamptz not null default now();

update reviews
set
  pet_id = coalesce(reviews.pet_id, appointments.pet_id),
  clinic_id = appointments.clinic_id,
  doctor_id = coalesce(reviews.doctor_id, appointments.doctor_id),
  is_published = coalesce(reviews.is_published, true),
  status = case
    when reviews.status is not null then reviews.status
    when reviews.is_published = true then 'published'
    else 'hidden'
  end
from appointments
where appointments.id = reviews.appointment_id;

alter table reviews alter column appointment_id set not null;
alter table reviews alter column pet_id set not null;
alter table reviews alter column status set default 'published';

alter table reviews drop constraint if exists reviews_rating_range_check;
alter table reviews add constraint reviews_rating_range_check check (rating between 1 and 5);

alter table reviews drop constraint if exists reviews_doctor_rating_range_check;
alter table reviews add constraint reviews_doctor_rating_range_check check (doctor_rating is null or doctor_rating between 1 and 5);

alter table reviews drop constraint if exists reviews_clinic_rating_range_check;
alter table reviews add constraint reviews_clinic_rating_range_check check (clinic_rating is null or clinic_rating between 1 and 5);

alter table reviews drop constraint if exists reviews_service_quality_rating_range_check;
alter table reviews add constraint reviews_service_quality_rating_range_check check (service_quality_rating is null or service_quality_rating between 1 and 5);

alter table reviews drop constraint if exists reviews_status_check;
alter table reviews add constraint reviews_status_check check (status in ('pending_moderation', 'published', 'hidden', 'reported', 'removed'));

create unique index if not exists reviews_one_per_appointment_owner_idx
on reviews(appointment_id, owner_id);

create index if not exists reviews_clinic_id_idx on reviews(clinic_id);
create index if not exists reviews_doctor_id_idx on reviews(doctor_id);
create index if not exists reviews_owner_id_idx on reviews(owner_id);
create index if not exists reviews_appointment_id_idx on reviews(appointment_id);
create index if not exists reviews_status_idx on reviews(status);
create index if not exists reviews_rating_idx on reviews(rating);
create index if not exists reviews_created_at_idx on reviews(created_at);

create or replace function public.has_user_reviewed_appointment(target_user_id uuid, target_appointment_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from reviews
    where owner_id = target_user_id
      and appointment_id = target_appointment_id
      and status <> 'removed'
  );
$$;

create or replace function public.can_user_review_appointment(target_user_id uuid, target_appointment_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from appointments appointment
    join profiles profile on profile.id = target_user_id and profile.role = 'pet_owner'
    where appointment.id = target_appointment_id
      and appointment.owner_id = target_user_id
      and public.owns_pet(appointment.pet_id)
      and (
        appointment.status = 'completed'
        or exists (
          select 1
          from visit_records record
          where record.appointment_id = appointment.id
            and record.status = 'published'
        )
      )
      and not public.has_user_reviewed_appointment(target_user_id, target_appointment_id)
  );
$$;

create or replace function public.validate_review_relationships()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  appointment_row appointments%rowtype;
  visit_row visit_records%rowtype;
begin
  select * into appointment_row
  from appointments
  where id = new.appointment_id;

  if not found then
    raise exception 'Review must reference a valid appointment';
  end if;

  if new.owner_id <> appointment_row.owner_id then
    raise exception 'Review owner must match appointment owner';
  end if;

  if new.clinic_id <> appointment_row.clinic_id then
    raise exception 'Review clinic must match appointment clinic';
  end if;

  if new.pet_id <> appointment_row.pet_id then
    raise exception 'Review pet must match appointment pet';
  end if;

  if new.doctor_id is not null and appointment_row.doctor_id is not null and new.doctor_id <> appointment_row.doctor_id then
    raise exception 'Review doctor must match appointment doctor';
  end if;

  if new.doctor_id is null then
    new.doctor_id := appointment_row.doctor_id;
  end if;

  if new.visit_record_id is not null then
    select * into visit_row
    from visit_records
    where id = new.visit_record_id;

    if not found
      or visit_row.appointment_id <> new.appointment_id
      or visit_row.clinic_id <> new.clinic_id
      or visit_row.pet_id <> new.pet_id
      or visit_row.status <> 'published' then
      raise exception 'Review visit record must match a published appointment visit record';
    end if;
  end if;

  if new.status is null then
    new.status := 'published';
  end if;

  new.is_published := new.status = 'published';
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists validate_review_relationships_trigger on reviews;
create trigger validate_review_relationships_trigger
before insert or update on reviews
for each row
execute function public.validate_review_relationships();

create or replace view clinic_rating_summary as
select
  clinic_id,
  round(avg(rating)::numeric, 2) as average_rating,
  count(*)::integer as review_count,
  round(avg(clinic_rating)::numeric, 2) as average_clinic_rating,
  max(created_at) as latest_review_date
from reviews
where status = 'published'
group by clinic_id;

create or replace view doctor_rating_summary as
select
  doctor_id,
  round(avg(rating)::numeric, 2) as average_rating,
  count(*)::integer as review_count,
  round(avg(doctor_rating)::numeric, 2) as average_doctor_rating,
  max(created_at) as latest_review_date
from reviews
where status = 'published'
  and doctor_id is not null
group by doctor_id;

drop policy if exists "public reads published reviews" on reviews;
drop policy if exists "owners create reviews for completed appointments" on reviews;
drop policy if exists "reviews public and connected read" on reviews;
drop policy if exists "pet owners create eligible reviews" on reviews;
drop policy if exists "pet owners update own editable reviews" on reviews;
drop policy if exists "platform admins moderate reviews" on reviews;

create policy "reviews public and connected read"
on reviews for select
using (
  status = 'published'
  or owner_id = auth.uid()
  or public.is_clinic_member(clinic_id)
  or public.is_platform_admin()
);

create policy "pet owners create eligible reviews"
on reviews for insert
with check (
  owner_id = auth.uid()
  and exists (
    select 1 from profiles
    where profiles.id = auth.uid()
      and profiles.role = 'pet_owner'
  )
  and public.can_user_review_appointment(auth.uid(), appointment_id)
);

create policy "pet owners update own editable reviews"
on reviews for update
using (
  owner_id = auth.uid()
  and status in ('pending_moderation', 'published')
)
with check (
  owner_id = auth.uid()
  and status in ('pending_moderation', 'published')
);

create policy "platform admins moderate reviews"
on reviews for update
using (public.is_platform_admin())
with check (public.is_platform_admin());
