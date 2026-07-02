# Evidence Log — Prime UI/UX Audit

> Every location inspected (read-only) with concrete observations + file:line citations. This is the traceability backbone for `SCORECARD.md` and `PRIME_UI_UX_AUDIT_REPORT.md`. **No files were modified during this audit.**
> Date: 2026-07-01.

---

## A. WEB — prime_ai (`/Users/bkwork/Herd/prime_ai`)

### Shell & layout
- `public/backend/css/adminlte-custom.css` (2228 lines) — Brand tokens `--primary:#6673fc` … at L1-50; full dark token set L52-68; dark overrides for navbar/dropdowns/launcher/cards/tables/tabs/forms/footer L1760-2227; `fadeInUp` card cascade L651-687 with `prefers-reduced-motion` guard L690; empty-state component L703-774. **No `:focus-visible` rules anywhere.**
- `resources/views/backend/v1/layouts/app.blade.php` — **Left sidebar commented out (L17-19)**; navigation via top navbar + app-launcher only. Preloader invoked but its component is commented out (dead). Stale backup `app.blade_27_12_2025.php` checked in.
- `resources/views/components/backend/partials/head.blade.php` — Loads **3 icon families** (Bootstrap Icons L26, FontAwesome 6 L40, + Source Sans font); **jQuery 3.6 render-blocking in `<head>` L44**; FullCalendar global on every page L48; leftover meta `author="ColorlibHQ"`, title "AdminLTE v4 | Dashboard" L10-15; theme-flash-prevention inline script L60-66 (good).
- `resources/views/components/backend/partials/footer-scripts.blade.php` — **1747 lines globally loaded.** Page-specific chart code dereferences `window.statusDistribution` (L1099) + ~9 other page-globals unconditionally → TypeErrors site-wide; 14 chart instances instantiated globally; sortablejs loaded twice (L39, L761); global table sort L1607; SweetAlert confirm flows L254/355-405.
- `resources/views/components/backend/partials/navbar.blade.php` — Strong: hover dropdowns, notification empty-states L147-152, theme toggle L162-167, role-switch modal with proper `aria-*` L231-283, app-launcher grid w/ search L286-364, honest dead-link dots L54.
- `resources/views/components/backend/partials/sidebar.blade.php` — Fully built treeview + active-path JS, but **not rendered**; brand uses demo `AdminLTELogo.png` L7.

### Components
- `components/backend/components/breadcrum.blade.php` — Page-header card, back button, title, description, actions slot; proper `aria-label="breadcrumb"`/`aria-current` L23,39.
- `components/backend/components/empty-state.blade.php` — Good reusable icon+title+message+CTA, 4 variants.
- `components/backend/table/action.blade.php` — Permission-gated view/edit/delete; icon-only buttons have `title` but **no `aria-label`** L31-55; FontAwesome.
- `components/backend/table/status-switch.blade.php` — AJAX toggle or read-only badge; **color-only status**.
- `components/backend/form/input-text.blade.php` — `@error`/`is-invalid`/`invalid-feedback` + blur validation JS; **`autocomplete="false"` (invalid value)** L4.
- `components/backend/tab/nav-tab.blade.php` — Scrollable, permission-gated, `role="tab"`/`aria-selected`, URL-syncs active tab (solid).

### Module views (consistency sample)
- `Modules/StudentFee/resources/views/dashboard.blade.php` — Stat cards = **fully saturated `small-box text-bg-*` fills** L10-128; dead `href="#"` "More info" L104,123.
- `Modules/Payment/.../payment-gateway/index.blade.php` — hardcoded `bg-white` L1 (breaks dark mode); no `table-responsive`; color-only badges L48-77; plain-text empty "No payment gateways found." L100-102.
- `Modules/MarksheetGeneration/.../dashboard.blade.php` — **Different** stat pattern: `bg-opacity-10` accent tiles L34-79; hardcoded `text-dark` L13,51 (breaks dark mode).
- `Modules/Hostel/.../incidents/index.blade.php` — Bootstrap `nav-tabs` (not shared component); responsive filters; `onchange="this.form.submit()"`.
- `Modules/StudentPortal/.../layouts/master.blade.php` — **Stub layout**, empty body, Vite commented out — no real Smart University theme here.
- `Modules/StudentPortal/.../components/stat-card.blade.php` — Inline-styled full-color cards using **Feather icons** (3rd icon system).
- `Modules/ParentPortal/.../layouts/app.blade.php` — Uses `<x-frontend.layout>` = **legacy "Smart University"/Metronic theme** (Poppins, FA v4+v6, Material Design Lite, bundled legacy Bootstrap); hand-rolled `pptToast()` JS.
- `resources/views/components/frontend/layout/head.blade.php` — Portal stack: Poppins, Simple Line Icons, FA v4 AND v6, MDI, MDL, **bundled legacy Bootstrap** L23; meta `author="SmartUniversity"`, unbranded title L10-11.
- `resources/views/errors/{403,404,419,500}.blade.php` — Friendly branded error pages w/ Home/Back; **404 leaks `$exception->getMessage()`** L64; no dark mode.

### Asset/icon inventory (WEB)
- **5 icon families:** FontAwesome 6.7.2 (1562 files), Bootstrap Icons 1.11.3 (174 files), Feather (33 StudentPortal files), Simple Line Icons + Material Design Icons (portals).
- **Bootstrap:** backend = 5.3.3; portals = legacy bundled Bootstrap + MDL (two generations coexist).
- **jQuery 3.6** hard dependency (Select2, toggles, inline scripts).
- Present-but-unlinked: `adminlte.rtl.css`, `adminlte.min.css`, stale `adminlte_26_12_2025.css`.
- i18n: only **11 of 3718 blade files** use `__()`/`@lang`; **`₹` hardcoded in 290 files**.

---

## B. ADM — mobile_school / "primeadmin" (`/Users/bkwork/Herd/mobile_school`)

- `package.json` — expo ~54.0.33, RN 0.81.5, react 19.1.0, expo-router ~6, reanimated ~4.1.1, drawer+bottom-tabs, haptics, image-picker, datetimepicker. **No i18n, no form lib, no FlashList, no toast lib.**
- `app.json` — `newArchEnabled`, `reactCompiler`, `typedRoutes`, `userInterfaceStyle:"automatic"`, portrait-locked. `assets/images/` still has **Expo template leftovers** (react-logo*).
- `constants/theme.ts` — Clean tokens: Colors light/dark, Spacing 4pt, Typography, Shadows, BorderRadius, Fonts; real custom dark palette.
- `constants/menu-config.ts` — 9 `isBuilt:false` placeholder items; **accent colors hardcoded hex** L32-61.
- `components/ui/` — `AppButton` (4 variants, loading; **no accessibilityRole** button.tsx:65-78), `AppInput` (password toggle, **eye has no a11y label** input.tsx:76-88), `DateTimePickerField` (platform-branched, good), `Collapsible`+`IconSymbol` (**dead template code**).
- `components/navigation/` — `app-header` (console.log L31, icon buttons unlabeled), `screen-header`, `drawer-content` (active state, "Soon" badges, `console.log('[DrawerContent] Rendered')` L22).
- `hooks/use-refresh.ts` — **silently swallows errors** (`catch {}` L19) → failed refresh looks successful.
- `store/auth-store.tsx` / `utils/api.ts` — robust (SecureStore token, 15s timeout, `ApiError`) but **`console.log` of auth'd request/response bodies** api.ts:88, auth-store:127.
- Screens: `(app)/index.tsx` dashboard **hardcoded stats** L66-69, **fake `setTimeout(500)` refresh** L31, 2/4 quick actions inert; `(auth)/credentials.tsx` **"Forgot Password?" dead** L132; `complaints/*` = strong real reference (pagination, filters, detail/manage tabs) but **pagination via manual scroll-offset on a ScrollView** list.tsx:250-256; `complaints/create.tsx` validation via **blocking `Alert` one-at-a-time** L156-169; `staff-leave/index.tsx` **fully mocked** L47-59.
- **Accessibility:** grep = **0** `accessibilityLabel/Role/Hint` across `app/`+`components/`.
- **Lists:** grep = **0** `FlatList`/`FlashList`.
- **Error boundaries:** grep = **0** `ErrorBoundary`.
- **Dark-mode leaks:** hardcoded surface hex `attendance/index.tsx:81`, `complaints/[id].tsx:722`, `create.tsx:602`, `staff-attendance/mark.tsx:513`.
- **i18n:** none; `en-GB` locale hardcoded `complaints/list.tsx:365`; duplicate date formatters (`utils/date-format.ts` vs inline).

---

## C. STU — mobile_student / "primeapp" (`/Users/bkwork/Herd/mobile_student`)

- `app.json` — `userInterfaceStyle:"automatic"`, newArch, reactCompiler, typedRoutes; only declared permission is `RECORD_AUDIO` (odd).
- `app/_layout.tsx` — Deep routes manually enumerated L33-57 (brittle). `store/theme-store.ts` defaults `'light'` L37, **does not read device scheme** despite app.json `automatic`.
- `constants/theme.ts` — complete light+dark tokens; `surfaceSecondary:#f5f5f5` (drift vs web `#f8fafc`).
- `constants/menu-config.ts` — role menus (student/parent/teacher); teacher items `isBuilt:false` L176,182; **accent colors inline hex** L42-197.
- `store/auth-store.ts` — role architecture + parent child-switch server-sync-first L208-227 (good); session restored w/o token re-validation L91.
- `components/ui/` — `AppButton` (no size/icon, no a11y), `AppInput` (no a11y label), `date-picker-modal.tsx` **hardcodes `Colors.light` L14 (no dark)**, `collapsible`/`icon-symbol` dead template.
- `components/navigation/app-header.tsx` — **notification bell has no `onPress` (dead) L65**; `drawer-content.tsx` **hardcodes `Colors.light` L52 (drawer never darkens)**.
- `components/dashboard/` — `overview-card` (press-scale micro-interaction L47), `detail-modal` (bottom sheet), `today-schedule-preview` (**`TimelineDot` hardcodes Colors.light L88**).
- Screens (40 route files, ~21,882 LOC). Student & parent dashboards personal/alive; **teacher dashboard = hardcoded `TEACHER_SCHEDULE`/`TEACHER_INFO` dummy** `(app)/index.tsx:48-54`. `leave/apply.tsx` strong form (business-rule validation L75-105). `login.tsx` ships **demo string "Try: ACT-07_A_ENG_TH"** L227-232.
- **Accessibility:** grep = **0** a11y props. `textMuted #94a3b8` on white ≈ 2.6:1 (fails AA) yet default for captions.
- **Dark mode:** **27 files hardcode `const C = Colors.light`** (e.g. `fees/index.tsx:18`, `results/index.tsx:15`, `timetable/index.tsx:17`, `performance/index.tsx:17`, `profile`, `settings`, drawer, date picker) → toggle only affects shell.
- **Color:** **514 raw hex literals**; off-palette shadow set + `SUBJECT_COLORS` `children/index.tsx:27-38`.
- **Feedback:** `utils/toast.ts` **Android-only, iOS no-op**; no skeletons (grep 0).
- **Lists:** only 2 `FlatList`; rest `ScrollView.map` (`library` 11×).
- **i18n:** none; `en-IN` + `₹` hardcoded (correct market, not localizable).

---

## D. Cross-cutting confirmations
- **Token palette identical** across all 3 apps (brand colors verified byte-for-byte); the two mobile `theme.ts` are near-identical. See `DESIGN_TOKEN_DRIFT.md`.
- **Zero accessibility instrumentation on mobile; no `:focus-visible` on web** — confirmed in all three independently.
- **No i18n framework in any app**; RTL unwired everywhere.
- **`ScrollView.map` over `FlatList`** is a shared mobile anti-pattern.
- **Screenshots folders present** (`prime_ai/tests/Browser/screenshots`, `Back_Prime_context_Tarun/Screenshots`, `tarun_prime_context/.../Screenshots`) — not individually opened image-by-image in this pass; code-level evidence was sufficient for scoring. Flagged for a follow-up visual pass if pixel-level review is required.
