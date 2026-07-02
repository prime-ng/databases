# 06 · Student Dashboard (Home)

App: `mobile_student` (`primeapp`). Composes `OverviewCard` (03), `FeatureCard`, and a
timeline. The goal is a **personal, alive** home — greeting, at-a-glance KPIs, today's
schedule, quick links — with **progressive disclosure**: card → detail modal → full screen.

---

## Visual description

```
Good morning, Aarav 👋              [VII-A]     ← greeting + class badge
───────────────────────────────────────────
Overview
┌ Attendance ┐ ┌ Fees        ┐
│ 87%        │ │ ₹12,500 due │              ← 2-col accent card grid
└────────────┘ └─────────────┘
┌ Homework   ┐ ┌ Avg. score  ┐
│ 3 pending  │ │ 82%         │
└────────────┘ └─────────────┘
───────────────────────────────────────────
Today                              Fri, 4 Jul
● 09:00  Mathematics   Room 12   ● LIVE
│ 10:00  Science       Room 07   (upcoming)
│ 11:00  English       Room 03
◦ 08:00  Assembly                (past, dimmed)
───────────────────────────────────────────
Quick links
[📚 Syllabus] [📝 Quizzes] [🏫 Attendance] [💬 Notices]
```

---

## Recommended composition

```tsx
<SafeAreaView style={{ flex: 1, backgroundColor: colors.background }} edges={['top']}>
  <FlatList                                 // FlatList, not ScrollView.map (audit)
    data={sections}                         // or a single ScrollView if content is fixed & short
    keyExtractor={s => s.key}
    renderItem={renderSection}
    ListHeaderComponent={<Greeting name={student.firstName} className={student.className} />}
    contentContainerStyle={{ padding: Spacing.md, gap: Spacing.lg }}
    refreshControl={<RefreshControl refreshing={refreshing} onRefresh={refetch}
                                    tintColor={colors.primary} />}
  />
</SafeAreaView>
```

### Greeting + class badge

```tsx
function Greeting({ name, className }) {
  const colors = useTheme();
  return (
    <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
                   marginBottom: Spacing.lg }}>
      <View>
        <Text style={[Typography.caption, { color: colors.textSecondary }]}>{greetingByHour()}</Text>
        <Text accessibilityRole="header"
              style={[Typography.h2, { color: colors.text }]}>{name} 👋</Text>
      </View>
      <View style={{ paddingHorizontal: Spacing.sm, paddingVertical: 4,
                     borderRadius: BorderRadius.full, backgroundColor: `${colors.primary}18` }}>
        <Text style={[Typography.label, { color: colors.primary }]}>{className}</Text>
      </View>
    </View>
  );
}
```

### Overview grid (accent cards)

```tsx
<View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: Spacing.sm }}>
  <OverviewCard icon="event-available" title="Attendance" value="87%"
    subtitle="13/15 present" accentColor={colors.success}
    onPress={() => setDetail('attendance')} />          {/* → DetailModal */}
  <OverviewCard icon="account-balance-wallet" title="Fees" value="₹12,500"
    subtitle="Due 10 Jul" accentColor={colors.warning} onPress={() => setDetail('fees')} />
  <OverviewCard icon="assignment" title="Homework" value="3" subtitle="pending"
    accentColor={colors.info} onPress={() => router.push('/homework')} />
  <OverviewCard icon="trending-up" title="Avg. score" value="82%" subtitle="this term"
    accentColor={colors.primary} onPress={() => router.push('/results')} />
</View>
```

### Today timeline (Live / upcoming / past)

```tsx
{schedule.map(period => {
  const state = periodState(period);       // 'live' | 'upcoming' | 'past'
  const dot = state === 'live' ? colors.success
            : state === 'past' ? colors.textMuted : colors.primary;
  return (
    <View key={period.id} style={{ flexDirection: 'row', gap: Spacing.md,
             opacity: state === 'past' ? 0.55 : 1 }}
          accessibilityRole="text"
          accessibilityLabel={`${period.time} ${period.subject}, ${period.room}${state==='live'?', live now':''}`}>
      <View style={{ width: 10, height: 10, borderRadius: 999, backgroundColor: dot, marginTop: 6 }} />
      <View style={{ flex: 1 }}>
        <Text style={[Typography.body, { color: colors.text }]}>{period.subject}</Text>
        <Text style={[Typography.caption, { color: colors.textSecondary }]}>
          {period.time} · {period.room}
        </Text>
      </View>
      {state === 'live' && (
        <View style={{ flexDirection:'row', alignItems:'center', gap:4 }}>
          <View style={{ width:6, height:6, borderRadius:999, backgroundColor: colors.success }} />
          <Text style={[Typography.caption, { color: colors.success }]}>LIVE</Text>
        </View>
      )}
    </View>
  );
})}
```

### Progressive disclosure

`OverviewCard` (glanceable) → **DetailModal** (a `Modal`/bottom-sheet with the mini
breakdown) → **full screen** (`router.push`). Don't cram everything into the card; the
tap reveals depth. Keep the card to one value + one subtitle.

### Quick links

Row/grid of `FeatureCard` tiles (`components/feature-card.tsx`) routing to the main
features. Each tile is a `Pressable` with role/label and ≥44pt.

---

## Color token usage

| Part | Token |
|------|-------|
| screen bg | `colors.background` |
| greeting name | `colors.text`; sub-line | `colors.textSecondary` |
| class badge | text `colors.primary` on `${primary}18` tint |
| KPI accents | `success` / `warning` / `info` / `primary` |
| live dot / label | `colors.success`; past items | dim via `opacity`, text `colors.textSecondary` |

---

## Spacing & typography

- Screen padding `Spacing.md`; section gap `Spacing.lg`; grid gap `Spacing.sm`.
- Greeting name `Typography.h2`; section titles `Typography.label`.
- Timeline rows `gap: Spacing.md`, dot 10px, past rows `opacity ~0.55`.

---

## Accessibility notes

- Greeting name and section titles: `accessibilityRole="header"`.
- Each KPI card: role `button` + spoken value ("Attendance, 87 percent, 13 of 15 present").
- Timeline rows: one `accessibilityLabel` per period incl. "live now" so status isn't color-only.
- All tap targets (cards, tiles) ≥44pt.

---

## Dark-mode note

Use `useTheme()` (student app's store-driven hook) for `colors`. Never `const C =
Colors.light`. The `${primary}18` badge/tint composites over `surface` in both modes;
"past" dimming uses `opacity`, which is theme-safe.
