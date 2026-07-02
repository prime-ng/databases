# Roadmap to 10/10 — Prime Ecosystem UI/UX

> A phased plan from the current **5.2** baseline to a **9–10** international-grade experience. Each phase lists its backlog IDs, the score it targets, and its exit criteria. Timelines are indicative (assume ~1–2 UI engineers across the three apps).
> ⚠️ Recommendations only — no app code has been changed.

---

## Trajectory

| Phase | Theme | Weeks | Score target |
|-------|-------|:-----:|:---:|
| 0 | Quick wins | 1 | 5.2 → 6.0 |
| 1 | Foundations | 2–4 | → 6.8 |
| 2 | Component unification | 4–8 | → 7.6 |
| 3 | Flagship screens | 8–12 | → 8.5 |
| 4 | Reach & polish | 12–16 | → 9–10 |

---

## Phase 0 — Quick Wins (Week 1) → 6.0
**Backlog:** ENH-001, 002, 003, 006, 008, 009, 010, 026, 027, 028, 032 + the two one-line fixes.
**Focus:** Accessibility attributes, focus ring, contrast, stop-the-errors, kill dead/demo UI, RTL plumbing.
**Exit criteria:** Keyboard focus visible everywhere (web); shared mobile primitives have a11y labels; no console errors on backend pages; no dead links/demo strings shipped; `rtl.css` linked.
**Why first:** Highest RICE, lifts the worst dimension (a11y 1.7→~4), ~1 dev-week. See `QUICK_WINS.md`.

## Phase 1 — Foundations (Weeks 2–4) → 6.8
**Backlog:** ENH-021 (token-only color + lint), ENH-004 (dark-mode fix, depends on 021), ENH-013 (one web icon family), ENH-020 (per-page JS), plus adopting the design-system tokens + `prime-modern-ui.css` override layer.
**Focus:** Make the token system authoritative; fix dark mode; de-bloat web JS; converge iconography.
**Exit criteria:** No raw hex / `Colors.light` in mobile screens (lint-enforced); dark mode works on all STU screens; one icon family per platform; backend pages load only the JS they use.

## Phase 2 — Component Unification (Weeks 4–8) → 7.6
**Backlog:** ENH-012 (accent stat card), ENH-007 (token badge), ENH-017 (one toast/platform), ENH-019 (empty-state everywhere), ENH-025 (mobile `Sheet`), ENH-014 (FlatList), ENH-015/016 (table sticky/sort/bulk + card-stack), ENH-022 (modal focus mgmt), ENH-024 (skeletons), ENH-029 (inline validation).
**Focus:** One component per concept, across all surfaces (the design system is the reference).
**Exit criteria:** Single stat-card / badge / toast / empty-state / table language in use; mobile lists virtualized; skeletons replace blank loads; validation always inline.

## Phase 3 — Flagship Screens (Weeks 8–12) → 8.5
**Backlog:** ENH-005 (wire real data), ENH-023 (personalized dashboards), ENH-030 (stepped forms), ENH-018 (retire legacy portal theme), ENH-035 (onboarding), ENH-037 (brand pass).
**Focus:** Redesign the screens users see most; retire the legacy theme onto the modern system; add personality.
**Exit criteria:** All dashboards personal + real-data + priority-led; portals on the modern theme; first-run guidance present; real brand identity (no ColorlibHQ/SmartUniversity leftovers).

## Phase 4 — Reach & Polish (Weeks 12–16) → 9–10
**Backlog:** ENH-011 (i18n), ENH-033 (locale formatting), ENH-031 (Dynamic Type), ENH-036 (mobile motion), ENH-034 (illustration language), ENH-038 (print/PDF styles), ENH-039 (saved views), ENH-040 (offline resilience), full AA sign-off.
**Focus:** Internationalization, motion, illustration, and the last accessibility mile.
**Exit criteria:** App localizable + RTL-correct; AA green on every design-system component; motion language shipped; report-card/receipt print styles; offline-resilient mobile.

---

## Key Design Principles (guardrails for every phase)

1. **Accent, don't fill** — colored borders/icons/tints on light surfaces, never saturated tiles.
2. **One system, everywhere** — one token set, one icon family per platform, one component per concept.
3. **Status = color + icon + label.**
4. **Lead with the person** — dashboards greet, prioritize, act.
5. **Forgive and guide** — confirm destructive actions, validate inline, guide empty states.
6. **Accessible by default** — AA contrast, visible focus, ≥44px targets, labels.
7. **Localizable from day one** — externalized strings, locale formatting, RTL.
8. **No dead ends, no demo data** — if it's shown, it works.

---

## Measuring Progress

Re-run the 25-dimension scorecard (`../01_AUDIT/SCORECARD.md`) at the end of each phase. Success = the four red dimensions (Accessibility, i18n/RTL, Empty-state art, Onboarding) all reach ≥7, and no dimension regresses. The foundations (visual, layout, hierarchy, nav) are already ≥6.7 — protect them.

## Immediate Next Steps
1. Ratify the 5.2 baseline with the team.
2. Approve Phase 0 (`QUICK_WINS.md`) — one dev-week, biggest lift.
3. Adopt `../03_DESIGN_SYSTEM/prime-design-system/` as the reference; implement per its `AI_IMPLEMENTATION_GUIDE.md`.
4. Assign owners for the two red dimensions (accessibility, i18n).
5. Re-audit after Phase 1.
