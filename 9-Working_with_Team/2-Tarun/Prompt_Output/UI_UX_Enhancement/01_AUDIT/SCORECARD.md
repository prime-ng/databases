# Prime Ecosystem — 25-Dimension UI/UX Scorecard

> **Method:** Each app was audited read-only against the 25-dimension taxonomy. Per-dimension scores are 0–10 (rubric below). The **App avg** columns are the raw per-app ratings; the **Weighted** column applies the dimension weight to the cross-app average. Overall = Σ(weight × cross-app-avg) ÷ Σ(weight).
> **Apps:** WEB = prime_ai (Laravel/AdminLTE) · ADM = mobile_school (admin) · STU = mobile_student (student/parent/teacher).
> **Date:** 2026-07-01. All scores trace to `EVIDENCE_LOG.md`.

**Rubric anchors:** 9–10 best-in-class · 7–8 polished · 5–6 functional-but-generic · 3–4 noticeable problems · 0–2 broken/absent.

---

## Overall Score: **5.2 / 10**  — "Functional, capable, and consistent in its bones, but reads as a generic ERP; held back by accessibility, internationalization, empty-state craft, and cross-surface inconsistency."

| Per-app headline | Score | One-line |
|------------------|:-----:|----------|
| **WEB** — prime_ai backend | **5.5** | Polished, modern AdminLTE v4 shell; undermined by a legacy portal theme, global JS/asset bloat, no focus states, near-zero i18n. |
| **ADM** — mobile_school | **5.2** | Clean token-driven visuals; zero accessibility, mock dashboards, `ScrollView`-not-`FlatList`, inconsistent feedback. |
| **STU** — mobile_student | **5.0** | Best UX patterns in the ecosystem (progressive disclosure); crippled by broken dark mode on 27 screens + zero accessibility. |

---

## Scorecard

| # | Dimension | Wt | WEB | ADM | STU | Avg | Wtd | Verdict |
|---|-----------|:--:|:---:|:---:|:---:|:---:|:---:|---------|
| 1 | Visual design & modernness | 5% | 7 | 7 | 7 | 7.0 | 0.35 | 🟢 Solid — modern surfaces, soft cards |
| 2 | Brand personality | 3% | 4 | 5 | 5 | 4.7 | 0.14 | 🟠 "P-in-a-circle"; ColorlibHQ/Smart-University leftovers |
| 3 | Color system usage | 4% | 5 | 6 | 3 | 4.7 | 0.19 | 🟠 Tokens exist but bypassed (514 hex in STU; 3 stat-card styles in WEB) |
| 4 | Typography | 4% | 5 | 7 | 7 | 6.3 | 0.25 | 🟢 Clean scales; WEB fragmented (3 fonts) |
| 5 | Iconography consistency | 3% | 3 | 8 | 8 | 6.3 | 0.19 | 🟠 Mobile single-family; **WEB uses 5 icon families** |
| 6 | Imagery / empty-state art | 2% | 5 | 2 | 2 | 3.0 | 0.06 | 🔴 No illustration language anywhere |
| 7 | Layout & whitespace | 4% | 6 | 8 | 8 | 7.3 | 0.29 | 🟢 Good rhythm; WEB ad-hoc spacing |
| 8 | Information hierarchy | 5% | 6 | 7 | 7 | 6.7 | 0.33 | 🟢 Strong on dashboards |
| 9 | Navigation & wayfinding | 4% | 6 | 7 | 7 | 6.7 | 0.27 | 🟢 Good; WEB sidebar disabled, mobile 2-taps-deep |
| 10 | Dashboard design | 4% | 6 | 5 | 6 | 5.7 | 0.23 | 🟠 Some are hardcoded mock (ADM index, STU teacher) |
| 11 | Data density & tables | 4% | 5 | 4 | 4 | 4.3 | 0.17 | 🔴 No sticky headers/server-sort (WEB); no FlatList (mobile) |
| 12 | Nielsen heuristics | 6% | 4 | 5 | 5 | 4.7 | 0.28 | 🟠 Global JS errors (WEB), inconsistent feedback |
| 13 | Forms & input UX | 5% | 6 | 6 | 7 | 6.3 | 0.32 | 🟢 Inline validation; no steppers |
| 14 | Feedback & system status | 4% | 6 | 5 | 4 | 5.0 | 0.20 | 🟠 No skeletons; iOS toasts silent (STU) |
| 15 | Error handling & recovery | 4% | 7 | 4 | 6 | 5.7 | 0.23 | 🟠 WEB has friendly error pages; mobile lacks ErrorBoundary |
| 16 | Empty / first-run / onboarding | 3% | 5 | 3 | 3 | 3.7 | 0.11 | 🔴 No onboarding anywhere |
| 17 | Motion & micro-interactions | 2% | 7 | 3 | 4 | 4.7 | 0.09 | 🟠 WEB tasteful; mobile Reanimated unused |
| 18 | Cognitive load & disclosure | 4% | 5 | 6 | 8 | 6.3 | 0.25 | 🟢 STU overview→modal→full is exemplary |
| 19 | **Accessibility (WCAG 2.2 AA)** | 7% | 3 | 1 | 1 | 1.7 | 0.12 | 🔴🔴 **Worst dimension.** 0 a11y props on mobile; no focus-visible on web |
| 20 | Responsive / mobile-web | 4% | 5 | — | — | 5.0 | 0.20 | 🟠 WEB tables horizontal-scroll only, no card-stack |
| 21 | Mobile-app nativeness | 4% | — | 6 | 7 | 6.5 | 0.26 | 🟢 Real native shells, safe-area, gestures |
| 22 | Dark-mode parity | 3% | 5 | 7 | 2 | 4.7 | 0.14 | 🔴 STU dark mode broken on 27 files; WEB module content leaks |
| 23 | **i18n & RTL** | 3% | 2 | 1 | 1 | 1.3 | 0.04 | 🔴🔴 English hardcoded; ₹ hardcoded 290× (WEB); rtl.css unused |
| 24 | Microcopy & content design | 3% | 6 | 6 | 6 | 6.0 | 0.18 | 🟢 Friendly; demo strings leak to prod |
| 25 | Performance perception | 2% | 4 | 5 | 5 | 4.7 | 0.09 | 🟠 WEB global bundle bloat; no skeletons |
| | **TOTAL (Σwt = 96)** | | | | | | **4.98/96 → 5.2** | |

---

## Reading the Scorecard

**The five red zones (fix these to move the number):**
1. **Accessibility (1.7, weight 7%)** — the single biggest drag. Cheap to fix, high leverage, and competitors ignore it → differentiator.
2. **i18n & RTL (1.3)** — blocks international/Gulf expansion; `adminlte.rtl.css` already ships but isn't linked.
3. **Imagery / empty-state art (3.0)** & **Onboarding (3.7)** — the "premium product vs. ERP" tell.
4. **Data density & tables (4.3)** — no sticky headers / server sort (web); `ScrollView.map` instead of `FlatList` (mobile).
5. **Dark-mode parity (4.7, dragged by STU 2)** — one app's toggle is decorative.

**The strong base to build on (don't regress):** visual modernness (7.0), layout/whitespace (7.3), info hierarchy (6.7), navigation (6.7), typography (6.3), cognitive-load/progressive-disclosure (6.3). The foundations are genuinely good — this is a **polish and consistency** problem, not a rebuild.
