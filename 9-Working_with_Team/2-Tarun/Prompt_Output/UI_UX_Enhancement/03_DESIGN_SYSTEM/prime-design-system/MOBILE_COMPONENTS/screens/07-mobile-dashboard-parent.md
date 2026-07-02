# 07 · Parent Dashboard (Home)

App: `mobile_student` (`primeapp`, parent role). Reuses the student dashboard pieces
(06) but scoped to a **selected child**. The defining element is a **single shared child
switcher** at the top — one component, not three copies.

---

## Visual description

```
┌ Parent · Rao family ──────────────────────┐
│ 👧 Diya (VII-A)  ▾   [👦 Kabir] [＋ Add]  │  ← child switcher (ONE component)
├───────────────────────────────────────────┤
│ Overview — Diya                            │
│ ┌ Attendance ┐ ┌ Fees due  ┐               │
│ │ 91%        │ │ ₹8,000    │               │
│ └────────────┘ └───────────┘               │
│ ┌ Homework   ┐ ┌ Avg score ┐               │
│ │ 1 pending  │ │ 88%       │               │
│ └────────────┘ └───────────┘               │
│ Fee status: ⚠ ₹8,000 due 10 Jul  [Pay]     │
│ Notices                                    │
│  • PTM on 12 Jul · • Holiday 15 Jul        │
│ Calendar → this week's events              │
└───────────────────────────────────────────┘
```

Switching child re-scopes **every** KPI, fee, notice, and calendar block below.

---

## Recommended composition — the child switcher (build ONCE)

The audit's parent-side concern: avoid duplicating child-selection logic per screen.
Put the selected child in a store; render one `ChildSwitcher`; every screen reads
`activeChild` from the same store.

```tsx
// store: useChildStore -> { children, activeChildId, setActiveChild }
function ChildSwitcher() {
  const colors = useTheme();
  const { children, activeChildId, setActiveChild } = useChildStore();
  return (
    <FlatList
      horizontal showsHorizontalScrollIndicator={false}
      data={children}
      keyExtractor={c => String(c.id)}
      contentContainerStyle={{ gap: Spacing.sm, paddingVertical: Spacing.sm }}
      renderItem={({ item }) => {
        const active = item.id === activeChildId;
        return (
          <Pressable
            onPress={() => setActiveChild(item.id)}
            accessibilityRole="button"
            accessibilityState={{ selected: active }}
            accessibilityLabel={`View ${item.name}, class ${item.className}`}
            style={{ flexDirection: 'row', alignItems: 'center', gap: Spacing.sm,
                     paddingHorizontal: Spacing.md, minHeight: 44,
                     borderRadius: BorderRadius.full,
                     backgroundColor: active ? `${colors.primary}18` : colors.surfaceSecondary,
                     borderWidth: 1.5, borderColor: active ? colors.primary : 'transparent' }}
          >
            <Avatar uri={item.photo} name={item.name} size={28} />
            <Text style={[Typography.label,
                   { color: active ? colors.primary : colors.text }]}>{item.name}</Text>
          </Pressable>
        );
      }}
    />
  );
}
```

### Child-scoped body

```tsx
const child = useChildStore(s => s.activeChild);
// re-fetch keyed on child.id so KPIs always match the selected child
const { data } = useChildDashboard(child.id);

<OverviewGrid>              {/* same OverviewCard grid as file 06, data = child.* */}
  <OverviewCard title="Attendance" value={data.attendancePct} accentColor={colors.success} … />
  <OverviewCard title="Fees due"  value={money(data.feeDue)} accentColor={colors.warning}
                onPress={() => router.push({ pathname: '/fees', params: { childId: child.id } })} />
  …
</OverviewGrid>
```

### Fee status block

Accent (not fill): `surface` card + warning/danger icon + amount + due date + **Pay** button.

```tsx
<View style={{ flexDirection:'row', alignItems:'center', gap: Spacing.md,
               padding: Spacing.md, borderRadius: BorderRadius.lg,
               backgroundColor: colors.surface, ...Shadows.sm }}>
  <MaterialIcons name="account-balance-wallet" size={20} color={colors.warning} />
  <View style={{ flex: 1 }}>
    <Text style={[Typography.body, { color: colors.text }]}>{money(feeDue)} due</Text>
    <Text style={[Typography.caption, { color: colors.textSecondary }]}>Due {dueDate}</Text>
  </View>
  <AppButton title="Pay" size="sm" fullWidth={false} onPress={payFees}
             accessibilityLabel={`Pay ${money(feeDue)} for ${child.name}`} />
</View>
```

### Notices & calendar

- **Notices**: a `FlatList` of notice rows (icon + title + date), tap → detail. Not `.map`.
- **Calendar**: this-week strip or agenda list scoped to the child (events, exams, holidays).

---

## Color token usage

| Part | Token |
|------|-------|
| active child chip | text `colors.primary` on `${primary}18`, border `colors.primary` |
| inactive child chip | `colors.surfaceSecondary`, text `colors.text` |
| fee due accent | `colors.warning` (or `danger` if overdue) |
| notices icon | `colors.info` |
| KPI accents | success / warning / info / primary (as 06) |

---

## Spacing & typography

- Switcher `gap: Spacing.sm`, chip `minHeight: 44`, `BorderRadius.full`.
- Body section gap `Spacing.lg`; card grid gap `Spacing.sm`.
- Child name in chip `Typography.label`; section titles `Typography.label`/`h3`.

---

## Accessibility notes

- Child chips: `accessibilityRole="button"` + `accessibilityState={{ selected }}` so the
  active child is announced — selection must not be color-only.
- Chips ≥44pt; horizontal `FlatList` keeps them reachable.
- Announce the scoped context (e.g. section header "Overview — Diya") so a screen-reader
  user knows which child the numbers belong to after switching.

---

## Dark-mode note

`colors` via `useTheme()`; never `const C = Colors.light`. Active/inactive chip
backgrounds are `${primary}18` / `surfaceSecondary`, both theme-derived, so the switcher
reads correctly in dark mode. One switcher component means one place to keep dark-mode
correct.
