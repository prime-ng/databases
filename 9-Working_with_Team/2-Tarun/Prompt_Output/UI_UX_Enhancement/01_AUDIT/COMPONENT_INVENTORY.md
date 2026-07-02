# Component Inventory & Duplication Map — Prime Ecosystem

> Catalog of reusable UI components across the three apps, with duplicate/near-duplicate flags. This is the backbone for the unified design system in `../03_DESIGN_SYSTEM/`.
> Evidence in `EVIDENCE_LOG.md`.

---

## 1. WEB — prime_ai (`resources/views/components/backend/*`)

### Layout & partials
| Component | Notes |
|-----------|-------|
| `x-backend.layouts.app` | Root shell; **sidebar commented out**; stale `app.blade_27_12_2025.php` backup |
| `partials.head` | Loads 3 icon families + jQuery (blocking) + FullCalendar |
| `partials.navbar` | Strong; + **dead `navbar.blade_26_11_2025.php`** backup |
| `partials.sidebar` | Fully built treeview — **unused (not rendered)** |
| `partials.sidebar-navbar`, `partials.footer`, `partials.footer-scripts` | footer-scripts = 1747 lines, global |

### Components
| Component | Notes |
|-----------|-------|
| `components.breadcrum` | ✅ Good page-header + breadcrumb, proper ARIA |
| `components.empty-state` | ✅ Good, 4 variants — **the reference empty state** |
| `components.pre-loader` | ❌ **Entirely commented out (dead) yet still invoked** |
| `components.search`, `.filter`, `.search-filter-option`, `.menu-item`, `.dropdown-need` | Search/filter primitives |
| `components.create-dropdown` **/ `create-dropdownpg`** | 🔴 **Near-duplicate** |

### Tab / Table / Card / Form
| Component | Notes |
|-----------|-------|
| `tab.nav-tab`, `tab.search-bar`, `tab.filter-bar` | ✅ Solid tab system |
| `table.action` **/ `table.action-trashed`** | 🔴 **Near-duplicate** |
| `table.status-switch` **/ `form.status-switch`** | 🔴 **Conceptual duplicate** across two folders |
| `card.header` | Single card partial |
| `form.*` (35+) | `input-text/number/textarea/date/date-range`, `checkbox`, `button-submit`, `form-dropdown`, `menu-dropdown`, + ~24 `select-*` (geo, class/section/subject/board, plan/module/org, timezone/language/currency, room-type/building…) |
| `select-room-type` **/ `select-room_type`** | 🔴 **Naming-collision duplicate** |
| `select-route-prefix` **/ `backup_select-route-prefix`** | 🔴 **Stale backup checked in** |
| Other | `chat-widget`, `email.template`; StudentPortal ships its **own** `components/stat-card` (Feather + inline) |

**Dead/stale files to remove:** `layouts/app.blade_27_12_2025.php`, `partials/navbar.blade_26_11_2025.php`, `public/backend/css/adminlte_26_12_2025.css`, `backup_select-route-prefix.blade.php`, `pre-loader` (commented-out).

---

## 2. ADM — mobile_school (`components/ui/*` + others)

| Component | Path | Variants / gaps |
|-----------|------|-----------------|
| `AppButton` | `ui/button.tsx` | primary/secondary/ghost/danger; loading; **no a11y role, no icon slot, no size** |
| `AppInput` | `ui/input.tsx` | label/error/hint/leftIcon, password toggle; **eye has no a11y label** |
| `DateTimePickerField` | `ui/datetime-picker.tsx` | ✅ platform-branched |
| `Collapsible`, `IconSymbol` | `ui/collapsible.tsx`, `ui/icon-symbol*.tsx` | ❌ **dead Expo-template code** |
| Navigation | `navigation/app-header`, `screen-header`, `drawer-content` | + inlined header in `profile.tsx` |
| Template leftovers | `themed-text`, `themed-view`, `haptic-tab`, `hello-wave`, `parallax-scroll-view`, `external-link` | ❌ unused |

**Duplicates:** 🔴 Header ×3 (`AppHeader` + `ScreenHeader` + inlined `profile.tsx:44-50`) · 🔴 `StatCard` reimplemented in 3 screens (`(app)/index`, `complaints/index`, `staff-leave/index`) · 🔴 `formatDate` re-declared despite `utils/date-format.ts` · 🔴 typography scale duplicated in `themed-text.tsx` · Chip/search-row hand-rolled per screen (no shared primitive).

---

## 3. STU — mobile_student (`components/ui/*` + dashboard)

| Component | Path | Variants / gaps |
|-----------|------|-----------------|
| `AppButton` | `ui/button.tsx` | 4 variants, loading; **no size/icon, no a11y** |
| `AppInput` | `ui/input.tsx` | label/error/hint/leftIcon, password toggle; **no a11y label** |
| `DatePickerModal` | `ui/date-picker-modal.tsx` | 🔴 custom wheel, **light-only**, duplicates installed `@react-native-community/datetimepicker` |
| `Collapsible`, `IconSymbol` | | ❌ dead template |
| Dashboard | `dashboard/overview-card`, `detail-modal`, `today-schedule-preview`, `modal-contents/*` | ✅ strong progressive-disclosure set (`TimelineDot` light-only) |
| Layout/nav | `layout/screen-wrapper`, `screen-header`, `role-guard`; `navigation/app-header` (**dead bell**), `drawer-content` (**light-only**) |
| `feature-card` | `components/feature-card.tsx` | ⚠️ well-built but **unused** (dashboard uses inline `OverviewCard`/`QuickCard`) |

**Duplicates:** 🔴 **Child-switcher implemented 3×** (drawer pill+modal, dashboard card+modal, `children` screen+modal) · 🔴 **Bottom-sheet modal re-implemented per screen** (`detail-modal`, `date-picker-modal`, `leave/apply` type modal, drawer) — no shared `Sheet` · 🔴 two card systems (`feature-card` unused vs inline dashboard cards) · `retryBtn`/`retryText` styles copy-pasted across many screens.

---

## 4. Consolidation Targets (ranked by payoff)

| Rank | Consolidate | From → To | Payoff |
|:---:|-------------|-----------|--------|
| 1 | **Stat card** | 4 web + 3 ADM + inline STU → **1 accent card** | Kills the biggest visual inconsistency |
| 2 | **Bottom-sheet/modal (mobile)** | per-screen bespoke → **1 `Sheet` primitive** | Removes the most-copied mobile pattern |
| 3 | **Toast** | SweetAlert + `pptToast` + `Alert` + Android-only → **1 per platform** | Fixes silent-iOS + 4-mechanism sprawl |
| 4 | **Header (mobile)** | 3 (ADM) / 2+ (STU) → **1 `ScreenHeader`** | Simplifies nav chrome |
| 5 | **Child-switcher (STU)** | 3 → **1 shared component** | Removes triplicated logic |
| 6 | **Empty state** | web component + plain-text + mobile icon-text → **1 pattern everywhere** | Consistency + guidance |
| 7 | **Status badge** | color-only + off-palette maps → **1 token-only badge** | Accessibility + palette discipline |
| 8 | **Date picker** | web + ADM native + STU custom-wheel → **1 per platform (native)** | Removes light-only custom wheel |
| 9 | **Remove dead code** | web backups, mobile Expo-template leftovers, `feature-card`, dead bell/preloader | Reduces confusion + bundle |

---

## 5. What the Design System Publishes

`../03_DESIGN_SYSTEM/prime-design-system/` provides **one canonical spec** for items 1–8 above:
- Web: CSS + HTML galleries for buttons, forms, tables, cards (accent stat card), navigation, tabs, modals, dropdowns, badges/alerts, pagination, empty-states, loaders, toasts.
- Mobile: markdown patterns composing the **existing** `components/ui/*` primitives (button, input, card, badge, sheet, list-row, empty state) so mobile teams consolidate onto shared components rather than re-inventing per screen.

The inventory shows the ecosystem doesn't need *more* components — it needs **fewer, shared** ones. The token layer is already unified; the component layer is where the consolidation work lives.
