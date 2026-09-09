# DESIGN — Visual language (from design-handoff mockup)

Source: `design-handoff/` (Claude Design canvas export). The mockup describes a different product (shared household finance app with bank-account linking and transaction splitting) than this app — see `SPEC.md`. **Only the visual style is adopted; the household/bank-linking/splitting mechanics are not.**

## Design tokens

**Fonts** (Google Fonts): `IBM Plex Sans` (body/UI text), `Bricolage Grotesque` (large numeric displays — balances, amounts)

**Light theme**
- Background: `#FAF7F0`, Card: `#FFFFFF`, Bar: `#FFFFFF`
- Line/border: `#E5E0D5`, Track (progress bg): `#EAE5DA`, Chip: `#F0EDE4`
- Ink (primary text): `#12211F`, Muted text: `#66756F`, Muted text 2: `#98A6A1`

**Dark theme**
- Background: `#0F1A1C`, Card: `#162426`, Bar: `#132022`
- Line/border: `#233436`, Track: `#1E2E30`, Chip: `#1C2C2E`
- Ink: `#EEF3F1`, Muted: `#8DA39E`, Muted 2: `#5F7370`

**Accent/semantic colors**
- Primary accent (teal): `#0FA3A3`, hover: `#14BDBD`
- On-accent text: `#04201F`
- Positive/income green: `#2F8F6B`
- Warning/amber (budget 70-99%): `#C98A16`

**Shape/spacing conventions**
- Cards: 14-16px border radius, 1px border in `line` color
- Chips/pills: 20px border radius (fully rounded)
- Buttons (primary): 14px radius, 16px padding
- Progress bars: 4-5px height, fully rounded track + fill

## Screen mapping (mockup → our actual v1/v2 scope)

| Mockup screen | Maps to | Notes |
|---|---|---|
| "Add expense" (numeric keypad, category chips) | Quick-add transaction (v1) | Reuse layout; drop the "From [account]" account-switcher since we have no bank accounts |
| "Activity" (day-grouped list, filter chips) | Transaction history (v1) | Reuse layout; filters become date-range/category/type instead of per-bank-account |
| Transaction detail + "Recategorize" | Transaction detail/edit (v1) | Reuse; drop the "Split"/"Settle" section entirely |
| "Insights" (6-month bar chart + category list) | Trends/reports (v1) | Reuse directly, this is a near 1:1 match |
| "Budgets" + budget edit (progress bars, +/- limit) | Budgeting (v2) | Reuse when v2 is built |
| "Goals" + debt payoff card | Debt tracking (v2) | Reuse when v2 is built; savings-goals concept is new — flag to user if wanted, not currently in spec |
| Settings (appearance toggle) | Settings (v1) | Reuse the dark/light toggle pattern; drop "Household" member section entirely |
| Bottom nav (Home, Activity, Budgets, Goals, More) | Nav (v1: Home, Activity, Trends, Settings + a floating quick-add button) | Add Budgets/Goals tabs later when v2 ships, not before |

## Explicitly dropped (household/bank-linking product, not this app)
Welcome/"set up my household" onboarding, "Link your accounts" flow, multiple named bank accounts (Chequing/Savings/Business), household member management + invites, transaction splitting/settling between people.
