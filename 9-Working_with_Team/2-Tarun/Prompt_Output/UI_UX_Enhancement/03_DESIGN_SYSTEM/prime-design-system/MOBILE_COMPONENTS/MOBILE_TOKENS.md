# Mobile Tokens (React Native / Expo)

> The values below are the **live** contents of `constants/theme.ts` in both
> `mobile_school` and `mobile_student` (verified 2026-07-01). Import them; never
> re-declare hexes inline. The canonical cross-platform token spec is
> `../DESIGN_TOKENS.md` — this file is the mobile-specific view plus the drift to fix.

```tsx
import { Colors, Spacing, Typography, Shadows, BorderRadius, Fonts } from '@/constants/theme';
```

Always resolve colors through a hook, not `Colors.light` directly (see bottom).

---

## 1. Colors

### Brand palette (identical across web + both apps — do not diverge)

| Token | Hex |
|-------|-----|
| primary | `#6673fc` |
| primaryDark (pressed/hover) | `#545ed6` |
| secondary | `#64748b` |
| success | `#3fcc7e` |
| info | `#4abad2` |
| warning | `#facc15` |
| danger | `#e44f56` |
| dark | `#222c3c` |

### Semantic tokens — light / dark

| Token | Light | Dark |
|-------|-------|------|
| text | `#1e293b` | `#e2e8f0` |
| textSecondary | `#475569` | `#94a3b8` |
| textMuted | `#94a3b8` | `#64748b` |
| background | `#ffffff` | `#1e1e2d` |
| surface | `#ffffff` | `#252536` |
| surfaceSecondary | `#f5f5f5` ⚠️ | `#2a2a3d` |
| border | `#e2e8f0` | `#323248` |
| primary | `#6673fc` | `#6673fc` |
| primaryDark | `#545ed6` | `#545ed6` |
| icon | `#64748b` | `#94a3b8` |
| tabIconDefault | `#94a3b8` | `#64748b` |
| tabIconSelected | `#6673fc` | `#6673fc` |

### Drift to fix (from the audit — align mobile to the canonical spec)

| # | Token | Current mobile | Fix to | Why |
|---|-------|----------------|--------|-----|
| D1 | `surfaceSecondary` (light) | `#f5f5f5` | **`#f8fafc`** | Matches web page/row bg; `#f5f5f5` is a warm-grey off-brand drift |
| D2 | `surfaceHover` | *missing* | add **`#f1f5f9`** (light) / `#2a2a3d` (dark) | Pressed row / hover surface |
| D3 | `link` / `text-link` | *missing* | add **`#3b82f6`** (light) / `#60a5fa` (dark) | Tappable inline links need a distinct token |
| D4 | `light` chip bg | *missing* | add **`#f4f6f9`** | Muted chip/tag background parity with web |

Add these to `constants/theme.ts` in both apps; do not scatter raw hexes across screens.

### Contrast rule (WCAG AA)

`textMuted` (`#94a3b8`) on white/`surface` measures **~2.5:1** — it **fails** AA for
normal text. Use it **only** for:
- text **≥ 18px** (large-text threshold), or
- bold text **≥ 14px**, or
- decorative / non-essential glyphs.

For body (16px) and caption (12px) content use **`textSecondary`** (`#475569`, ~7:1).

### Accent-usage rule

Status and stat surfaces use color as **accent, not fill**: `surface` / `surfaceSecondary`
background + a tinted icon circle (`` `${accent}18` `` = ~9% alpha) or colored value text.
Never a full-saturation card fill. Status = **color + icon + text label**, never color alone.

---

## 2. Spacing (4/8 grid)

| Token | px |
|-------|----|
| `Spacing.xs` | 4 |
| `Spacing.sm` | 8 |
| `Spacing.md` | 16 |
| `Spacing.lg` | 24 |
| `Spacing.xl` | 32 |
| `Spacing.xxl` | 48 |

Default gap between elements is `sm`/`md`; `xs` is for tight controls (chips, dense rows).
Screen horizontal padding is typically `Spacing.md` (16).

---

## 3. Typography

| Role | fontSize | lineHeight | fontWeight |
|------|----------|-----------|------------|
| `Typography.h1` | 32 | 40 | 700 |
| `Typography.h2` | 24 | 32 | 700 |
| `Typography.h3` | 20 | 28 | 600 |
| `Typography.h4` | 18 | 24 | 600 |
| `Typography.body` | 16 | 24 | 400 |
| `Typography.bodySmall` | 14 | 20 | 400 |
| `Typography.label` | 14 | 20 | 600 |
| `Typography.caption` | 12 | 16 | 400 |

Spread a role, then override only what you must:
```tsx
<Text style={[Typography.body, { color: colors.text }]}>…</Text>
```
Never render body copy below **12px**. `Fonts` resolves to the system stack per platform.

---

## 4. Shadows (elevation)

| Token | iOS opacity / radius | Android elevation |
|-------|----------------------|-------------------|
| `Shadows.sm` | 0.05 / 2 | 2 |
| `Shadows.md` | 0.08 / 8 | 4 |
| `Shadows.lg` | 0.12 / 16 | 8 |

Prefer **sm** for cards; reserve **lg** for modals/overlays. In dark mode shadows read
weakly — lean on `surface` vs `background` contrast and `border` for separation.

---

## 5. Border radius

| Token | px | Usage |
|-------|----|-------|
| `BorderRadius.sm` | 4 | small chips |
| `BorderRadius.md` | 8 | inputs, small buttons |
| `BorderRadius.lg` | 12 | buttons, cards (default) |
| `BorderRadius.xl` | 16 | large cards, modals |
| `BorderRadius.xxl` | 24 | feature panels |
| `BorderRadius.full` | 999 | pills, avatars |

---

## 6. Resolving colors (the dark-mode contract)

```tsx
// ❌ NEVER — pins the screen to light, breaks dark mode (audit finding)
const C = Colors.light;

// ✅ student app (theme store)
import { useTheme } from '@/hooks/use-theme';
const colors = useTheme();

// ✅ admin app (OS color scheme)
import { useColorScheme } from '@/hooks/use-color-scheme';
const colors = Colors[useColorScheme() ?? 'light'];

// ✅ single property, with optional per-mode override
import { useThemeColor } from '@/hooks/use-theme-color';
const bg = useThemeColor({ light: '#fff', dark: '#1e1e2d' }, 'background');
```

Every `backgroundColor`, `color`, and `borderColor` in a component must come from
`colors.*` (or `useThemeColor`). Static `Spacing` / `Typography` / `BorderRadius` /
`Shadows` are theme-independent and can be imported directly.
