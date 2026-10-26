# Module: Ptm

Append-only rollup. Newest entries at the bottom.

## 2026-10-25 — PTM-01/02 turnout summary on bookings tab

- **Commit:** `e00588591`
- **Files:**
  - `Modules/Ptm/app/Http/Controllers/PtmCombinedViewController.php` (M)
  - `Modules/Ptm/resources/views/management/partials/bookings/index.blade.php` (M)
- **What:** Per-event turnout stats (invited / booked / attended / turnout % / attendance rate) computed from `PtmEvent`, `PtmSlotBooking`, `PtmEventClassSection`, `ClassSection` and `StudentAcademicSession`; turnout cards added to the bookings tab. PTM-01 (58% turnout) and PTM-02 (19 of 41 booked) are now visible.
- **Verified:** `php -l` OK; `php artisan view:cache` OK; no DB/migration change.
- **Status:** Done
- **Report:** [daily/2026-10-25.md](../daily/2026-10-25.md)
