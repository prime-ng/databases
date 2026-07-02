# 09 · Empty, Error & Loading States

The states that carry the audit's sharpest findings: **no skeletons** (blank while
loading), **dead-end errors** (no Retry), and **iOS-silent toasts**. These patterns are
reused by list screens (04), dashboards (06–08), and forms (05).

---

## The five states

| State | When | Must contain |
|-------|------|--------------|
| **Loading** | data in flight | **Skeleton** shimmer (not a blank screen or bare spinner) |
| **Empty** | success, zero items | icon + title + message + optional **CTA** |
| **No-results** | filter/search yields nothing | icon + "No matches" + **Clear filters** action |
| **Error** | fetch/mutation failed | icon + message + **Retry** (never a dead end) |
| **Permission-denied** | role/tenancy blocks access | icon + explanation + safe way back (RoleGuard) |

---

## Shared `StateView` (build once, reuse)

```tsx
function StateView({ icon, title, message, tone = 'neutral', action }) {
  const colors = useTheme();                 // or Colors[useColorScheme() ?? 'light']
  const accent = tone === 'error' ? colors.danger
               : tone === 'success' ? colors.success : colors.textSecondary;
  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center',
                   padding: Spacing.xl, gap: Spacing.md }}
          accessibilityLiveRegion="polite">
      <View style={{ width: 64, height: 64, borderRadius: BorderRadius.full,
                     alignItems: 'center', justifyContent: 'center',
                     backgroundColor: `${accent}18` }}>
        <MaterialIcons name={icon} size={32} color={accent} />
      </View>
      <Text accessibilityRole="header"
            style={[Typography.h4, { color: colors.text, textAlign: 'center' }]}>{title}</Text>
      {message && (
        <Text style={[Typography.body, { color: colors.textSecondary, textAlign: 'center' }]}>
          {message}
        </Text>
      )}
      {action && (
        <AppButton title={action.label} onPress={action.onPress} fullWidth={false}
                   variant={tone === 'error' ? 'primary' : 'secondary'}
                   accessibilityLabel={action.label} style={{ marginTop: Spacing.sm }} />
      )}
    </View>
  );
}
```

### Empty

```tsx
<StateView icon="inbox" title="No homework yet"
  message="Assignments from your teachers will show up here."
  action={{ label: 'Refresh', onPress: refetch }} />
```

### No-results

```tsx
<StateView icon="search-off" title="No matches"
  message={`Nothing matches “${query}”.`}
  action={{ label: 'Clear filters', onPress: clearFilters }} />
```

### Error (recoverable — audit: no dead ends)

```tsx
<StateView icon="error-outline" tone="error"
  title="Couldn't load"
  message="Check your connection and try again."
  action={{ label: 'Retry', onPress: refetch }} />
```

### Permission-denied (RoleGuard)

```tsx
// wrap protected screens; render a safe fallback, never a crash/blank
<RoleGuard allow={['Teacher', 'Admin']} fallback={
  <StateView icon="lock" title="Not available"
    message="You don't have access to this section."
    action={{ label: 'Go back', onPress: () => router.back() }} />
}>
  <MarksScreen />
</RoleGuard>
```

### Loading — skeleton, not blank

```tsx
function CardSkeleton() {
  const colors = useTheme();
  return (
    <View accessibilityElementsHidden importantForAccessibility="no-hide-descendants"
          style={{ padding: Spacing.md, borderRadius: BorderRadius.xl,
                   backgroundColor: colors.surface, ...Shadows.sm, gap: Spacing.sm }}>
      <View style={{ width: 36, height: 36, borderRadius: BorderRadius.md, backgroundColor: colors.surfaceSecondary }} />
      <View style={{ height: 18, width: '50%', borderRadius: 4, backgroundColor: colors.surfaceSecondary }} />
      <View style={{ height: 12, width: '70%', borderRadius: 4, backgroundColor: colors.surfaceSecondary }} />
    </View>
  );
}
```

> Optional shimmer: animate opacity 0.5→1 with `Animated`/`reanimated`, **gated behind**
> `AccessibilityInfo.isReduceMotionEnabled()` (see 03). A static grey block is a fine
> fallback — the point is *shape*, not blankness.

---

## Cross-platform toast / feedback (audit: iOS silent)

`ToastAndroid` only exists on Android — on iOS it's a no-op, so users get **no feedback**.
Use a shared, platform-safe helper (in-app snackbar preferred; `Alert` as a last resort):

```tsx
export function notify(message: string) {
  if (Platform.OS === 'android') {
    ToastAndroid.show(message, ToastAndroid.SHORT);
  } else {
    // iOS: in-app snackbar via a global store/provider (preferred),
    // or fall back to Alert so the user actually sees it.
    showSnackbar(message);           // e.g. useSnackbarStore().show(message)
  }
}
```

The in-app snackbar should carry `accessibilityLiveRegion="polite"` (or
`AccessibilityInfo.announceForAccessibility(message)`) so VoiceOver/TalkBack speak it.

---

## Color token usage

| Part | Token |
|------|-------|
| neutral icon (empty/no-results) | `colors.textSecondary` on `${textSecondary}18` |
| error icon | `colors.danger` on `${danger}18` |
| success (all-caught-up) | `colors.success` |
| title | `colors.text`; message | `colors.textSecondary` (not `textMuted` at body size) |
| skeleton blocks | `colors.surfaceSecondary` on `colors.surface` |

---

## Spacing & typography

- Container centered, `padding: Spacing.xl`, `gap: Spacing.md`. Icon bubble 64px, glyph 32.
- Title `Typography.h4`; message `Typography.body`, `textAlign: 'center'`.
- CTA is a non-full-width `AppButton` with `marginTop: Spacing.sm`.

---

## Accessibility notes

- Wrap the state container in `accessibilityLiveRegion="polite"` so it's announced on appear.
- Title: `accessibilityRole="header"`. Error/Retry button: role `button` + clear label.
- **Skeletons must be hidden** from the reader (`accessibilityElementsHidden` /
  `importantForAccessibility="no-hide-descendants"`) so it doesn't read placeholder noise.
- Toast/snackbar must announce via live region on **both** platforms.
- CTA ≥44pt; never present an error without a way forward.

---

## Dark-mode note

`colors` via `useTheme()` / `Colors[useColorScheme() ?? 'light']` — never `const C =
Colors.light`. Icon bubbles use `${accent}18` and skeletons use `surfaceSecondary` over
`surface`, so every state renders correctly in dark mode. Do not special-case light vs
dark with literal hexes.
