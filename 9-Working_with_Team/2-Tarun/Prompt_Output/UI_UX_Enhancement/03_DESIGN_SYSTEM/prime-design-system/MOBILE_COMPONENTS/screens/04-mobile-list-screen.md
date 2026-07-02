# 04 · Mobile List Screen — `FlatList` / `FlashList`

The most important structural rule in the mobile system: **lists render with `FlatList`
(or `@shopify/flash-list`), never `ScrollView` + `.map()`.** The audit found long lists
mapped inside a `ScrollView`, mounting every row at once — jank, memory pressure, no
recycling, no windowing.

---

## Visual description

A scrollable, virtualized list of uniform rows with pull-to-refresh at the top and
infinite scroll at the bottom. Distinct states for **loading (skeleton)**, **empty**,
**error (with Retry)**, and the normal populated list.

```
╔══ Students ═══════════════ 🔍 ╗
║ ◉ Aarav Sharma      VII-A   › ║   ← shared list-row
║ ◉ Diya Patel        VII-A   › ║
║ ◉ Kabir Singh       VII-B   › ║
║ …                            ║
║ [ loading more…  ⟳ ]         ║   ← onEndReached footer
╚══════════════════════════════╝
```

---

## Recommended composition

```tsx
<FlatList
  data={students}
  keyExtractor={(item) => String(item.id)}
  renderItem={({ item }) => <ListRow item={item} onPress={() => open(item)} />}
  ItemSeparatorComponent={() => (
    <View style={{ height: StyleSheet.hairlineWidth, backgroundColor: colors.border }} />
  )}
  contentContainerStyle={{ padding: Spacing.md, flexGrow: 1 }}
  refreshControl={
    <RefreshControl refreshing={isRefreshing} onRefresh={refetch}
                    tintColor={colors.primary} colors={[colors.primary]} />
  }
  onEndReached={loadNextPage}
  onEndReachedThreshold={0.5}
  ListFooterComponent={isFetchingNextPage ? <RowSkeleton /> : null}
  ListEmptyComponent={
    isLoading ? <ListSkeleton count={8} />
    : error ? <ErrorState onRetry={refetch} />
    : <EmptyState icon="group" title="No students yet"
                  message="Students you add will appear here." />
  }
  // perf
  initialNumToRender={10}
  windowSize={7}
  removeClippedSubviews
/>
```

> Prefer `@shopify/flash-list` (`<FlashList estimatedItemSize={64} … />`) where it is
> already a dependency — same API surface, better recycling. Do **not** add it just for
> this if it isn't present; `FlatList` is sufficient.

### Shared list-row (build once, reuse)

```tsx
function ListRow({ item, onPress }) {
  const colors = useTheme();            // or Colors[useColorScheme() ?? 'light']
  return (
    <Pressable
      onPress={onPress}
      android_ripple={{ color: colors.surfaceSecondary }}
      accessibilityRole="button"
      accessibilityLabel={`${item.name}, class ${item.className}`}
      style={({ pressed }) => [
        { flexDirection: 'row', alignItems: 'center', gap: Spacing.md,
          paddingVertical: Spacing.md, minHeight: 56 },        // ≥44pt
        pressed && { backgroundColor: colors.surfaceSecondary },
      ]}
    >
      <Avatar uri={item.photo} name={item.name} />
      <View style={{ flex: 1 }}>
        <Text style={[Typography.body, { color: colors.text }]} numberOfLines={1}>{item.name}</Text>
        <Text style={[Typography.caption, { color: colors.textSecondary }]}>{item.className}</Text>
      </View>
      <MaterialIcons name="chevron-right" size={20} color={colors.textMuted} />
    </Pressable>
  );
}
```

### Skeleton row (see also file 09)

```tsx
function RowSkeleton() {
  const colors = useTheme();
  return (
    <View style={{ flexDirection: 'row', gap: Spacing.md, paddingVertical: Spacing.md }}
          accessibilityElementsHidden importantForAccessibility="no-hide-descendants">
      <View style={{ width: 40, height: 40, borderRadius: 999, backgroundColor: colors.surfaceSecondary }} />
      <View style={{ flex: 1, gap: 6 }}>
        <View style={{ height: 12, width: '60%', borderRadius: 4, backgroundColor: colors.surfaceSecondary }} />
        <View style={{ height: 10, width: '35%', borderRadius: 4, backgroundColor: colors.surfaceSecondary }} />
      </View>
    </View>
  );
}
// ListSkeleton = <>{Array.from({length: count}).map((_,i) => <RowSkeleton key={i} />)}</>
```

---

## State matrix

| State | Render |
|-------|--------|
| Loading (first page) | `ListSkeleton` (6–8 shimmer rows), **not** a bare spinner or blank |
| Loading (next page) | `ListFooterComponent` skeleton/spinner |
| Empty | `EmptyState` — icon + title + message + optional CTA |
| Error | `ErrorState` — icon + message + **Retry** button (no dead ends) |
| Refreshing | `RefreshControl` spinner, list stays visible |
| Populated | virtualized rows |

---

## Color token usage

| Part | Token |
|------|-------|
| screen bg | `colors.background` |
| row pressed bg / separators | `colors.surfaceSecondary` / `colors.border` |
| primary text | `colors.text` |
| secondary line | `colors.textSecondary` (not `textMuted` — 12px fails contrast) |
| chevron / avatar placeholder | `colors.textMuted` (decorative) |
| refresh spinner | `colors.primary` |

---

## Spacing & typography

- Row `paddingVertical: Spacing.md`, `minHeight: 56`, inner `gap: Spacing.md`.
- List `contentContainerStyle: { padding: Spacing.md, flexGrow: 1 }` (`flexGrow` lets empty state center).
- Row title `Typography.body`, subtitle `Typography.caption`.

---

## Accessibility notes

- Each row: `accessibilityRole="button"` + a full-sentence `accessibilityLabel`.
- Row min height 56 (≥44pt); use `hitSlop` for any inline icon buttons within a row.
- Hide skeletons from the screen reader (`accessibilityElementsHidden` /
  `importantForAccessibility="no-hide-descendants"`).
- `keyExtractor` must return stable unique ids — never array index for dynamic data.

---

## Dark-mode note

Resolve `colors` via `useTheme()` (student) or `Colors[useColorScheme() ?? 'light']`
(admin) at the top of the row and screen. Never `const C = Colors.light`. Separators,
pressed backgrounds, and skeletons all read off `colors.*`, so the list themes correctly
in dark mode (`background #1e1e2d`, rows on `surfaceSecondary #2a2a3d`).
