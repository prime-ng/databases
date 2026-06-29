# Module Knowledge: Library (LIB)
# Last Updated: 2026-06-29
# Completion Status: ~55% — Partially Implemented (business logic flows done; security, services, scheduled jobs missing)

---

## FRD Summary

| Item | Value |
|------|-------|
| FRD File (current) | `4-Requirement_Module_wise/0-FRD_Documents/LIB_FRD_2026-06-29.md` (v2.0, flat layout) |
| Supersedes | `LIB_FRD_Old_v1.md` (v1.0, 2026-06-25) |
| Total Functional Requirements (REQ-) | 13 |
| Total Business Rules (BR-) | 60 |
| Total Workflows | 4 |
| Total Reports (RPT-) | 6 |
| Total Enhancements (ENH-) | 15 |
| Priority Split (REQ) | P0 = 8 · P1 = 5 · P2 = 0 |
| Design lessons honored | Catalog (REQ-LIB-002) kept separate from Acquisition/Copy Registration (REQ-LIB-003); Fine Config (REQ-LIB-009) kept separate from Fine Collection & Waiver (REQ-LIB-010, Librarian-collects/Supervisor-waives split preserved in BR-LIB-048) |
| v2.0 accuracy fix | Section 10.4 P0/P1 split corrected 6/7 → 8/5 (REQ-LIB-009 & 010 are Core/P0); all IDs and denominators preserved — no renumbering |

---

## Module Facts

| Item | Value |
|------|-------|
| Table prefix | `lib_*` |
| DDL (canonical) | `2-DDL_Tenant_Consolidated/Library_ddl_v7.sql` — **48 tables** + 3 triggers + 1 MySQL Event + 5 views |
| V2 Requirement | `4-Requirement_Module_wise/4-Initial_Requirements/V2/LIB_Library_Requirement.md` |
| FRD (current) | `4-Requirement_Module_wise/0-FRD_Documents/LIB_FRD_2026-06-29.md` (v2.0; flat layout; supersedes `LIB_FRD_Old_v1.md`) |
| Namespace | `Modules\Library` |
| Route Prefix | `library/` |
| Routes | `routes/tenant.php` lines 2719–2967 (~120+ routes) |
| Controllers | 26 (25 domain + 1 hub `LibraryController`) |
| Models | 35 (existing code); DDL v7 has 48 tables — 13 new models needed |
| Services | 9 (all report/analytics services — business logic services MISSING) |
| FormRequests | 19 |
| Policies | 23 |
| Blade Views | ~120 Blade templates |
| Browser (Dusk) Tests | 15 (no unit/feature tests) |
| Note on Prefix | RBS used `bok_*` as planned prefix; actual implementation uses `lib_*` throughout |

---

## DDL v7 vs V2 Requirement Gap

| Dimension | V2 Req Doc (2026-03-26) | DDL v7 (2026-06-20) |
|-----------|------------------------|---------------------|
| Table count | 35 proposed | **48 tables** |
| Extra tables | — | +13 new tables (see below) |
| Status fields | ENUM per table | INT UNSIGNED FK → `lib_library_status_masters` |
| Fine type | ENUM on fine table | FK → `lib_fine_type` master |
| Shelf location | Flat columns (aisle/shelf/rack/floor/zone) | FK components → `lib_locations_master` |
| Reservations | `lib_reservations` | `lib_physical_book_requests` (renamed + expanded) |
| Acquisition | No purchase table | `lib_book_purchases` + `lib_book_purchases_items` |
| Digital access | Simple download flag | Full `lib_digital_access_requests` + `lib_digital_access_transactions` workflow |
| Access control | None | `lib_digital_resource_access_restrictions` (role/dept/user) |
| Reviews | Not in req doc | `lib_book_reviews_ratings` (new NT-001) |
| Wishlist | Not in req doc | `lib_wishlist` (new NT-002) |
| Settings | Not detailed | `lib_library_config` (key-value per academic year) |
| Accounting | Mentioned conceptually | `lib_account_entry_config` (fine → ledger mapping) |
| Triggers/Events | Not documented | 3 MySQL triggers + 1 daily MySQL Event for auto fine |
| DB Views | Not documented | 5 reporting views |

---

## DDL v7 Table Inventory (48 tables)

### Sub-Menu 1: Book Masters (7)
| Table | Purpose |
|-------|---------|
| `lib_resource_types` | Format classification (physical, e-book, audio, journal) |
| `lib_categories` | Hierarchical book classification (self-referencing) |
| `lib_genres` | Literary genre tags |
| `lib_book_conditions` | Standardized condition states; `is_borrowable` flag |
| `lib_publishers` | Publisher master |
| `lib_authors` | Author master (FK → `glb_countries`, `lib_genres`) |
| `lib_keywords` | Searchable keyword tags |

### Sub-Menu 2: Location Masters (2)
| Table | Purpose |
|-------|---------|
| `lib_locations_master` | Location components: Zone/Floor/Aisle/Shelf/Rack — FK to `sch_buildings` |
| `lib_shelf_locations` | Composite shelf location: FK to each component in `lib_locations_master` |

### Sub-Menu 3: Library Configuration (5)
| Table | Purpose |
|-------|---------|
| `lib_fine_type` | Fine type master (LateReturn/LostBook/DamagedBook/ProcessingFee) |
| `lib_fine_slab_config` | Fine slab rule (rate table per membership/resource type, priority ordering) |
| `lib_fine_slab_details` | Day-range rate rows per slab; `calculation_type` ENUM (Per_Day/Per_Week/Per_Book) |
| `lib_account_entry_config` | Maps fine type + slab → `acc_account_groups` + `acc_ledgers` for accounting integration |
| `lib_library_status_masters` | Central status master for all ENUM-like status codes across module |

### Sub-Menu 4: Acquisition & Cataloging (13)
| Table | Purpose |
|-------|---------|
| `lib_books_master` | Central catalogue; FULLTEXT index on title/subtitle/summary |
| `lib_book_author_jnt` | Book–Author M:N (`author_order`, `is_primary`) |
| `lib_book_category_jnt` | Book–Category M:N |
| `lib_book_genre_jnt` | Book–Genre M:N |
| `lib_book_subject_jnt` | Book–Class–Subject M:N (curricular alignment) |
| `lib_book_keyword_jnt` | Book–Keyword M:N |
| `lib_book_purchases` | Purchase/acquisition header (vendor, bill_no, bill_amt) |
| `lib_book_purchases_items` | Purchase line items (book_id, quantity, price, tax) |
| `lib_book_copies` | Physical copy tracking (accession, barcode, rfid_tag NULL-able in v7) |
| `lib_book_condition_jnt` | Condition history per copy |
| `lib_digital_resources` | Digital file records; `license_count` for concurrent license limit |
| `lib_digital_access_request_types` | Request type master (Download/View_Online/Stream/Offline/Extended) |
| `lib_digital_resource_tags` | Tags per digital resource |

### Sub-Menu 5: Member & Access Management (3)
| Table | Purpose |
|-------|---------|
| `lib_membership_types` | Borrowing rules; `digital_access_days`; `can_restricted_members_view_list` |
| `lib_members` | Member profiles; analytics fields; `user_type` ENUM(Student/Teacher/Staff) |
| `lib_digital_resource_access_restrictions` | Row-level access control per digital resource (role/designation/dept/user) |

### Sub-Menu 6: Operation Management (6)
| Table | Purpose |
|-------|---------|
| `lib_physical_book_requests` | Physical book requests (borrowing + renewal) — RENAMED from `lib_reservations` in v7 |
| `lib_transactions` | Book issue/return records |
| `lib_digital_access_requests` | Digital resource access request workflow |
| `lib_digital_access_transactions` | Granted digital access sessions; download tracking, view duration |
| `lib_fines` | Fine records; `transaction_type ENUM('Digital','Physical')` discriminator |
| `lib_fine_payments` | Fine payment records |

### Sub-Menu 7: Audit & History (3)
| Table | Purpose |
|-------|---------|
| `lib_transaction_history` | Audit trail per transaction event (both physical and digital) |
| `lib_inventory_audit` | Audit session header |
| `lib_inventory_audit_details` | Per-copy scan records (found/missing/misplaced/damaged) |

### Sub-Menu 8: Advanced Analytics (6 — schema exists, no service/UI built)
| Table | Purpose |
|-------|---------|
| `lib_reading_behavior_analytics` | Per-member reading patterns (FK → `academic_years.id`) |
| `lib_book_popularity_trends` | Daily popularity score per book |
| `lib_collection_health_metrics` | Collection-level utilization, diversity, turnover metrics |
| `lib_predictive_analytics` | ML output: demand forecast, churn, acquisition recommendations |
| `lib_curricular_alignment` | Book–class–subject alignment scoring (FK → `academic_years.id`) |
| `lib_engagement_events` | Granular interaction events (16 event types) |

### Sub-Menu 9: New Tables (3)
| Table | Purpose |
|-------|---------|
| `lib_book_reviews_ratings` | Member book ratings (1–5) + moderated review text |
| `lib_wishlist` | Personal reading wishlist |
| `lib_library_config` | Library settings key-value store (per `academic_years.id`, NULL = global default) |

### DB Triggers & Events (defined in Sub-Menu 11)
| Object | Trigger |
|--------|---------|
| `update_member_borrowed_count` | AFTER INSERT on `lib_transactions` — increments member `total_books_borrowed` |
| `update_copy_status_on_issue` | AFTER INSERT on `lib_transactions` — updates copy status to `Issued` |
| `update_copy_status_on_return` | AFTER UPDATE on `lib_transactions` — updates copy status to `Available` on return |
| `auto_calculate_fines` | MySQL EVENT: daily — inserts `lib_fines` for overdue transactions respecting `grace_period_days` |

### DB Views (Sub-Menu 12)
`lib_view_member_360`, `lib_view_collection_performance`, `lib_view_predictive_demand`, `lib_view_overdue_books`, `lib_view_most_issued_books`

---

## Feature Groups & Implementation Status

| Sub-Module | FR | Tables | Status |
|-----------|-----|--------|--------|
| Reference Masters | FR-LIB-001–011 | lib_resource_types, lib_categories, lib_genres, lib_publishers, lib_authors, lib_keywords, lib_book_conditions, lib_membership_types, lib_shelf_locations | ✅ ~100% |
| Digital Resources | FR-LIB-012–013 | lib_digital_resources, lib_digital_resource_tags | 🟡 ~70% |
| Member Management | FR-LIB-014–016 | lib_members | ✅ ~85% |
| Book Circulation | FR-LIB-017–022 | lib_transactions, lib_transaction_history | ✅ ~80% |
| Reservations / Holds | FR-LIB-023–025 | lib_physical_book_requests | 🟡 ~60% (notification not wired) |
| Inventory Audit | FR-LIB-026–027 | lib_inventory_audit, lib_inventory_audit_details | ✅ ~90% |
| Fine Config | FR-LIB-028 | lib_fine_slab_config, lib_fine_slab_details, lib_fine_type | ✅ ~90% |
| Fine Collection | FR-LIB-029–031 | lib_fines, lib_fine_payments | 🟡 ~50% (no auth on LibFineController) |
| Reports & Dashboard | FR-LIB-032–038 | Report services | ✅ ~75% (no auth on report controllers) |
| Book Acquisition | FR-LIB-039 (proposed) | lib_book_purchases, lib_book_purchases_items | ❌ 0% — no controller/service |
| Digital Access Workflow | — (DDL v7 addition) | lib_digital_access_requests, lib_digital_access_transactions | ❌ 0% — no controller/service |
| Book Reviews & Ratings | — (DDL v7 addition) | lib_book_reviews_ratings | ❌ 0% |
| Wishlist | — (DDL v7 addition) | lib_wishlist | ❌ 0% |
| Advanced Analytics | FR-LIB-036 | lib_reading_behavior_analytics, lib_book_popularity_trends, etc. | ❌ 0% (schema only) |

---

## Known Gaps & Open Issues

### P0 — Critical Security (Must Fix Before Production)

1. **`EnsureTenantHasModule` middleware MISSING** from library route group (`routes/tenant.php` line 2719). Fix:
   ```
   Change: ['auth', 'verified']
   To:     ['auth', 'verified', 'tenant.module:Library']
   ```

2. **6 controllers with zero `Gate::authorize()` calls:**
   - `LibraryController` (hub — all main library operations exposed)
   - `MasterDashboardController`
   - `LibFineController` — **HIGH RISK**: fine collection and waiver without any authorization
   - `LibCirculationReportController`
   - `LibFineReportController`
   - `LibReportPrintController`

### DDL Issues (v7 file — must fix before migration)

| # | Severity | Issue |
|---|----------|-------|
| DDL-001 | P0 | Views (`lib_view_member_360`, `lib_view_collection_performance`, performance index) reference `lib_reservations` — table was RENAMED to `lib_physical_book_requests` in v7. Migration will fail. |
| DDL-002 | P0 | `lib_background_services` referenced in seed data (`INSERT INTO lib_background_services`) but table is NOT defined anywhere in DDL. Seed will fail. |
| DDL-003 | P1 | `academic_years` FK used in `lib_reading_behavior_analytics` and `lib_curricular_alignment` — table name format (`academic_years`) doesn't match the `sch_*` naming convention. Verify correct table name. |
| DDL-004 | P1 | `lib_membership_types` seed data references `fine_rate_per_day` column (line 1792 seed values include it), but the column was commented out in the v7 table definition. Seed insert will fail if `fine_rate_per_day` removed. |
| DDL-005 | P2 | `lib_view_overdue_books` view references `mt.fine_rate_per_day` in SELECT + `estimated_fine` calculation, but this column is commented out in `lib_membership_types`. View query will fail. |
| DDL-006 | P2 | `lib_digital_access_transactions.lib_view_member_360` subquery joins `lib_reservations` — same rename issue as DDL-001. |

### Logic Gaps (Existing Implementation)

- `grace_period_days` field EXISTS in `lib_membership_types` but is NOT enforced in fine calculation engine — fines start from due date with no grace deduction
- `lib_members.outstanding_fines` decrement on payment/waiver not verified in `LibFine::markPaid()`
- Digital resource license expiry NOT enforced in `LibDigitalResourceController::incrementDownload()` — expired licenses still downloadable
- `lib_reservations` table name used in existing code — rename to `lib_physical_book_requests` will break it

### Structural / Code Quality (Existing Implementation)

- 22 controllers unnecessarily import `Modules\Vendor\Models\Vendor` — copy-paste artifact
- Multiple controllers use `$request->all()` instead of `$request->validated()`
- No unit or feature tests — only 15 browser (Dusk) tests covering basic CRUD
- `lib_members.calculateSegment()` endpoint exists but segmentation algorithm not implemented
- No scheduled commands (`library:send-overdue-reminders`, `library:expire-reservations`, `library:expire-memberships`)
- Google Books API key not configured — rate limited without key
- `IsbnLookupService` has no timeout or error handling on external API calls
- `LibCirculationReportService` uses in-memory collection iteration — performance risk at 5,000+ records

### Technical Audit 2026-06-29 — New Confirmed Findings (Mode A, live code)

| Code | Sev | Finding | File:Line |
|------|-----|---------|-----------|
| BUG-LIB-012 | P0 | `dd($e);` in the LIVE `update()` catch block — dumps stack trace + halts before `DB::rollBack()` runs | `LibBookMasterController.php:481` |
| SEC-LIB-012 | P1 | Fine **waiver** gated by generic `tenant.lib-fines.update` (same perm as pay) — any Librarian can waive, violating BR-LIB-048 (Supervisor-only). FormRequest authorize() also `true`. | `LibFineController.php:339,321` |
| SEC-LIB-013 | P1 | `$transaction->update($request->all())` mass-assignment (D25); `LibTransaction` fillable exposes `member_id,status,due_date,return_date` → circulation tampering. +3 sites. | `LibTransactionController.php:314`; `LibInventoryAuditDetailController.php:437`; `LibFineSlabDetailController.php:50,94` |
| BUG-LIB-013 | P1 | Fine payment uses `$payment->amount` but column is `amount_paid` → `increment/decrement` by NULL; member `outstanding_fines` NOT reduced (BR-LIB-047 broken on partial-payment path). | `LibFinePaymentController.php:46-47` |
| DAT-LIB-001 | P1 | Checkout (`store()`) eligibility is unlocked read-modify-write (copy-available CHECK-1; max-books CHECK-4) with no `lockForUpdate` and no surrounding `DB::transaction` → double-issue / over-limit race (BR-LIB-019/021); 3 writes non-atomic. | `LibTransactionController.php:94-224` |
| VAL-LIB-003 | P1 | Fine payment amount only `min:0.01` — no validation vs remaining balance (BR-LIB-044) and store() never auto-settles fine to Paid (BR-LIB-046). | `LibFinePaymentRequest.php:14-23`; `LibFinePaymentController.php:36-58` |
| DAT-LIB-002 | P2 | Unlocked fine settlement; two divergent payment paths (`LibFine::markPaid` vs `LibFinePaymentController`) can both run for one Pending fine → double-decrement reachable. | `LibFine.php:143,176`; `LibFineController.php:196-261` |
| SEC-LIB-014 | P2 | Library route group lacks `tenant.module:Library` subscription gate (tenancy isolation itself is intact — full stancl stack present). | `RouteServiceProvider.php:41-50` |
| DEAD-LIB-014 | P3 | Unused `use Modules\Vendor\Models\Vendor;` import in 18 controllers (only the acquisition/copy flow needs it). | `app/Http/Controllers/` (17 redundant) |

**Corrections to prior knowledge (verified live 2026-06-29):**
- **Tenancy is correctly wired** — `RouteServiceProvider.php:41-50` applies `web, InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive, auth, verified` to all `/library/*` routes. Earlier "Library not wired into tenancy" note (known-issues line 138) is OUTDATED — routes are now module-owned (D22) under the full stack. The remaining gap is only the `tenant.module:Library` subscription gate (SEC-LIB-014, P2) — downgraded from the prior "P0".
- **`LibFineController` is NOT zero-auth** — every action (incl. `waive` :339, `markPaid` :293) now has `Gate::authorize`. The real issue is permission *granularity* (SEC-LIB-012), not absence. The module-knowledge "LibFineController — HIGH RISK: no auth" line is stale.
- **Layer-5.2 "commented gates in LibInventoryAuditController (5 sites)" is a FALSE POSITIVE** — those `//Gate::authorize` lines are inside fully commented-out alternate method bodies; the live methods below carry active gates. It is dead code (DEAD-LIB-002), not an auth hole.
- **D30 count is now 28/28 FormRequests returning `true`** (was 27 — `StoreLibBookPurchaseRequest` added). Still tracked under SEC-LIB-011.
- Health this pass: **capped 40/100 (P0 present)**. Tenancy Green; Layers 4/5/7/8 Red.

### Not Yet Built (DDL v7 tables with zero implementation)
- `lib_book_purchases` + `lib_book_purchases_items` — acquisition workflow
- `lib_digital_access_requests` + `lib_digital_access_transactions` — digital access workflow
- `lib_digital_resource_access_restrictions` — role/dept-based digital access control
- `lib_account_entry_config` + accounting integration
- `lib_book_reviews_ratings` — review + rating system
- `lib_wishlist` — member wishlist
- `lib_library_config` — library settings screen
- All 6 analytics tables (schema only)

---

## Design Decisions Made

1. **`lib_library_status_masters` replaces all ENUMs**: Status fields in all `lib_*` tables use `SMALLINT UNSIGNED FK → lib_library_status_masters` instead of inline ENUMs. 10 status type groups covering book/digital/member/transaction/reservation/fine/audit statuses. `is_system = 1` seeds are protected.

2. **`lib_physical_book_requests` combines reservation + renewal request**: V7 renamed `lib_reservations` to `lib_physical_book_requests` and added `is_renewal_request` flag. One table handles both "hold for a book" and "request to renew a borrowed copy." This breaks all existing code and views that reference `lib_reservations`.

3. **`lib_fine_type` master replaces ENUM**: Fine type (LateReturn/LostBook/DamagedBook/ProcessingFee) is now a FK → `lib_fine_type` master, enabling admin to add fine types without code changes.

4. **`lib_shelf_locations` uses component FKs**: Zone/Floor/Aisle/Shelf/Rack are separate FK refs → `lib_locations_master`. Each location component has its own code and name. More granular than flat VARCHAR columns in v1.

5. **`lib_fines.transaction_type ENUM('Digital','Physical')`**: Single `lib_fines` table covers both physical book fines (FK → `lib_transactions`) and digital access fines (FK → `lib_digital_access_transactions`). Both FK columns are nullable; CHECK constraint (not in DDL — must add in code) should enforce exactly one is non-null.

6. **`lib_book_copies.rfid_tag` is now NULL-able in v7**: Fixed the P2 DDL-003 gap from v1/req doc. RFID is optional; UNIQUE constraint remains (MySQL UNIQUE ignores multiple NULLs).

7. **`lib_digital_access_transactions` tracks per-session access windows**: One row per granted access grant. Re-request after expiry creates new row. `download_history_json` appends each download event as JSON. `status` transitions: Active → Expired (scheduled job) / Revoked (manual) / Completed (member closes).

8. **`lib_book_category_jnt` DDL-002 FIXED in v7**: Dual PK bug removed. Now uses `id AUTO_INCREMENT` as PK only; `UNIQUE KEY (book_id, category_id)` enforces M:N uniqueness.

9. **MySQL triggers on `lib_transactions`** handle cascading updates: trigger auto-updates `lib_book_copies.status` on issue and return; trigger increments `lib_members.total_books_borrowed` on issue. These are DB-level triggers, not Laravel model events.

10. **`auto_calculate_fines` MySQL EVENT**: Daily event auto-inserts `lib_fines` records for overdue transactions. Uses `DECLARE/SELECT INTO` pattern to resolve status IDs from `lib_library_status_masters` dynamically (avoids hard-coded ENUM values). Fine is only inserted if no existing pending fine for that transaction exists.

11. **`lib_book_purchases` links to `lib_book_copies`**: Purchase items can reference the copy created after purchase. `book_copy_id` on `lib_book_purchases_items` is nullable — set after the copy is created. Enables acquisitions report to show cost per copy.

12. **`lib_library_config` is per-academic-year**: `UNIQUE (academic_year_id, setting_key)`. `academic_year_id = NULL` = global default; school sets year-specific overrides. Values are read-only after creation by design (`User can only update setting_value & description`).

13. **`lib_digital_resource_access_restrictions` CHECK constraint**: `CHECK (role_id IS NOT NULL OR designation_id IS NOT NULL OR department_id IS NOT NULL OR user_id IS NOT NULL)` — at least one restriction dimension must be set. No orphan restriction rows.

14. **`lib_book_reviews_ratings.is_faculty` flag**: Single table for both student and faculty reviews. Faculty reviews update `lib_books_master.academic_rating`; student reviews update `lib_books_master.student_rating` / `rating_count`. `is_approved` moderation flag before display.

15. **Analytics tables reference `academic_years.id`**: `lib_reading_behavior_analytics`, `lib_curricular_alignment`, and `lib_library_config` FK to `academic_years.id` (not `sch_academic_term` or `sch_academic_sessions`). Verify this table name before writing migrations.

---

## State Machine Summaries

| FSM | States |
|-----|--------|
| Book Copy Status | `Available` → `Issued` (trigger on insert) → `Available` (trigger on return) / `Reserved` / `Under_Maintenance` / `Lost` / `Withdrawn` |
| Transaction | `Issued` → `Returned` / `Overdue` (daily event) / `Lost` |
| Physical Book Request | `Pending` → `Available` (notification sent) → `Picked_Up` / `Expired` (scheduler) / `Cancelled` |
| Renewal Request | `Pending` → `Approved` / `Rejected` / `Withdrawn` |
| Digital Access Request | `Pending` → `Approved` (→ creates lib_digital_access_transactions) / `Rejected` / `Withdrawn` |
| Digital Access Transaction | `Active` → `Expired` (scheduler) / `Revoked` (manual) / `Completed` |
| Fine | `Pending` → `Paid` (→ creates lib_fine_payments) / `Waived` |
| Membership | `Active` → `Expired` (scheduler — not built) / `Suspended` / `Deactivated` |
| Inventory Audit | `In_Progress` → `Completed` / `Cancelled` |
| Book Review | `pending moderation` (is_approved=0) → `approved` (is_approved=1) |
| Digital Resource | `Available` → `License_Consumed` / `License_Expired` |

---

## Key Business Rules

| Rule | Status |
|------|--------|
| BR-LIB-001: Member cannot borrow more than `max_books_allowed` simultaneously | ✅ enforced |
| BR-LIB-002: Due date = issue_date + loan_period_days | ✅ |
| BR-LIB-003: `is_reference_only = true` → cannot be borrowed | ✅ |
| BR-LIB-004: Copy condition where `is_borrowable = false` → cannot be issued | ✅ |
| BR-LIB-005/006: Suspended/Deactivated/Expired members cannot borrow | ✅ |
| BR-LIB-007: Renewal only if `renewal_allowed = true` AND `renewal_count < max_renewals` | ✅ |
| BR-LIB-010: Fine accrual starts after due date — grace period NOT yet deducted | 🟡 gap |
| BR-LIB-011: `days_overdue = return_date - due_date - grace_period_days` | 📐 proposed |
| BR-LIB-012: Fine = days_overdue × rate_per_day per matching slab detail | ✅ |
| BR-LIB-013: Total fine capped at `max_fine_amt` | ✅ |
| BR-LIB-014: Higher `priority` slab evaluated first | ✅ |
| BR-LIB-015: Fallback fine rate = `fine_rate_per_day × days_overdue` from membership type | 🟡 rate column commented out in v7 — fallback broken |
| BR-LIB-016: Only `Pending` fines can be paid or waived | ✅ |
| BR-LIB-017: Fine creation increments `lib_members.outstanding_fines` | ✅ |
| BR-LIB-018: Fine payment/waiver decrements `lib_members.outstanding_fines` | 🟡 needs verification |
| BR-LIB-019: One active reservation per (book, member) — UNIQUE on (book_id, member_id, status) | ✅ |
| BR-LIB-022: Auto-expire reservation after `pickup_by_date` | ❌ no scheduler |
| BR-LIB-023: Notification on reservation available — flag set; dispatch NOT wired | 🟡 |
| BR-LIB-024: Only one inventory audit session `In Progress` at a time | 🟡 business rule only; no DB enforcement |
| BR-LIB-028: Digital resource blocked after `license_end_date` | ❌ not enforced in controller |
| BR-LIB-030: `access_restriction` JSON evaluated before serving download | ❌ not implemented |
| MySQL daily event: auto-inserts lib_fines for overdue transactions | DDL-only; Laravel event scheduler NOT set up |

---

## Cross-Module Dependencies

### Inbound (LIB reads from)

| Module | Table | Usage |
|--------|-------|-------|
| System (SYS) | `sys_users` | `lib_members.user_id` (INT UNSIGNED) |
| System (SYS) | `sys_media` | `lib_books_master.cover_image_media_id`, `lib_digital_resources.file_media_id` |
| System (SYS) | `sys_roles`, `sys_designations`, `sys_departments` | `lib_digital_resource_access_restrictions` FKs |
| System (SYS) | `sys_dropdown_table` | `lib_books_master.language`, `lib_members.preferred_language` |
| SchoolSetup (SCH) | `sch_buildings` | `lib_locations_master.building_id`, `lib_shelf_locations.building_id` |
| SchoolSetup (SCH) | `sch_classes`, `sch_subjects` | `lib_book_subject_jnt`, `lib_curricular_alignment` |
| GlobalMaster (GLB) | `glb_countries` | `lib_authors.country_id` |
| Academic (SYS?) | `academic_years` | `lib_reading_behavior_analytics`, `lib_curricular_alignment`, `lib_library_config` — **verify table name** |
| Vendor (VND) | `vnd_vendors` | `lib_book_purchases.vendor_id` (acquisition) |
| Accounting (ACC) | `acc_account_groups`, `acc_ledgers` | `lib_account_entry_config` — fine → journal posting |

### Outbound (Modules that depend on LIB)

| Target Module | What Is Sent / What It Reads |
|--------------|------------------------------|
| Notification (NTF) | Reservation availability, overdue reminders, membership expiry — **NOT YET WIRED** |
| Student Portal (STP) | OPAC catalogue browse, self-service reservation, fine viewing — **planned** |
| Parent Portal (PPT) | Child's borrowing history, outstanding fines — **planned** |
| SLK (SyllabusBooks) | Link `lib_books_master` → `bok_syllabus_books` via ISBN — **planned** |
| Accounting (ACC) | Fine payments → journal vouchers via `lib_account_entry_config` — **not implemented** |

### Module Independence Notes
- `lib_fines` is LIB-internal; fine-to-StudentFee transfer is a future integration
- LIB has its own `lib_digital_resource_access_restrictions` table — does not share with sys_permissions
- 22 controllers unnecessarily import `Modules\Vendor\Models\Vendor` — only `LibBookCopyController` actually needs it

---

## Technology Stack Notes

- **DomPDF** — circulation analysis report, fine collection report, overdue report, acquisition report, digital report, all PDF print routes
- **Open Library API** — ISBN metadata lookup (no API key required)
- **Google Books API** — ISBN fallback (no API key configured — rate limited)
- **FULLTEXT INDEX** — `lib_books_master` (title, subtitle, summary); `lib_digital_resources` (file_name) — enables `MATCH() AGAINST()` search
- **MySQL Triggers** — 3 triggers on `lib_transactions` (copy status + member counter); fires on INSERT/UPDATE — NOT Laravel model events
- **MySQL Event Scheduler** — `auto_calculate_fines` daily event; separate from Laravel scheduler
- **SoftDeletes** — all 35 existing models have SoftDeletes trait; analytics + junction tables may not

---

## Remaining Implementation Work

### Phase A — Critical Fixes (P0)
1. Add `EnsureTenantHasModule` to route group
2. Add `Gate::authorize()` to 6 zero-auth controllers (especially `LibFineController::waive`)
3. Fix DDL-001: rename `lib_reservations` → `lib_physical_book_requests` in all views + indexes + existing code
4. Fix DDL-002: remove seed data for `lib_background_services` (table not defined)
5. Resolve `fine_rate_per_day` column removal from `lib_membership_types` — fix seed and `lib_view_overdue_books`

### Phase B — Business Logic Fixes (P1)
6. Standardize permission prefix to `tenant.lib-*` everywhere
7. Replace `$request->all()` with `$request->validated()` in 7+ controllers
8. Enforce `grace_period_days` in fine calculation (FR-LIB-046)
9. Verify `outstanding_fines` decrement in `LibFine::markPaid()` and `LibFine::waive()`
10. Enforce digital resource license check before download
11. Wire NTF notification dispatch in `LibReservation::markAvailable()`
12. Build 3 Artisan scheduled commands (overdue-reminders, expire-reservations, expire-memberships)

### Phase C — New DDL v7 Features (P2+)
13. Book Acquisition workflow (`lib_book_purchases` + `lib_book_purchases_items` + controller/service)
14. Digital Access Request + Transaction workflow (new sub-module)
15. Digital Resource Access Restrictions enforcement
16. Book Reviews & Ratings screen + approval workflow
17. Member Wishlist screen
18. Library Config settings screen
19. Accounting integration (`lib_account_entry_config` → journal posting on fine payment)
20. Advanced Analytics services for 6 analytics tables

---

## Lessons Learned

- [2026-06-25 | FRD] Always separate "Book Catalog Management" from "Book Acquisition & Copy Registration" — they share the word "book" but have completely different actors, rules, and integrations.
- [2026-06-25 | FRD] Fine configuration deserves its own REQ — the permission split (Supervisor waives, Librarian collects) is invisible if they're merged.
- [2026-06-25 | FRD] The V2 technical requirement doc gives field-level accuracy; preliminary screen files give UX context — both are needed. V2 alone produces technically accurate but UX-thin FRD sections.
- [2026-06-27 | DDL Seed] `lib_reservations` was renamed to `lib_physical_book_requests` in DDL v7 but views + indexes in the same file still reference the old name — must audit all DDL cross-references when renaming tables.
- [2026-06-27 | DDL Seed] DDL v7 removes `lib_membership_types.fine_rate_per_day` from table definition but the seed data and `lib_view_overdue_books` still use it — column removal must cascade to views, seeds, and Laravel fallback logic.
- [2026-06-29 | Technical Auditor] A `dd($e)` can hide in a catch block that otherwise looks correct (it sits ABOVE `DB::rollBack()` + `Log::error()`), so the method reads as production-safe at a glance — always read the first line of every catch, not just the last. (`LibBookMasterController.php:481`)
- [2026-06-29 | Technical Auditor] Atomic `increment()/decrement()` protects the *counter write* but NOT the *eligibility decision*: the borrow-limit/copy-available checks in checkout are a separate read-modify-write and need `lockForUpdate` + a transaction. Counting `->increment()` as "concurrency-safe" is a trap.
- [2026-06-29 | Technical Auditor] Column-name drift is a silent money bug: `$payment->amount` vs the real `amount_paid` column makes `decrement('outstanding_fines', null)` no-op — fines never clear and no error surfaces in the happy path. Always diff controller attribute reads against the model `$fillable` + migration.
- [2026-06-29 | Technical Auditor] "Has a Gate::authorize" ≠ "correctly authorized". `LibFineController::waive` is gated, but on the *pay* permission — a business-rule (BR-LIB-048 Supervisor-only) breach that a presence-only authz grep misses. Cross-check each gate string against the FRD role matrix.
- [2026-06-29 | Technical Auditor] Guardrail win: commented `//Gate::authorize` lines flagged by a Layer-5.2 grep were inside fully commented-out alternate method bodies (dead code), not disabled gates on live methods — confirm the surrounding method is live before raising a SEC finding.

---

## Pending Next Steps

| # | Work | Agent | Priority |
|---|------|-------|----------|
| 1 | Fix 5 DDL migration issues above (DDL-001 to DDL-005) | `act as DB Architect` | P0 before migration |
| 2 | Add `EnsureTenantHasModule` + `Gate::authorize()` to 6 controllers | `act as Developer` | P0 |
| 3 | Verify exact `academic_years` table name in tenant_db_v4.sql | `act as DB Architect` | P0 |
| 4 | DDL Gap Analysis: FRD Section REQ list vs DDL v7 48 tables | `act as DB Architect` | P1 |
| 5 | Code Gap Analysis: Map FRD REQs → existing 26 controllers → identify unimplemented | `act as Technical Auditor` | P1 |
| 6 | Implement 3 scheduled Artisan commands | `act as Developer` | P1 |
| 7 | Build `TransactionService`, `ReservationService`, `FineCalculationService` | `act as Developer` | P1 |
| 8 | Book Acquisition workflow (new controller + service for `lib_book_purchases`) | `act as Developer` | P2 |
| 9 | Digital Access workflow (new controller + service for `lib_digital_access_requests`) | `act as Developer` | P2 |
| 10 | DDL v7 new tables (purchases, digital-access workflow, reviews, wishlist, config) remain captured as REQ-LIB-003/011 + ENH backlog in FRD v2.0; promote relevant ENH- items to REQ- when scoped for a release | `act as Business Analyst` | P2 |
| 11 | Run DDL + Code gap analysis against FRD v2.0 Section 10.1 coverage flags (now with corrected P0/P1 split) | `act as DB Architect` / `act as Technical Auditor` | P1 |

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-25 | Business Analyst | FRD v1.0 generated (13 REQ, 60 BR, 4 workflows, 6 reports, 15 enhancements). Module knowledge file v1 created from FRD + code audit. |
| 2026-06-27 | Business Analyst | Knowledge file rebuilt from V2 requirement doc + DDL v7 (48 tables). DDL v7 gaps documented (table rename, missing triggers/views in req doc, new 13 tables, critical DDL migration blockers). Preserved all code-audit findings from v1. |
| 2026-06-29 | Business Analyst | FRD superseded → `LIB_FRD_2026-06-29.md` (v2.0, flat layout). Preserved all 13 REQ / 60 BR / 6 RPT / 15 ENH IDs and denominators (no renumbering). Fixed Section 10.4 P0/P1 miscount (6/7 → 8/5). Honored Library design lessons (catalog vs acquisition; fine config vs collection). Added FRD Summary block; refreshed FRD path reference and Pending Next Steps. |
| 2026-06-29 | Technical Auditor | Mode A 12-layer deep audit (live code). 9 new codes: BUG-LIB-012 (P0 dd in live catch), SEC-LIB-012/013, BUG-LIB-013, DAT-LIB-001, VAL-LIB-003 (P1), DAT-LIB-002/SEC-LIB-014 (P2), DEAD-LIB-014 (P3). Health capped 40/100 (P0). Corrected stale notes: tenancy IS wired (full stancl stack); LibFineController IS gated (granularity issue only); Layer-5.2 commented-gate flag = false positive (dead code). Report: `3-Audit_Reports/V1_Jun-2026/Library_Technical_Audit_2026-06-29.md`. |
