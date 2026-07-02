# Quick Wins — Ship This Week

> Filtered from `ENHANCEMENT_BACKLOG.md`: **Effort ≤ 2 and Impact ≥ 3**. High leverage, low cost, mostly attribute-level or config-level. These move the 5.2 score fastest.
> ⚠️ Recommendations only — implement in the app repos in a separate, approved effort.

| # | ID | Win | Apps | Why it's fast | Impact |
|:-:|----|-----|------|---------------|:------:|
| 1 | ENH-002 | Global `:focus-visible` ring + skip-link | WEB | One CSS rule + one link element; fixes invisible keyboard focus platform-wide | 🔴 High |
| 2 | ENH-001 | `accessibilityRole`/`Label` on `AppButton`, `AppInput` + 4 global icon buttons | ADM, STU | Two primitives + four buttons → covers ~90% of screens | 🔴 High |
| 3 | ENH-006 | Restrict `#94a3b8` muted text to ≥18px; small text → `#475569` | ALL | Token/usage swap; fixes the most widespread contrast failure | 🔴 High |
| 4 | ENH-009 | Delete dead/demo UI (dead links, demo login string, dead bell, commented preloader, stale `.blade_*` backups, Expo react-logo assets) | ALL | Deletions + small edits; removes "unfinished" tells | 🟠 Med |
| 5 | ENH-003 | Guard global chart JS with existence checks (`if (window.x) …`) | WEB | Wrap ~10 globals; stops site-wide console TypeErrors | 🟠 Med |
| 6 | ENH-008 | Surface `useRefresh` errors (ADM); add iOS toast (STU) | ADM, STU | Small hook/util edits; stops silent failures | 🟠 Med |
| 7 | ENH-010 | Link `adminlte.rtl.css` + `dir` toggle scaffold | WEB | The file already ships — just reference it; unlocks RTL foundation | 🟠 Med |
| 8 | ENH-028 | Touch-target sweep to ≥44px (chips, inline icon buttons) | ADM, STU | `hitSlop`/min-size on a handful of shared patterns | 🟠 Med |
| 9 | ENH-026 | Consolidate mobile header trio → one `ScreenHeader` | ADM, STU | Replace 2–3 near-dupes with the existing best one | 🟡 Low-Med |
| 10 | ENH-027 | Consolidate STU child-switcher (3 → 1) | STU | Extract one component, reuse | 🟡 Low-Med |
| 11 | ENH-032 | Reduced-motion gating on mobile animations | ADM, STU | One `AccessibilityInfo` check around press-scale/transitions | 🟡 Low-Med |
| — | (fix) | Correct `autocomplete="false"` → `off` in `form.input-text` | WEB | One-character-class fix; valid HTML | 🟡 Low |
| — | (fix) | 404 page: stop leaking `$exception->getMessage()` | WEB | Swap to generic copy; log server-side | 🟡 Low |

## Suggested one-week sequence
- **Day 1–2:** ENH-002, ENH-001, ENH-006 (the three accessibility wins — biggest score lift).
- **Day 2–3:** ENH-003, ENH-008 (stop errors/silent failures) + the two one-line fixes.
- **Day 3–4:** ENH-009 (dead/demo cleanup), ENH-010 (RTL link).
- **Day 4–5:** ENH-028, ENH-026, ENH-027, ENH-032 (mobile consolidation + targets).

**Expected effect:** ~**5.2 → ~6.0** ecosystem score, concentrated in the Accessibility (1.7→~4) and Trust/Nielsen dimensions — for roughly one developer-week across the three apps.
