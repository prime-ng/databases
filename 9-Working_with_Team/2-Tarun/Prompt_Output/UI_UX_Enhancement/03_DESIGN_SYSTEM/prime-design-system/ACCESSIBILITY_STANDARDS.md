# Prime Design System — Accessibility Standards

> Target: **WCAG 2.2 Level AA** across web (prime_ai) and both mobile apps, with AAA adopted where it is cheap. Every component in this design system is built to these rules; every implementation must preserve them.

---

## 1. Color & Contrast

- **Normal text (< 18px / < 14px bold):** contrast ratio **≥ 4.5:1** against its background.
- **Large text (≥ 18px or ≥ 14px bold):** **≥ 3:1**.
- **Non-text (icons, input borders, focus rings, UI boundaries):** **≥ 3:1**.
- **Never convey meaning by color alone.** Status = color **+ icon + text label** (e.g. a red dot must be accompanied by "Overdue" and an icon).

### Verified palette contrast notes
| Foreground | On background | Ratio | Verdict |
|------------|---------------|-------|---------|
| `#1e293b` text-primary | `#ffffff` | ~13.6:1 | ✅ AAA |
| `#475569` text-secondary | `#ffffff` | ~7.5:1 | ✅ AAA |
| `#94a3b8` text-muted | `#ffffff` | ~2.6:1 | ❌ **fails 4.5:1** — muted text only for ≥18px or decorative; never body text |
| white text | `#6673fc` primary | ~3.6:1 | ⚠️ passes for **large/bold** only — button labels must be ≥14px bold |
| white text | `#facc15` warning | ~1.4:1 | ❌ never white-on-warning — use `#222c3c` dark text on warning |
| white text | `#3fcc7e` success | ~1.9:1 | ❌ use dark text on success fills, or use success as accent not fill |
| white text | `#e44f56` danger | ~3.9:1 | ⚠️ large/bold only |

**Rule of thumb:** treat `success`/`warning` as **accents** (borders, icons, tints), not as fills behind white text. When a solid brand fill is unavoidable, use **`#222c3c` (dark) text** on `warning`/`success` and reserve white text for `primary`/`danger`/`secondary` at ≥14px bold.

---

## 2. Focus Indicators

- Every interactive element (link, button, input, tab, menuitem, switch) has a **visible focus state**: `box-shadow: 0 0 0 3px rgba(102,115,252,0.35)` (token `--p-focus-ring`).
- **Never** `outline: none` without an equivalent replacement.
- Focus order follows visual/reading order. No positive `tabindex`.
- Focus is **not trapped** except intentionally inside open modals/drawers (and released on close).

---

## 3. Keyboard Navigation (web)

- All functionality operable by keyboard alone.
- **Skip-to-content** link as the first focusable element.
- Modals: focus moves in on open, is trapped while open, `Esc` closes, focus returns to the trigger on close.
- Dropdowns/menus: arrow-key navigation, `Esc` to close, `Enter`/`Space` to activate.
- Tables with actions: action buttons are real `<button>`/`<a>`, reachable by tab.
- No keyboard trap anywhere.

---

## 4. Touch Targets (mobile + touch web)

- Minimum **44×44px** hit area for every interactive element (WCAG 2.2 SC 2.5.8 → 24px min; Prime standard is the stricter 44px).
- Adequate spacing between adjacent targets (≥ 8px) to prevent mis-taps.
- Icon-only controls get invisible padding to reach 44px if the glyph is smaller.

---

## 5. Semantics & Structure

- **Web:** one `<h1>` per page; heading levels never skip. Landmarks (`<header> <nav> <main> <footer>`). Native elements over ARIA (`<button>` not `<div onclick>`). Form inputs have associated `<label>` (or `aria-label`). Tables use `<th scope>`. Icon-only buttons carry `aria-label`. Decorative icons `aria-hidden="true"`.
- **Mobile:** every `Pressable`/`TouchableOpacity` has `accessibilityRole` + `accessibilityLabel`. Images have `accessibilityLabel` or are marked decorative. Live regions (`accessibilityLiveRegion`) for async status/toasts. Headings use `accessibilityRole="header"`.

---

## 6. Screen Reader Support

- Icon-only actions announce their purpose ("Edit student", not "button").
- Status changes (save success, validation errors, loading complete) announced via live regions / `role="status"` / `role="alert"`.
- Loading states announce ("Loading…") rather than silent spinners.
- Decorative imagery hidden from the accessibility tree.

---

## 7. Forms

- Every field has a persistent visible label (not placeholder-as-label).
- Errors: shown inline, next to the field, in **text + icon** (not color alone), programmatically associated (`aria-describedby` / `accessibilityHint`), and summarized/announced on submit.
- Required fields marked in text ("Required"), not asterisk-alone.
- Inputs set correct `type`/`inputmode`/`autocomplete` (mobile keyboards, autofill).

---

## 8. RTL Layout

- Web: rely on **logical properties** (`margin-inline-start`, `padding-inline-end`, `text-align: start`) so `dir="rtl"` and `adminlte.rtl.css` work without extra CSS. Never hardcode `left`/`right` for flow-relative spacing. Directional icons (arrows, chevrons) mirror in RTL.
- Mobile: use `I18nManager`-aware layouts; `start`/`end` instead of `left`/`right`; mirror directional icons.

---

## 9. Reduced Motion

- Web: wrap non-essential transitions/animations in `@media (prefers-reduced-motion: reduce)` (tokens already zero out durations).
- Mobile: check `AccessibilityInfo.isReduceMotionEnabled()` before running Reanimated transitions; provide instant fallbacks.

---

## 10. Text & Zoom

- Support 200% zoom (web) and OS Dynamic Type / font scaling (mobile) without clipping or loss of function.
- No text in images.
- Line length ≤ ~75 characters for readability; body line-height ≥ 1.5.

---

## 11. Component Acceptance Checklist

Before a component is "done":
- [ ] Contrast ≥ AA for all text and non-text.
- [ ] Visible focus state.
- [ ] Fully keyboard operable (web) / has role + label (mobile).
- [ ] Touch targets ≥ 44px.
- [ ] Status not color-only.
- [ ] Works in light + dark.
- [ ] Works in RTL.
- [ ] Respects reduced motion.
- [ ] Screen-reader labels present and meaningful.
