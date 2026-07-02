# Prime Mobile Reference (React Native / Expo)

> The mobile half of the Prime Design System. Covers the two Expo apps —
> **mobile_school** (`primeadmin`) and **mobile_student** (`primeapp`).
> Both run **Expo SDK 54 / RN 0.81 / TypeScript / expo-router / MaterialIcons**
> and share the same `constants/theme.ts` token set.
> Tokens live in [MOBILE_TOKENS.md](./MOBILE_TOKENS.md); screen patterns live in
> [`screens/`](./screens).

---

## What this reference is (and is not)

This is a **composition guide**, not a component library. Every pattern here is
built by **composing the primitives that already ship in each app** under
`components/ui/*` and `components/dashboard/*`. There is no new package to install,
no design-system npm dependency, and no `.tsx` to copy wholesale — read the pattern,
then wire the existing primitives together.

**Existing primitives (already in both apps unless noted):**

| Primitive | Path | Notes |
|-----------|------|-------|
| `AppButton` | `components/ui/button.tsx` | Pressable + Text/ActivityIndicator, variants |
| `AppInput` | `components/ui/input.tsx` | label / error / hint / leftIcon / password toggle |
| `Collapsible` | `components/ui/collapsible.tsx` | disclosure section |
| `IconSymbol` | `components/ui/icon-symbol.tsx` | icon wrapper |
| Date pickers | `datetime-picker.tsx` (admin) / `date-picker-modal.tsx` (student) | |
| `OverviewCard` | `components/dashboard/overview-card.tsx` (student) | accent card — the card pattern |
| `FeatureCard` | `components/feature-card.tsx` (student) | quick-link tile |

> If a "card" or "badge" primitive is not yet present in an app, build it once from
> `View` + tokens following [`screens/03-mobile-cards.md`](./screens/03-mobile-cards.md)
> and reuse it — do **not** pull in a UI kit.

---

## The three non-negotiable mandates

These come straight from the mobile audit. Every pattern file restates them, but they
are global — apply them to **all** new mobile code.

### 1. Accessibility on every interactive element
The audit found **0 accessibility props** across the current screens. That is the
single biggest gap. Every touchable, input, and status surface MUST carry:

- `accessibilityRole` — `"button"`, `"link"`, `"header"`, `"image"`, `"switch"`, etc.
- `accessibilityLabel` — a human sentence, especially for icon-only controls.
- `accessibilityState` — `{{ disabled, busy, selected, checked, expanded }}` where relevant.
- **44×44 pt minimum touch target** (use `hitSlop` to reach it without bloating layout).
- Status must be **color + icon + text**, never color alone.
- `textMuted` (`#94a3b8`) fails WCAG AA on white below 18px — use it **only** for text
  ≥ 18px (or bold ≥ 14px). For body/caption use `textSecondary` (`#475569`).

### 2. Dark mode via the theme hook — never hardcode
The audit found dark mode broken by the anti-pattern `const C = Colors.light`. That
pins the whole screen to the light palette. **Never** reference `Colors.light` /
`Colors.dark` directly in a component.

```tsx
// ❌ BROKEN — ignores the user's theme
const C = Colors.light;

// ✅ student app — reactive to the theme store
const colors = useTheme();            // hooks/use-theme.ts → Colors[theme]

// ✅ admin app — reactive to OS scheme
const scheme = useColorScheme() ?? 'light';
const colors = Colors[scheme];
// or per-property:
const bg = useThemeColor({}, 'background');
```

Read every color off `colors.*` so the same component renders correctly in both modes.

### 3. Lists use FlatList / FlashList — never `ScrollView` + `.map()`
The audit found long lists rendered as `ScrollView` mapping an array. That mounts every
row at once (jank, memory, no recycling). Any list that can exceed ~10 rows MUST use
`FlatList` (or `@shopify/flash-list` where already available) with `keyExtractor`,
`onEndReached` pagination, and a skeleton loading state. See
[`screens/04-mobile-list-screen.md`](./screens/04-mobile-list-screen.md).

**Also globally required (from the audit):**

- **Skeletons, not blank screens** — show shimmer placeholders while loading.
- **Cross-platform feedback** — `ToastAndroid` is silent on iOS. Use a shared
  in-app toast/snackbar (or `Alert` fallback) so iOS users get feedback too.
- **Errors must recover** — every error state needs a **Retry**; no dead ends.
- **Teacher/other dashboards must bind real data** — the audit found hardcoded
  placeholders; wire to services/store.

---

## How to read a screen file

Each file in `screens/` follows the same shape:

1. **Visual description** — what the screen looks like.
2. **Recommended composition** — pseudo-code JSX wiring the existing primitives.
3. **Color token usage** — which `colors.*` token goes where.
4. **Spacing & typography** — which `Spacing.*` / `Typography.*` to apply.
5. **Accessibility notes** — roles, labels, touch targets, contrast.
6. **Dark-mode note** — the `useTheme()` / `useThemeColor()` reminder.

Pseudo-code is illustrative — adapt prop names to the primitive as it exists in the
target app. Do not ship `.tsx` copied from here verbatim without wiring real data and
a11y props.

---

## Screen index

| File | Screen / pattern |
|------|------------------|
| [01-mobile-buttons.md](./screens/01-mobile-buttons.md) | AppButton variants, sizes, icons, loading |
| [02-mobile-inputs.md](./screens/02-mobile-inputs.md) | AppInput, validation, keyboard, password |
| [03-mobile-cards.md](./screens/03-mobile-cards.md) | Accent cards / OverviewCard composition |
| [04-mobile-list-screen.md](./screens/04-mobile-list-screen.md) | FlatList list screens |
| [05-mobile-form-screen.md](./screens/05-mobile-form-screen.md) | Sectioned forms |
| [06-mobile-dashboard-student.md](./screens/06-mobile-dashboard-student.md) | Student home |
| [07-mobile-dashboard-parent.md](./screens/07-mobile-dashboard-parent.md) | Parent home + child switcher |
| [08-mobile-dashboard-teacher.md](./screens/08-mobile-dashboard-teacher.md) | Teacher home |
| [09-mobile-empty-error-states.md](./screens/09-mobile-empty-error-states.md) | Empty / error / loading states |
