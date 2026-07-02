# 02 · Mobile Inputs — `AppInput`

Reference primitive: `components/ui/input.tsx` (both apps). Compose it; do not fork it.

---

## Visual description

A labeled field: label above, a rounded row (52pt tall, `surfaceSecondary` fill, 1.5
border) containing an optional left icon, the `TextInput`, and — for password fields —
a trailing eye toggle. Below the row: an error message (danger) **or** a hint (muted).
The border turns `danger` when `error` is set.

```
Email address
┌──────────────────────────────────────────┐
│  ✉  you@school.edu                        │
└──────────────────────────────────────────┘
We'll never share your email.

Password
┌──────────────────────────────────────────┐
│  🔒  ••••••••                        👁    │
└──────────────────────────────────────────┘
Password must be at least 8 characters.        ← danger colored when error
```

---

## Recommended composition

```tsx
<AppInput
  label="Email address"
  leftIcon="mail"
  value={email}
  onChangeText={setEmail}
  keyboardType="email-address"
  inputMode="email"
  autoCapitalize="none"
  autoComplete="email"
  textContentType="emailAddress"
  error={errors.email}                 // inline — NOT Alert()
  hint={!errors.email ? "We'll never share your email." : undefined}
  accessibilityLabel="Email address"
/>

<AppInput
  label="Password"
  leftIcon="lock"
  value={password}
  onChangeText={setPassword}
  secureTextEntry                       // enables the eye toggle
  autoComplete="password"
  textContentType="password"
  error={errors.password}
/>
```

Wrap forms so the keyboard never covers the active field:

```tsx
<KeyboardAvoidingView
  behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
  style={{ flex: 1 }}
>
  <ScrollView keyboardShouldPersistTaps="handled"
              contentContainerStyle={{ padding: Spacing.md }}>
    {/* AppInput fields … */}
  </ScrollView>
</KeyboardAvoidingView>
```

### Enhancement: announce errors + label the eye toggle

The current toggle `Pressable` has no label, and errors are visual-only. Add:

```tsx
// eye toggle — pseudo-code
<Pressable
  onPress={() => setShowPassword(v => !v)}
  hitSlop={8}                                  // 20px icon + pad → ≥44pt
  accessibilityRole="button"
  accessibilityLabel={showPassword ? 'Hide password' : 'Show password'}
  accessibilityState={{ selected: showPassword }}
>
  <MaterialIcons name={showPassword ? 'visibility' : 'visibility-off'}
                 size={20} color={colors.textMuted} />
</Pressable>

// error text — live region so it's announced
{hasError && (
  <Text accessibilityLiveRegion="polite" accessibilityRole="alert"
        style={[styles.helperText, { color: colors.danger }]}>
    {error}
  </Text>
)}

// the field itself
<TextInput
  accessibilityLabel={label}
  accessibilityState={{ /* invalid handled via label text */ }}
  … />
```

---

## Keyboard types / input modes

| Field | keyboardType | inputMode | autoComplete / textContentType |
|-------|--------------|-----------|--------------------------------|
| Email | `email-address` | `email` | `email` / `emailAddress` |
| Phone | `phone-pad` | `tel` | `tel` / `telephoneNumber` |
| Numeric (amount, roll no.) | `number-pad` / `decimal-pad` | `numeric` / `decimal` | — |
| OTP | `number-pad` | `numeric` | `sms-otp` (Android) / `oneTimeCode` (iOS) |
| Password | default | — | `password` |

Set `returnKeyType="next"` / `"done"` and move focus with a `ref` chain for multi-field forms.

---

## Inline validation (never `Alert`)

Validate on blur and on submit; surface the message through the `error` prop under the
field — **not** a modal `Alert`. `Alert` blocks the flow, hides which field failed, and
is silent to screen-reader flow context. Clear the error as the user corrects the value.

---

## Color token usage

| Part | Token |
|------|-------|
| label | `colors.textSecondary` (`#475569`) |
| field fill | `colors.surfaceSecondary` (align to `#f8fafc`, drift D1) |
| border (default) | `colors.border` (`#e2e8f0`) |
| border (error) | `colors.danger` (`#e44f56`) |
| typed text | `colors.text` |
| placeholder / left icon | `colors.textMuted` (decorative — OK) |
| error text | `colors.danger` |
| hint text | ⚠️ `colors.textMuted` fails contrast at 12px — prefer `colors.textSecondary` for hints |

---

## Spacing & typography

- Row height **52** (≥44pt target). Horizontal padding `Spacing.md` (16).
- Label `Typography.label`, `marginBottom: Spacing.xs`.
- Left icon `size 20`, `marginRight: Spacing.sm`.
- Helper text `Typography.caption`, `marginTop: 4`. Field container `marginBottom: Spacing.md`.

---

## Accessibility notes

- Give the `TextInput` an `accessibilityLabel` (mirror the visible label).
- Icon-only eye toggle **must** have `accessibilityLabel` ("Show/Hide password") + `hitSlop` to 44pt.
- Announce errors with `accessibilityLiveRegion="polite"` + `accessibilityRole="alert"`.
- Do not signal error by border color alone — the message text is mandatory.
- Ensure placeholder is not the only label (placeholders vanish on input).

---

## Dark-mode note

`AppInput` already resolves `colors = Colors[useColorScheme() ?? 'light']`. All fills,
borders, and text read off `colors.*`, so it themes correctly — keep it that way and
never hardcode `Colors.light`. In dark mode the field fill becomes `#2a2a3d` and text
`#e2e8f0` automatically.
