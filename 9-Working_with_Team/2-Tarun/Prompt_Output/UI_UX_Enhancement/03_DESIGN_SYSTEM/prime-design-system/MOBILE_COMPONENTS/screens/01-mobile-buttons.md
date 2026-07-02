# 01 · Mobile Buttons — `AppButton`

Reference primitive: `components/ui/button.tsx` (both apps). Compose it; do not fork it.

---

## Visual description

A full-width (by default) pill/rounded-rect button, 52pt tall, centered label. Four
variants: **primary** (filled brand), **secondary** (outlined brand), **ghost**
(text-only brand), **danger** (filled red). Pressed state dims to 60% opacity. When
`loading`, the label is replaced by an `ActivityIndicator` in the label color.

```
┌───────────────────────────────────────┐   primary  (bg #6673fc, white text)
│                Save                    │
└───────────────────────────────────────┘
┌───────────────────────────────────────┐   secondary (outline #6673fc)
│               Cancel                   │
└───────────────────────────────────────┘
                Skip                          ghost (text only)
┌───────────────────────────────────────┐   danger (bg #e44f56, white text)
│               Delete                   │
└───────────────────────────────────────┘
```

---

## Recommended composition

The primitive already exists — most screens just call it:

```tsx
<AppButton
  title="Save changes"
  onPress={handleSave}
  variant="primary"
  loading={isSaving}
  disabled={!isDirty}
  accessibilityRole="button"
  accessibilityLabel="Save changes"
  accessibilityState={{ disabled: !isDirty, busy: isSaving }}
/>
```

Non-full-width (e.g. side-by-side in a footer row):

```tsx
<View style={{ flexDirection: 'row', gap: Spacing.sm }}>
  <AppButton title="Cancel" variant="secondary" fullWidth={false}
             style={{ flex: 1 }} onPress={close}
             accessibilityRole="button" accessibilityLabel="Cancel" />
  <AppButton title="Confirm" variant="primary" fullWidth={false}
             style={{ flex: 1 }} onPress={confirm}
             accessibilityRole="button" accessibilityLabel="Confirm" />
</View>
```

### Recommended enhancements to the primitive (add once, reuse everywhere)

The current `AppButton` lacks **sizes**, an **icon slot**, and explicit a11y props.
Extend it in `components/ui/button.tsx` rather than styling ad-hoc at call sites:

```tsx
// proposed prop additions — pseudo-code
interface AppButtonProps {
  title: string;
  onPress: () => void;
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';         // NEW — height 40 / 52 / 60 ; sm still ≥44 via hitSlop
  icon?: keyof typeof MaterialIcons.glyphMap;  // NEW — leading icon
  iconPosition?: 'left' | 'right';   // NEW
  disabled?: boolean;
  loading?: boolean;
  fullWidth?: boolean;
  accessibilityLabel?: string;       // NEW — defaults to title
}

// inside render — icon slot + a11y wired on the Pressable:
<Pressable
  onPress={onPress}
  disabled={disabled || loading}
  accessibilityRole="button"
  accessibilityLabel={accessibilityLabel ?? title}
  accessibilityState={{ disabled: disabled || loading, busy: loading }}
  hitSlop={size === 'sm' ? 6 : 0}    // guarantee 44pt target for small size
  style={({ pressed }) => [
    styles.base,
    sizeMap[size ?? 'md'],
    { backgroundColor: pressed ? colors.primaryDark : vs.bg, borderColor: vs.border },
    fullWidth && styles.fullWidth,
    (pressed || disabled) && styles.dimmed,
  ]}
>
  {loading ? <ActivityIndicator color={vs.textColor} size="small" />
    : <View style={styles.row}>
        {icon && iconPosition !== 'right' &&
          <MaterialIcons name={icon} size={18} color={vs.textColor} />}
        <Text style={[styles.text, { color: vs.textColor }]}>{title}</Text>
        {icon && iconPosition === 'right' &&
          <MaterialIcons name={icon} size={18} color={vs.textColor} />}
      </View>}
</Pressable>
```

---

## Color token usage

| Part | Token |
|------|-------|
| primary bg / secondary+ghost text | `colors.primary` (`#6673fc`) |
| **pressed** primary bg | `colors.primaryDark` (`#545ed6`) — use pressed state, don't dim only |
| danger bg | `colors.danger` (`#e44f56`) |
| filled-button text | `#ffffff` (on-brand contrast, ~4.7:1) |
| outline / ghost border+text | `colors.primary` |
| disabled | 60% opacity of the variant (existing `styles.dimmed`) |

Never hardcode `#6673fc` at the call site — it comes from `colors` inside the primitive.

---

## Spacing & typography

- Height **52** (default) — already ≥ 44pt. `sm` size (40) needs `hitSlop` to stay ≥ 44.
- Horizontal padding `Spacing.lg` (24); icon↔label gap `Spacing.sm` (8).
- Label: `Typography.label` at 16px / weight 600.
- `BorderRadius.lg` (12) corners; border width 1.5 for outlined variants.
- Stack full-width buttons with `Spacing.sm`–`md` vertical gap; footer button rows use `gap: Spacing.sm`.

---

## Accessibility notes

- `accessibilityRole="button"` on every button (the primitive should set it internally).
- `accessibilityLabel` — required when the title is ambiguous or icon-only; defaults to `title`.
- `accessibilityState={{ disabled, busy: loading }}` so screen readers announce state.
- **44×44pt minimum** touch target — enforce with `hitSlop` for `sm` size.
- Do not rely on color alone to signal danger — the word ("Delete") + red both present.
- Provide a **pressed** visual (bg → `primaryDark`), not just opacity, for clearer feedback.

---

## Dark-mode note

`AppButton` already reads `colors = Colors[useColorScheme() ?? 'light']`. Keep it that
way — never introduce `const C = Colors.light`. White label text stays white in both
modes (brand fills are dark enough); the outline/ghost text tracks `colors.primary`,
which is theme-safe.
