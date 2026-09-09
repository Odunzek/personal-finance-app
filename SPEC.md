# SPEC — Personal Finance Tracker

## Purpose
Personal, multi-profile finance tracker for manually logging income/expenses. Synced across the owner's own devices. Not distributed on any app store — installed directly on the owner's own devices; the web build is reachable only by the owner unless shared deliberately later.

## Devices (v1)
- **Phone** (Android) — native Flutter app
- **Tablet** — Samsung Galaxy Tab S10 FE (Android) — same native Flutter app as phone
- **Laptop** — Flutter web build, opened in a browser, nothing installed

iOS is not needed now but is a future option without a rewrite, since Flutter shares one codebase across platforms — it only requires access to a Mac/Xcode when that day comes.

## Platform & Backend
- **Flutter (Dart)** — single codebase across Android, web, and (later, if wanted) iOS/desktop
- **Supabase** (Postgres + Auth + Realtime) as the backend — a managed service, not self-hosted, so there is no server to build or maintain
- **Security model: end-to-end encryption.** Financial data is encrypted on-device before it is ever sent to Supabase. Supabase stores and syncs only ciphertext — it never holds readable financial data. Cross-device key handling (so phone/tablet/laptop can all decrypt the same data) is a deferred design detail, to be solved during the sync/security implementation phase — not blocking earlier feature work.
- **Auth**: Supabase Auth gates the app. This also means the data model is already multi-user-capable (each row scoped to the authenticated user) at effectively no extra cost, even though only the owner uses it today.
- **App-level lock**: in addition to the Supabase account login, the phone/tablet apps also get a local PIN/biometric lock, matching the original "protect this if my device is picked up" requirement.
- Manual transaction entry only — no bank account integration.
- No AI features in v1 (deferred).

## Core entities
- **Profile**: id, ownerUserId, displayName, currencyCode (default CAD), createdAt
- **Category**: id, profileId, name, type (income/expense), colorArgb, iconKey, isActive (soft-delete — never hard-deleted once referenced), parentCategoryId (nullable, reserved for future subcategories), sortOrder
- **Transaction**: id, profileId, categoryId, amountMinorUnits (integer cents, never float), type (income/expense, denormalized from category so edits never rewrite history), occurredAt, note, createdAt, updatedAt

## v1 Feature checklist
1. **Auth**: sign up / log in (Supabase Auth), same account usable from phone, tablet, and laptop web
2. **Onboarding**: create first profile, choose currency (default CAD)
3. **Profiles**: create / rename / switch / delete, each with fully separate data
4. **Quick-add transaction**: amount, income/expense, category, date (defaults today), optional note
5. **Transaction history**: list, filter by date range/category/type, search
6. **Categories**: user-created/renamed/recolored/deactivated, per profile
7. **Trends/reports**: monthly summary, category breakdown chart, spending-over-time chart
8. **Sync**: the same data available and editable from phone, tablet, and laptop web, via Supabase
9. **Settings**: account management, PIN/biometric management (mobile), theme, about
10. **App-level PIN/biometric lock** on the mobile apps

## Explicitly deferred (v2+)
- Recurring/scheduled transactions
- Budgets with alerts
- Receipt photo attachments
- Home-screen quick-add widget
- AI-based insights/analysis
- Multi-currency per transaction
- Full cross-device encryption key exchange UX (v1 ships with a working interim approach; hardened later)
- Native iOS build (code stays iOS-ready; the build step itself waits for Mac/Xcode access)

## Architecture requirement
Every deferred feature above must be addable as new tables/screens referencing existing rows by ID, without modifying or destructively migrating v1 data — same principle applied throughout this spec's entity design.
