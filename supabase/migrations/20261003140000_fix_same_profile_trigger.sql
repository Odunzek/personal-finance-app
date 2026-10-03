-- Repairs 20261002151500, which blocked every insert into `transactions`.
--
-- That migration used ONE trigger function for both `transactions` and
-- `recurring_rules`, naming new.transfer_account_id (transactions only) and
-- new.to_account_id (recurring_rules only) in the same body, each behind a
-- tg_table_name guard. PL/pgSQL resolves record fields when it evaluates an
-- expression, not when it compiles the function, and it evaluates the whole
-- boolean at once -- so the tg_table_name guard never protected the field
-- reference. Every transaction insert failed with
--   42703: record "new" has no field "to_account_id"
-- which is to say: no transaction could be recorded at all.
--
-- Split into one function per table, so each only ever names columns that
-- exist on the table it is attached to.
--
-- Both are SECURITY DEFINER: the lookup must see the referenced row to
-- compare its profile, and under the caller's RLS a hidden row would read
-- back as NULL and be reported as a cross-profile reference -- turning any
-- visibility edge case into a rejected write. They only ever read profile_id
-- and return nothing, so they expose no data.

drop trigger if exists transactions_same_profile_refs on public.transactions;
drop trigger if exists recurring_rules_same_profile_refs on public.recurring_rules;
drop function if exists public.enforce_same_profile_refs();

create function public.enforce_transaction_profile_refs()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  ref_profile bigint;
begin
  select profile_id into ref_profile
    from public.accounts where id = new.account_id;
  if ref_profile is distinct from new.profile_id then
    raise exception 'account % does not belong to profile %',
      new.account_id, new.profile_id;
  end if;

  if new.category_id is not null then
    select profile_id into ref_profile
      from public.categories where id = new.category_id;
    if ref_profile is distinct from new.profile_id then
      raise exception 'category % does not belong to profile %',
        new.category_id, new.profile_id;
    end if;
  end if;

  if new.transfer_account_id is not null then
    select profile_id into ref_profile
      from public.accounts where id = new.transfer_account_id;
    if ref_profile is distinct from new.profile_id then
      raise exception 'transfer account % does not belong to profile %',
        new.transfer_account_id, new.profile_id;
    end if;
  end if;

  return new;
end;
$$;

create function public.enforce_recurring_rule_profile_refs()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  ref_profile bigint;
begin
  select profile_id into ref_profile
    from public.accounts where id = new.account_id;
  if ref_profile is distinct from new.profile_id then
    raise exception 'account % does not belong to profile %',
      new.account_id, new.profile_id;
  end if;

  if new.category_id is not null then
    select profile_id into ref_profile
      from public.categories where id = new.category_id;
    if ref_profile is distinct from new.profile_id then
      raise exception 'category % does not belong to profile %',
        new.category_id, new.profile_id;
    end if;
  end if;

  if new.to_account_id is not null then
    select profile_id into ref_profile
      from public.accounts where id = new.to_account_id;
    if ref_profile is distinct from new.profile_id then
      raise exception 'destination account % does not belong to profile %',
        new.to_account_id, new.profile_id;
    end if;
  end if;

  return new;
end;
$$;

create trigger transactions_same_profile_refs
  before insert or update of
    account_id, transfer_account_id, category_id, profile_id
  on public.transactions
  for each row execute function public.enforce_transaction_profile_refs();

create trigger recurring_rules_same_profile_refs
  before insert or update of
    account_id, to_account_id, category_id, profile_id
  on public.recurring_rules
  for each row execute function public.enforce_recurring_rule_profile_refs();
