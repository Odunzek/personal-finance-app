# CLAUDE.md — FINANCE_APP

Personal, multi-device finance tracker. See `SPEC.md` for the full functional spec and v1 checklist — keep it in sync with reality as decisions evolve.

## Tech Stack
- Flutter (Dart) — single codebase for Android now; web (laptop) and iOS/desktop are future targets from the same code, not a rewrite
- Supabase (Postgres + Auth + Realtime) as the backend — managed service, no self-hosted server
- State/data layer: repository pattern wrapping Supabase client calls, so UI never talks to Supabase directly

## Architecture
- Package-by-feature (e.g. `lib/features/transactions`, `lib/features/categories`, `lib/features/profiles`, `lib/features/trends`, `lib/features/auth`, `lib/features/settings`), with shared code in `lib/core` (theme, encryption, Supabase client wrapper, models)
- New (v2+) features must attach via new tables/screens referencing existing rows by ID — never by modifying existing tables or destructively migrating data
- Money stored as integer minor units (cents), never floating point
- Dates stored as UTC, rendered in local time at the UI layer only
- Categories and profiles are soft-deletable (`isActive`) if referenced by transactions — never hard-deleted

## Security
- Financial data is encrypted client-side before it is sent to Supabase — Supabase only ever stores/syncs ciphertext, never readable financial data
- Supabase Auth gates account access; a local PIN/biometric lock additionally gates the mobile apps themselves
- No hardcoded secrets; Supabase keys/config loaded from environment, never committed

## Testing
- Business logic (repositories, view models) is unit-tested with Dart's standard `test`/`flutter_test` packages
- Critical flows (auth, quick-add, sync) get widget/integration tests
- No feature is done until its tests pass

## Conventions
- No comments unless the WHY is non-obvious
- No speculative abstractions beyond what the current feature needs
- Functional/composable-first Flutter widget code, minimal unnecessary state
