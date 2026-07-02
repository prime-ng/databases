# Accessibility Audit — WCAG 2.2 AA (Prime Ecosystem)

> **Target:** WCAG 2.2 Level AA. **Method:** static analysis of code, markup, and theme tokens across all three apps (no automated runtime scanner was run — findings are reasoned from source and flagged as static analysis). Contrast ratios computed from the verified palette.
> **Headline:** This is the ecosystem's **lowest-scoring dimension (1.7/10)** and its highest-leverage fix. Most competitors in the segment ignore accessibility, so closing this gap is both a compliance win and a differentiator.

---

## 1. Severity Summary

| Severity | Count | Examples |
|----------|:-----:|----------|
| 🔴 Blocker | 5 | 0 a11y props on mobile; no `:focus-visible` on web; color-only status; failing contrast on default muted text; icon-only controls unlabeled |
| 🟠 Major | 6 | Touch targets < 44px; no keyboard focus management in modals; headings skip levels; no reduced-motion on mobile; date picker light-only; no live regions for async status |
| 🟡 Minor | 4 | `autocomplete="false"` invalid; decorative demo avatars without proper handling; 404 leaks exception text; no skip-link |

---

## 2. Color & Contrast (verified against the real palette)

| Pair | Ratio | WCAG AA | Where it bites |
|------|------:|:-------:|----------------|
| `#1e293b` text-primary on `#ffffff` | ~13.6:1 | ✅ AAA | body text — fine |
| `#475569` text-secondary on `#ffffff` | ~7.5:1 | ✅ AAA | secondary text — fine |
| **`#94a3b8` text-muted on `#ffffff`** | **~2.6:1** | ❌ **FAIL** | 🔴 **Default caption/placeholder/subtitle color across all 3 apps** — the most widespread contrast failure |
| white on `#6673fc` primary | ~3.6:1 | ⚠️ large/bold only | Button labels must be ≥14px bold (they are ~OK); small white-on-primary text fails |
| white on `#facc15` warning | ~1.4:1 | ❌ FAIL | Never white-on-warning; use `#222c3c` dark text |
| white on `#3fcc7e` success | ~1.9:1 | ❌ FAIL | Use success as accent, or dark text on fills |
| white on `#e44f56` danger | ~3.9:1 | ⚠️ large/bold only | Fine for ≥14px bold labels |

**Actions:** (1) restrict `text-muted #94a3b8` to ≥18px or decorative use; use `text-secondary #475569` for small helper text. (2) Never put white text on `warning`/`success` fills. (3) Treat `success`/`warning` as accents, not fills-behind-white-text.

---

## 3. Web (prime_ai) — WCAG findings

| WCAG SC | Finding | Evidence | Fix |
|---------|---------|----------|-----|
| 2.4.7 Focus Visible | 🔴 **72 `outline:none/0`, zero `:focus-visible`** — keyboard focus is invisible platform-wide | `adminlte-custom.css` | Add a global `:focus-visible` ring (`--p-focus-ring`); never remove outline without replacement |
| 4.1.2 Name/Role/Value | 🔴 Icon-only action buttons have `title` but **no `aria-label`** | `table/action.blade.php:31-55` | Add `aria-label` to every icon-only control |
| 1.4.1 Use of Color | 🔴 Status conveyed **color-only** | `status-switch.blade.php`, Payment badges | Add icon + text label to badges |
| 1.3.1 Info & Relationships | 🟠 Heading order jumps (h3→h4 on dashboards) | module dashboards | Enforce sequential headings, one `<h1>`/page |
| 1.4.10 Reflow / 1.4.4 | 🟠 Tables horizontal-scroll only; breadcrumbs hidden < 768px | `adminlte-custom.css:638` | Card-stack tables < md; keep wayfinding on mobile |
| 3.2.2 / 1.3.5 | 🟡 `autocomplete="false"` is an **invalid value** (should be `off`) | `form/input-text.blade.php:4` | Correct the attribute |
| 2.4.1 Bypass Blocks | 🟡 No skip-to-content link | layout | Add skip-link as first focusable element |
| 3.3.1 | 🟡 404 exposes raw `$exception->getMessage()` | `errors/404.blade.php:64` | Show generic copy; log detail server-side |
| 2.3.3 | ✅ Reduced-motion **is** respected on web | `adminlte-custom.css:690` | Keep |

**Web positives:** breadcrumb/tab/role-switch components carry correct `aria-*`; reduced-motion guard present; friendly error pages exist.

---

## 4. Mobile (mobile_school + mobile_student) — findings

| Area | Finding | Evidence | Fix |
|------|---------|----------|-----|
| Labels/roles | 🔴 **Zero `accessibilityLabel/Role/Hint` in either codebase** (grep = 0) | both apps, all screens/components | Add `accessibilityRole` + `accessibilityLabel` to every `Pressable`/`TouchableOpacity`; start with primitives (`AppButton`, `AppInput` eye-toggle) |
| Icon-only controls | 🔴 Hamburger, back, bell, FAB, close, eye-toggle unlabeled | `app-header.tsx`, `input.tsx` | Label each ("Open menu", "Notifications", "Show password") |
| Contrast | 🔴 `textMuted #94a3b8` (fails AA) is default caption color | `theme.ts:44` | Darken to `text-secondary` for small text |
| Touch targets | 🟠 Chips & some inline icon `Pressable`s < 44px | ADM chips `paddingVertical ~10px` | Enforce 44×44 min hit area (use `hitSlop`/min-size) |
| Async status | 🟠 No live regions; iOS toasts silent; `useRefresh` swallows errors | STU `toast.ts` (Android-only), ADM `use-refresh.ts:19` | Announce status via `accessibilityLiveRegion`; add iOS toast; surface refresh errors |
| Dynamic Type | 🟠 Fixed `fontSize` throughout; no scaling support | both `Typography` usage | Support OS font scaling / `allowFontScaling` |
| Dark mode | 🟠 (STU) 27 screens locked to `Colors.light` → contrast unpredictable in dark | STU screens | Token-only color access |
| Reduced motion | 🟠 No `AccessibilityInfo.isReduceMotionEnabled` checks | both | Gate press-scale/transitions |
| Date picker | 🟠 (STU) custom wheel light-only, no a11y | `date-picker-modal.tsx:14` | Use native picker or label + theme it |

**Mobile positives:** `hitSlop` used in places (14× in STU); buttons/inputs are 52px (≥44); safe-area handling is solid.

---

## 5. Prioritized Remediation (maps to backlog)

**Phase 0 (days):**
1. Web: global `:focus-visible` ring + skip-link.
2. Web: `aria-label` on `table.action` icon buttons; fix `autocomplete`.
3. Mobile: `accessibilityRole`+`Label` on the two shared primitives (`AppButton`, `AppInput`) and the four global icon buttons — covers most screens at once.
4. All: stop using `text-muted #94a3b8` for small text; add icon+label to status badges.
5. Mobile: surface refresh errors; add iOS toast.

**Phase 1–2 (weeks):**
6. Modal focus management (web + mobile), keyboard nav, live regions.
7. Touch-target sweep (≥44px); Dynamic Type; reduced-motion gating.
8. Contrast pass on all fills (no white-on-warning/success).

**Sign-off:** re-run against the `ACCESSIBILITY_STANDARDS.md` §11 component checklist in the design system; target AA green on every component before Phase 3.

---

## 6. Why This Is the Best ROI in the Audit

Accessibility is weight-7% and scores 1.7 — the largest single point-drag. Most fixes are **attribute-level and mechanical** (labels, a focus ring, a contrast swap), not redesigns. And because regional competitors uniformly ignore accessibility (see `COMPETITIVE_BENCHMARK.md`), fixing it simultaneously (a) raises the score fastest, (b) opens enterprise/government procurement that mandates AA, and (c) differentiates the product. **Do this first.**
