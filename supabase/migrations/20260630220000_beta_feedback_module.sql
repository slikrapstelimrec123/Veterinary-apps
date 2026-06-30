-- Beta feedback collection for controlled MVP testing.

create table if not exists beta_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  clinic_id uuid references clinics(id) on delete set null,
  role text not null,
  rating integer,
  category text,
  message text not null,
  status text not null default 'new',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint beta_feedback_rating_check check (rating is null or rating between 1 and 5),
  constraint beta_feedback_category_check check (category is null or category in ('bug', 'usability', 'feature_request', 'data_issue', 'other')),
  constraint beta_feedback_status_check check (status in ('new', 'reviewed', 'resolved', 'ignored'))
);

create index if not exists beta_feedback_user_idx on beta_feedback(user_id, created_at desc);
create index if not exists beta_feedback_clinic_idx on beta_feedback(clinic_id, created_at desc);
create index if not exists beta_feedback_status_idx on beta_feedback(status, created_at desc);

alter table beta_feedback enable row level security;

drop policy if exists "users create own beta feedback" on beta_feedback;
drop policy if exists "users read own beta feedback" on beta_feedback;
drop policy if exists "platform admins manage beta feedback" on beta_feedback;

create policy "users create own beta feedback"
on beta_feedback for insert
with check (user_id = auth.uid());

create policy "users read own beta feedback"
on beta_feedback for select
using (user_id = auth.uid() or public.is_platform_admin());

create policy "platform admins manage beta feedback"
on beta_feedback for all
using (public.is_platform_admin())
with check (public.is_platform_admin());
