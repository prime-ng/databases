# Module Knowledge: Library (LIB)
# Last Updated: 2026-06-25
# Completion Status: ~55%

---

## Module Facts

| Item | Value |
|------|-------|
| Table prefix | `lib_*` |
| DDL (canonical) | `2-DDL_Tenant_Consolidated/Library_ddl_v7.sql` — 35 tables |
| Routes | `routes/tenant.php` lines 2719–2967 |
| Controllers | 26 |
| Models | 35 |
| Services | 9 |
| FormRequests | 19 |
| Policies | 23 |
| Dusk Tests | 15 |
| FRD | `4-Requirement_Module_wise/0-FRD_Documents/Library/LIB_FRD_v1.md` |

---

## FRD Summary (v1.0 — saved 2026-06-25)

- **13 REQ** — REQ-LIB-001 to REQ-LIB-013 (6 × P0, 7 × P1, 0 × P2)
- **60 BR** — BR-LIB-001 to BR-LIB-060
- **4 Workflows** — Issue/Return, Fine Collection, Reservation Queue, Inventory Audit
- **6 Reports** — RPT-LIB-001 to RPT-LIB-006
- **15 Enhancements** — ENH-LIB-001 to ENH-LIB-015

---

## Known Gaps & Open Issues

### P0 — Security (must fix before production)
- `EnsureTenantHasModule` middleware is MISSING from the library route group
- **6 controllers with zero `Gate::authorize()` calls:**
  - `LibraryController` (main hub — all library operations exposed)
  - `MasterDashboardController`
  - `LibFineController` ← financial risk — fines can be collected/waived without any authorization check
  - `LibCirculationReportController`
  - `LibFineReportController`
  - `LibReportPrintController`

### Logic Gaps
- Grace period days field EXISTS in `lib_membership_types` config but is NOT enforced in the fine calculation engine — fines are calculated from due date with no grace deduction
- `lib_members.outstanding_fines` decrement on payment has not been verified in code

### Structural / Code Quality
- 22 controllers unnecessarily import `Modules\Vendor\Models\Vendor` — likely copy-paste artifact

---

## Design Decisions Made

| Decision | Reason |
|----------|--------|
| Book Catalog Management (REQ-LIB-002) split from Book Acquisition & Copy Registration (REQ-LIB-003) | Different actors (catalog = metadata; acquisition = physical lifecycle), different downstream integrations (acquisition → Vendor + Accounting; catalog is self-contained) |
| Fine Configuration (REQ-LIB-009) split from Fine Collection & Waiver (REQ-LIB-010) | Config is infrequent System Admin work; collection is daily Librarian work. Permission difference: Supervisor can waive fines, Librarian cannot — merging obscures this |
| Digital Resources given its own REQ (REQ-LIB-011) | Separate approval workflow, license-based access rules, and notification needs distinguish it from physical book management |

---

## Cross-Module Dependencies

| Dependency | Integration Point |
|------------|-------------------|
| StudentProfile | Member registration links to `sys_users`; book subject mapping links to `std_students` |
| SchoolSetup | Shelf location hierarchy uses `sch_buildings`; academic mapping uses `sch_classes`, `sch_subjects` |
| Vendor module | Book purchase records link to `vnd_vendors` |
| Accounting module | Fine payments post journal vouchers via `acc_account_groups`, `acc_ledgers` |
| Notification module | Reservation availability + overdue reminders — **NOT YET WIRED** |
| Student Fee module | Fine-to-fee transfer — future |
| Student Portal | Self-service reservation and catalog browse — future |
| SyllabusBooks module | Curricular alignment of library books to textbooks — future |

---

## Lessons Learned

- [2026-06-25 | FRD] Always separate "Book Catalog Management" from "Book Acquisition & Copy Registration" — they share the word "book" but have completely different actors, rules, and integrations.
- [2026-06-25 | FRD] Fine configuration deserves its own REQ — the permission split (Supervisor waives, Librarian collects) is invisible if they're merged.
- [2026-06-25 | FRD] The V2 technical requirement doc gives field-level accuracy; the preliminary screen files give UX context — both are needed. V2 alone produces technically accurate but UX-thin FRD sections.

---

## Pending Next Steps

These were offered at end of the last session but not yet started — pick up from here:

| # | Work | Agent | Input |
|---|------|-------|-------|
| 1 | DDL Gap Analysis | `act as DB Architect` | Compare FRD Section 10.1 REQ list against `Library_ddl_v7.sql` — identify missing tables/columns |
| 2 | Code Gap Analysis | `act as Technical Auditor` | Check which REQ entries (Screen Needed / API Needed = Yes) are actually implemented in `Modules/Library/` |
| 3 | Completion Scoring | `act as Status Analyzer` | 6-dimension scorecard — use FRD Section 10.4 totals as the denominator |
| 4 | Test Coverage Gap | `act as Testing Architect` | Map FRD acceptance criteria to the 15 existing Dusk tests — identify untested criteria |

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-25 | Business Analyst | FRD v1.0 generated (13 REQ, 60 BR, 4 workflows, 6 reports, 15 enhancements). Module knowledge file created. |
| 2026-06-25 | Business Analyst | Module knowledge system established. Pending Next Steps section added. No new Library analysis in this session. |
