-- ============================================================================
-- Admin "Users" dashboard fix
-- ============================================================================
-- WHY THIS IS NEEDED:
-- The admin "Users" tab in the app only ever showed accounts that had been
-- seen locally in the admin's own browser session (people who logged in, or
-- signed up, in that same tab) — it never actually asked the database for the
-- full list of registered accounts. That's why a new signup from someone
-- else's device never showed up for the admin: the app simply never looked.
--
-- The app-side fix (already applied in MindKlass.jsx) now fetches every row
-- from public.profiles for the admin dashboard. But profiles has never stored
-- a user's email address (email normally only lives in Supabase's private
-- auth.users table, which the app can only read for whoever is currently
-- logged in) — so this migration adds an email column to profiles and keeps
-- it filled in automatically, the same way country/currency already are.
-- ============================================================================

-- 1) Add the column.
alter table public.profiles add column if not exists email text;

-- 2) Extend the existing signup backfill trigger to also copy email across.
--    (This is the same trigger that already backfills country/currency from
--    auth.users at signup time — see currency_referral_migration.sql.)
create or replace function public.backfill_profile_country_currency()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  meta jsonb;
  auth_email text;
begin
  select raw_user_meta_data, email into meta, auth_email from auth.users where id = new.id;
  if meta is not null then
    if (new.country is null or new.country = '') and (meta->>'country') is not null then
      new.country := meta->>'country';
    end if;
    if (new.currency is null or new.currency = 'USD') and (meta->>'currency') is not null then
      new.currency := meta->>'currency';
    end if;
  end if;
  if (new.email is null or new.email = '') and auth_email is not null then
    new.email := auth_email;
  end if;
  return new;
end;
$$;
-- (trigger itself already exists and points at this function, so no need to
-- re-create trg_backfill_profile_currency — updating the function is enough.)

-- 3) One-off backfill: fill in email for every profile that already exists
--    today (this is what makes your existing accounts show up correctly the
--    first time you load the fixed admin dashboard, instead of only new
--    signups going forward).
update public.profiles p
set email = u.email
from auth.users u
where p.id = u.id and (p.email is null or p.email = '');
