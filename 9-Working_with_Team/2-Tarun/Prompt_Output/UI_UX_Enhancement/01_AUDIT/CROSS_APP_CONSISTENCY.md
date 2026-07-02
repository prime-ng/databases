# Cross-App Consistency Audit — Web vs. Admin App vs. Student App

> Compares the **same concept** across prime_ai (WEB), mobile_school (ADM), and mobile_student (STU) to find where the three surfaces diverge, which treatment is the best reference, and what a unified spec should be.
> Evidence in `EVIDENCE_LOG.md`. Token-level drift is detailed separately in `DESIGN_TOKEN_DRIFT.md`.

---

## 1. Verdict

**Consistency is strong at the token layer and weak at the component layer.** The brand palette is identical everywhere (a real achievement), but *how that palette is expressed* — cards, badges, buttons, empty states, feedback — diverges significantly, and in the worst case (stat cards, web portals) a single concept has **three or more visual treatments**. The two mobile apps are highly consistent *with each other* (near-identical `theme.ts`, same primitives), so the main fault line is **web ↔ mobile** and, within web, **backend ↔ legacy portals**.

**Concepts with 3+ divergent treatments (🔴 flag):** Stat cards · Icon families · Toasts/feedback · Empty states.

---

## 2. Concept-by-Concept

### 2.1 Primary Button
| | Treatment | Reference? |
|---|-----------|:---:|
| WEB | Bootstrap/AdminLTE `.btn.btn-primary`, radius ~8px, hover lift | |
| ADM | `AppButton variant="primary"`, height 52, opacity-0.6 press, no icon slot, no a11y role | |
| STU | `AppButton variant="primary"`, height 52, same as ADM | |
**Divergence:** Low. Mobile buttons match each other; web is framework-default. **Unified spec:** one button token set (height 44–52, radius `md`, primary/secondary/ghost/danger/outline, icon slot, loading + disabled + focus-visible, a11y role). Mobile primitives need an **icon slot** and **accessibilityRole**; web needs a **visible focus ring**.

### 2.2 Stat / KPI Card — 🔴 4 treatments
| | Treatment |
|---|-----------|
| WEB (StudentFee) | **Fully saturated** `small-box text-bg-primary/success/...` color-fill tiles |
| WEB (MarksheetGeneration) | Subtle `bg-opacity-10` accent tile + icon |
| WEB (StudentPortal) | Inline-styled full-color gradient card, **Feather** icon |
| ADM / STU | Rounded card, tinted icon-circle, value + label + trend (the best of the set) |
**Divergence:** Critical. **Unified spec:** the mobile "white surface + tinted icon-circle + value + delta" card, ported to web as an accent-bordered card (per audit priority #1: accent, don't fill). Retire the saturated `small-box` and inline-gradient variants.

### 2.3 Status Badge — 🔴 color-only + off-palette
| | Treatment |
|---|-----------|
| WEB | `.badge bg-success/bg-secondary` — **color only, no icon** |
| ADM | Inline pill, status→hex map that **differs from tokens** (`#ef4444` vs `danger #e44f56`) |
| STU | status→hex functions returning **off-palette** `#0984e3/#00b894/#b2bec3` |
**Divergence:** High + accessibility failure (color-only) + palette drift. **Unified spec:** one badge = **tinted bg + colored icon + text label**, colors drawn only from `success/warning/danger/info/secondary` tokens. Never color alone.

### 2.4 Data List / Table — 🔴 structurally different
| | Treatment |
|---|-----------|
| WEB | Bootstrap `.table`, client-side sort auto-injected, ~54% wrapped in `table-responsive`, no sticky header, horizontal-scroll on mobile |
| ADM | `ScrollView.map`, pagination via **manual scroll-offset math**, no `FlatList` |
| STU | `ScrollView.map`, mostly no pagination, only 2 `FlatList` in the app |
**Divergence:** High and a shared performance risk. **Unified spec:** web tables get sticky headers + server sort + bulk actions + **card-stack below `md`**; mobile lists standardize on `FlatList`/`FlashList` with a shared list-row + empty + load-more pattern.

### 2.5 Empty State — 🔴 3 treatments
| | Treatment | Reference? |
|---|-----------|:---:|
| WEB | Good reusable `empty-state` component (icon tile + title + message + CTA)… | ✅ best |
| WEB (modules) | …but many fall back to plain "No X found" text | |
| ADM / STU | Single grey MaterialIcon + one line of muted text, no CTA | |
**Divergence:** High. **Unified spec:** adopt the web `empty-state` structure everywhere (icon + title + message + **action**), add illustration slots, and mandate it (no plain-text empties).

### 2.6 Toast / Feedback — 🔴 4 mechanisms
| | Treatment |
|---|-----------|
| WEB (backend) | SweetAlert2 toasts |
| WEB (portals) | Hand-rolled `pptToast()` |
| ADM | Blocking `Alert.alert()` (22 call sites), no toast lib |
| STU | `utils/toast.ts` — **Android-only, silent on iOS** |
**Divergence:** Critical — four mechanisms, one of which is silent on half its devices. **Unified spec:** one non-blocking toast per platform (success/info/warning/error, auto-dismiss + progress, stack positioning, screen-reader live-region). Replace blocking `Alert` for non-critical feedback.

### 2.7 Header / Navigation Chrome
| | Treatment |
|---|-----------|
| WEB | Top navbar + app-launcher; **left sidebar built but disabled** |
| ADM | Drawer + `AppHeader`/`ScreenHeader` (2 near-dup headers + 1 inlined) |
| STU | Drawer + `AppHeader`/`ScreenHeader` (branded gradient variant) |
**Divergence:** Medium. Mobile apps consistent with each other; web differs by platform necessity. **Unified spec:** acceptable to differ web↔mobile, but consolidate the mobile header trio into one component, and decide whether the web sidebar is on or gone (don't ship dead code).

### 2.8 Form Input + Validation
| | Treatment |
|---|-----------|
| WEB | `form.input-text` w/ `is-invalid`/`invalid-feedback` + blur JS (inline) |
| ADM | `AppInput` (inline error) **but** create-form validation via blocking `Alert` one-at-a-time |
| STU | `AppInput` (inline error) + strong business-rule validation in `leave/apply` |
**Divergence:** Medium; the *primitive* is consistent, the *validation UX* isn't. **Unified spec:** always inline, field-level, text+icon errors; summarize on submit; never blocking `Alert` for validation.

### 2.9 Iconography — 🔴 (web only)
| | Treatment |
|---|-----------|
| WEB | **5 families** (FontAwesome 6, Bootstrap Icons, Feather, Simple Line, Material Design Icons), mixed per screen |
| ADM / STU | **1 family** (MaterialIcons) — consistent ✅ |
**Unified spec:** one family per platform — **Bootstrap Icons OR FontAwesome for web** (pick one), MaterialIcons for mobile. Mobile is already correct.

### 2.10 Dark Mode
| | Treatment |
|---|-----------|
| WEB | Shell fully themed; **module content leaks** (`bg-white`, `text-dark`, inline `#fff`) |
| ADM | Works across screens; a few hardcoded surface hex leaks |
| STU | **Broken** — 27 files hardcode `Colors.light` |
**Divergence:** Critical (STU). **Unified spec:** all color access through tokens; ban hardcoded surface/text hex; lint for `Colors.light` direct usage and raw hex.

---

## 3. Consistency Scorecard

| Concept | Web↔Mobile | Within-Mobile | Within-Web | Severity |
|---------|:---:|:---:|:---:|:---:|
| Tokens/palette | ✅ | ✅ | ✅ | — |
| Buttons | ⚠️ | ✅ | ✅ | Low |
| Stat cards | ❌ | ✅ | ❌ (4 styles) | 🔴 Critical |
| Status badges | ❌ | ⚠️ | ⚠️ | 🔴 High |
| Tables/lists | ❌ | ✅ (same anti-pattern) | ⚠️ | 🔴 High |
| Empty states | ❌ | ✅ | ❌ | 🔴 High |
| Toasts/feedback | ❌ | ❌ | ❌ (2 web) | 🔴 Critical |
| Headers/nav | ⚠️ | ✅ | ⚠️ | Medium |
| Forms/validation | ⚠️ | ⚠️ | ✅ | Medium |
| Iconography | ⚠️ | ✅ | ❌ (5 families) | 🔴 High |
| Dark mode | ⚠️ | ⚠️ | ⚠️ | 🔴 Critical (STU) |

---

## 4. The Unification Play

The design system in `../03_DESIGN_SYSTEM/` publishes **one canonical spec per concept above**. Priority order (highest inconsistency + highest visibility first):
1. **Stat cards** → one accent-card language (kills 4 web treatments).
2. **Toasts/feedback** → one non-blocking toast per platform (kills 4 mechanisms).
3. **Status badges** → token-only, color+icon+label.
4. **Empty states** → the web component structure, everywhere, with actions.
5. **Icon family** → one per platform (web needs consolidation).
6. **Dark mode** → tokens-only color access (unblocks STU).

Because the token layer is *already* shared, unification is mostly a **component + discipline** exercise, not a rebrand.
