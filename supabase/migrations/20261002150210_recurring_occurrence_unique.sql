-- A rule may only ever create one transaction per due date. The runner now
-- advances next_due_date after every insert, which handles crashes on one
-- device; this index is the backstop for two devices catching up the same
-- rule concurrently. NULL recurring_rule_id rows (manual transactions) are
-- never constrained, since NULLs are distinct in a unique index.
--
-- Clean up any duplicates that the old batch-advance behavior may already
-- have produced (keep the earliest row of each pair) before adding it.

delete from public.transactions t
using public.transactions keep
where t.recurring_rule_id is not null
  and t.recurring_rule_id = keep.recurring_rule_id
  and t.occurred_at = keep.occurred_at
  and t.id > keep.id;

create unique index transactions_rule_occurrence_key
  on public.transactions (recurring_rule_id, occurred_at)
  where recurring_rule_id is not null;
