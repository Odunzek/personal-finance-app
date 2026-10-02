-- RLS guarantees every row belongs to a profile the user owns, but nothing
-- stopped a transaction or recurring rule in profile A from pointing at an
-- account/category in profile B (both owned by the same user). That would
-- corrupt per-profile balances and reports. These triggers make the database
-- reject any such cross-profile reference.
--
-- Done as triggers rather than composite FKs because composite FKs would
-- require new unique indexes on (id, profile_id) plus rewriting every
-- existing FK — triggers are additive, per the no-destructive-migrations rule.

create or replace function public.enforce_same_profile_refs()
returns trigger
language plpgsql
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

  if tg_table_name = 'transactions' and new.transfer_account_id is not null then
    select profile_id into ref_profile
      from public.accounts where id = new.transfer_account_id;
    if ref_profile is distinct from new.profile_id then
      raise exception 'transfer account % does not belong to profile %',
        new.transfer_account_id, new.profile_id;
    end if;
  end if;

  if tg_table_name = 'recurring_rules' and new.to_account_id is not null then
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
  before insert or update of account_id, transfer_account_id, category_id, profile_id
  on public.transactions
  for each row execute function public.enforce_same_profile_refs();

create trigger recurring_rules_same_profile_refs
  before insert or update of account_id, to_account_id, category_id, profile_id
  on public.recurring_rules
  for each row execute function public.enforce_same_profile_refs();

-- A transfer that moves money from an account to itself is meaningless and
-- would silently net to zero; `not valid` so any pre-existing row is left
-- alone while all new writes are checked.
alter table public.transactions
  add constraint transactions_transfer_distinct_chk
  check (transfer_account_id is null or transfer_account_id <> account_id)
  not valid;

alter table public.recurring_rules
  add constraint recurring_rules_transfer_distinct_chk
  check (to_account_id is null or to_account_id <> account_id)
  not valid;
