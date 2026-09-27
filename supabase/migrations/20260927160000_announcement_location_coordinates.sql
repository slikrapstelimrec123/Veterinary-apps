-- Coordinates are optional because legacy records may only contain a city/address.
-- They are used only for the client-side "Поруч" discovery filter.
alter table public.announcements
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

alter table public.announcements
  drop constraint if exists announcements_latitude_range_check;

alter table public.announcements
  add constraint announcements_latitude_range_check
    check (latitude is null or latitude between -90 and 90),
  add constraint announcements_longitude_range_check
    check (longitude is null or longitude between -180 and 180);

create index if not exists announcements_published_location_idx
  on public.announcements (latitude, longitude)
  where status = 'active' and moderation_status = 'published';
