# Design-Token Drift Analysis — Prime Ecosystem

> **Scope:** Divergence of design tokens across the three apps.
> **Sources inspected (read-only):**
> - Web: `/Users/bkwork/Herd/prime_ai/public/backend/css/adminlte-custom.css` (`:root` + `[data-bs-theme=dark]`)
> - Admin app: `/Users/bkwork/Herd/mobile_school/constants/theme.ts`
> - Student app: `/Users/bkwork/Herd/mobile_student/constants/theme.ts`
> **Status:** All values below were read directly from the files on 2026-07-01.

---

## 1. Executive Verdict

Token alignment across the three apps is **good but not airtight (≈85%)**. The brand palette (`primary/secondary/success/info/warning/danger/dark`) is **identical** everywhere — a real strength and clearly intentional (the mobile `theme.ts` files even document "taken directly from the Laravel backend CSS"). The two mobile apps are **byte-for-byte identical** in their token layer.

However, there are **7 concrete drift points** — most minor, two worth fixing — plus **structural gaps** where the mobile token set is missing tokens the web has (link color, hover/active surfaces, muted-surface `light`). These gaps force mobile developers to improvise, which is where silent divergence creeps in over time.

---

## 2. Brand Palette — ✅ Fully Aligned

| Token | Web (`adminlte-custom.css`) | Admin app | Student app | Match |
|-------|------|------|------|:---:|
| primary | `#6673fc` | `#6673fc` | `#6673fc` | ✅ |
| secondary | `#64748b` | `#64748b` | `#64748b` | ✅ |
| success | `#3fcc7e` | `#3fcc7e` | `#3fcc7e` | ✅ |
| info | `#4abad2` | `#4abad2` | `#4abad2` | ✅ |
| warning | `#facc15` | `#facc15` | `#facc15` | ✅ |
| danger | `#e44f56` | `#e44f56` | `#e44f56` | ✅ |
| dark | `#222c3c` | `#222c3c` | `#222c3c` | ✅ |

**Note — `primaryDark` (`#545ed6`)** exists in *both* mobile apps as the pressed/hover state, but there is **no matching `--primary-dark`/`--primary-hover` token in the web CSS**. The web derives hover states ad-hoc. → *Drift point D6 below.*

---

## 3. Text & Surface Tokens — ⚠️ Two Real Mismatches

| Concept | Web light | Mobile light | Web dark | Mobile dark | Verdict |
|---------|-----------|--------------|----------|-------------|---------|
| text primary | `--text-primary #1e293b` | `text #1e293b` | `#e2e8f0` | `#e2e8f0` | ✅ |
| text secondary | `#475569` | `#475569` | `#94a3b8` | `#94a3b8` | ✅ |
| text muted | `#94a3b8` | `#94a3b8` | `#64748b` | `#64748b` | ✅ |
| surface / card | `--surface-bg #ffffff` | `surface #ffffff` | `#1e1e2d` | `#1e1e2d` (`background`) | ✅ |
| **secondary surface** | `--surface-secondary #f8fafc` | `surfaceSecondary #f5f5f5` | `#252536` | `#2a2a3d` | ❌ **D1 / D2** |
| border | `--surface-border #e2e8f0` | `border #e2e8f0` | `#323248` | `#323248` | ✅ |

### 🔴 D1 — Light secondary-surface mismatch
`--surface-secondary: #f8fafc` (web, a cool blue-tinted off-white) vs `surfaceSecondary: #f5f5f5` (mobile, a neutral gray). Small numerically, but `#f8fafc` carries the brand's cool undertone while `#f5f5f5` is dead neutral — side by side on the same screen (e.g. a web report embedded near the app) they read as different "whites." **Fix:** set mobile `surfaceSecondary` to `#f8fafc`.

### 🟠 D2 — Dark secondary/tertiary surface offset by one step
Web dark ladder: surface `#1e1e2d` → secondary `#252536` → hover `#2a2a3d` → active `#323248`.
Mobile dark ladder: `background #1e1e2d` → `surface #252536` → `surfaceSecondary #2a2a3d`.
The mobile app maps its **card surface** to the web's **secondary** value and its **secondarySurface** to the web's **hover** value — i.e. everything is shifted up one rung. Functionally fine (the ladder is internally consistent) but a card in the app is one shade lighter than the equivalent web card in dark mode. **Fix:** align naming so `surface`=`#1e1e2d`(page)/`#252536`(card) semantics match web, or document the intentional offset.

---

## 4. Missing Tokens on Mobile — ⚠️ Structural Gaps

These exist on web but have **no mobile equivalent**, forcing hardcoding:

| Web token | Value (light / dark) | Mobile status | Impact |
|-----------|----------------------|---------------|--------|
| `--text-link` | `#3b82f6` / `#60a5fa` | ❌ absent | **D3** — inline links have no token; devs hardcode blue |
| `--surface-hover` | `#f1f5f9` / `#2a2a3d` | ❌ absent (only pressed-state via `primaryDark`) | **D4** — list-row / pressable hover states improvised |
| `--surface-border-light` | `#f1f5f9` / `#2a2a3d` | ❌ absent | **D4** — softer dividers not available |
| `--light` | `#f4f6f9` | ❌ absent | **D5** — no "muted chip / tag background" token |

---

## 5. Spacing, Radius, Typography, Shadows

| System | Web | Mobile | Verdict |
|--------|-----|--------|---------|
| **Spacing grid** | Design intent = **8px grid** (per design direction) | **4pt grid** (`xs4 sm8 md16 lg24 xl32 xxl48`) | 🟠 **D7** — different base units. Mobile's `md16/lg24/xl32` are 8-multiples so they reconcile, but `xs4` and `sm8` allow 4px increments the web grid disallows. Document one canonical scale. |
| **Border radius** | ad-hoc in CSS (cards ~8–12px) | `sm4 md8 lg12 xl16 xxl24 full999` | 🟡 Mobile has a formal scale; **web has none codified** — should adopt the mobile scale as the shared token set. |
| **Typography scale** | ad-hoc (AdminLTE/BS defaults + overrides) | Formal: `h1 32 / h2 24 / h3 20 / h4 18 / body 16 / bodySmall 14 / caption 12 / label 14` | 🟡 Mobile scale is clean and should become the **shared canonical type scale**; web currently lacks a documented scale. |
| **Shadows** | `--shadow-sm/md/lg` (rgba, three steps) | `Shadows.sm/md/lg` (iOS+elevation, three steps) | ✅ Conceptually aligned three-tier ramp; values differ by platform necessity (acceptable). |
| **Fonts** | system font stack (implicit) | `system-ui` stack via `Platform.select` | ✅ Both use system fonts — consistent, no web-font dependency. |

---

## 6. Drift Register (ranked)

| ID | Drift | Severity | Fix effort | Recommendation |
|----|-------|:---:|:---:|----------------|
| D1 | Light secondary surface `#f5f5f5` (mobile) ≠ `#f8fafc` (web) | 🔴 Med | Trivial | Set mobile `surfaceSecondary = #f8fafc` |
| D2 | Dark surface ladder shifted one step | 🟠 Low-Med | Small | Re-map or document offset |
| D3 | No `text-link` token on mobile | 🟠 Low-Med | Trivial | Add `link: #3b82f6 / #60a5fa` |
| D4 | No `surface-hover` / `surface-border-light` on mobile | 🟠 Low | Small | Add hover + soft-divider tokens |
| D5 | No `light` (muted chip bg) token on mobile | 🟡 Low | Trivial | Add `muted: #f4f6f9` |
| D6 | `primaryDark`/hover exists on mobile but not codified on web | 🟡 Low | Trivial | Add `--primary-hover: #545ed6` to web `:root` |
| D7 | 4pt (mobile) vs 8px (web) spacing base | 🟡 Low | Doc | Declare one canonical spacing scale in `DESIGN_TOKENS.md` |

**None are P0.** D1 is the only visually noticeable one in normal use. The bigger long-term risk is the **missing-token gaps (D3–D6)**: absent tokens are the seams where future drift enters. Closing them in a single shared `DESIGN_TOKENS.md` (the design-system deliverable) is the durable fix.

---

## 7. Recommended Canonical Token Set

The design system's `DESIGN_TOKENS.md` should publish **one** table and both platforms should conform to it:
- **Brand:** the 7 confirmed-aligned colors + `primary-hover #545ed6`.
- **Surfaces (light):** bg `#ffffff`, secondary `#f8fafc`, hover `#f1f5f9`, border `#e2e8f0`, border-light `#f1f5f9`, muted `#f4f6f9`.
- **Surfaces (dark):** bg `#1e1e2d`, card `#252536`, hover `#2a2a3d`, active/border `#323248`.
- **Text:** primary `#1e293b`/`#e2e8f0`, secondary `#475569`/`#94a3b8`, muted `#94a3b8`/`#64748b`, link `#3b82f6`/`#60a5fa`.
- **Spacing:** canonical **4/8/16/24/32/48** (declare 8 as the default step; 4 reserved for tight controls).
- **Radius:** `4/8/12/16/24/full`.
- **Type:** the mobile scale (32/24/20/18/16/14/12).
- **Shadows:** three-tier ramp, per-platform values documented together.

*This is a documentation + token-addition exercise only — no application code is modified as part of this audit.*
