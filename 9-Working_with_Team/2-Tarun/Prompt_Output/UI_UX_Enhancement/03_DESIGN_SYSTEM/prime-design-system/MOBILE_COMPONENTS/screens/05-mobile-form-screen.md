# 05 · Mobile Form Screen — Sectioned / Stepped Forms

Composes `AppInput` (02), `AppButton` (01), pickers, and `Collapsible`. Long forms are
**grouped into sections** (or steps); errors are **inline per field**; the submit action
is **sticky** so it's always reachable.

---

## Visual description

A scrollable form under a safe-area header. Fields are grouped under section titles
(e.g. "Personal", "Contact", "Documents"). Each field shows inline error text + icon on
failure. A sticky footer holds the primary submit (and optional secondary). For long
flows, a stepper header (1·2·3) replaces sections.

```
┌ Add Student ───────────────────────────┐
│ PERSONAL                                │
│  Full name   [ Aarav Sharma        ]    │
│  DOB         [ 12 Apr 2015    📅   ]    │
│ CONTACT                                 │
│  Phone       [ 98•••••••• ]  ⚠ invalid  │  ← inline error, red + icon
│  Email       [ … ]                      │
│ DOCUMENTS                               │
│  [ 📎 Upload birth certificate ]        │
├─────────────────────────────────────────┤
│ [           Save student            ]   │  ← sticky footer
└─────────────────────────────────────────┘
```

---

## Recommended composition

```tsx
<SafeAreaView style={{ flex: 1, backgroundColor: colors.background }} edges={['top','bottom']}>
  <KeyboardAvoidingView style={{ flex: 1 }}
    behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>

    <ScrollView keyboardShouldPersistTaps="handled"
      contentContainerStyle={{ padding: Spacing.md, paddingBottom: Spacing.xxl }}>

      <FormSection title="Personal">
        <AppInput label="Full name" value={name} onChangeText={setName}
                  error={errors.name} autoCapitalize="words" />
        <DateField label="Date of birth" value={dob} onChange={setDob} error={errors.dob} />
      </FormSection>

      <FormSection title="Contact">
        <AppInput label="Phone" leftIcon="phone" keyboardType="phone-pad"
                  inputMode="tel" value={phone} onChangeText={setPhone} error={errors.phone} />
        <AppInput label="Email" leftIcon="mail" keyboardType="email-address"
                  inputMode="email" autoCapitalize="none" value={email}
                  onChangeText={setEmail} error={errors.email} />
      </FormSection>

      <FormSection title="Documents">
        <PickerRow label="Birth certificate" onPress={pickDocument} filename={doc?.name} />
      </FormSection>
    </ScrollView>

    {/* sticky submit — outside ScrollView so it stays pinned */}
    <View style={{ padding: Spacing.md, borderTopWidth: StyleSheet.hairlineWidth,
                   borderTopColor: colors.border, backgroundColor: colors.surface }}>
      <AppButton title="Save student" onPress={submit}
                 loading={isSaving} disabled={!isValid}
                 accessibilityLabel="Save student"
                 accessibilityState={{ disabled: !isValid, busy: isSaving }} />
    </View>
  </KeyboardAvoidingView>
</SafeAreaView>
```

### Section wrapper

```tsx
function FormSection({ title, children }) {
  const colors = useTheme();
  return (
    <View style={{ marginBottom: Spacing.lg }}>
      <Text accessibilityRole="header"
            style={[Typography.label, { color: colors.textSecondary,
                    textTransform: 'uppercase', marginBottom: Spacing.sm }]}>
        {title}
      </Text>
      <View style={{ gap: Spacing.sm }}>{children}</View>
    </View>
  );
}
```

### Inline field error (text + icon)

Errors ride on `AppInput`'s `error` prop (see 02). For custom rows (pickers), render the
same treatment manually:

```tsx
{error && (
  <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 4 }}
        accessibilityLiveRegion="polite" accessibilityRole="alert">
    <MaterialIcons name="error-outline" size={14} color={colors.danger} />
    <Text style={[Typography.caption, { color: colors.danger }]}>{error}</Text>
  </View>
)}
```

Never surface validation via `Alert`. On submit, scroll to and focus the **first**
invalid field.

### Stepped variant

For long flows use a step header + per-step `FormSection`s, keep the same sticky footer
("Next" / "Back" / final "Submit"), and validate each step before advancing.

### Document / image picker note

Use `expo-document-picker` / `expo-image-picker`. Always **request permission first** and
handle denial with a recoverable message (link to Settings), not a silent no-op. Show the
picked filename/thumbnail as confirmation, and a remove (✕) affordance with `hitSlop`.

---

## Color token usage

| Part | Token |
|------|-------|
| screen bg | `colors.background` |
| section title | `colors.textSecondary` |
| sticky footer bg / top border | `colors.surface` / `colors.border` |
| field error | `colors.danger` (+ icon) |
| picker filled/attached state | `colors.success` accent |

---

## Spacing & typography

- Screen padding `Spacing.md`; section `marginBottom: Spacing.lg`; field `gap: Spacing.sm`.
- `paddingBottom: Spacing.xxl` on the ScrollView so the last field clears the sticky footer.
- Section title `Typography.label` uppercase; field labels via `AppInput`.

---

## Accessibility notes

- Section titles: `accessibilityRole="header"`.
- Inline errors: `accessibilityLiveRegion="polite"` + `accessibilityRole="alert"`.
- Submit button: `accessibilityState={{ disabled, busy }}`; footer control ≥44pt (52 default).
- `KeyboardAvoidingView` + `keyboardShouldPersistTaps="handled"` so taps on buttons work
  while the keyboard is open.
- Focus-order should follow visual order; wire `returnKeyType="next"` + ref chaining.

---

## Dark-mode note

Resolve `colors` via `useTheme()` / `Colors[useColorScheme() ?? 'light']` at the top of
the screen and every sub-component (`FormSection`, error rows). Never `const C =
Colors.light`. The sticky footer uses `colors.surface` + `colors.border`, which invert
correctly for dark mode.
