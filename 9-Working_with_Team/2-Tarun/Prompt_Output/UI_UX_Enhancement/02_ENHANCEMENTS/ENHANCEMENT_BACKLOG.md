# Enhancement Backlog — Prime Ecosystem UI/UX

> Every issue from the audit converted into a scored, prioritized, buildable recommendation. **Recommendations only — nothing here has been applied to the apps.**
> **Scoring:** Impact 1–5 (user/business value) · Effort 1–5 (1 = hours, 5 = multi-week) · Reach = approx % of screens/users touched · **RICE** = (Reach × Impact) ÷ Effort (higher = do sooner) · Priority P0 (critical) → P3 (nice-to-have) · Type = Quick win / Standard / Strategic.
> Apps: WEB = prime_ai · ADM = mobile_school · STU = mobile_student · ALL = all three.

---

## Summary

| Priority | Count | | Type | Count | | By app | Count |
|:--------:|:-----:|---|------|:-----:|---|--------|:-----:|
| P0 | 9 | | Quick win | 14 | | WEB | 15 |
| P1 | 13 | | Standard | 18 | | Mobile (ADM/STU) | 18 |
| P2 | 11 | | Strategic | 8 | | ALL | 7 |
| P3 | 7 | | | | | | |
| **Total** | **40** | | | | | | |

**Top 10 by RICE:** ENH-001, ENH-002, ENH-004, ENH-003, ENH-006, ENH-005, ENH-009, ENH-007, ENH-011, ENH-008.

---

## P0 — Critical (do first)

| ID | Title | Cat | Apps | Impact | Effort | Reach | RICE | Type |
|----|-------|-----|------|:---:|:---:|:---:|:---:|------|
| ENH-001 | Add `accessibilityRole` + `accessibilityLabel` to the 2 shared primitives (`AppButton`, `AppInput`) + 4 global icon buttons | A11y (19) | ADM,STU | 5 | 1 | 90% | **450** | Quick win |
| ENH-002 | Add global `:focus-visible` ring + skip-link (web) | A11y (19) | WEB | 5 | 1 | 100% | **500** | Quick win |
| ENH-003 | Guard global chart JS behind existence checks; stop instantiating 14 charts on every page | Perf/Nielsen (12,25) | WEB | 4 | 2 | 100% | **200** | Quick win |
| ENH-004 | Fix broken dark mode: replace 27 `const C = Colors.light` with `useTheme()` tokens | Dark-mode (22) | STU | 5 | 3 | 70% | **117** | Standard |
| ENH-005 | Stop shipping mock data as real: wire admin dashboard, `staff-leave`, STU teacher dashboard to APIs (or clearly mark WIP) | Trust (10) | ADM,STU | 4 | 3 | 30% | 40 | Standard |
| ENH-006 | Fix default muted-text contrast: restrict `#94a3b8` to ≥18px; use `#475569` for small text | A11y (19) | ALL | 4 | 1 | 80% | **320** | Quick win |
| ENH-007 | Status badges: color-only → **color + icon + label**, token colors only | A11y/Color (19,3) | ALL | 4 | 2 | 60% | 120 | Standard |
| ENH-008 | Make feedback reliable: surface `useRefresh` errors (ADM), add iOS toast (STU) | Feedback (14) | ADM,STU | 4 | 2 | 50% | 100 | Quick win |
| ENH-009 | Remove dead/demo UI: dead links, demo login strings, dead bell, commented preloader, stale `.blade_*` backups | Trust (12,24) | ALL | 3 | 1 | 60% | 180 | Quick win |

## P1 — High

| ID | Title | Cat | Apps | Impact | Effort | Reach | RICE | Type |
|----|-------|-----|------|:---:|:---:|:---:|:---:|------|
| ENH-010 | Link `adminlte.rtl.css` + add `dir` toggle scaffold (RTL foundation) | i18n (23) | WEB | 4 | 2 | 100% | 200 | Quick win |
| ENH-011 | Introduce an i18n layer (externalize strings) starting with high-traffic screens | i18n (23) | ALL | 5 | 5 | 100% | 100 | Strategic |
| ENH-012 | Unify stat cards → one accent-bordered card (retire 4 web + 3 ADM treatments) | Consistency (3,10) | ALL | 4 | 3 | 50% | 67 | Standard |
| ENH-013 | Consolidate to one icon family on web (pick Bootstrap Icons OR FontAwesome) | Iconography (5) | WEB | 3 | 3 | 100% | 100 | Standard |
| ENH-014 | Migrate mobile lists `ScrollView.map` → `FlatList`/`FlashList` w/ shared list-row | Perf/Tables (11,25) | ADM,STU | 4 | 4 | 60% | 60 | Standard |
| ENH-015 | Web tables: sticky headers + server sort + bulk actions | Tables (11) | WEB | 4 | 4 | 70% | 70 | Standard |
| ENH-016 | Web tables: responsive card-stack below `md` | Responsive (20) | WEB | 4 | 3 | 70% | 93 | Standard |
| ENH-017 | One toast mechanism per platform (retire SweetAlert/`pptToast`/blocking `Alert`/Android-only) | Feedback (14) | ALL | 4 | 3 | 60% | 80 | Standard |
| ENH-018 | Retire legacy "Smart University" portal theme onto the modern system | Consistency (1,5) | WEB | 5 | 5 | 30% | 30 | Strategic |
| ENH-019 | Adopt `empty-state` component everywhere (kill plain-text empties), add action + art slot | Empty (16) | ALL | 3 | 3 | 60% | 60 | Standard |
| ENH-020 | Move page-specific chart JS out of the global footer into per-page bundles | Perf (25) | WEB | 4 | 4 | 100% | 100 | Standard |
| ENH-021 | Token-only color access on mobile; ban raw hex + `Colors.light` (add lint rule) | Color/Dark (3,22) | ADM,STU | 4 | 3 | 80% | 107 | Standard |
| ENH-022 | Modal/drawer focus management + keyboard nav (web) | A11y (19) | WEB | 4 | 3 | 40% | 53 | Standard |

## P2 — Medium

| ID | Title | Cat | Apps | Impact | Effort | Reach | RICE | Type |
|----|-------|-----|------|:---:|:---:|:---:|:---:|------|
| ENH-023 | Personalized dashboards: greeting + priority "needs you today" feed | Dashboard (10) | ALL | 4 | 4 | 40% | 40 | Strategic |
| ENH-024 | Skeleton loaders for cards/tables/lists (replace blank→spinner) | Feedback/Perf (14,25) | ALL | 3 | 3 | 70% | 70 | Standard |
| ENH-025 | Consolidate mobile bottom-sheets into one `Sheet` primitive | Consistency (Comp) | ADM,STU | 3 | 3 | 40% | 40 | Standard |
| ENH-026 | Consolidate mobile header trio → one `ScreenHeader` | Consistency (Comp) | ADM,STU | 2 | 2 | 40% | 40 | Quick win |
| ENH-027 | Consolidate STU child-switcher (3 → 1 shared) | Consistency (Comp) | STU | 2 | 2 | 20% | 20 | Quick win |
| ENH-028 | Touch-target sweep ≥44px (chips, inline icon buttons) | A11y (19) | ADM,STU | 3 | 2 | 50% | 75 | Quick win |
| ENH-029 | Inline validation everywhere; replace blocking `Alert` validation | Forms (13) | ADM | 3 | 2 | 30% | 45 | Standard |
| ENH-030 | Sectioned / stepped long forms (wizard for multi-part flows) | Forms (13) | ALL | 3 | 4 | 30% | 23 | Standard |
| ENH-031 | Dynamic Type / font scaling support (mobile) | A11y (19) | ADM,STU | 3 | 3 | 60% | 60 | Standard |
| ENH-032 | Reduced-motion gating on mobile animations | A11y (17,19) | ADM,STU | 2 | 2 | 40% | 40 | Quick win |
| ENH-033 | Currency/date localization helpers (remove hardcoded `₹`/`en-*`) | i18n (23) | ALL | 3 | 3 | 60% | 60 | Standard |

## P3 — Nice-to-have

| ID | Title | Cat | Apps | Impact | Effort | Reach | RICE | Type |
|----|-------|-----|------|:---:|:---:|:---:|:---:|------|
| ENH-034 | Illustration/empty-state art language (branded, culturally neutral) | Imagery (6) | ALL | 3 | 4 | 50% | 38 | Strategic |
| ENH-035 | First-run onboarding / coach-marks (drawer, child-switcher) | Onboarding (16) | ADM,STU | 3 | 4 | 40% | 30 | Strategic |
| ENH-036 | Motion language on mobile (purposeful transitions via Reanimated) | Motion (17) | ADM,STU | 2 | 4 | 50% | 25 | Strategic |
| ENH-037 | Brand identity pass: real logo, brand voice, retire ColorlibHQ/SmartUniversity leftovers | Brand (2) | ALL | 3 | 3 | 60% | 60 | Standard |
| ENH-038 | Print/PDF styles for report cards, marksheets, fee receipts | Content (24) | WEB | 3 | 3 | 20% | 20 | Standard |
| ENH-039 | Saved views / column config / saved filters (power users) | Tables (11) | WEB | 3 | 4 | 40% | 30 | Standard |
| ENH-040 | Offline/low-bandwidth resilience (mobile caching, retry) | Perf (25) | ADM,STU | 3 | 5 | 50% | 30 | Strategic |

---

## Dependencies (build order)

- **ENH-021 (token-only color) precedes ENH-004 (dark-mode fix)** — tokens first, then swap.
- **Design-system tokens/DESIGN_TOKENS.md precedes ENH-012, ENH-019, ENH-024** (components reference the token contract).
- **ENH-010 (link rtl.css) precedes full ENH-011 (i18n)** — RTL plumbing before translation rollout.
- **ENH-013 (one icon family) precedes ENH-037 (brand pass).**
- **ENH-020 (per-page JS) pairs with ENH-003 (guard globals).**

## How to read RICE here
RICE ranks *sequencing*, not importance. High-RICE quick wins (ENH-001/002/006/009) go first because they're cheap and broad. Strategic P1s with lower RICE (ENH-011 i18n, ENH-018 portal retirement) still matter — they're just bigger bets scheduled into later phases (see `ROADMAP_TO_10.md`). No item here is silently dropped; anything deferred is captured as P2/P3.
