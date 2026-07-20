-- Allows platform administrators to archive rule-breaking announcements.
-- The owner receives a durable notification and cannot republish a blocked row.

alter table public.announcements
  add column if not exists moderation_reason text,
  add column if not exists moderated_at timestamptz,
  add column if not exists moderated_by uuid references public.profiles(id)
    on delete set null;

alter table public.notifications
  drop constraint if exists notifications_type_check,
  add constraint notifications_type_check check (
    type in (
      'appointment_created', 'appointment_confirmed',
      'appointment_cancelled_by_clinic', 'appointment_reminder_24h',
      'appointment_reminder_2h', 'visit_record_published',
      'document_uploaded', 'next_visit_recommended', 'review_request',
      'clinic_message_placeholder', 'new_appointment_request',
      'appointment_cancelled_by_owner', 'appointment_upcoming_today',
      'visit_record_missing', 'review_received',
      'subscription_limit_warning', 'subscription_upgrade_request_status',
      'pet_transfer_request', 'medication_reminder',
      'announcement_moderated'
    )
  );

drop policy if exists "owners update announcements" on public.announcements;
create policy "owners update announcements"
on public.announcements for update to authenticated
using (
  owner_id = auth.uid()
  and moderation_status <> 'blocked'
)
with check (
  owner_id = auth.uid()
  and moderation_status = 'published'
  and (
    (
      announcement_type in ('sale', 'breeding')
      and public.owns_pet(pet_id)
    )
    or (
      announcement_type in ('event', 'service', 'offer')
      and pet_id is null
    )
  )
);

create or replace function public.admin_archive_announcement(
  target_announcement_id uuid,
  target_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  announcement_owner_id uuid;
  announcement_title text;
  normalized_reason text := nullif(trim(target_reason), '');
begin
  if not public.is_platform_admin() then
    raise exception 'ADMIN_REQUIRED';
  end if;
  if normalized_reason is null
     or char_length(normalized_reason) < 10
     or char_length(normalized_reason) > 500 then
    raise exception 'INVALID_MODERATION_REASON';
  end if;

  select
    announcement.owner_id,
    coalesce(
      nullif(trim(announcement.title), ''),
      nullif(trim(announcement.pet_name), ''),
      nullif(trim(announcement.breed), ''),
      'Без назви'
    )
  into announcement_owner_id, announcement_title
  from public.announcements announcement
  where announcement.id = target_announcement_id
  for update;

  if announcement_owner_id is null then
    raise exception 'ANNOUNCEMENT_NOT_FOUND';
  end if;

  update public.announcements
  set
    status = 'inactive',
    moderation_status = 'blocked',
    moderation_reason = normalized_reason,
    moderated_at = now(),
    moderated_by = auth.uid(),
    updated_at = now()
  where id = target_announcement_id;

  insert into public.notifications (
    user_id,
    type,
    title,
    body,
    status,
    data
  )
  values (
    announcement_owner_id,
    'announcement_moderated',
    'Оголошення переміщено в архів',
    format(
      'Оголошення «%s» переміщено в архів через порушення правил. Причина: %s',
      announcement_title,
      normalized_reason
    ),
    'unread',
    jsonb_build_object(
      'announcement_id', target_announcement_id,
      'reason', normalized_reason,
      'action', 'archived_by_moderator'
    )
  );

  insert into public.platform_admin_audit_log (
    admin_user_id,
    action,
    target_type,
    target_id,
    details
  )
  values (
    auth.uid(),
    'announcement_archived',
    'announcement',
    target_announcement_id::text,
    jsonb_build_object(
      'owner_id', announcement_owner_id,
      'reason', normalized_reason,
      'title', announcement_title
    )
  );
end;
$$;

drop function if exists public.admin_announcement_analytics();
create function public.admin_announcement_analytics()
returns table (
  announcement_id uuid,
  owner_id uuid,
  owner_email text,
  owner_name text,
  announcement_type text,
  title text,
  summary text,
  city text,
  status text,
  moderation_status text,
  moderation_reason text,
  moderated_at timestamptz,
  publication_tier text,
  publication_source text,
  view_count bigint,
  created_at timestamptz,
  publication_expires_at timestamptz,
  details jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_platform_admin() then
    raise exception 'ADMIN_REQUIRED';
  end if;

  return query
  select
    announcement.id,
    announcement.owner_id,
    profile.email,
    profile.full_name,
    announcement.announcement_type,
    coalesce(
      nullif(trim(announcement.title), ''),
      nullif(trim(announcement.pet_name), ''),
      nullif(trim(announcement.breed), ''),
      'Без назви'
    ),
    coalesce(
      nullif(trim(announcement.description), ''),
      nullif(trim(announcement.offer_text), ''),
      nullif(trim(announcement.conditions), '')
    ),
    announcement.city,
    announcement.status,
    announcement.moderation_status,
    announcement.moderation_reason,
    announcement.moderated_at,
    announcement.publication_tier,
    announcement.publication_source,
    coalesce(metrics.view_count, 0),
    announcement.created_at,
    announcement.publication_expires_at,
    jsonb_strip_nulls(jsonb_build_object(
      'pet_name', announcement.pet_name,
      'breed', announcement.breed,
      'gender', announcement.gender,
      'birth_date', announcement.birth_date,
      'price_amount', announcement.price_amount,
      'desired_breed', announcement.desired_breed,
      'address', announcement.address,
      'event_date', announcement.event_date,
      'service_category', announcement.service_category,
      'offer_category', announcement.offer_category,
      'website', announcement.website,
      'offer_text', announcement.offer_text,
      'valid_from', announcement.valid_from,
      'valid_until', announcement.valid_until,
      'promo_code', announcement.promo_code,
      'contact_name', announcement.contact_name,
      'contact_phone', announcement.contact_phone,
      'contact_info', announcement.contact_info
    ))
  from public.announcements announcement
  join public.profiles profile on profile.id = announcement.owner_id
  left join public.announcement_owner_metrics metrics
    on metrics.announcement_id = announcement.id
  order by announcement.created_at desc;
end;
$$;

revoke all on function public.admin_archive_announcement(uuid, text)
  from public, anon;
revoke all on function public.admin_announcement_analytics()
  from public, anon;

grant execute on function public.admin_archive_announcement(uuid, text)
  to authenticated;
grant execute on function public.admin_announcement_analytics()
  to authenticated;

notify pgrst, 'reload schema';
