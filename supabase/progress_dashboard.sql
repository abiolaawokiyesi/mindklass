-- MindKlass progress dashboard: one-time Supabase setup.
-- Run this once in Supabase > SQL Editor (paste, press Run). It is safe to run again.
-- It lets administrators read EVERY learner's course progress (course_progress) and who they are
-- (profiles). Learners still see only their own rows. It does not change or delete any data.

-- Is the signed-in user an administrator? (same helper as supabase/staff_performance.sql)
create or replace function public.mk_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin');
$$;

-- Learners read their own progress; administrators read all of it.
alter table public.course_progress enable row level security;

drop policy if exists "course_progress admin read" on public.course_progress;
create policy "course_progress admin read" on public.course_progress
  for select to authenticated using (public.mk_is_admin());

drop policy if exists "course_progress own read" on public.course_progress;
create policy "course_progress own read" on public.course_progress
  for select to authenticated using (user_id = auth.uid());

-- Note: if course_progress already had its own policies, these are added alongside them
-- (Postgres combines permissive policies with OR), so nothing that worked before stops working.
-- The dashboard also needs administrators to read profiles (name, nick); the Users page already does.
