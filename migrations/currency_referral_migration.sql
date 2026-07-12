-- ============================================================================
-- MindKlass — Currency & One-Off Referral Commission migration
-- ============================================================================
-- Run this once in Supabase Dashboard -> SQL Editor -> New query -> Run.
-- Safe to run more than once — every statement below is idempotent.
--
-- What this changes:
--   1) Everyone picks their COUNTRY when they register (already wired up in
--      the app) and that sets a CURRENCY used to *display* money to them —
--      referral earnings, fees, everything. Adds profiles.country/currency.
--   2) The referral programme becomes a ONE-OFF 10% commission, credited
--      once when the referred person's first payment clears — replacing the
--      old "10% every month for 12 months" model. Adds status tracking
--      (pending -> credited -> paid) to the referrals table.
--   3) Referrers can save payout account details (bank transfer or mobile
--      money) so admin knows where to send their monthly payout. Adds
--      payout_* columns to profiles.
--   4) Two new triggers make the one-off crediting automatic:
--        - When someone signs up with a referral code, a "pending" referral
--          row is created for their referrer.
--        - When that referred person's first fee is marked "paid", the
--          pending row is credited with 10% of that payment, once.
--   5) Admin gets a "Referral Payouts Due" panel (Fees & Billing tab) to see
--      who's owed money, their payout details, and mark them paid monthly.
-- ============================================================================

-- ── 1) Currency + payout columns on profiles ────────────────────────────────
alter table public.profiles add column if not exists country text;
alter table public.profiles add column if not exists currency text not null default 'USD';
alter table public.profiles add column if not exists payout_method text; -- 'bank' | 'mobile_money'
alter table public.profiles add column if not exists payout_bank_name text;
alter table public.profiles add column if not exists payout_account_number text;
alter table public.profiles add column if not exists payout_account_name text;
alter table public.profiles add column if not exists payout_mobile_provider text;
alter table public.profiles add column if not exists payout_mobile_number text;

-- Let users update their own row (needed for the Refer & Earn payout-details
-- form, the profile Country field, and any future self-service edits).
drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile" on public.profiles
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- security-definer helper so an "admins can read every profile" policy on
-- profiles doesn't recurse into itself checking the very table it's on.
create or replace function public.is_admin()
returns boolean language sql security definer stable set search_path = public as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

drop policy if exists "admins read all profiles" on public.profiles;
create policy "admins read all profiles" on public.profiles
  for select
  using (auth.uid() = id or public.is_admin());

-- ── 2) One-off referral commission tracking on referrals ────────────────────
alter table public.referrals add column if not exists status text not null default 'pending';
alter table public.referrals add column if not exists amount_usd numeric not null default 0;
alter table public.referrals add column if not exists credited_at timestamptz;
alter table public.referrals add column if not exists paid_at timestamptz;

do $$ begin
  alter table public.referrals add constraint referrals_status_check
    check (status in ('pending','credited','paid'));
exception when duplicate_object then null;
end $$;

-- One referral row per referred person — needed for the ON CONFLICT below.
do $$ begin
  alter table public.referrals add constraint referrals_referred_id_key unique (referred_id);
exception when duplicate_object then null;
end $$;

-- Admins can see and update every referral (to inspect + mark payouts paid);
-- referrers can already see their own rows via whatever policy exists today,
-- this just adds admin visibility on top of it.
drop policy if exists "admins manage all referrals" on public.referrals;
create policy "admins manage all referrals" on public.referrals
  for all
  using (public.is_admin())
  with check (public.is_admin());

-- ── 3) Backfill country/currency from signup metadata ───────────────────────
-- Covers the case where email confirmation is required: at that point there's
-- no session yet to call supabase.from("profiles").update(...) from the app,
-- so this trigger picks the values straight off the auth.users row instead.
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
  end if;
  return new;
end;
$$;

drop trigger if exists trg_backfill_profile_currency on public.profiles;
create trigger trg_backfill_profile_currency
  before insert on public.profiles
  for each row execute function public.backfill_profile_country_currency();

-- ── 4) Create a pending referral row when someone signs up with a code ─────
create or replace function public.create_pending_referral()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.referred_by is not null then
    insert into public.referrals (referrer_id, referred_id, date, status, amount_usd)
    values (new.referred_by, new.id, current_date, 'pending', 0)
    on conflict (referred_id) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_create_pending_referral on public.profiles;
create trigger trg_create_pending_referral
  after insert on public.profiles
  for each row execute function public.create_pending_referral();

-- ── 5) Credit the one-off 10% commission on the referred person's first
--      paid fee — covers "all courses" since it fires off whatever fee/course
--      payment happens to clear first, regardless of which course it's for.
create or replace function public.credit_referral_on_payment()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  pending_ref public.referrals%rowtype;
begin
  if new.status = 'paid' and (old.status is distinct from 'paid') then
    select * into pending_ref from public.referrals
      where referred_id = new.student_id and status = 'pending'
      limit 1;
    if found then
      update public.referrals
        set status = 'credited', amount_usd = round(new.amount * 0.10, 2), credited_at = now()
        where id = pending_ref.id;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_credit_referral_on_payment on public.fees;
create trigger trg_credit_referral_on_payment
  after update on public.fees
  for each row execute function public.credit_referral_on_payment();

-- ============================================================================
-- That's it. New signups now choose a country (currency) and, if referred,
-- get a "pending" referral row automatically. The first fee/course payment
-- they complete credits their referrer a one-off 10% — visible immediately
-- on the referrer's Refer & Earn page. Admin runs "Fees & Billing" once a
-- month, pays out everyone listed under "Referral Payouts Due" via their
-- saved bank/mobile-money details, then clicks "Mark Paid" for each.
-- ============================================================================
