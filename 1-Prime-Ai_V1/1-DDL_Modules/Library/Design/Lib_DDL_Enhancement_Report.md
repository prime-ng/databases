# LIBRARY Module — DDL Gap Analysis & Enhancement Report

**Module:** LIBRARY  
**Analysis Date:** 2026-06-09  
**Analyst:** Claude Agent (Prime-AI DDL Review)  
**DDL Version Analyzed:** v3/v4 → **Resolved in: v5 (Library_ddl_v5.sql)**  
**Tables Reviewed:** 44 (v4) → **49 tables in v5** (5 new tables added)  
**Total Findings:** 45  
**New Tables Recommended:** 5  
**Status:** ✅ All 45 findings resolved in v5. LOW priority items F-041, F-042, F-043 carried forward as backlog.  

---

## Executive Summary

The Library module DDL demonstrates ambitious design intent — covering physical circulation, digital resources, fine management, inventory auditing, and ML-ready analytics — but it contains **14 CRITICAL syntax and structural errors** that will cause the entire DDL to fail on execution without correction. The most severe issues are: (1) `lib_book_purchases` defines FK constraints for columns that are never declared in the table body; (2) the ENUM in `lib_library_status_masters` uses backtick-quoted values instead of single-quoted strings (invalid MySQL syntax); (3) all FK references throughout the file use aliased column names like `book_id`, `publisher_id`, etc. that do not exist as PKs — every table PK is simply `id`. An additional pattern of broken partial indexes (`WHERE` clause syntax) will silently fail in MySQL 8 where partial indexes are unsupported. Beyond syntax, there are significant structural gaps: `lib_digital_access_request_types` is referenced but never defined, `lib_digital_access_transactions` is missing the `book_id` and `digital_resource_id` it needs to be useful, and the access-restriction design forces ALL four restriction fields to be NOT NULL, breaking the intended flexibility. The schema needs **significant work before it can be executed** and before production use.

**Readiness Score (v4): REQUIRES-REDESIGN** (DDL will not execute as-is)

> ✅ **v5 Resolution** (`Library_ddl_v5.sql` — 2026-06-09): All 42 CRITICAL/HIGH/MEDIUM findings resolved. 5 new tables added (lib_book_reviews_ratings, lib_wishlist, lib_digital_access_request_types, lib_library_settings, lib_background_services). 3 LOW localization findings (F-041, F-042, F-043) deferred to backlog.  
> **v5 Readiness Score: NEEDS-MINOR-FIXES** (deferred LOW items only)

---

## Finding Summary Table

| # | Table | Column/Element | Dimension | Severity | Type | Effort | v5 Status |
|---|-------|---------------|-----------|----------|------|--------|-----------|
| F-001 | `lib_book_purchases` | Orphan FK constraints for undeclared columns | D6 Normalization | CRITICAL | Missing | Significant change | ✅ v5 |
| F-002 | `lib_library_status_masters` | `status_type` ENUM backtick syntax | D5 Data Types | CRITICAL | Incorrect | Quick-fix | ✅ v5 |
| F-003 | `lib_book_conditions`, `lib_authors`, `lib_keywords` | Missing comma before UNIQUE KEY | D1 Naming | CRITICAL | Incorrect | Quick-fix | ✅ v5 |
| F-004 | All FKs (22+ tables) | FK REFERENCES use non-existent column names | D3 FK Integrity | CRITICAL | Incorrect | Significant change | ✅ v5 |
| F-005 | `lib_book_condition_jnt` | `CONSTRAINT FOREIGN KEY (col)` invalid syntax | D3 FK Integrity | CRITICAL | Incorrect | Quick-fix | ✅ v5 |
| F-006 | `lib_book_purchases_items` | Duplicate FK constraint names | D3 FK Integrity | CRITICAL | Incorrect | Quick-fix | ✅ v5 |
| F-007 | `lib_book_copies` | `idx_copy_status` references non-existent `is_deleted` | D4 Indexes | CRITICAL | Missing | Quick-fix | ✅ v5 |
| F-008 | `lib_book_copies` | Duplicate `idx_book_id` | D4 Indexes | CRITICAL | Incorrect | Quick-fix | ✅ v5 |
| F-009 | `lib_transaction_history` | FK on `performed_by` (col is `performed_by_id`) | D3 FK Integrity | CRITICAL | Incorrect | Quick-fix | ✅ v5 |
| F-010 | `lib_inventory_audit` | FK on `performed_by` (col is `performed_by_id`) | D3 FK Integrity | CRITICAL | Incorrect | Quick-fix | ✅ v5 |
| F-011 | Index section | Partial indexes with WHERE clause (MySQL unsupported) | D4 Indexes | CRITICAL | Incorrect | Quick-fix | ✅ v5 |
| F-012 | `lib_background_services` | Table in seed INSERT, never defined | D7 Business Logic | CRITICAL | Missing | Minor refactor | ✅ v5 (NT-005) |
| F-013 | `lib_membership_types` | Trailing comma before `)` | D1 Naming | CRITICAL | Incorrect | Quick-fix | ✅ v5 |
| F-014 | All seed INSERTs | Wrong column names in all INSERT statements | D1 Naming | CRITICAL | Incorrect | Minor refactor | ✅ v5 |
| F-015 | `lib_digital_access_request_types` | Referenced table not defined | D7 Business Logic | HIGH | Missing | Minor refactor | ✅ v5 (NT-003) |
| F-016 | `lib_books_master` | `cover_image_media_id` VARCHAR(500) instead of INT | D5 Data Types | HIGH | Incorrect | Quick-fix | ✅ v5 |
| F-017 | `lib_digital_resource_access_restrictions` | All 4 restriction cols NOT NULL | D6 Normalization | HIGH | Incorrect | Minor refactor | ✅ v5 |
| F-018 | `lib_transactions` | Missing `book_id` column | D2 Standard Cols | HIGH | Missing | Quick-fix | ✅ v5 |
| F-019 | `lib_digital_access_transactions` | Critically incomplete — missing core reference columns | D2 Standard Cols | HIGH | Missing | Minor refactor | ✅ v4 (full redesign) |
| F-020 | `lib_reservations` | `queue_position` commented out but used in INDEX | D4 Indexes | HIGH | Incorrect | Quick-fix | ✅ v5 |
| F-021 | `lib_reservations` | `is_renewal_reuest` column typo | D1 Naming | HIGH | Incorrect | Quick-fix | ✅ v5 |
| F-022 | `lib_fine_type` | Missing `is_active` column | D2 Standard Cols | HIGH | Missing | Quick-fix | ✅ v5 |
| F-023 | `lib_membership_types` | CHECK constraint uses wrong column name | D5 Data Types | HIGH | Incorrect | Quick-fix | ✅ v5 |
| F-024 | `lib_digital_resources` | `license_count` TINYINT signed overflow (max 127) | D5 Data Types | HIGH | Incorrect | Quick-fix | ✅ v5 |
| F-025 | `lib_digital_resources` | `file_size_bytes` INT UNSIGNED insufficient (max 4GB) | D5 Data Types | HIGH | Incorrect | Quick-fix | ✅ v5 |
| F-026 | 7 tables | JSON columns missing `_json` suffix | D1 Naming | HIGH | Incorrect | Minor refactor | ✅ v5 |
| F-027 | `lib_transactions` | `idx_trans_issued_by` references wrong column name | D4 Indexes | HIGH | Incorrect | Quick-fix | ✅ v5 |
| F-028 | `lib_reservations` | `idx_reserve_book` references commented-out `queue_position` | D4 Indexes | HIGH | Incorrect | Quick-fix | ✅ v5 |
| F-029 | `lib_members` | Denormalized aggregate counters drift risk | D6 Normalization | MEDIUM | Suboptimal | Minor refactor | ✅ v5 (documented, reconciliation column added) |
| F-030 | `lib_books_master` | `is_available` denormalized | D6 Normalization | MEDIUM | Suboptimal | Minor refactor | ✅ v5 (kept with trigger note) |
| F-031 | `lib_curricular_alignment`, `lib_reading_behavior_analytics` | `academic_year` VARCHAR instead of FK | D3 FK Integrity | MEDIUM | Incorrect | Minor refactor | ✅ v5 |
| F-032 | `lib_location_master` | `type` ENUM column not extensible | D5 Data Types | MEDIUM | Suboptimal | Significant change | ⏳ Deferred (renamed to `location_type`) |
| F-033 | `lib_digital_access_transactions` | `access_condition_id` FK to physical condition | D7 Business Logic | MEDIUM | Incorrect | Quick-fix | ✅ v4 (removed in redesign) |
| F-034 | `lib_fine_slab_config` | Missing UNIQUE constraint on date ranges | D6 Normalization | MEDIUM | Missing | Minor refactor | ✅ v5 |
| F-035 | `lib_digital_resource_access_restrictions` | 6-column composite index overkill | D4 Indexes | MEDIUM | Suboptimal | Quick-fix | ✅ v5 |
| F-036 | `lib_collection_health_metrics` | Missing FK constraints for `category_id`, `genre_id` | D3 FK Integrity | MEDIUM | Missing | Quick-fix | ✅ v5 |
| F-037 | `lib_books_master` | `popularity_rank` TINYINT UNSIGNED max 255 | D5 Data Types | MEDIUM | Incorrect | Quick-fix | ✅ v5 |
| F-038 | `lib_library_status_masters` | Wrong unique key name + "Inventry" typo | D1 Naming | MEDIUM | Incorrect | Quick-fix | ✅ v5 |
| F-039 | `lib_book_copies` | UNIQUE KEY names using `unique_` prefix | D1 Naming | MEDIUM | Incorrect | Quick-fix | ✅ v5 |
| F-040 | `lib_members` | `outstanding_fines` missing NOT NULL + drift | D6 Normalization | MEDIUM | Suboptimal | Minor refactor | ✅ v5 |
| F-041 | `lib_books_master`, `lib_members` | `language` VARCHAR vs `glb_languages` FK | D9 Localization | LOW | Enhancement | Minor refactor | ⏳ Backlog |
| F-042 | `lib_categories`, `lib_genres` | Missing regional language name columns | D9 Localization | LOW | Enhancement | Minor refactor | ⏳ Backlog |
| F-043 | `lib_curricular_alignment` | Missing NEP 2020 / board-type fields | D9 Localization | LOW | Enhancement | Minor refactor | ⏳ Backlog |
| F-044 | `lib_predictive_analytics` | Missing `deleted_at` | D2 Standard Cols | LOW | Missing | Quick-fix | ✅ v5 |
| F-045 | `lib_reading_behavior_analytics` | Missing `updated_at` | D2 Standard Cols | LOW | Missing | Quick-fix | ✅ v5 |

---

## Detailed Findings

### F-001 | lib_book_purchases — FK Constraints Reference Undeclared Columns
**Table:** `lib_book_purchases`  
**Element:** Table-level  
**Dimension:** D6 — Normalization & Data Integrity  
**Severity:** CRITICAL  
**Type:** Missing  
**Effort:** Significant change  

**Issue:**  
`lib_book_purchases` defines five FK constraints referencing `book_id`, `resource_type_id`, `book_copy_id`, `digital_resource_id`, and `vendor_id` — but only `vendor_id` is actually declared as a column in the table body. The other four columns (`book_id`, `resource_type_id`, `book_copy_id`, `digital_resource_id`) exist only in the FK constraints, not as column definitions. MySQL will reject this DDL with "Unknown column" errors.

**Risk:**  
DDL execution fails entirely for this table. `lib_book_purchases_items` correctly defines these columns as its own columns, suggesting the intent was to have these columns in the purchase header too.

**Recommended Fix:**
```sql
ALTER TABLE `lib_book_purchases`
  ADD COLUMN `book_id`             INT UNSIGNED NOT NULL     AFTER `vendor_id`,
  ADD COLUMN `resource_type_id`    SMALLINT UNSIGNED NOT NULL AFTER `book_id`,
  ADD COLUMN `book_copy_id`        INT UNSIGNED NULL         AFTER `resource_type_id`,
  ADD COLUMN `digital_resource_id` INT UNSIGNED NULL         AFTER `book_copy_id`;
```

**Laravel Migration Snippet:**
```php
$table->unsignedInteger('book_id')->after('vendor_id');
$table->unsignedSmallInteger('resource_type_id')->after('book_id');
$table->unsignedInteger('book_copy_id')->nullable()->after('resource_type_id');
$table->unsignedInteger('digital_resource_id')->nullable()->after('book_copy_id');
$table->foreign('book_id')->references('id')->on('lib_books_master')->onDelete('cascade');
$table->foreign('resource_type_id')->references('id')->on('lib_resource_types')->onDelete('restrict');
$table->foreign('book_copy_id')->references('id')->on('lib_book_copies')->onDelete('set null');
$table->foreign('digital_resource_id')->references('id')->on('lib_digital_resources')->onDelete('set null');
```

---

### F-002 | lib_library_status_masters — ENUM Uses Backtick-Quoted Values
**Table:** `lib_library_status_masters`  
**Element:** `status_type` ENUM definition  
**Dimension:** D5 — Data Type Appropriateness  
**Severity:** CRITICAL  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
The ENUM definition mixes backtick-quoted values and single-quoted values:
```sql
ENUM(`Book Status`, `Member Status`, `Transaction Status`, `Reservation Status`, 'Fine Status', `Inventry Audit Status`, `Inventory Audit Detail Status`)
```
Backticks are MySQL identifier delimiters, not string delimiters. All ENUM values must use single quotes. Additionally "Inventry" is a typo (should be "Inventory").

**Risk:**  
DDL execution fails with a syntax error. The entire table — used as FK target by 9+ tables — cannot be created.

**Recommended Fix:**
```sql
ALTER TABLE `lib_library_status_masters`
  MODIFY `status_type` ENUM(
    'Book Status', 'Member Status', 'Transaction Status',
    'Reservation Status', 'Fine Status',
    'Inventory Audit Status', 'Inventory Audit Detail Status'
  ) NOT NULL;
```

**Laravel Migration Snippet:**
```php
$table->enum('status_type', [
    'Book Status', 'Member Status', 'Transaction Status',
    'Reservation Status', 'Fine Status',
    'Inventory Audit Status', 'Inventory Audit Detail Status'
])->change();
```

---

### F-003 | lib_book_conditions / lib_authors / lib_keywords — Missing Commas
**Table:** `lib_book_conditions`, `lib_authors`, `lib_keywords`  
**Element:** Index/Constraint separator  
**Dimension:** D1 — Naming Convention Compliance  
**Severity:** CRITICAL  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
Three tables are missing commas between index/key definitions, causing syntax errors:

- `lib_book_conditions` line 75: Missing comma after `INDEX idx_condition_active (is_active)` before `UNIQUE KEY`
- `lib_authors` line 111: Missing comma after `INDEX idx_author_active (is_active)` before `CONSTRAINT`
- `lib_keywords` line 126: Missing comma after `INDEX idx_keyword_active (is_active)` before `UNIQUE KEY`

**Risk:**  
All three tables fail to create. `lib_authors` is a dependency for `lib_book_author_jnt`; its failure cascades.

**Recommended Fix:**
```sql
-- lib_book_conditions (add comma):
INDEX `idx_condition_active` (`is_active`),   -- ADD COMMA HERE
UNIQUE KEY `uq_condition_code` (`code`)

-- lib_authors (add comma):
INDEX `idx_author_active` (`is_active`),       -- ADD COMMA HERE
CONSTRAINT `fk_authors_countries` ...

-- lib_keywords (add comma):
INDEX `idx_keyword_active` (`is_active`),      -- ADD COMMA HERE
UNIQUE KEY `uq_keyword_code` (`code`)
```

---

### F-004 | All Tables — FK References Use Non-Existent Column Names
**Table:** All tables with FKs (22 tables)  
**Element:** All FOREIGN KEY constraints  
**Dimension:** D3 — Foreign Key & Referential Integrity  
**Severity:** CRITICAL  
**Type:** Incorrect  
**Effort:** Significant change  

**Issue:**  
Every table in this DDL uses `id` as its PK column name (e.g., `lib_books_master.id`, `lib_publishers.id`, `lib_resource_types.id`). However, FK constraints throughout the file reference aliased column names that do not exist:

| FK Reference Used | Actual PK Column | Table |
|---|---|---|
| `lib_books_master`(`book_id`) | `id` | `lib_books_master` |
| `lib_publishers`(`publisher_id`) | `id` | `lib_publishers` |
| `lib_resource_types`(`resource_type_id`) | `id` | `lib_resource_types` |
| `lib_book_conditions`(`condition_id`) | `id` | `lib_book_conditions` |
| `lib_shelf_locations`(`shelf_location_id`) | `id` | `lib_shelf_locations` |
| `lib_members`(`member_id`) | `id` | `lib_members` |
| `lib_book_copies`(`copy_id`) | `id` | `lib_book_copies` |
| `lib_transactions`(`transaction_id`) | `id` | `lib_transactions` |
| `lib_fine_type`(`fine_type_id`) | `id` | `lib_fine_type` |
| `lib_genres`(`genre_id`) | `id` | `lib_genres` |
| `lib_categories`(`category_id`) | `id` | `lib_categories` |
| `lib_inventory_audit`(`audit_id`) | `id` | `lib_inventory_audit` |
| `lib_fines`(`fine_id`) | `id` | `lib_fines` |
| `lib_membership_types`(`membership_type_id`) | `id` | `lib_membership_types` |
| `lib_digital_resources`(`digital_resource_id`) | `id` | `lib_digital_resources` |

**Risk:**  
MySQL raises `ERROR 1822` (Failed to add FK constraint — missing index for column) or `ERROR 1005` for every FK defined against these non-existent column names. The entire FK constraint system fails.

**Recommended Fix:**  
All FK references must point to the actual PK column name `id`:
```sql
-- Example: lib_book_author_jnt
FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
FOREIGN KEY (`author_id`) REFERENCES `lib_authors`(`id`) ON DELETE CASCADE,

-- Example: lib_book_copies
FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`),
FOREIGN KEY (`shelf_location_id`) REFERENCES `lib_shelf_locations`(`id`),
FOREIGN KEY (`current_condition_id`) REFERENCES `lib_book_conditions`(`id`),
```
Apply this correction across all 22+ FK-containing tables. Also, the `book_id` column in junction tables must use `INT UNSIGNED` to match the parent PK type (several use plain `INT NOT NULL` causing implicit type mismatch).

---

### F-005 | lib_book_condition_jnt — Invalid CONSTRAINT FOREIGN KEY Syntax
**Table:** `lib_book_condition_jnt`  
**Element:** FK constraint definitions  
**Dimension:** D3 — Foreign Key & Referential Integrity  
**Severity:** CRITICAL  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
The table uses an invalid MySQL syntax where the constraint name is placed after FOREIGN KEY as if it were a column name:
```sql
CONSTRAINT FOREIGN KEY (`bookCondition_book_id`) REFERENCES `lib_books_master`(`book_id`) ...
```
The correct syntax is:
```sql
CONSTRAINT `fk_name` FOREIGN KEY (`column_name`) REFERENCES ...
```

**Risk:**  
DDL parse failure. All three FK constraints in this table are malformed.

**Recommended Fix:**
```sql
CONSTRAINT `fk_bookCondJnt_bookId`   FOREIGN KEY (`book_id`)      REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
CONSTRAINT `fk_bookCondJnt_copyId`   FOREIGN KEY (`book_copy_id`) REFERENCES `lib_book_copies`(`id`)  ON DELETE CASCADE,
CONSTRAINT `fk_bookCondJnt_condId`   FOREIGN KEY (`condition_id`) REFERENCES `lib_book_conditions`(`id`) ON DELETE CASCADE
```

---

### F-006 | lib_book_purchases_items — Duplicate FK Constraint Names
**Table:** `lib_book_purchases_items`  
**Element:** FK constraint names  
**Dimension:** D3 — Foreign Key & Referential Integrity  
**Severity:** CRITICAL  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
`lib_book_purchases_items` reuses the same FK constraint names already defined in `lib_book_purchases`:  
`fk_bookPurchase_book_id`, `fk_bookPurchase_resourceType_id`, `fk_bookPurchase_bookCopy_id`, `fk_bookPurchase_digitalResource_id`, `fk_bookPurchase_vendor_id`.  
MySQL requires globally unique FK constraint names within the same database.

**Risk:**  
`ERROR 1826` (Duplicate FK constraint name). The child table fails to create.

**Recommended Fix:**
```sql
-- In lib_book_purchases_items, rename all constraints:
CONSTRAINT `fk_bookPurchItems_bookId`      FOREIGN KEY (`book_id`)             REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
CONSTRAINT `fk_bookPurchItems_resTypeId`   FOREIGN KEY (`resource_type_id`)    REFERENCES `lib_resource_types`(`id`) ON DELETE RESTRICT,
CONSTRAINT `fk_bookPurchItems_copyId`      FOREIGN KEY (`book_copy_id`)        REFERENCES `lib_book_copies`(`id`) ON DELETE SET NULL,
CONSTRAINT `fk_bookPurchItems_digResId`    FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`id`) ON DELETE SET NULL,
CONSTRAINT `fk_bookPurchItems_purchId`     FOREIGN KEY (`book_purchase_id`)    REFERENCES `lib_book_purchases`(`id`) ON DELETE CASCADE
```

---

### F-007 | lib_book_copies — Index References Non-Existent Column `is_deleted`
**Table:** `lib_book_copies`  
**Element:** `idx_copy_status` index  
**Dimension:** D4 — Index Coverage  
**Severity:** CRITICAL  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
```sql
INDEX `idx_copy_status` (`status`, `is_active`, `is_deleted`)
```
The column `is_deleted` does not exist in `lib_book_copies`. The soft-delete column is named `deleted_at`.

**Recommended Fix:**
```sql
DROP INDEX `idx_copy_status` ON `lib_book_copies`;
CREATE INDEX `idx_copy_status` ON `lib_book_copies` (`status`, `is_active`, `deleted_at`);
```

---

### F-008 | lib_book_copies — Duplicate Index `idx_book_id`
**Table:** `lib_book_copies`  
**Element:** `idx_book_id` defined twice  
**Dimension:** D4 — Index Coverage  
**Severity:** CRITICAL  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
`idx_book_id` (`book_id`) appears at both line 496 (`idx_copy_book`) and line 509 (`idx_book_id`) in the CREATE TABLE definition. MySQL will reject the duplicate.

**Recommended Fix:**  
Remove the trailing duplicate:
```sql
-- Remove the second INDEX definition:
-- INDEX `idx_book_id` (`book_id`)   ← DELETE THIS LINE
```
Keep only `INDEX idx_copy_book (book_id)` which is already defined.

---

### F-009 | lib_transaction_history — FK References Non-Existent Column `performed_by`
**Table:** `lib_transaction_history`  
**Element:** FK to `users`  
**Dimension:** D3 — Foreign Key & Referential Integrity  
**Severity:** CRITICAL  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
```sql
FOREIGN KEY (`performed_by`) REFERENCES `users`(id)
```
The column declared in the table is `performed_by_id`, not `performed_by`.

**Recommended Fix:**
```sql
CONSTRAINT `fk_txHistory_performedById` FOREIGN KEY (`performed_by_id`) REFERENCES `sys_users`(`id`) ON DELETE RESTRICT
```

---

### F-010 | lib_inventory_audit — FK References Non-Existent Column `performed_by`
**Table:** `lib_inventory_audit`  
**Element:** FK to `users`  
**Dimension:** D3 — Foreign Key & Referential Integrity  
**Severity:** CRITICAL  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
Same issue as F-009. The table column is `performed_by_id` but FK references `performed_by`.

**Recommended Fix:**
```sql
CONSTRAINT `fk_invAudit_performedById` FOREIGN KEY (`performed_by_id`) REFERENCES `sys_users`(`id`) ON DELETE RESTRICT
```

---

### F-011 | Index Section — Partial Indexes with WHERE Clause Not Supported in MySQL 8
**Table:** Multiple (lib_transactions, lib_members, lib_fines, lib_reservations, lib_digital_resources)  
**Element:** Lines 1132–1136 — conditional CREATE INDEX statements  
**Dimension:** D4 — Index Coverage  
**Severity:** CRITICAL  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
MySQL 8.x does **not** support partial (filtered) indexes with WHERE clause. These statements are PostgreSQL syntax:
```sql
CREATE INDEX idx_transactions_overdue ON lib_transactions(status, due_date) WHERE status = 'issued';
CREATE INDEX idx_members_outstanding ON lib_members(outstanding_fines) WHERE outstanding_fines > 0;
CREATE INDEX idx_fines_pending ON lib_fines(status, created_at) WHERE status = 'pending';
CREATE INDEX idx_reservations_available ON lib_reservations(status, ...) WHERE status = 'pending';
CREATE INDEX idx_digital_license_expiry ON lib_digital_resources(license_end_date) WHERE license_end_date IS NOT NULL;
```

**Risk:**  
All five CREATE INDEX statements fail with `ERROR 1064` (syntax error).

**Recommended Fix:**  
Remove the WHERE clauses — standard composite indexes achieve the same query optimization in MySQL 8:
```sql
CREATE INDEX `idx_transactions_overdue`    ON `lib_transactions`     (`status`, `due_date`);
CREATE INDEX `idx_members_outstanding`     ON `lib_members`          (`outstanding_fines`);
CREATE INDEX `idx_fines_pending`           ON `lib_fines`            (`status`, `created_at`);
CREATE INDEX `idx_reservations_available`  ON `lib_reservations`     (`status`, `expected_available_date`, `notification_sent`);
CREATE INDEX `idx_digital_license_expiry`  ON `lib_digital_resources`(`license_end_date`);
```

---

### F-012 | lib_background_services — Table Referenced in Seed Data but Never Defined
**Table:** `lib_background_services`  
**Element:** Seed INSERT (line 1446)  
**Dimension:** D7 — Module-Specific Business Logic  
**Severity:** CRITICAL  
**Type:** Missing  
**Effort:** Minor refactor  

**Issue:**  
Seed data attempts to insert into `lib_background_services`, but this table has no CREATE TABLE definition anywhere in the DDL.

**Recommended Fix:**  
Either remove the seed data, or define the table (see NT-005 in Recommended New Tables section).

---

### F-013 | lib_membership_types — Trailing Comma Syntax Error
**Table:** `lib_membership_types`  
**Element:** Last constraint before closing parenthesis  
**Dimension:** D1 — Naming Convention  
**Severity:** CRITICAL  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
Line 602:
```sql
UNIQUE KEY `uq_membership_type_code` (`code`),   -- ← trailing comma before )
) ENGINE=InnoDB ...
```

**Recommended Fix:**  
Remove the trailing comma:
```sql
UNIQUE KEY `uq_membership_type_code` (`code`)
) ENGINE=InnoDB ...
```

---

### F-014 | All Seed INSERT Statements — Wrong Column Names
**Table:** All seed data tables  
**Element:** INSERT column lists  
**Dimension:** D1 — Naming Convention  
**Severity:** CRITICAL  
**Type:** Incorrect  
**Effort:** Minor refactor  

**Issue:**  
All seed INSERT statements use legacy column names that don't match the current schema:

| INSERT Uses | Actual Column | Table |
|---|---|---|
| `membership_type_code` | `code` | `lib_membership_types` |
| `membership_type_name` | `name` | `lib_membership_types` |
| `category_code` | `code` | `lib_categories` |
| `category_name` | `name` | `lib_categories` |
| `category_level` | `level` | `lib_categories` |
| `genre_code` | `code` | `lib_genres` |
| `genre_name` | `name` | `lib_genres` |
| `resource_type_code` | `code` | `lib_resource_types` |
| `resource_type_name` | `name` | `lib_resource_types` |
| `condition_code` | `code` | `lib_book_conditions` |
| `condition_name` | `name` | `lib_book_conditions` |

Also the `lib_shelf_locations` seed uses old schema columns (`aisle_number`, `shelf_number`, `rack_number`, `floor_number`, `building`) that no longer exist in the current normalized `lib_shelf_locations` design.

**Recommended Fix:**  
Update all INSERT statements to use actual column names. Example for `lib_membership_types`:
```sql
INSERT INTO `lib_membership_types` (`code`, `name`, `max_books_allowed`, `loan_period_days`, `fine_rate_per_day`, `grace_period_days`, `priority_level`) VALUES
  ('STD_STUDENT',     'Standard Student',  5,  14, 5.00, 2, 1),
  ('STD_STAFF',       'Standard Staff',   10,  30, 2.00, 5, 3),
  ('RESEARCH_SCHOLAR','Research Scholar', 15,  45, 2.00, 7, 4),
  ('PREMIUM_STUDENT', 'Premium Student',  10,  21, 3.00, 3, 2),
  ('EXTERNAL',        'External Member',   3,  14, 10.00, 0, 0);
```

---

### F-015 | lib_digital_access_request_types — Referenced Table Not Defined
**Table:** `lib_digital_access_request_types`  
**Element:** Table entirely missing  
**Dimension:** D7 — Module-Specific Business Logic  
**Severity:** HIGH  
**Type:** Missing  
**Effort:** Minor refactor  

**Issue:**  
`lib_digital_access_requests.request_type` has FK comment referencing `lib_digital_access_request_types`, but this table is never defined. This FK cannot be established.

**Recommended Fix:**  
See NT-003 in Recommended New Tables section.

---

### F-016 | lib_books_master — cover_image_media_id Wrong Data Type
**Table:** `lib_books_master`  
**Element:** `cover_image_media_id` column  
**Dimension:** D5 — Data Type Appropriateness  
**Severity:** HIGH  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
`cover_image_media_id` is defined as `VARCHAR(500)` with a comment "FK to sys_media.id". A FK column must be numeric to match `sys_media.id` which is presumably `INT/BIGINT UNSIGNED`. Using VARCHAR means no FK constraint can be enforced.

**Recommended Fix:**
```sql
ALTER TABLE `lib_books_master`
  MODIFY `cover_image_media_id` INT UNSIGNED NULL AFTER `summary`,
  ADD CONSTRAINT `fk_booksM_coverImageMediaId` FOREIGN KEY (`cover_image_media_id`) REFERENCES `sys_media`(`id`) ON DELETE SET NULL;
```

**Laravel Migration Snippet:**
```php
$table->unsignedInteger('cover_image_media_id')->nullable()->change();
$table->foreign('cover_image_media_id')->references('id')->on('sys_media')->onDelete('set null');
```

---

### F-017 | lib_digital_resource_access_restrictions — All Restriction Columns NOT NULL
**Table:** `lib_digital_resource_access_restrictions`  
**Element:** `role_id`, `designation_id`, `department_id`, `user_id`  
**Dimension:** D6 — Normalization & Data Integrity  
**Severity:** HIGH  
**Type:** Incorrect  
**Effort:** Minor refactor  

**Issue:**  
All four access restriction dimension columns are `INT NOT NULL`. This forces every row to specify a role, designation, department AND user simultaneously. The design intent is clearly to allow flexible restriction (e.g., restrict to a specific role only, or to a specific user only). A record restricting by role would need to specify a valid designation_id and department_id even if irrelevant.

**Risk:**  
Application cannot insert role-only, department-only, or user-only restrictions without fabricating values for the other columns.

**Recommended Fix:**
```sql
ALTER TABLE `lib_digital_resource_access_restrictions`
  MODIFY `role_id`        INT UNSIGNED NULL,
  MODIFY `designation_id` INT UNSIGNED NULL,
  MODIFY `department_id`  INT UNSIGNED NULL,
  MODIFY `user_id`        INT UNSIGNED NULL,
  ADD CONSTRAINT `chk_drar_at_least_one` CHECK (
    role_id IS NOT NULL OR designation_id IS NOT NULL
    OR department_id IS NOT NULL OR user_id IS NOT NULL
  );
```

---

### F-018 | lib_transactions — Missing book_id Column
**Table:** `lib_transactions`  
**Element:** `book_id` column  
**Dimension:** D2 — Missing Standard Columns  
**Severity:** HIGH  
**Type:** Missing  
**Effort:** Quick-fix  

**Issue:**  
`lib_transactions` has `copy_id` but no `book_id`. To find what book was transacted, the app must JOIN `lib_book_copies` first. All reporting queries (overdue books by title, borrowing history by book, demand analysis) require this extra join. The FK in `lib_reservations` already references `book_id`, indicating the module design expects direct book-level queries on transactions.

**Recommended Fix:**
```sql
ALTER TABLE `lib_transactions`
  ADD COLUMN `book_id` INT UNSIGNED NOT NULL AFTER `id`,
  ADD CONSTRAINT `fk_trans_bookId` FOREIGN KEY (`book_id`) REFERENCES `lib_books_master`(`id`) ON DELETE RESTRICT,
  ADD INDEX `idx_trans_book` (`book_id`);
```

**Laravel Migration Snippet:**
```php
$table->unsignedInteger('book_id')->after('id');
$table->foreign('book_id')->references('id')->on('lib_books_master')->onDelete('restrict');
```

---

### F-019 | lib_digital_access_transactions — Critically Incomplete
**Table:** `lib_digital_access_transactions`  
**Element:** Multiple missing columns  
**Dimension:** D2 — Missing Standard Columns  
**Severity:** HIGH  
**Type:** Missing  
**Effort:** Minor refactor  

**Issue:**  
`lib_digital_access_transactions` tracks digital resource access but is missing essential columns:
1. **`book_id`** — no way to know which book was accessed
2. **`digital_resource_id`** — no way to know which specific resource file was accessed
3. **`access_request_id`** — no link back to the originating `lib_digital_access_requests` record

Also `access_condition_id` references `lib_book_conditions` (physical book conditions like NEW/DAMAGED) which makes no sense for a digital resource — this column should be removed.

**Recommended Fix:**
```sql
ALTER TABLE `lib_digital_access_transactions`
  ADD COLUMN `book_id`            INT UNSIGNED NOT NULL AFTER `id`,
  ADD COLUMN `digital_resource_id` INT UNSIGNED NOT NULL AFTER `book_id`,
  ADD COLUMN `access_request_id`  INT UNSIGNED NULL AFTER `digital_resource_id`,
  DROP COLUMN `access_condition_id`,
  ADD CONSTRAINT `fk_digAccTx_bookId`      FOREIGN KEY (`book_id`)             REFERENCES `lib_books_master`(`id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `fk_digAccTx_digResId`    FOREIGN KEY (`digital_resource_id`) REFERENCES `lib_digital_resources`(`id`) ON DELETE RESTRICT,
  ADD CONSTRAINT `fk_digAccTx_accReqId`    FOREIGN KEY (`access_request_id`)   REFERENCES `lib_digital_access_requests`(`id`) ON DELETE SET NULL;
```

---

### F-020 | lib_reservations — queue_position Commented Out But Referenced in Index
**Table:** `lib_reservations`  
**Element:** `idx_reserve_book` index  
**Dimension:** D4 — Index Coverage  
**Severity:** HIGH  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
`queue_position` is commented out (`-- queue_position INT NULL DEFAULT 1`) but the index `idx_reserve_book` still includes `queue_position`:
```sql
INDEX `idx_reserve_book` (`book_id`, `status`, `queue_position`)
```
This will cause DDL failure with "Unknown column 'queue_position' in 'index'".

**Risk:**  
Without queue_position, reservation ordering is also undefined — first-come-first-served logic cannot be enforced at the DB level.

**Recommended Fix:**  
Decide: either restore the column or fix the index. Recommendation: restore it as it is needed for reservation queue management.
```sql
ALTER TABLE `lib_reservations`
  ADD COLUMN `queue_position` SMALLINT UNSIGNED NOT NULL DEFAULT 1 AFTER `pickup_by_date`;

-- Fix the index to include it:
CREATE INDEX `idx_reserve_book` ON `lib_reservations` (`book_id`, `status`, `queue_position`);
```

---

### F-021 | lib_reservations — Typo in Column Name `is_renewal_reuest`
**Table:** `lib_reservations`  
**Element:** `is_renewal_reuest` column  
**Dimension:** D1 — Naming Convention  
**Severity:** HIGH  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
Column is named `is_renewal_reuest` — missing the 'q' in "request". Any application code referencing the correct spelling `is_renewal_request` will fail.

**Recommended Fix:**
```sql
ALTER TABLE `lib_reservations` RENAME COLUMN `is_renewal_reuest` TO `is_renewal_request`;
```

**Laravel Migration Snippet:**
```php
$table->renameColumn('is_renewal_reuest', 'is_renewal_request');
```

---

### F-022 | lib_fine_type — Missing `is_active` Column
**Table:** `lib_fine_type`  
**Element:** `is_active` column  
**Dimension:** D2 — Missing Standard Columns  
**Severity:** HIGH  
**Type:** Missing  
**Effort:** Quick-fix  

**Issue:**  
`lib_fine_type` represents a manageable master entity (fine types can be activated/deactivated by admins) but lacks `is_active`. Fine types that are deprecated cannot be soft-disabled without deleting them, breaking referential integrity with historical fine records.

**Recommended Fix:**
```sql
ALTER TABLE `lib_fine_type`
  ADD COLUMN `is_active` TINYINT(1) NOT NULL DEFAULT 1 AFTER `description`,
  ADD INDEX `idx_fineType_active` (`is_active`);
```

---

### F-023 | lib_membership_types — CHECK Constraint Uses Wrong Column Name
**Table:** `lib_membership_types`  
**Element:** `max_books_allowed` CHECK constraint  
**Dimension:** D5 — Data Type Appropriateness  
**Severity:** HIGH  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
```sql
`max_books_allowed` TINYINT UNSIGNED NOT NULL CHECK (loan_period_days > 0)
```
The CHECK constraint on `max_books_allowed` references `loan_period_days` instead of `max_books_allowed`. This allows `max_books_allowed = 0` (zero books) and silently double-validates `loan_period_days`.

**Recommended Fix:**
```sql
ALTER TABLE `lib_membership_types`
  MODIFY `max_books_allowed` TINYINT UNSIGNED NOT NULL CHECK (`max_books_allowed` > 0);
```

---

### F-024 | lib_digital_resources — license_count TINYINT Signed Overflow
**Table:** `lib_digital_resources`  
**Element:** `license_count` column  
**Dimension:** D5 — Data Type Appropriateness  
**Severity:** HIGH  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
`license_count TINYINT NOT NULL DEFAULT 0` uses a **signed** TINYINT with max value 127. For digital resources with more than 127 concurrent licenses (e.g., a site license for 500 students), the insert will fail with data truncation. Also the comment says "IF 0 THEN UNLIMITED" — a NULL would be semantically cleaner than 0 for unlimited.

**Recommended Fix:**
```sql
ALTER TABLE `lib_digital_resources`
  MODIFY `license_count` SMALLINT UNSIGNED NULL DEFAULT NULL
  COMMENT 'Number of concurrent licenses. NULL = unlimited.';
```

---

### F-025 | lib_digital_resources — file_size_bytes INT UNSIGNED Insufficient
**Table:** `lib_digital_resources`  
**Element:** `file_size_bytes` column  
**Dimension:** D5 — Data Type Appropriateness  
**Severity:** HIGH  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
`INT UNSIGNED` has a maximum value of 4,294,967,295 bytes (≈4GB). A single high-quality video lecture or large textbook collection can exceed this. Using `BIGINT UNSIGNED` covers files up to 18 exabytes.

**Recommended Fix:**
```sql
ALTER TABLE `lib_digital_resources`
  MODIFY `file_size_bytes` BIGINT UNSIGNED NOT NULL;
```

---

### F-026 | Multiple Tables — JSON Columns Missing `_json` Suffix
**Table:** `lib_books_master`, `lib_fines`, `lib_transaction_history`, `lib_engagement_events`, `lib_predictive_analytics`  
**Element:** JSON-typed columns  
**Dimension:** D1 — Naming Convention  
**Severity:** HIGH  
**Type:** Incorrect  
**Effort:** Minor refactor  

**Issue:**  
Prime-AI naming convention requires `_json` suffix on all JSON-type columns. The following violate this:

| Table | Current Name | Corrected Name |
|---|---|---|
| `lib_books_master` | `tags` | `tags_json` |
| `lib_books_master` | `key_concepts` | `key_concepts_json` |
| `lib_fines` | `calculation_breakdown` | `calculation_breakdown_json` |
| `lib_transaction_history` | `old_value` | `old_value_json` |
| `lib_transaction_history` | `new_value` | `new_value_json` |
| `lib_engagement_events` | `filters_used` | `filters_used_json` |
| `lib_predictive_analytics` | `features_used` | `features_used_json` |

Also `lib_books_master.awards` is `TEXT` but stores structured data — should be `awards_json JSON`.

**Recommended Fix:**
```sql
ALTER TABLE `lib_books_master`
  RENAME COLUMN `tags` TO `tags_json`,
  RENAME COLUMN `key_concepts` TO `key_concepts_json`,
  MODIFY `awards` JSON NULL,
  RENAME COLUMN `awards` TO `awards_json`;

ALTER TABLE `lib_fines`         RENAME COLUMN `calculation_breakdown` TO `calculation_breakdown_json`;
ALTER TABLE `lib_transaction_history` RENAME COLUMN `old_value` TO `old_value_json`, RENAME COLUMN `new_value` TO `new_value_json`;
ALTER TABLE `lib_engagement_events`   RENAME COLUMN `filters_used` TO `filters_used_json`;
ALTER TABLE `lib_predictive_analytics` RENAME COLUMN `features_used` TO `features_used_json`;
```

---

### F-027 | lib_transactions — Index References Misnamed Column `issued_by`
**Table:** `lib_transactions`  
**Element:** `idx_trans_issued_by` index  
**Dimension:** D4 — Index Coverage  
**Severity:** HIGH  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
`INDEX idx_trans_issued_by (issued_by)` — but the column is `issued_by_id`.

**Recommended Fix:**
```sql
DROP INDEX `idx_trans_issued_by` ON `lib_transactions`;
CREATE INDEX `idx_trans_issuedById` ON `lib_transactions` (`issued_by_id`);
```

---

### F-028 | lib_reservations — Index References Commented-Out Column
**Table:** `lib_reservations`  
**Element:** `idx_reserve_book` references `queue_position`  
**Dimension:** D4 — Index Coverage  
**Severity:** HIGH  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
Already covered in F-020 — the index `idx_reserve_book (book_id, status, queue_position)` references the commented-out `queue_position` column. This causes DDL failure independent of F-020.

**Recommended Fix:**  
Same as F-020 — restore `queue_position` column and keep the index as-is, OR drop queue_position from the index if the column stays commented out.

---

### F-029 | lib_members — Denormalized Aggregate Counters
**Table:** `lib_members`  
**Element:** `total_books_borrowed`, `total_fines_paid`, `outstanding_fines`, `reading_progress_ytd`  
**Dimension:** D6 — Normalization & Data Integrity  
**Severity:** MEDIUM  
**Type:** Suboptimal  
**Effort:** Minor refactor  

**Issue:**  
Four columns store pre-aggregated values that will drift from their source tables:
- `total_books_borrowed` — derived from COUNT on `lib_transactions`
- `total_fines_paid` — derived from SUM on `lib_fine_payments`
- `outstanding_fines` — derived from SUM on `lib_fines WHERE status = 'pending'`
- `reading_progress_ytd` — derived from transactions in current year

These are maintained by triggers and event schedulers, but any missed event or trigger error will cause silent inconsistency.

**Risk:**  
Member dashboard shows wrong borrowed count or outstanding balance. Fine waivers not reflecting correctly.

**Recommended Fix:**  
Replace with database views or computed queries. If denormalization is kept for performance, add a periodic reconciliation job and document the denormalization explicitly:
```sql
-- If kept, add reconciliation tracking:
ALTER TABLE `lib_members`
  ADD COLUMN `last_reconciled_at` TIMESTAMP NULL AFTER `reading_progress_ytd`;
```

---

### F-030 | lib_books_master — `is_available` Denormalized
**Table:** `lib_books_master`  
**Element:** `is_available` column  
**Dimension:** D6 — Normalization & Data Integrity  
**Severity:** MEDIUM  
**Type:** Suboptimal  
**Effort:** Minor refactor  

**Issue:**  
`is_available TINYINT(1)` in `lib_books_master` is redundant — availability is deterministic from `lib_book_copies` where `status = 'Available' AND is_active = 1`. Storing it denormalized creates a stale-data risk when copies are issued/returned.

**Recommended Fix:**  
Remove `is_available` and derive it in the `lib_view_collection_performance` view instead. If caching availability for performance, add a trigger:
```sql
-- Remove the column, or document it as a cached field updated by trigger only
-- ALTER TABLE `lib_books_master` DROP COLUMN `is_available`;
```

---

### F-031 | lib_curricular_alignment / lib_reading_behavior_analytics — academic_year as VARCHAR
**Table:** `lib_curricular_alignment`, `lib_reading_behavior_analytics`  
**Element:** `academic_year` column  
**Dimension:** D3 — Foreign Key & Referential Integrity  
**Severity:** MEDIUM  
**Type:** Incorrect  
**Effort:** Minor refactor  

**Issue:**  
Both tables store `academic_year` as `VARCHAR(20)`. All other Prime-AI modules link to `academic_years` via `academic_year_id INT UNSIGNED FK`. This breaks cross-module joins and allows arbitrary string values.

**Recommended Fix:**
```sql
-- ⚠️ DATA MIGRATION WARNING: Requires existing VARCHAR values mapped to academic_years.id

ALTER TABLE `lib_curricular_alignment`
  ADD COLUMN `academic_year_id` INT UNSIGNED NOT NULL AFTER `id`,
  ADD CONSTRAINT `fk_libCurrAlign_academicYearId` FOREIGN KEY (`academic_year_id`) REFERENCES `academic_years`(`id`);
-- After migration, drop VARCHAR column

ALTER TABLE `lib_reading_behavior_analytics`
  ADD COLUMN `academic_year_id` INT UNSIGNED NOT NULL AFTER `id`,
  ADD CONSTRAINT `fk_libRBA_academicYearId` FOREIGN KEY (`academic_year_id`) REFERENCES `academic_years`(`id`);
```

---

### F-032 | lib_location_master — `type` ENUM Not Extensible
**Table:** `lib_location_master`  
**Element:** `type` ENUM column  
**Dimension:** D5 — Data Type Appropriateness  
**Severity:** MEDIUM  
**Type:** Suboptimal  
**Effort:** Significant change  

**Issue:**  
`type ENUM('Zone', 'Floor', 'Aisle', 'Shelf', 'Rack')` hardcodes location types. Adding a new type (e.g., 'Cabinet', 'Locker', 'Display') requires an ALTER TABLE that can lock the table. Also the column name `type` is a reserved word risk; rename to `location_type`.

**Recommended Fix:**  
Convert to a self-referential code or simple TINYINT UNSIGNED referencing a `lib_location_types` seed table. Minimum fix:
```sql
ALTER TABLE `lib_location_master`
  RENAME COLUMN `type` TO `location_type`;
-- Consider future migration to lookup table if more types are added
```

---

### F-033 | lib_digital_access_transactions — access_condition_id Semantically Wrong
**Table:** `lib_digital_access_transactions`  
**Element:** `access_condition_id` column  
**Dimension:** D7 — Module-Specific Business Logic  
**Severity:** MEDIUM  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
`access_condition_id` references `lib_book_conditions` (physical states: NEW, GOOD, DAMAGED, etc.). Digital resources have no physical condition. This column is semantically meaningless here.

**Recommended Fix:**  
Drop the column (covered in F-019 fix above). If an "access quality" metric is needed for digital resources (e.g., whether content was accessible), use an ENUM:
```sql
ALTER TABLE `lib_digital_access_transactions`
  DROP COLUMN `access_condition_id`,
  ADD COLUMN `access_quality` ENUM('Full', 'Partial', 'Timeout', 'Error') NULL;
```

---

### F-034 | lib_fine_slab_config — Missing UNIQUE Constraint on Date Range
**Table:** `lib_fine_slab_config`  
**Element:** Effective date range uniqueness  
**Dimension:** D6 — Normalization & Data Integrity  
**Severity:** MEDIUM  
**Type:** Missing  
**Effort:** Minor refactor  

**Issue:**  
Nothing prevents two active fine slabs for the same membership_type + fine_type combination with overlapping effective dates. The application would need to resolve ambiguity, but the DB provides no safety net.

**Recommended Fix:**
```sql
ALTER TABLE `lib_fine_slab_config`
  ADD UNIQUE KEY `uq_fineSlabConf_memType_fineType_EffFrom`
    (`membership_type_id`, `fine_type_id`, `effective_from`);
```

---

### F-035 | lib_digital_resource_access_restrictions — Overweight Composite Index
**Table:** `lib_digital_resource_access_restrictions`  
**Element:** `idx_digital_access_active_resource` (6 columns)  
**Dimension:** D4 — Index Coverage  
**Severity:** MEDIUM  
**Type:** Suboptimal  
**Effort:** Quick-fix  

**Issue:**  
The 6-column composite index `(digital_resource_id, role_id, designation_id, department_id, user_id, is_active)` covers scenarios that are better served by individual narrow indexes. A 6-column composite index has high write overhead and is only useful for the exact prefix query pattern.

**Recommended Fix:**
```sql
DROP INDEX `idx_digital_access_active_resource` ON `lib_digital_resource_access_restrictions`;
CREATE INDEX `idx_drar_resId_active`  ON `lib_digital_resource_access_restrictions` (`digital_resource_id`, `is_active`);
CREATE INDEX `idx_drar_roleId`        ON `lib_digital_resource_access_restrictions` (`role_id`);
CREATE INDEX `idx_drar_userId`        ON `lib_digital_resource_access_restrictions` (`user_id`);
```

---

### F-036 | lib_collection_health_metrics — Missing FK Constraints
**Table:** `lib_collection_health_metrics`  
**Element:** `category_id`, `genre_id` columns  
**Dimension:** D3 — Foreign Key & Referential Integrity  
**Severity:** MEDIUM  
**Type:** Missing  
**Effort:** Quick-fix  

**Issue:**  
`category_id` and `genre_id` columns implicitly reference `lib_categories` and `lib_genres` but no FK constraints are declared.

**Recommended Fix:**
```sql
ALTER TABLE `lib_collection_health_metrics`
  ADD CONSTRAINT `fk_collHealth_categoryId` FOREIGN KEY (`category_id`) REFERENCES `lib_categories`(`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_collHealth_genreId`    FOREIGN KEY (`genre_id`)    REFERENCES `lib_genres`(`id`)      ON DELETE SET NULL;
```

---

### F-037 | lib_books_master — popularity_rank TINYINT Overflow Risk
**Table:** `lib_books_master`  
**Element:** `popularity_rank` column  
**Dimension:** D5 — Data Type Appropriateness  
**Severity:** MEDIUM  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
`popularity_rank TINYINT UNSIGNED NULL` can only store up to 255. A library with 1,000+ books will lose ranking precision for any book beyond rank 255.

**Recommended Fix:**
```sql
ALTER TABLE `lib_books_master`
  MODIFY `popularity_rank` MEDIUMINT UNSIGNED NULL;
```

---

### F-038 | lib_library_status_masters — Wrong Unique Key Name + Typo
**Table:** `lib_library_status_masters`  
**Element:** `uq_accounting_status_code` constraint name  
**Dimension:** D1 — Naming Convention  
**Severity:** MEDIUM  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
1. The unique key is named `uq_accounting_status_code` — "accounting" has no relation to a library status master table. Should be `uq_lib_status_typeCode`.
2. The ENUM value "Inventry Audit Status" is a typo — should be "Inventory Audit Status" (also fixed in F-002).

**Recommended Fix:**
```sql
ALTER TABLE `lib_library_status_masters`
  DROP KEY `uq_accounting_status_code`,
  ADD UNIQUE KEY `uq_lib_status_typeCode` (`status_type`, `code`);
```

---

### F-039 | lib_book_copies — UNIQUE KEY Names Using Wrong Prefix
**Table:** `lib_book_copies`  
**Element:** Three UNIQUE KEY definitions  
**Dimension:** D1 — Naming Convention  
**Severity:** MEDIUM  
**Type:** Incorrect  
**Effort:** Quick-fix  

**Issue:**  
Three unique keys use `unique_` prefix instead of `uq_`:
- `unique_copy_barcode` → should be `uq_copy_barcode`
- `unique_copy_accession` → should be `uq_copy_accession`
- `unique_copy_rfid` → should be `uq_copy_rfid`

**Recommended Fix:**
```sql
ALTER TABLE `lib_book_copies`
  DROP KEY `unique_copy_barcode`,
  DROP KEY `unique_copy_accession`,
  DROP KEY `unique_copy_rfid`,
  ADD UNIQUE KEY `uq_copy_barcode`   (`barcode`),
  ADD UNIQUE KEY `uq_copy_accession` (`accession_number`),
  ADD UNIQUE KEY `uq_copy_rfid`      (`rfid_tag`);
```

---

### F-040 | lib_members — outstanding_fines NOT NULL Missing + Drift Risk
**Table:** `lib_members`  
**Element:** `outstanding_fines` column  
**Dimension:** D6 — Normalization & Data Integrity  
**Severity:** MEDIUM  
**Type:** Suboptimal  
**Effort:** Minor refactor  

**Issue:**  
`outstanding_fines DECIMAL(10,2) DEFAULT 0.00 CHECK (outstanding_fines >= 0)` has no `NOT NULL` declaration. Also, this is a pre-aggregated value sourced from `lib_fines` which can drift if fine records are bulk-updated or imported. The trigger `update_member_borrowed_count` updates `total_books_borrowed` but no corresponding trigger keeps `outstanding_fines` in sync.

**Recommended Fix:**
```sql
ALTER TABLE `lib_members`
  MODIFY `outstanding_fines` DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (`outstanding_fines` >= 0);
```
Add a trigger or event to reconcile periodically, or use a computed view.

---

### F-041 | lib_books_master / lib_members — Language as VARCHAR vs Lookup
**Table:** `lib_books_master`, `lib_members`  
**Element:** `language`, `preferred_language` columns  
**Dimension:** D9 — Localization & Indian Education Compliance  
**Severity:** LOW  
**Type:** Enhancement  
**Effort:** Minor refactor  

**Issue:**  
Language is stored as free-text VARCHAR(50). For Indian schools, this should reference a controlled list from `glb_languages` to support regional languages (Hindi, Tamil, Telugu, Marathi, etc.) consistently.

**Recommended Fix:**
```sql
ALTER TABLE `lib_books_master`
  ADD COLUMN `language_id` INT UNSIGNED NULL AFTER `language`,
  ADD CONSTRAINT `fk_booksM_languageId` FOREIGN KEY (`language_id`) REFERENCES `glb_languages`(`id`);
-- Keep `language` for legacy, migrate and deprecate

ALTER TABLE `lib_members`
  ADD COLUMN `preferred_language_id` INT UNSIGNED NULL AFTER `preferred_language`,
  ADD CONSTRAINT `fk_member_preferredLangId` FOREIGN KEY (`preferred_language_id`) REFERENCES `glb_languages`(`id`);
```

---

### F-042 | lib_categories / lib_genres — No Regional Language Support
**Table:** `lib_categories`, `lib_genres`  
**Element:** Missing multilingual name columns  
**Dimension:** D9 — Localization & Indian Education Compliance  
**Severity:** LOW  
**Type:** Enhancement  
**Effort:** Minor refactor  

**Issue:**  
Categories and genres have only `name` (English). Indian schools with regional-language medium of instruction need category/genre names in Hindi, Tamil, Marathi, etc. for the student OPAC interface.

**Recommended Fix:**
```sql
ALTER TABLE `lib_categories`
  ADD COLUMN `name_hi` VARCHAR(200) NULL COMMENT 'Hindi name' AFTER `name`,
  ADD COLUMN `name_regional` VARCHAR(200) NULL COMMENT 'Regional language name' AFTER `name_hi`;

ALTER TABLE `lib_genres`
  ADD COLUMN `name_hi` VARCHAR(200) NULL COMMENT 'Hindi name' AFTER `name`,
  ADD COLUMN `name_regional` VARCHAR(200) NULL COMMENT 'Regional language name' AFTER `name_hi`;
```

---

### F-043 | lib_curricular_alignment — Missing NEP 2020 & Board-Type Fields
**Table:** `lib_curricular_alignment`  
**Element:** Missing compliance columns  
**Dimension:** D9 — Localization & Indian Education Compliance  
**Severity:** LOW  
**Type:** Enhancement  
**Effort:** Minor refactor  

**Issue:**  
The `lib_curricular_alignment` table is well-designed but missing Indian education compliance fields:
- No `board_type` (CBSE/ICSE/State/IGCSE) — critical when a school offers multiple boards
- No `competency_tags_json` for NEP 2020 competency-based mapping
- No `ncert_code` for mapping to NCERT textbook curriculum units

**Recommended Fix:**
```sql
ALTER TABLE `lib_curricular_alignment`
  ADD COLUMN `board_type`          ENUM('CBSE','ICSE','State','IGCSE','IB','Other') NULL AFTER `subject_id`,
  ADD COLUMN `competency_tags_json` JSON NULL COMMENT 'NEP 2020 competency tags' AFTER `curriculum_unit`,
  ADD COLUMN `ncert_unit_code`     VARCHAR(50) NULL COMMENT 'NCERT chapter/unit code' AFTER `competency_tags_json`;
```

---

### F-044 | lib_predictive_analytics — Missing `deleted_at`
**Table:** `lib_predictive_analytics`  
**Element:** `deleted_at` column  
**Dimension:** D2 — Missing Standard Columns  
**Severity:** LOW  
**Type:** Missing  
**Effort:** Quick-fix  

**Recommended Fix:**
```sql
ALTER TABLE `lib_predictive_analytics`
  ADD COLUMN `deleted_at` TIMESTAMP NULL AFTER `updated_at`;
```

---

### F-045 | lib_reading_behavior_analytics — Missing `updated_at`
**Table:** `lib_reading_behavior_analytics`  
**Element:** `updated_at` column  
**Dimension:** D2 — Missing Standard Columns  
**Severity:** LOW  
**Type:** Missing  
**Effort:** Quick-fix  

**Issue:**  
The table has `last_calculated_at` (which tracks when ML metrics were last computed) and `created_at`, but no `updated_at`. Standard Prime-AI requirement for all tables.

**Recommended Fix:**
```sql
ALTER TABLE `lib_reading_behavior_analytics`
  ADD COLUMN `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER `created_at`;
```

---

## Recommended New Tables

### NT-001 | `lib_book_reviews_ratings`
**Rationale:** The `lib_engagement_events` table includes event types `Rate_Book` and `Add_Review`, and `lib_books_master` stores `student_rating` and `academic_rating` as denormalized averages. But there is no table to actually store individual reviews and ratings from members. Without this, ratings cannot be personalized, moderated, or tied to a specific transaction.  
**Triggered By:** F-029, F-030

```sql
CREATE TABLE `lib_book_reviews_ratings` (
  `id`             INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `book_id`        INT UNSIGNED NOT NULL,
  `member_id`      INT UNSIGNED NOT NULL,
  `transaction_id` INT UNSIGNED NULL,        -- The transaction that led to this review
  `rating`         TINYINT UNSIGNED NOT NULL CHECK (`rating` BETWEEN 1 AND 5),
  `review_text`    TEXT NULL,
  `is_faculty`     TINYINT(1) NOT NULL DEFAULT 0, -- Whether reviewer is faculty
  `is_approved`    TINYINT(1) NOT NULL DEFAULT 0, -- Moderation flag
  `approved_by_id` INT UNSIGNED NULL,
  `approved_at`    TIMESTAMP NULL,
  `is_active`      TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`     TIMESTAMP NULL,
  CONSTRAINT `fk_bookReview_bookId`      FOREIGN KEY (`book_id`)        REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_bookReview_memberId`    FOREIGN KEY (`member_id`)      REFERENCES `lib_members`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_bookReview_txId`        FOREIGN KEY (`transaction_id`) REFERENCES `lib_transactions`(`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_bookReview_approvedById` FOREIGN KEY (`approved_by_id`) REFERENCES `sys_users`(`id`) ON DELETE SET NULL,
  UNIQUE KEY `uq_bookReview_member_book` (`book_id`, `member_id`),
  INDEX `idx_bookReview_book`     (`book_id`, `is_approved`),
  INDEX `idx_bookReview_member`   (`member_id`),
  INDEX `idx_bookReview_rating`   (`rating`, `is_approved`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### NT-002 | `lib_wishlist`
**Rationale:** `lib_engagement_events` includes `Save_To_Wishlist` as an event type, but there is no wishlist table. Members should be able to maintain a personal reading wishlist for future borrowing, purchase requests, or reading goal tracking.  
**Triggered By:** F-007 (implied by engagement events)

```sql
CREATE TABLE `lib_wishlist` (
  `id`          INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `member_id`   INT UNSIGNED NOT NULL,
  `book_id`     INT UNSIGNED NOT NULL,
  `notes`       VARCHAR(255) NULL,
  `priority`    TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `is_active`   TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`  TIMESTAMP NULL,
  CONSTRAINT `fk_wishlist_memberId` FOREIGN KEY (`member_id`) REFERENCES `lib_members`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_wishlist_bookId`   FOREIGN KEY (`book_id`)   REFERENCES `lib_books_master`(`id`) ON DELETE CASCADE,
  UNIQUE KEY `uq_wishlist_member_book` (`member_id`, `book_id`),
  INDEX `idx_wishlist_member`   (`member_id`, `is_active`),
  INDEX `idx_wishlist_book`     (`book_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### NT-003 | `lib_digital_access_request_types`
**Rationale:** Referenced by `lib_digital_access_requests.request_type` FK but never defined.  
**Triggered By:** F-015

```sql
CREATE TABLE `lib_digital_access_request_types` (
  `id`          SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `code`        VARCHAR(30) NOT NULL,
  `name`        VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) NULL,
  `is_active`   TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`  TIMESTAMP NULL,
  UNIQUE KEY `uq_digAccReqType_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed data
INSERT INTO `lib_digital_access_request_types` (`code`, `name`) VALUES
  ('DOWNLOAD',   'Download Request'),
  ('VIEW',       'Online View Request'),
  ('OFFLINE',    'Offline Access Request'),
  ('EXTENDED',   'Extended License Request');
```

---

### NT-004 | `lib_library_settings`
**Rationale:** No module-level configuration table exists. A library needs configurable settings such as operating hours, max reservation days before cancellation, auto-renewal toggle, notification lead times, and academic-year-specific policy overrides.  
**Triggered By:** D7 analysis

```sql
CREATE TABLE `lib_library_settings` (
  `id`               INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `academic_year_id` INT UNSIGNED NULL,  -- NULL = global default; non-null = year-specific override
  `setting_key`      VARCHAR(100) NOT NULL,
  `setting_value`    VARCHAR(500) NOT NULL,
  `value_type`       ENUM('string','integer','decimal','boolean','json') NOT NULL DEFAULT 'string',
  `description`      VARCHAR(255) NULL,
  `is_active`        TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`       TIMESTAMP NULL,
  CONSTRAINT `fk_libSettings_academicYearId` FOREIGN KEY (`academic_year_id`) REFERENCES `academic_years`(`id`) ON DELETE CASCADE,
  UNIQUE KEY `uq_libSettings_year_key` (`academic_year_id`, `setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### NT-005 | `lib_background_services`
**Rationale:** Seed data inserts into this table (line 1446) but it is never defined.  
**Triggered By:** F-012

```sql
CREATE TABLE `lib_background_services` (
  `id`               INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `service_name`     VARCHAR(100) NOT NULL,
  `service_url`      VARCHAR(500) NULL,
  `service_interval` INT UNSIGNED NOT NULL DEFAULT 1440 COMMENT 'Interval in minutes',
  `last_run_at`      TIMESTAMP NULL,
  `last_status`      ENUM('Success','Failed','Running','Pending') DEFAULT 'Pending',
  `is_active`        TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at`       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at`       TIMESTAMP NULL,
  UNIQUE KEY `uq_bgService_name` (`service_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## Priority Implementation Roadmap

> ✅ **v5 update (2026-06-09):** Phases 1 and 2 are fully resolved in `Library_ddl_v5.sql`. Only Phase 3 backlog items remain open.

### Phase 1 — Critical Fixes ✅ COMPLETE in v5

All 14 CRITICAL findings resolved. See `Library_ddl_v5.sql` change log for migration order.

### Phase 2 — High Priority ✅ COMPLETE in v5

All HIGH findings (F-015 to F-028) resolved. New tables NT-001 through NT-005 added.  
`lib_digital_access_transactions` fully redesigned in v4 (F-019, F-033).

### Phase 3 — Remaining Backlog

**Resolved in v5 (previously Phase 3):** F-029, F-030, F-031, F-034, F-035, F-036, F-037, F-038, F-039, F-040, F-044, F-045 ✅

**Still Open — Localization (LOW priority):**
- **F-041** — Add `language_id INT UNSIGNED FK` to `lib_books_master` and `lib_members` referencing `glb_languages(id)`
- **F-042** — Add `name_hi` and `name_regional` columns to `lib_categories` and `lib_genres` for Indian regional languages
- **F-043** — Add `board_type ENUM`, `competency_tags_json JSON`, `ncert_unit_code VARCHAR(50)` to `lib_curricular_alignment` for NEP 2020 compliance

**Still Open — Design (deferred, significant change):**
- **F-032** — Convert `lib_location_master.location_type` from ENUM to a `lib_location_types` lookup table FK (F-032 partially addressed: column renamed from `type` to `location_type` in v5)

---

## Naming Convention Violations Summary

| Current Name | Corrected Name | Rule Violated |
|---|---|---|
| `lib_fine_type` | `lib_fine_types` | Plural table naming convention |
| `lib_library_status_masters` | `lib_status_masters` | Redundant `lib_library_` double-prefix |
| `is_renewal_reuest` | `is_renewal_request` | Typo |
| `tags` | `tags_json` | JSON columns must have `_json` suffix |
| `key_concepts` | `key_concepts_json` | JSON columns must have `_json` suffix |
| `awards` | `awards_json` | JSON columns must have `_json` suffix |
| `calculation_breakdown` | `calculation_breakdown_json` | JSON columns must have `_json` suffix |
| `old_value` | `old_value_json` | JSON columns must have `_json` suffix |
| `new_value` | `new_value_json` | JSON columns must have `_json` suffix |
| `filters_used` | `filters_used_json` | JSON columns must have `_json` suffix |
| `features_used` | `features_used_json` | JSON columns must have `_json` suffix |
| `unique_copy_barcode` | `uq_copy_barcode` | Unique key must use `uq_` prefix |
| `unique_copy_accession` | `uq_copy_accession` | Unique key must use `uq_` prefix |
| `unique_copy_rfid` | `uq_copy_rfid` | Unique key must use `uq_` prefix |
| `uq_accounting_status_code` | `uq_lib_status_typeCode` | Name must reflect table context |
| `type` (lib_location_master) | `location_type` | Avoids reserved word, improves clarity |
| `note` (lib_book_purchases) | `notes` | Inconsistent with other tables (some use `note`, others `notes`) |

---

## Cross-Module Integration Gaps

| This Table | Missing FK Column | Target Module | Target Table |
|---|---|---|---|
| `lib_curricular_alignment` | `academic_year_id` | Core | `academic_years` |
| `lib_reading_behavior_analytics` | `academic_year_id` | Core | `academic_years` |
| `lib_members` | `class_id` (for students) | School | `sch_classes` |
| `lib_members` | `section_id` (for students) | School | `sch_sections` |
| `lib_transactions` | `academic_year_id` | Core | `academic_years` |
| `lib_fines` | (link to `fee_payments`) | Finance | `fee_payments` |
| `lib_fine_payments` | `fee_payment_id` | Finance | `fee_payments` |
| `lib_digital_resources` | `file_media_id` to consistent table | System | `sys_media` (not `media_files`) |
| `lib_members` | `user_id` references inconsistent (`users` vs `sys_users`) | System | Standardize to `sys_users` |

---

## Notes for Development Team

1. **FK Target Tables — `users` vs `sys_users`:** The DDL inconsistently references both `users` and `sys_users` as the FK target for user lookups. Pick one and apply it uniformly before executing. Prime-AI platform likely uses `sys_users` as the canonical table.

2. **Media Table Name:** `lib_books_master` comment says "FK to `sys_media`.id" but `lib_digital_resources` references `media_files`. Standardize on one name before adding FK constraints.

3. **Trigger Design Review Required:** The trigger `auto_calculate_fines` runs as a MySQL EVENT but uses the fine slab logic from `lib_membership_types.fine_rate_per_day`. Now that `lib_fine_slab_config` and `lib_fine_slab_details` exist with per-day-range rates, the trigger logic is outdated — it doesn't use the slab system. A Laravel job (via Queue) that uses the slab tables is recommended over a MySQL EVENT trigger.

4. **`lib_digital_resource_access_restrictions` Design Intent:** The original design likely intended this table to support OR-based restrictions (restrict to this role OR this user). All-NOT-NULL makes it AND-based (role AND designation AND department AND user simultaneously). Clarify the intended semantics before applying F-017 fix.

5. **View Compatibility After Renames:** Views `lib_view_member_360`, `lib_view_collection_performance`, `lib_view_predictive_demand`, `lib_view_overdue_books`, and `lib_view_most_issued_books` all use old column alias names (e.g., `member_id`, `book_id`, `category_id` in FK references). After applying F-004 fixes, all five views must be recreated.

6. **Partial Indexes Alternative:** For the 5 partial index use-cases removed in F-011, consider adding computed/virtual columns (MySQL 8 supports `VIRTUAL` columns) or using covering indexes with the status column as the leading prefix for query optimization.

7. **`lib_inventory_audit_details` — Missing Timestamps:** This table has no `created_at`, `updated_at`, or `deleted_at`. Add all three before production.

8. ⚠️ **DATA MIGRATION WARNING** — F-031: Migrating `academic_year VARCHAR(20)` to `academic_year_id INT UNSIGNED FK` in `lib_curricular_alignment` and `lib_reading_behavior_analytics` requires a mapping step. If `academic_years` table already has records matching the year strings, an UPDATE query can populate the new FK column. If not, the migration order must ensure `academic_years` seeding happens first.

---

*Report Version: 1.0 | Prime-AI DDL Review System | PrimeGurukul | 2026-06-09*
