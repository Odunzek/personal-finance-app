# DESIGN — Visual language (from design-handoff mockup)

Source: `design-handoff/` (Claude Design canvas export). The mockup describes a different product (shared household finance app with bank-account linking and transaction splitting) than this app — see `SPEC.md`. **Only the visual style is adopted; the household/bank-linking/splitting mechanics are not.**

## Brand

**Name: Kinscope.** A full brand identity (logo mark, wordmark, lockups, app icon set at 32/64/180/192/512px) was supplied in the design handoff — see `design-handoff-v2/mobile-finance-app-design/project/brand/`. Pending confirmation with the user on whether to adopt this name/logo for the real app (currently still titled generically "Finance App" in code).

**Logo usage rules** (from the brand sheet):
- Clear space equal to 1/3 of the mark's height on every side
- Minimum sizes: mark 24px, horizontal lockup 120px wide, stacked lockup 80px wide
- Never stretch, rotate, recolor the teal, or place the full-color mark on a teal or dark background (use the light/mono variant on dark)
- Icon files are the mark centered with 10% padding (survives OS rounded-corner masking)

## Design tokens

**Fonts** (Google Fonts): `IBM Plex Sans` (Regular/Medium/Semibold — all UI text, labels, body copy), `Bricolage Grotesque` (Semibold — every numeric figure/amount in the product, tabular numerals on)

**Light theme**
- Background: `#FAF7F0` ("Paper"), Card: `#FFFFFF`, Bar: `#FFFFFF`
- Line/border: `#E5E0D5`, Track (progress bg): `#EAE5DA`, Chip: `#F0EDE4`
- Ink (primary text): `#131E1D`, Muted: `#5C6A65`, Muted 2: `#5A6863`
- Accent text/links (teal deep — teal itself is too light for text on paper): `#2C6E79`
- Positive/income: `#1F6B4F`, Over-budget/negative: `#A93B1F`, Warning text: `#8A5A16`
- Debt-payoff card background/border: `#EDF5F6` / `#C6DFE3`

**Dark theme**
- Background: `#0F1A1C`, Card: `#162426`, Bar: `#132022`
- Line/border: `#233436`, Track: `#1E2E30`, Chip: `#1C2C2E`
- Ink: `#EEF3F1`, Muted: `#8DA39E`, Muted 2: `#7A8F8A`
- Accent text/links: `#7FC3CC`
- Positive/income: `#59BE93`, Over-budget/negative: `#E0765A`, Warning text: `#D9A63A`
- Debt-payoff card background/border: `#122B2A` / `#1F4645`

**Accent/semantic colors (theme-independent)**
- Primary accent (teal, shapes/fills only — not text on paper): `#5CA2AC`, hover: `#14BDBD`
- On-accent text: `#04201F`
- Budget warning tier (70-99% spent) fill: `#C98A16`

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
