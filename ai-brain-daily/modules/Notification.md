# Module: Notification

Append-only rollup. Newest entries at the bottom.

## 2026-10-20 — Digest notification support

- **Commit:** `a1aa5436a`
- **Files:** `Modules/Notification/app/Services/NotificationService.php` (M, +28/-5)
- **What:** Extended `NotificationService` so the new `SendInsightDigestCommand` can deliver digest notifications; seeded via `InsightDigestNotificationSeeder`.
- **Why:** Morning digest delivery channel for Dashboard insights.
- **Tests:** none added.
- **Status:** Done
- **Report:** `ai-brain-daily/daily/2026-10-20.md`
