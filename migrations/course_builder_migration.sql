-- ============================================================================
-- MindKlass Course Builder — Supabase migration
-- ============================================================================
-- Run this once in Supabase Dashboard -> SQL Editor -> New query -> Run.
-- It creates the "courses" table that the new admin "Course Builder" page
-- reads from and writes to, and locks it down with the same Row Level
-- Security pattern as every other MindKlass table:
--   - admins can create, read, update and delete every course (draft or published)
--   - everyone else (logged-in students/teachers/parents) can only read courses
--     that are marked "published"
-- Safe to run more than once — every statement below is idempotent.
-- ============================================================================

create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  system text not null check (system in ('trainings','sjourneys')),
  code text not null,
  cat text not null,
  subject text not null,
  group_name text,
  year text,
  term int,
  term_label text,
  title text not null,
  tagline text,
  duration_label text,
  weeks int,
  months text,
  pass_mark int not null default 75,
  total_questions int not null default 100,
  exam_mins int not null default 60,
  units jsonb not null default '[]'::jsonb,
  questions jsonb not null default '[]'::jsonb,
  status text not null default 'draft' check (status in ('draft','published')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Keep updated_at current on every edit.
create or replace function public.courses_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_courses_updated_at on public.courses;
create trigger trg_courses_updated_at
  before update on public.courses
  for each row execute function public.courses_set_updated_at();

alter table public.courses enable row level security;

drop policy if exists "admins manage all courses" on public.courses;
create policy "admins manage all courses" on public.courses
  for all
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

drop policy if exists "everyone reads published courses" on public.courses;
create policy "everyone reads published courses" on public.courses
  for select
  using (status = 'published' and auth.uid() is not null);

-- ============================================================================
-- That's it. Once this has run, open the app as an admin, go to the new
-- "Course Builder" tab in the sidebar, and start creating courses. A course
-- only shows up for teachers/students once you hit "Save & Publish" on it.
-- ============================================================================
