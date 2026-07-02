# 08 · Teacher Dashboard (Home)

App: `mobile_school` (`primeadmin`, teacher role) — and/or teacher mode in `primeapp`.

> **Audit finding to fix:** the teacher home currently renders **hardcoded placeholder
> data**. This screen must be **wired to real services/store** (classes, timetable,
> pending tasks). No mock arrays in production render paths.

---

## Visual description

```
Good morning, Ms. Rao 👋            Fri, 4 Jul
───────────────────────────────────────────
Today's classes
● 09:00  VII-A · Mathematics   Room 12  LIVE
│ 11:00  VIII-B · Mathematics  Room 07
│ 13:00  VII-C · Mathematics   Room 03
───────────────────────────────────────────
Quick actions
[✔ Take attendance] [📝 Assign homework]
[🗒 Enter marks]     [💬 Message parents]
───────────────────────────────────────────
Pending tasks                        4
• 12 attendance not marked (VIII-B)   ›
• 3 homework to grade                 ›
• 1 leave request to approve          ›
```

---

## Recommended composition — bind real data

```tsx
function TeacherHome() {
  const colors = useTheme();                        // or Colors[useColorScheme() ?? 'light']
  const { data: today, isLoading, error, refetch } = useTeacherToday();   // REAL fetch
  const { data: tasks } = usePendingTasks();

  if (isLoading) return <DashboardSkeleton />;       // skeleton, not blank
  if (error)     return <ErrorState onRetry={refetch} />;   // recoverable, not dead-end

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: colors.background }} edges={['top']}>
      <FlatList
        data={today.classes}
        keyExtractor={c => String(c.id)}
        ListHeaderComponent={<><Greeting name={teacher.name} /><SectionTitle>Today's classes</SectionTitle></>}
        renderItem={({ item }) => <ClassRow period={item} />}   // shared timeline row (see 06)
        ListFooterComponent={<><QuickActions /><PendingTasks tasks={tasks} /></>}
        refreshControl={<RefreshControl refreshing={false} onRefresh={refetch}
                                        tintColor={colors.primary} />}
        contentContainerStyle={{ padding: Spacing.md, gap: Spacing.lg }}
      />
    </SafeAreaView>
  );
}
```

### Quick actions (2×2 grid)

```tsx
function QuickActions() {
  const colors = useTheme();
  const actions = [
    { icon: 'how-to-reg', label: 'Take attendance', accent: colors.success, to: '/attendance/take' },
    { icon: 'assignment', label: 'Assign homework', accent: colors.info,    to: '/homework/new' },
    { icon: 'grading',    label: 'Enter marks',     accent: colors.primary, to: '/marks' },
    { icon: 'forum',      label: 'Message parents', accent: colors.warning, to: '/messages' },
  ];
  return (
    <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: Spacing.sm }}>
      {actions.map(a => (
        <Pressable key={a.label} onPress={() => router.push(a.to)}
          accessibilityRole="button" accessibilityLabel={a.label}
          style={({ pressed }) => [
            { minWidth: '46%', flex: 1, minHeight: 72, padding: Spacing.md, gap: Spacing.xs,
              borderRadius: BorderRadius.lg, backgroundColor: colors.surface, ...Shadows.sm },
            pressed && { opacity: 0.9 },
          ]}>
          <View style={{ width: 36, height: 36, borderRadius: BorderRadius.md,
                         alignItems: 'center', justifyContent: 'center',
                         backgroundColor: `${a.accent}18` }}>
            <MaterialIcons name={a.icon} size={18} color={a.accent} />
          </View>
          <Text style={[Typography.label, { color: colors.text }]}>{a.label}</Text>
        </Pressable>
      ))}
    </View>
  );
}
```

### Pending tasks (real, actionable)

```tsx
<FlatList
  data={tasks}
  keyExtractor={t => t.id}
  ListEmptyComponent={<EmptyState icon="check-circle" title="All caught up"
                                   message="No pending tasks right now." />}
  renderItem={({ item }) => (
    <Pressable onPress={() => router.push(item.route)}
      accessibilityRole="button" accessibilityLabel={`${item.label}. ${item.count} items`}
      style={{ flexDirection:'row', alignItems:'center', gap: Spacing.md,
               paddingVertical: Spacing.md, minHeight: 48 }}>
      <MaterialIcons name={item.icon} size={20} color={item.accent} />
      <Text style={[Typography.body, { color: colors.text, flex: 1 }]}>{item.label}</Text>
      {item.count > 0 && <Badge count={item.count} color={colors.danger} />}
      <MaterialIcons name="chevron-right" size={20} color={colors.textMuted} />
    </Pressable>
  )}
/>
```

---

## Color token usage

| Part | Token |
|------|-------|
| screen bg | `colors.background` |
| class LIVE dot/label | `colors.success` |
| quick-action tiles | `surface` bg + `${accent}18` icon circle (attendance→success, homework→info, marks→primary, message→warning) |
| pending count badge | `colors.danger` on `${danger}18` |
| task labels | `colors.text` / meta `colors.textSecondary` |

---

## Spacing & typography

- Screen padding `Spacing.md`; section gap `Spacing.lg`; grid/task gap `Spacing.sm`.
- Quick-action tile `minHeight: 72`, icon circle 36; task row `minHeight: 48`.
- Greeting `Typography.h2`; section titles `Typography.label`; task labels `Typography.body`.

---

## Accessibility notes

- Quick-action tiles: `accessibilityRole="button"` + label; ≥44pt (72 tall here).
- Pending task rows: label includes the count ("3 homework to grade") — badge color isn't the only signal.
- Loading → `DashboardSkeleton`; error → `ErrorState` with Retry (no dead ends).
- Greeting / section titles: `accessibilityRole="header"`.

---

## Dark-mode note

Resolve `colors` via `useTheme()` / `Colors[useColorScheme() ?? 'light']`. Never `const C
= Colors.light` — this screen is a prime offender for the hardcoded-palette + hardcoded-
data pair; fix both together. Tiles use `surface` + `${accent}18`, badge uses
`${danger}18`, all theme-derived.
