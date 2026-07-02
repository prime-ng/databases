# Strategic Bets — The Bigger Investments

> Filtered from `ENHANCEMENT_BACKLOG.md`: **Effort ≥ 4**. These are multi-week initiatives that change Prime's market position rather than patch a screen. Sequenced with rationale.
> ⚠️ Recommendations only.

---

## Bet 1 — Internationalization + RTL (ENH-011, ENH-010, ENH-033) · Effort 5
**What:** Introduce an i18n layer across all three apps; externalize hardcoded English; localize currency/date; wire RTL (the web `adminlte.rtl.css` already ships, just unlinked).
**Why it's strategic:** The product literally cannot be sold outside English-speaking India today. i18n + RTL opens Gulf/MENA and international markets — and **most regional competitors also lack it**, so it's a differentiator, not just catch-up.
**Sequence:** Link `rtl.css` + `dir` toggle (Phase 0 quick win) → i18n scaffolding + high-traffic screens (Phase 4) → full string coverage + locale formatting.
**Risk if skipped:** Permanent regional ceiling; "international-grade" claim stays false.

## Bet 2 — Retire the legacy portal theme (ENH-018) · Effort 5
**What:** Migrate the Student/Parent **web portals** off the "Smart University"/Metronic stack (old bundled Bootstrap, Poppins, FA v4+v6, Material Design Lite, Feather) onto the modern AdminLTE v4 + design-system layer.
**Why:** This is the single largest *visual* inconsistency — two product eras in one app. It also removes a whole legacy Bootstrap generation and two icon families.
**Sequence:** After the design system + component unification (Phases 1–2) exist to migrate onto.
**Risk if skipped:** Parents/students (the most brand-facing audience) keep seeing a 2016-era UI.

## Bet 3 — Personalized, priority-driven dashboards (ENH-023) · Effort 4
**What:** Replace equal-weight stat grids with: greeting + "what needs you today" priority feed + 3–4 key stats + secondary widgets. Per role (admin, teacher, student, parent).
**Why:** This is the #1 "premium SaaS vs. ERP" tell. It's what Toddle/Teachmint do that makes them feel personal.
**Dependency:** Needs the unified stat-card + real data wiring (ENH-005, ENH-012) first.

## Bet 4 — Mobile list architecture (ENH-014) · Effort 4
**What:** Migrate all mobile lists from `ScrollView.map` to `FlatList`/`FlashList` with a shared list-row, empty, and load-more pattern.
**Why:** Current lists mount every row — a scaling cliff for any school with large datasets. Foundational for perceived performance.
**Sequence:** Pairs with the shared list-row component (Phase 2).

## Bet 5 — Web performance re-architecture (ENH-020, ENH-003) · Effort 4
**What:** Move page-specific chart/plugin JS out of the 1747-line global `footer-scripts` into per-page bundles; load FullCalendar/ApexCharts/jsvectormap/sortablejs only where used; de-duplicate sortablejs.
**Why:** Every backend page currently downloads and executes the whole plugin suite and throws chart errors. Big perceived-speed and stability win.

## Bet 6 — Illustration + onboarding language (ENH-034, ENH-035) · Effort 4
**What:** A branded, culturally-neutral illustration set for empty/first-run states + coach-marks for the drawer and child-switcher.
**Why:** Turns blank screens into guidance and gives Prime a personality beyond "P-in-a-circle." Lower urgency, high polish payoff.

## Bet 7 — Motion language (mobile) (ENH-036) · Effort 4
**What:** A purposeful, restrained motion system on mobile (Reanimated is installed but unused). Shared-element transitions, list animations, gesture sheets.
**Why:** Motion is the cheapest signal of "premium." Do it after structure/consistency are solid so it enhances rather than masks.

## Bet 8 — Offline / low-bandwidth resilience (ENH-040) · Effort 5
**What:** Mobile caching, optimistic UI, retry/queue for poor connectivity.
**Why:** Indian K-12 context often means patchy networks; resilience is a real-world retention lever. Largest effort; schedule last.

---

## Sequencing view

```
Phase 1 (foundations)   → (enables) Bet 5 web perf
Phase 2 (components)    → (enables) Bet 4 lists, Bet 2 portal retirement
Phase 3 (flagship)      → Bet 3 dashboards, Bet 6 onboarding
Phase 4 (reach/polish)  → Bet 1 i18n/RTL, Bet 7 motion, Bet 8 offline
```

**Rule:** don't start a strategic bet before its foundation phase is done — e.g. personalized dashboards (Bet 3) need the unified stat-card and real data first, or they just re-skin mock tiles. Each bet is individually shippable and independently valuable, so they can be prioritized against business goals (international expansion → Bet 1 first; brand-facing polish → Bet 2 first).
