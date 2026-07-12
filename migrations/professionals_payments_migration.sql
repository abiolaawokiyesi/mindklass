-- ============================================================================
-- MindKlass — Other Professionals & Course Payments migration
-- ============================================================================
-- Run this once in Supabase Dashboard -> SQL Editor -> New query -> Run.
-- Safe to run more than once — every statement below is idempotent.
--
-- What this changes:
--   1) Adds profiles.profession, so the new "Other Professional" registration
--      role (accountant, lawyer, and ~48 more) can store which profession the
--      person picked. Extends the existing country/currency backfill trigger
--      so profession is also filled in from signup metadata for accounts that
--      require email confirmation before their first session (mirrors exactly
--      how country/currency are already backfilled).
--   2) Adds price_usd, payment_link and payment_provider to public.courses,
--      so an admin building a course in Course Builder can attach a Selar (or
--      Paystack / Flutterwave / Stripe / other) checkout link and a price.
--      The app shows a "Get This Course" card with a Pay Now button once
--      price_usd > 0 and payment_link is set; it does not gate access by
--      itself — the admin still approves the application after verifying
--      payment, exactly like every other course today.
-- ============================================================================

-- ── 1) Profession column on profiles ─────────────────────────────────────────
alter table public.profiles add column if not exists profession text;

-- Re-create the backfill trigger function to also cover profession, keeping
-- everything else it already does (country/currency) unchanged.
create or replace function public.backfill_profile_country_currency()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  meta jsonb;
begin
  select raw_user_meta_data into meta from auth.users where id = new.id;
  if meta is not null then
    if (new.country is null or new.country = '') and (meta->>'country') is not null then
      new.country := meta->>'country';
    end if;
    if (new.currency is null or new.currency = 'USD') and (meta->>'currency') is not null then
      new.currency := meta->>'currency';
    end if;
    if (new.profession is null or new.profession = '') and (meta->>'profession') is not null then
      new.profession := meta->>'profession';
    end if;
  end if;
  return new;
end;
$$;

-- Trigger already exists (created by currency_referral_migration.sql) and
-- fires "before insert" on profiles — no need to re-create it, just replacing
-- the function above is enough. Included here again so this file also works
-- standalone on a fresh database.
drop trigger if exists trg_backfill_profile_currency on public.profiles;
create trigger trg_backfill_profile_currency
  before insert on public.profiles
  for each row execute function public.backfill_profile_country_currency();

-- ── 2) Pricing / payment-link columns on courses ─────────────────────────────
alter table public.courses add column if not exists price_usd numeric not null default 0;
alter table public.courses add column if not exists payment_link text;
alter table public.courses add column if not exists payment_provider text;

-- ============================================================================
-- That's it. "Other Professional" signups now save their profession, and
-- Course Builder's Pricing & Payment section (price, provider, payment link)
-- is now persisted per course and shown to learners as a "Get This Course"
-- card before they apply.
-- ============================================================================
