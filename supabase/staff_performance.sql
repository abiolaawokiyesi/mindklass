-- MindKlass staff performance tracker: one-time Supabase setup.
-- Run this once in Supabase > SQL Editor (paste, press Run). It is safe to run again.
-- It creates the staff tables, the daily summary view and the access rules (row level security).
-- It does not change any existing table.

create extension if not exists pgcrypto;

-- Is the signed-in user an administrator? (reads the existing profiles table)
create or replace function public.mk_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin');
$$;

-- Is the signed-in user an approved staff member?
create or replace function public.mk_is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.staff_members s where s.user_id = auth.uid() and s.status = 'approved');
$$;

-- 1. Staff members: one row per person who registered as staff. Admin approves them.
create table if not exists public.staff_members (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  position     text not null default '',
  line_manager text not null default '',
  status       text not null default 'pending' check (status in ('pending','approved','rejected','inactive')),
  created_at   timestamptz not null default now(),
  approved_at  timestamptz,
  approved_by  uuid
);
alter table public.staff_members enable row level security;

drop policy if exists "staff_members read" on public.staff_members;
create policy "staff_members read" on public.staff_members
  for select to authenticated using (user_id = auth.uid() or public.mk_is_admin());

drop policy if exists "staff_members request" on public.staff_members;
create policy "staff_members request" on public.staff_members
  for insert to authenticated with check (user_id = auth.uid() and status = 'pending');

drop policy if exists "staff_members admin update" on public.staff_members;
create policy "staff_members admin update" on public.staff_members
  for update to authenticated using (public.mk_is_admin()) with check (public.mk_is_admin());

drop policy if exists "staff_members admin delete" on public.staff_members;
create policy "staff_members admin delete" on public.staff_members
  for delete to authenticated using (public.mk_is_admin());

-- 2. Daily tasks: one row per task per day.
create table if not exists public.staff_tasks (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  task_date   date not null,
  position    integer not null default 1,
  title       text not null default '',
  quadrant    text not null default 'Q2' check (quadrant in ('Q1','Q2','Q3','Q4')),
  expected    text not null default '',
  completion  integer not null default 0 check (completion between 0 and 100),
  evidence    text not null default '',
  status      text not null default 'Not Started',
  blocker     text not null default '',
  next_action text not null default '',
  notes       text not null default '',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists staff_tasks_user_date_idx on public.staff_tasks (user_id, task_date);
create index if not exists staff_tasks_date_idx on public.staff_tasks (task_date);
alter table public.staff_tasks enable row level security;

drop policy if exists "staff_tasks own" on public.staff_tasks;
create policy "staff_tasks own" on public.staff_tasks
  for all to authenticated
  using (user_id = auth.uid() and public.mk_is_staff())
  with check (user_id = auth.uid() and public.mk_is_staff());

drop policy if exists "staff_tasks admin read" on public.staff_tasks;
create policy "staff_tasks admin read" on public.staff_tasks
  for select to authenticated using (public.mk_is_admin());

-- 3. Manager review of a day (the clearance): Pending, Approved or Not Approved. Admin writes, staff reads.
create table if not exists public.staff_day_reviews (
  user_id     uuid not null references auth.users(id) on delete cascade,
  task_date   date not null,
  approval    text not null default 'Pending' check (approval in ('Pending','Approved','Not Approved')),
  comment     text not null default '',
  reviewed_by uuid,
  reviewed_at timestamptz not null default now(),
  primary key (user_id, task_date)
);
alter table public.staff_day_reviews enable row level security;

drop policy if exists "staff_day_reviews read" on public.staff_day_reviews;
create policy "staff_day_reviews read" on public.staff_day_reviews
  for select to authenticated using (user_id = auth.uid() or public.mk_is_admin());

drop policy if exists "staff_day_reviews admin write" on public.staff_day_reviews;
create policy "staff_day_reviews admin write" on public.staff_day_reviews
  for all to authenticated using (public.mk_is_admin()) with check (public.mk_is_admin());

-- 4. Weekly plan (reference for the daily tasks).
create table if not exists public.staff_weekly_plans (
  user_id    uuid not null references auth.users(id) on delete cascade,
  week_start date not null,
  objective  text not null default '',
  items      jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, week_start)
);
alter table public.staff_weekly_plans enable row level security;

drop policy if exists "staff_weekly_plans own" on public.staff_weekly_plans;
create policy "staff_weekly_plans own" on public.staff_weekly_plans
  for all to authenticated
  using (user_id = auth.uid() and public.mk_is_staff())
  with check (user_id = auth.uid() and public.mk_is_staff());

drop policy if exists "staff_weekly_plans admin read" on public.staff_weekly_plans;
create policy "staff_weekly_plans admin read" on public.staff_weekly_plans
  for select to authenticated using (public.mk_is_admin());

-- 5. One row per person per day with the score. Weights: Q1 40, Q2 30, Q3 20, Q4 10.
--    score = sum(weight x completion) / sum(weight). security_invoker keeps the row level security above.
create or replace view public.staff_daily_summary
with (security_invoker = true) as
select
  t.user_id,
  t.task_date,
  count(*)::int as tasks_planned,
  count(*) filter (where t.completion >= 100)::int as tasks_completed,
  sum(case t.quadrant when 'Q1' then 40 when 'Q2' then 30 when 'Q3' then 20 else 10 end)::numeric as planned_weight,
  sum(case t.quadrant when 'Q1' then 40 when 'Q2' then 30 when 'Q3' then 20 else 10 end * t.completion / 100.0)::numeric as completed_weight,
  count(*) filter (where btrim(t.evidence) <> '')::int as evidence_count,
  count(*) filter (where t.status = 'Blocked' or btrim(t.blocker) <> '')::int as blocked_count,
  round(
    100.0 * sum(case t.quadrant when 'Q1' then 40 when 'Q2' then 30 when 'Q3' then 20 else 10 end * t.completion / 100.0)
    / nullif(sum(case t.quadrant when 'Q1' then 40 when 'Q2' then 30 when 'Q3' then 20 else 10 end), 0), 1
  ) as score
from public.staff_tasks t
where btrim(t.title) <> ''
group by t.user_id, t.task_date;

grant select on public.staff_daily_summary to authenticated;
