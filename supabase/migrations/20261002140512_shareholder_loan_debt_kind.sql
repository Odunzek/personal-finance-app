-- Add "shareholder_loan" as a debt kind — money moving between an
-- incorporated profile and its owner (contributions/draws), tracked the
-- same way as any other liability account via the existing transfer
-- mechanism. CRA treats shareholder loan balances specially (a balance
-- owed BY the corporation TO the shareholder is routine; the reverse can
-- become taxable income if not repaid in time), so it gets its own label
-- rather than being lumped into "other debt".

alter table public.accounts drop constraint accounts_debt_kind_check;
alter table public.accounts add constraint accounts_debt_kind_check
  check (debt_kind in ('credit_card', 'loan', 'bnpl', 'shareholder_loan', 'other'));
