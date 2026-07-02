# AI Implementation Guide — Prime Design System

> For AI coding agents (and developers) implementing this design system into the **real** Prime apps. It maps the reference components to concrete files, classes, and conventions in `prime_ai` (Laravel/Blade) and the two React Native apps.
>
> ⛔ **This design system is a reference.** Applying it to the live apps is a **separate, explicitly-approved** effort. Nothing in the audit/design-system deliverable changed app code. When you do implement, follow the "additive only" rules below.

---

## 0. Golden rules

1. **Preserve the palette.** Use the tokens in `DESIGN_TOKENS.md` / `tokens.css`. Never introduce new brand hex.
2. **No new frameworks.** Web = AdminLTE v4.0.0-beta3 + Bootstrap 5.3 + jQuery only. Mobile = existing Expo/RN/TS primitives only.
3. **Override, don't replace.** Style existing AdminLTE/Bootstrap classes; never edit `adminlte.css`/`adminlte-custom.css` directly or rebuild the shell.
4. **Additive files only.** New web CSS → `public/backend/css/prime-modern-ui.css`; new web JS → `public/backend/js/prime-modern-ui.js`. Load them **after** `adminlte-custom.css`.
5. **Token-driven color.** No raw hex in components (web or mobile). Mobile: always `useTheme()`/`useThemeColor()`, never `const C = Colors.light`.
6. **Accessible by default.** Every implementation carries the a11y attributes shown here (see `ACCESSIBILITY_STANDARDS.md`).

---

## 1. Web (Laravel / Blade / AdminLTE v4)

### 1.1 Where things go

| Concern | Live-app location |
|---------|-------------------|
| New cosmetic CSS | `prime_ai/public/backend/css/prime-modern-ui.css` (new file) |
| New JS behavior | `prime_ai/public/backend/js/prime-modern-ui.js` (new file) |
| Link them | Add to `resources/views/components/backend/partials/head.blade.php` (CSS, after `adminlte-custom.css`) and `.../footer-scripts.blade.php` (JS) |
| Tokens | Copy the `:root` + `[data-bs-theme="dark"]` blocks from `WEB_COMPONENTS/css/tokens.css` into the top of `prime-modern-ui.css` |
| Reusable Blade components | `resources/views/components/backend/*` (existing `x-backend.*`) |

### 1.2 Map reference components → existing Blade components

| Design-system reference | Implement by styling / extending |
|-------------------------|----------------------------------|
| Buttons (`01-buttons.html`) | Bootstrap `.btn.btn-*`; add `.btn-ghost`/`.is-loading` via `prime-modern-ui.css`. Existing `x-backend.form.button-submit`. |
| Forms (`02-forms.html`) | `x-backend.form.input-text/-number/-textarea/-date/-date-range`, `checkbox`, `form-dropdown`, the `select-*` family. Fix `autocomplete="false"`→`off`. |
| Tables (`03-tables.html`) | `x-backend.table.action`, `table.status-switch`, `tab.search-bar`, `tab.filter-bar`. Add sticky-header + card-stack CSS; add `aria-label` to icon actions. |
| Cards / stat card (`04-cards.html`) | Replace saturated `small-box text-bg-*` with the **accent** `.p-stat-card`. Consolidate the 3 web stat-card styles onto this one. |
| Navigation (`05`) / Sidebar (`06`) | `partials.navbar`, `partials.sidebar` (decide: enable the built sidebar or remove it — don't ship it dead). |
| Tabs (`07`) | `x-backend.tab.nav-tab` (already solid — restyle only). |
| Modals (`08`) | Bootstrap modal + SweetAlert confirm flows (keep confirm-destructive; drop the "Sure to Edit?" on non-destructive nav). |
| Dropdowns (`09`) | `partials.navbar` dropdowns; `x-backend.components.dropdown-need`. |
| Badges & Alerts (`10`) | `.badge`/`.alert`; make badges **color+icon+label** (token colors only). |
| Empty states (`12`) | `x-backend.components.empty-state` (already the reference — mandate it, retire plain-text empties). |
| Loaders (`13`) | Add `.p-skeleton`; re-enable a real preloader or remove the commented-out one. |
| Toasts (`14`) | Standardize on one mechanism (SweetAlert toast **or** a Prime toast); retire portal `pptToast`. |

### 1.3 Override technique

```css
/* prime-modern-ui.css — load AFTER adminlte-custom.css */
/* 1) tokens (paste from tokens.css) */
:root { --p-primary:#6673fc; /* … */ }
/* 2) style existing classes with modest specificity */
.card { border:1px solid var(--p-surface-border); border-radius:var(--p-radius-lg); box-shadow:var(--p-shadow-sm); }
.btn-primary { --bs-btn-bg:var(--p-primary); --bs-btn-border-color:var(--p-primary); --bs-btn-hover-bg:var(--p-primary-hover); }
/* 3) accent stat card replaces .small-box fills */
.p-stat-card { background:var(--p-surface-bg); border-left:4px solid var(--p-primary); border-radius:var(--p-radius-lg); }
```
Prefer overriding Bootstrap's own `--bs-*` component variables (as tokens.css does) over `!important`.

### 1.4 RTL
`adminlte.rtl.css` already ships in `public/backend/css/` — **link it** (currently unused) and gate on `dir="rtl"`. Use logical properties (`margin-inline-start`) in `prime-modern-ui.css` so RTL works without extra rules.

---

## 2. Mobile (React Native / Expo — both apps)

### 2.1 Where things go

| Concern | Location (both `mobile_school` and `mobile_student`) |
|---------|------|
| Tokens | `constants/theme.ts` — add missing `link`, `surfaceHover`, `light`; fix `surfaceSecondary` → `#f8fafc` |
| Primitives | `components/ui/*` (`button.tsx`, `input.tsx`, `card`, `badge`) — extend, don't fork |
| Theming | `hooks/useTheme()` / `useThemeColor()` — **always** use these |
| Lists | `FlatList`/`FlashList` (replace `ScrollView.map`) |

### 2.2 The two non-negotiable mobile fixes (from the audit)

**A. Never hardcode the theme.** Replace every `const C = Colors.light` (27 files in the student app) with:
```tsx
const colors = useThemeColor();   // or useTheme()
// use colors.surface, colors.text, colors.primary — flips light/dark automatically
```
**B. Accessibility on every touchable.** The primitives must carry roles/labels so screens inherit them:
```tsx
<Pressable accessibilityRole="button" accessibilityLabel="Mark attendance"
           accessibilityState={{ disabled, busy: loading }} hitSlop={8} /* ≥44px target */>
```
Icon-only controls (hamburger, bell, back, eye-toggle, FAB) **must** get an `accessibilityLabel`.

### 2.3 Compose, don't re-invent
The audit found list-rows, chips, badges, sheets, and empty states re-implemented per screen. Implement the shared patterns from `MOBILE_COMPONENTS/screens/*` once in `components/ui/` and compose them. Consolidate: one `Sheet`, one `ScreenHeader`, one child-switcher, one stat card.

### 2.4 Example — accent stat card (mobile)
```tsx
// composes existing Card primitive; tokens via useTheme; NOT a saturated fill
function StatCard({ icon, label, value, trend, tone = 'primary' }) {
  const c = useThemeColor();
  return (
    <Card style={{ borderLeftWidth: 4, borderLeftColor: c[tone] }}>
      <View style={{ backgroundColor: withOpacity(c[tone], 0.12), /* tinted icon circle */ }}>
        <MaterialIcons name={icon} color={c[tone]} accessibilityElementsHidden />
      </View>
      <Text style={[Typography.h3, { color: c.text }]}>{value}</Text>
      <Text style={[Typography.caption, { color: c.textSecondary }]}>{label}</Text>
    </Card>
  );
}
```

---

## 3. Common mistakes to avoid

| ❌ Mistake | ✅ Do instead |
|-----------|--------------|
| Editing `adminlte.css` / `adminlte-custom.css` | Add `prime-modern-ui.css`, load after |
| `!important` everywhere | Override Bootstrap `--bs-*` tokens |
| Saturated `text-bg-*` stat tiles | Accent `.p-stat-card` (border + tinted icon) |
| Status as color only | Color + icon + text label |
| `outline:none` with no replacement | Keep the `:focus-visible` ring |
| `const C = Colors.light` (mobile) | `useThemeColor()` |
| Raw hex in components | Token references |
| `ScrollView.map` for lists | `FlatList`/`FlashList` |
| Blocking `Alert` for validation/feedback | Inline errors + non-blocking toast |
| Five icon families (web) | One per platform |
| Shipping mock data / dead links | Wire real data or mark WIP clearly |

---

## 4. Before / After — one component (web stat card)

**Before (audit finding — StudentFee dashboard):**
```blade
<div class="small-box text-bg-primary">
  <div class="inner"><h3>1,248</h3><p>Students</p></div>
  <a href="#" class="small-box-footer">More info</a>   {{-- dead link, saturated fill --}}
</div>
```
**After (Prime accent card):**
```blade
<div class="p-stat-card p-stat-card--primary">
  <span class="p-stat-icon" aria-hidden="true"><i class="bi bi-people"></i></span>
  <div>
    <div class="p-stat-value">1,248</div>
    <div class="p-stat-label">Students</div>
    <div class="p-stat-trend p-tint-success"><i class="bi bi-arrow-up"></i> 3.2%</div>
  </div>
</div>
```
White surface, colored accent + tinted icon, real trend, no dead link, accessible. Same data, premium feel.

---

## 5. Implementation order (mirrors the enhancement roadmap)

1. Paste tokens into `prime-modern-ui.css` / align `theme.ts` (foundation).
2. Ship the Phase-0 quick wins (`../../02_ENHANCEMENTS/QUICK_WINS.md`) — focus ring, a11y labels, contrast, dead-code cleanup.
3. Restyle shared components (buttons, forms, cards, tables, badges) via overrides.
4. Consolidate duplicates (stat card, toast, empty state, mobile sheet/header).
5. Roll into screen templates (dashboards, list, form, detail, login).
6. Fix dark-mode leaks + wire RTL/i18n.

Verify each component against `ACCESSIBILITY_STANDARDS.md` §11 before marking it done.
