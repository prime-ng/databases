# 03 · Mobile Cards — Accent Card / `OverviewCard`

Reference primitive: `components/dashboard/overview-card.tsx` (student app). This is the
canonical **accent card**. If the admin app needs it, port this same component.

---

## Visual description

A `surface`-background card with a **tinted icon circle** (accent at ~9% alpha), a title,
a large accent-colored value, a muted subtitle, an optional trend indicator, and a
chevron affordance. **Color is used as accent, not as a saturated fill** — the card body
stays white/`surface`; only the icon circle and the value carry the accent hue.

```
┌─────────────────────────────────────┐
│  ◐ Attendance                    ›  │   ◐ = icon in tinted circle (accent 18α)
│     87%                             │   value in accent color
│     13/15 present    ▲ +2%          │   subtitle muted · trend colored
└─────────────────────────────────────┘
```

> ❌ Anti-pattern: a fully green/red saturated card. ✅ Correct: white card, green icon
> circle + green value. Status is **color + icon + text**, never color alone.

---

## Recommended composition

Use the existing `OverviewCard` directly:

```tsx
<OverviewCard
  icon="event-available"
  title="Attendance"
  value="87%"
  subtitle="13 / 15 present"
  accentColor={colors.success}          // token, not a literal
  onPress={() => router.push('/attendance')}
/>
```

Add a **trend** row via the `children` slot (color + arrow + text):

```tsx
<OverviewCard icon="account-balance-wallet" title="Fees"
  value="₹12,500" subtitle="Due 10 Jul" accentColor={colors.warning}
  onPress={() => router.push('/fees')}>
  <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
    <MaterialIcons name="trending-up" size={14} color={colors.danger} />
    <Text style={[Typography.caption, { color: colors.danger }]}>Overdue soon</Text>
  </View>
</OverviewCard>
```

Grid layout (two per row) — the card is already `minWidth:'46%', maxWidth:'50%'`:

```tsx
<View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: Spacing.sm }}>
  {cards.map(c => <OverviewCard key={c.key} {...c} accentColor={colors[c.accent]} />)}
</View>
```

### Press-scale micro-interaction (with reduced-motion guard)

The primitive already dims + scales on press. If you add spring/animated motion,
**gate it behind reduce-motion**:

```tsx
const [reduceMotion, setReduceMotion] = useState(false);
useEffect(() => {
  AccessibilityInfo.isReduceMotionEnabled().then(setReduceMotion);
  const sub = AccessibilityInfo.addEventListener('reduceMotionChanged', setReduceMotion);
  return () => sub.remove();
}, []);

// pressed style — skip the transform when reduce-motion is on
pressed && !reduceMotion && { transform: [{ scale: 0.985 }], opacity: 0.9 }
```

---

## Color token usage

| Part | Token |
|------|-------|
| card background | `colors.surface` (`#fff` / `#252536`) |
| icon circle bg | `` `${accentColor}18` `` (accent at ~9% alpha) |
| icon glyph | `accentColor` (a brand/semantic token: success/info/warning/danger/primary) |
| value | `accentColor` |
| title | `colors.text` |
| subtitle | `colors.textMuted` **only if ≥18px**; else `colors.textSecondary` |
| chevron | `colors.textMuted` (decorative — OK) |
| trend up/positive | `colors.success`; down/negative | `colors.danger` |

Pass `accentColor` as a **token** (`colors.success`, not `'#3fcc7e'`).

---

## Spacing & typography

- Card `padding: Spacing.md` (16), inner `gap: Spacing.xs`, radius `BorderRadius.xl` (16), `Shadows.sm`.
- Icon circle 36×36, radius `BorderRadius.md`.
- Title `Typography.label` @12; value `Typography.h3` @18 weight 700; subtitle `Typography.caption` @10–12.
- Grid gap `Spacing.sm` between cards.

> Note: the primitive's subtitle at 10px in `textMuted` is below the AA large-text
> threshold — for genuinely important subtitles bump to 12px + `textSecondary`.

---

## Accessibility notes

- Make the whole card the touch target: `accessibilityRole="button"`,
  `accessibilityLabel="Attendance, 87 percent, 13 of 15 present"` (spell the value out).
- Card is already ≥44pt tall; keep it so.
- Never encode status in the accent color alone — the value/subtitle text carries it too.
- The trend arrow needs the accompanying text ("Overdue soon"), not just a red arrow.

---

## Dark-mode note

`OverviewCard` reads `colors = Colors[useColorScheme() ?? 'light']` — keep it. The
`${accent}18` tint works in both modes because it composites over `surface`. Never
hardcode `Colors.light`; in the student app you may swap to `useTheme()` for store-driven
theming, but the point stands: resolve through a hook.
