# Module: StudentFee

Append-only rollup. Newest entries at the bottom.

## 2026-10-20 — Fee reminder service + queued job

- **Commit:** `a1aa5436a`
- **Files:** `Modules/StudentFee/app/Services/FeeReminderService.php` (A, +162), `Modules/StudentFee/app/Jobs/SendFeeRemindersJob.php` (A, +57)
- **What:** Reminder selection/sending service and queue job, invoked from the Dashboard insights `FeeReminderCardAction`.
- **Why:** Let the fee-reminder insight card trigger reminders instead of being informational only.
- **Tests:** none added.
- **Status:** Done
- **Report:** `ai-brain-daily/daily/2026-10-20.md`
