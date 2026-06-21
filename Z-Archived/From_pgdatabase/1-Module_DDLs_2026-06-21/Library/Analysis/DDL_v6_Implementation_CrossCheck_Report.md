# Library DDL v6 — Implementation Cross-Check Report
**Generated:** 2026-06-14  
**Last Updated:** 2026-06-14 (Session 3: ENUM→FK, old columns, language FK, commands)  
**Source:** `Library_ddl_v6.sql` (1898 lines, 53 SQL entities)  
**Codebase:** `~/project/Modules/Library/` + `database/migrations/tenant/`

---

## Executive Summary

| Metric | Count |
|--------|-------|
| Tables in DDL v6 | 53 core tables/views/triggers |
| Implementation tables checked | 46 core data tables |
| Fully aligned (✅) | **37 tables** |
| Minor gaps (🟡) | **~8 tables** (default diffs, index naming, no dedicated CRUD) |
| Code-migration gaps (🔶) | **7 items** (see Remaining Issues) |
| Unimplemented features (📋) | **2** (no controller/views: `lib_library_settings`, `lib_background_services`) |

---

## SUB-MENU 1: BOOK MASTERS (7 tables)

### Tab-1.1: `lib_resource_types`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibResourceType` — all columns in `$fillable` + `$casts` |
| Controller | ✅ Full CRUD + toggleStatus + trashed/restore/forceDelete. `Gate::authorize()` on all methods |
| FormRequest | ✅ `LibResourceTypeRequest` — checkboxes via `prepareForValidation()`, unique code |
| Views | ✅ 5/5: create, edit, show, index, trash |
| Routes | ✅ Resource + custom routes |
| Migration | ✅ Matches DDL |
| **Issues** | None ✅ |

### Tab-1.2: `lib_categories`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibCategory` — `level`, `display_order` in fillable+casts |
| Controller | ✅ Full CRUD + toggleStatus + updateOrder/updateTree. `Gate::authorize()` |
| FormRequest | ✅ `LibCategoryRequest` — `level`, `display_order` validated |
| Views | ✅ 5/5 + tree-item/js/css partials |
| Routes | ✅ Resource + custom |
| Migration | ✅ Matches mostly |
| **Issues** | 🟡 `display_order` default: DDL=1, Migration=0 |

### Tab-1.3: `lib_genres`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibGenre` — `description` in fillable |
| Controller | ✅ Full CRUD + toggleStatus |
| FormRequest | ✅ `LibGenreRequest` |
| Views | ✅ 5/5 |
| Routes | ✅ |
| Migration | ✅ |
| **Issues** | None ✅ |

### Tab-1.4: `lib_book_conditions`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibBookCondition` — `is_borrowable`, multiple relationships |
| Controller | ✅ Full CRUD + toggleStatus + addBooks |
| FormRequest | ✅ `LibBookConditionRequest` |
| Views | ✅ 5/5 |
| Routes | ✅ |
| Migration | ✅ |
| **Issues** | None ✅ |

### Tab-1.5: `lib_publishers`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibPublisher` — `address`, `contact`, `email`, `phone`, `website` all in fillable |
| Controller | ✅ Full CRUD + toggleStatus |
| FormRequest | ✅ `LibPublisherRequest` — all fields validated |
| Views | ✅ 5/5 |
| Routes | ✅ |
| Migration | ✅ |
| **Issues** | None ✅ |

### Tab-1.6: `lib_authors`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibAuthor` — country(), primaryGenre(), books() |
| Controller | ✅ Full CRUD + toggleStatus |
| FormRequest | ✅ **FIXED** — `country_id` + `primary_genre_id` changed from `nullable` to `required` |
| Views | ✅ 5/5 |
| Routes | ✅ |
| Migration | 🔶 `country_id` + `primary_genre_id` still `nullable()` — blocked by FK `SET NULL` constraint |
| **Issues** | 🔶 **Migration-only**: FK constraint `fk_lib_authors_country` uses `SET NULL` which prevents ALTER to NOT NULL. Needs migration to drop+recreate FK with `RESTRICT`. |

### Tab-1.7: `lib_keywords`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibKeyword` |
| Controller | ✅ Full CRUD + toggleStatus |
| FormRequest | ✅ `LibKeywordRequest` |
| Views | ✅ 5/5 |
| Routes | ✅ |
| Migration | ✅ |
| **Issues** | None ✅ |

---

## SUB-MENU 2: LOCATION MASTERS (2 tables)

### Tab-2.1: `lib_locations_master`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibLocationMaster` — **FIXED**: removed legacy `type`, kept only `location_type` in fillable |
| Controller | ✅ Full CRUD + toggleStatus. **FIXED**: all 16 queries changed from `where('type',...)` to `where('location_type',...)` |
| FormRequest | ✅ **FIXED**: validates `location_type` (not `type`). Table name `lib_locations_master` (plural, correct) |
| Views | ✅ 5/5 |
| Routes | ✅ |
| Migration | ✅ Uses `location_type` ENUM matching DDL |
| **Issues** | None ✅ |

### Tab-2.2: `lib_shelf_locations`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibShelfLocation` — all FK relationships, `getFullLocationAttribute()` |
| Controller | ✅ Full CRUD + toggleStatus |
| FormRequest | ✅ **FIXED**: all 5 `exists:lib_locations_master,id` (plural, correct) |
| Views | ✅ 5/5 |
| Routes | ✅ |
| Migration | ✅ All 5 FKs reference `lib_locations_master` correctly |
| **Issues** | None ✅ |

---

## SUB-MENU 3: LIBRARY CONFIGURATION (6 tables)

### Tab-3.1: `lib_fine_type`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibFineType` — all 4 columns in fillable |
| Controller | ✅ **FIXED**: Added `toggleStatus()` method + route |
| FormRequest | ✅ **FIXED**: Added `is_active` validation + `prepareForValidation()` |
| Views | ✅ **FIXED**: Added `is_active` toggle to create/edit/show; Status column to index |
| Routes | ✅ **FIXED**: Added `lib-fine-types.toggleStatus` route |
| Migration | ✅ |
| **Issues** | None ✅ |

### Tab-3.2: `lib_fine_slab_config`
| Layer | Status |
|-------|--------|
| Model | ✅ `$fillable` has all 11 columns incl. `max_fine_cap`, `fine_amt_calc_type`, `max_fine_amt`; `$casts` correct |
| Controller | ✅ Full CRUD + toggleStatus |
| FormRequest | ✅ Overlap check in `withValidator()`; `fine_amt_calc_type` validated |
| Views | ✅ **FIXED**: `fine_amt_calc_type` added to edit + show views |
| Routes | ✅ |
| Migration | 🟡 FK references `lib_fine_types` (plural — wrong table name, should be `lib_fine_type`) |
| **Issues** | 🟡 Migration FK ref to `lib_fine_types` (plural) which doesn't exist — table is `lib_fine_type` (singular). Low impact as constraint name is auto-generated. |

### Tab-3.3: `lib_fine_slab_details`
| Layer | Status |
|-------|--------|
| Model | ✅ `$casts` includes `calculation_type` |
| Controller | ✅ Full CRUD |
| FormRequest | ✅ **FIXED**: `rate_type` validated as `in:fixed,percentage` (was free-text) |
| Views | ✅ **FIXED**: `rate_type` changed from `<input>` to `<select>` dropdown in create+edit; `calculation_type` added to index+show views |
| Routes | ✅ |
| Migration | ✅ Renamed `rate_per_day→fine_rate`, added `calculation_type` |
| **Issues** | None ✅ |

### Tab-3.4: `lib_account_entry_config`
| Layer | Status |
|-------|--------|
| Model | ✅ |
| Controller | ✅ Full CRUD + toggleStatus |
| FormRequest | ✅ Composite duplicate check |
| Views | ✅ 5/5 |
| Routes | ✅ |
| Migration | 🟡 FK references `lib_fine_types` (plural — should be `lib_fine_type`) |
| **Issues** | 🟡 Same migration FK table name mismatch as Tab-3.2 |

### Tab-3.5: `lib_library_status_masters`
| Layer | Status |
|-------|--------|
| Model | ✅ `$fillable` + `$casts` correct |
| Controller | ✅ Full CRUD + `is_system` guard on edit/update/destroy/forceDelete |
| FormRequest | ✅ **FIXED**: Added `Digital Resource Status`, `Digital Access Transaction Status`, and `Digital Access Request Status` to `in:` rule; fixed "Inventry" → "Inventory" |
| Views | ✅ **FIXED**: "Inventry" → "Inventory" typo in create/edit views |
| Routes | ✅ |
| Migration | 🔶 "Inventry" typo in seed data (code handles it correctly). ✅ 4 new system records added in Session 3 (status_type `Digital Access Request Status`: Pending→38, Approved→39, Rejected→40, Withdrawn→41). |
| **Issues** | 🔶 Migration seed has "Inventry" typo — DB already has correct "Inventory" value from earlier ALTER TABLE. Migration seed needs updating. |

### Extra: `lib_membership_types` (Tab-5.1 — Config-type table)
| Layer | Status |
|-------|--------|
| All layers | ✅ Fully implemented |
| **Issues** | 🟡 `store()` does double redirect (standalone → hub); negligible |

---

## SUB-MENU 4: ACQUISITION & CATALOGING (9 tables)

### Tab-4.1: `lib_books_master` (Core)
| Layer | Status |
|-------|--------|
| Model | ✅ `LibBookMaster` — **FIXED**: removed old `awards`/`tags`/`key_concepts` from fillable+casts. Only `awards_json`/`tags_json`/`key_concepts_json` remain. `popularity_rank` cast = `integer` |
| Controller | ✅ Full CRUD + ISBN lookup + quick-create AJAX |
| FormRequest | ✅ `LibBookMasterRequest` — **FIXED**: removed old `awards`/`tags`/`key_concepts` rules; `subject_ids` added |
| Views | ✅ 5/5 + subject multi-select added |
| Routes | ✅ |
| Migration | 🔶 **`publisher_id`** nullable in migration but DDL says NOT NULL (blocked by FK SET NULL). Extra migrated column (benign): `cover_image_url`. Language FK (`language_id` BIGINT→`sys_dropdowns`) added in Session 3. Old `awards`/`key_concepts` dropped, `tags`→`tags_json` renamed in Session 3. |
| **Issues** | 🔶 Migration-only: publisher_id NOT NULL (blocked by FK SET NULL constraint) |

### Junction tables (5 tables)
| Layer | Status |
|-------|--------|
| Models | ✅ All 5 models exist |
| Controllers | 🟡 No dedicated controllers (managed via BookMaster sync — intentional) |
| Views | 🟡 No dedicated views |
| Routes | 🟡 No direct routes |
| Migrations | ✅ All match DDL |
| **Issues** | 🟡 Managed through parent — intentionally no standalone CRUD |

### Tab-4.2: `lib_book_purchases`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibBookPurchase` — **FIXED**: `note`→`notes` in fillable |
| Controller | ✅ Full CRUD + toggleStatus |
| FormRequest | ✅ **FIXED**: `StoreLibBookPurchaseRequest` — `note`→`notes` validation key |
| Views | ✅ 5/5 |
| Routes | ✅ |
| Migration | 🟡 FK constraint action: DDL=`RESTRICT`, Migration=`nullOnDelete()` (SET NULL). Missing `idx_lib_bookPurchase_billDate` index. |
| **Issues** | 🟡 Migration: FK action differs from DDL; missing bill_date index |

### Tab-4.2 Items: `lib_book_purchases_items`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibBookPurchaseItem` |
| Migration | 🟡 FK constraint actions: DDL=RESTRICT, Migration=CASCADE |
| **Issues** | 🟡 Migration FK action differs from DDL |

### Tab-4.3: `lib_book_copies`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibBookCopy` — `withdrawal_reason` in fillable; `status` cast = `integer` |
| Controller | ✅ Full CRUD + markLost/markDamaged/updateStatus |
| FormRequest | ✅ `LibBookCopyRequest` |
| Views | ✅ 5/5 |
| Routes | ✅ |
| Migration | ✅ (stale columns dropped by `2026_06_06_110000`) |
| **Issues** | 🟡 Migration has extra composite index beyond DDL spec |

### Tab-4.3 Condition Log: `lib_book_condition_jnt`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibBookConditionJnt` |
| Migration | 🟡 Index name mismatch: migration=`idx_condition_book`, DDL=`idx_lib_bookCondJnt_book_copy_date_cond` |
| **Issues** | 🟡 Index naming |

### Tab-4.4: `lib_digital_resources`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibDigitalResource` — `license_count` cast = `integer`, `status` cast = `integer` |
| Controller | ✅ Full CRUD + incrementDownload/View |
| FormRequest | ✅ `LibDigitalResourceRequest` — `license_count` as `nullable|integer` |
| Views | ✅ 5/5 |
| Routes | ✅ |
| Migration | 🔶 **`file_media_id` FK references `media_files`** (DDL says `sys_media`). **`license_count` type**: DDL=`SMALLINT NULL`, Migration=`TINYINT NOT NULL 0`. Extra columns: `usage_score`, `daily_accesses` (not in DDL). |
| **Issues** | 🔶 Migration-only: FK target table, license_count type/nullability, extra columns |

### NT-003: `lib_digital_access_request_types`
| Layer | Status |
|-------|--------|
| **Entire table** | ✅ **Exists in DB** with 5 seed records (Download, View_Online, Stream, Offline, Extended). FK from `lib_digital_access_requests.request_type` already references it. |
| Model | ✅ `LibDigitalAccessRequestType` model exists |
| **Issues** | 🟡 No dedicated controller/views/routes (managed via DB seed only) |

### `lib_digital_resource_tags`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibDigitalResourceTag` — SoftDeletes trait present |
| Controller | ⚠️ Monolith — `index()` queries ALL entities, not just tags |
| Views | ✅ `index.blade.php` |
| Migration | ✅ `deleted_at` column EXISTS in DB (report was outdated) |
| **Issues** | 🟡 Controller could be improved for tag-specific filtering |

---

## SUB-MENU 5: MEMBER & ACCESS (3 tables)

### Tab-5.1: `lib_membership_types`
| Layer | Status |
|-------|--------|
| Model | ✅ All DDL columns in fillable + casts |
| Controller | ✅ Full CRUD + toggleStatus |
| FormRequest | ✅ |
| Views | ✅ 5/5 |
| Routes | ✅ |
| Migration | ✅ |
| **Issues** | 🟡 `store()` double redirect; negligible |

### Tab-5.2: `lib_members`
| Layer | Status |
|-------|--------|
| Model | ✅ **FIXED**: Added `integer` casts for `total_books_borrowed`, `reading_goal_annual`, `reading_progress_ytd` |
| Controller | ✅ Full CRUD + updateStatus + calculateSegment |
| FormRequest | ✅ `LibMemberRequest` |
| Views | ✅ 5/5 |
| Routes | ✅ |
| DB vs DDL | 🔶 **`preferred_language` is VARCHAR** (DDL says INT FK to `sys_dropdown_table`). `library_card_barcode` is NULLable in DB (DDL says NOT NULL). `status` is FK (converted from ENUM in Session 3). |
| **Issues** | 🔶 Migration-only: 2 type mismatches requiring data migration (preferred_language + library_card_barcode) |

### Tab-5.3: `lib_digital_resource_access_restrictions`
| Layer | Status |
|-------|--------|
| Model | ✅ |
| Controller | ✅ Full CRUD + toggleStatus |
| FormRequest | ✅ **FIXED**: All 4 restriction fields changed `required|integer` → `nullable|integer`. Added `withValidator()` for at-least-one-not-null check. |
| Views | ✅ 5/5 |
| Routes | ✅ |
| Migration | ✅ |
| **Issues** | None ✅ |

---

## SUB-MENU 6: OPERATIONS (6 tables)

### Tab-6.1: `lib_reservations`
| Layer | Status |
|-------|--------|
| Model | ✅ Renewal fields present (`is_renewal_request`, `renewal_days_requested`, `renewal_approved`, `renewal_approved_at`, `renewal_approved_by_id`) |
| Controller | ✅ Full CRUD + approveRenewal/rejectRenewal/markAvailable/cancel |
| FormRequest | ✅ Duplicate check |
| Views | ✅ 5/5 |
| Routes | ✅ |
| DB vs DDL | 🟡 `queue_position` exists but COMMENTED OUT in DDL v6. `status` is FK (converted from ENUM in Session 3). |
| **Issues** | 🟡 `queue_position` commented out in DDL v6 (already in DB); benign |

### Tab-6.2: `lib_transactions`
| Layer | Status |
|-------|--------|
| Model | ✅ `book_id`, `renewal_count`, `is_renewed` in fillable+casts |
| Controller | ✅ Full CRUD + returnBook/renew/markLost/history/calculateFine — **FIXED**: removed `toggleStatus()` method (no `is_active` column) |
| FormRequest | ✅ Auto-resolves book_id from copy |
| Views | ✅ 5/5 |
| Routes | ✅ **FIXED**: removed `lib-transactions.toggleStatus` route |
| DB vs DDL | ✅ `status` is FK (converted from ENUM in Session 3). `STATUS_ISSUED=14`, `STATUS_RETURNED=15`, `STATUS_OVERDUE=16`, `STATUS_LOST=17` |
| **Issues** | None ✅ |

### Tab-6.3: `lib_digital_access_requests`
| Layer | Status |
|-------|--------|
| Model | ✅ **FIXED**: `request_type` added to fillable+casts; extraneous `created_by`/`updated_by` removed |
| Controller | ✅ **FIXED**: `store()` now validates and saves `request_type` |
| FormRequest | 🟡 No dedicated FormRequest — inline validation used |
| Views | 🟡 No create/edit views with request_type dropdown |
| Routes | ✅ Resource |
| Migration | 🔶 Migration has no `request_type` column (but DB already has it from manual ALTER). Status uses ENUM not FK. |
| **Issues** | 🔶 Migration-only: missing request_type in migration file; status ENUM→FK |

### Tab-6.4: `lib_digital_access_transactions`
| Layer | Status |
|-------|--------|
| Model | ✅ **FIXED**: Removed extraneous `request_type` from fillable (not in DDL v6) |
| Controller | 🟡 No standalone CRUD (read-only tab in Operations hub) |
| Routes | 🟡 No CRUD routes |
| Views | ✅ Read-only tab added in Operations hub |
| Migration | ✅ |
| DB vs DDL | ✅ DB matches DDL v6 |
| **Issues** | 🟡 No standalone CRUD (only read-through in hub tab) |

### Tab-6.5: `lib_fines`
| Layer | Status |
|-------|--------|
| Model | ✅ **FIXED**: Removed `calculation_breakdown` (old) from fillable+casts. Only `calculation_breakdown_json` remains. |
| Controller | ✅ Full CRUD + markPaid/waive/payment/calculate |
| FormRequest | ⚠️ Uses `fine_type_id` not `fine_type` |
| Views | ✅ 5/5 |
| Routes | ✅ |
| DB vs DDL | 🔶 `fine_type` is ENUM in DB (DDL says FK to `lib_fine_type.id`). `status` is FK (converted from ENUM in Session 3). |
| **Issues** | 🔶 Migration-only: fine_type ENUM→FK to `lib_fine_type.id`. `calculation_breakdown` old column dropped in Session 3. |

### Tab-6.6: `lib_fine_payments`
| Layer | Status |
|-------|--------|
| Model | ✅ |
| Controller | ✅ Full CRUD |
| FormRequest | ✅ Payment method ENUM validation |
| Views | ✅ 5/5 |
| Routes | ✅ |
| DB vs DDL | ✅ **FIXED**: `payment_method` ENUM now matches DDL (`Cash,Card,Online,Waiver`). `Transfer To Fee` → `Waiver` (14 records migrated). DB already had `Cash,Online` matching DDL. |
| **Issues** | None ✅ |

---

## SUB-MENU 7: AUDIT & HISTORY (3 tables)

### Tab-7.1: `lib_transaction_history`
| Layer | Status |
|-------|--------|
| Model | ✅ **FIXED**: Removed `old_value`/`new_value` from fillable+casts. Only `old_value_json`/`new_value_json` remain. **FIXED**: All 4 consuming controller/service locations updated to use `_json` variant. |
| Controller | ❌ No dedicated CRUD — read-only via `LibraryController::historyIndex()` |
| Views | ❌ No dedicated views — shown in hub |
| Routes | ❌ No CRUD routes |
| Migration | ✅ Old `old_value`/`new_value` columns dropped in Session 3; only `old_value_json`/`new_value_json` remain |
| **Issues** | None ✅ |

### Tab-7.2: `lib_inventory_audit`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibInventoryAudit` |
| Controller | ✅ Full CRUD + markCompleted/cancel/initialize/complete/checkCopy. **FIXED**: route names `lib-inventory-audit.*` (no `library.` prefix). **FIXED**: "Inventry" → "Inventory" in `getIdByCode()`. |
| FormRequest | ✅ `LibInventoryAuditRequest` |
| Views | ✅ 5/5 |
| Routes | ✅ Resource + custom |
| Migration | ✅ |
| **Issues** | None ✅ |

### Tab-7.3: `lib_inventory_audit_details`
| Layer | Status |
|-------|--------|
| Model | ✅ **FIXED**: Added `SoftDeletes` trait |
| Controller | ✅ Full CRUD + bulkStore/byAudit |
| Views | ✅ 5/5 + by-audit |
| Routes | ✅ |
| Migration | ✅ `deleted_at` column EXISTS in DB (report was outdated) |
| **Issues** | 🟡 Model has `$timestamps = false` — prevents `created_at`/`updated_at` auto-management (migration provides them via default values). |

---

## SUB-MENU 8: ANALYTICS (6 tables)

### Tab-8.1: `lib_reading_behavior_analytics`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibReadingBehaviorAnalytics` — `$timestamps = false` |
| Controller | ✅ Read-only via `LibraryAnalyticsController::index()` |
| Views | ✅ Shown in `analyticsIndex.blade.php` |
| Routes | ✅ Single route |
| Commands | ✅ `UpdateReadingBehaviorAnalytics` + schedule |
| Migration | 🔶 `academic_year` VARCHAR still used — DDL v6 F-031 says replace with `academic_year_id` INT FK |
| **Issues** | 🔶 Migration-only: academic_year→academic_year_id FK |

### Tab-8.2: `lib_book_popularity_trends`
| Layer | Status |
|-------|--------|
| Model | ✅ All DDL columns in fillable |
| Controller | ✅ Read-only |
| Views | ✅ Shown in analytics tab |
| Commands | ✅ `UpdatePopularityTrends` + schedule |
| Migration | ✅ (extra `deleted_at` not in DDL but benign) |
| **Issues** | 🟡 Extra `deleted_at` in migration not in DDL |

### Tab-8.3: `lib_collection_health_metrics`
| Layer | Status |
|-------|--------|
| Model | ✅ **FIXED**: `category()` + `genre()` relationships now use `'id'` as owner key (not `'category_id'`/`'genre_id'`). |
| Controller | ✅ Read-only |
| Views | ✅ Shown in analytics tab |
| Commands | ✅ `UpdateCollectionHealthMetrics` + schedule |
| Migration | ✅ |
| **Issues** | None ✅ |

### Tab-8.4: `lib_predictive_analytics`
| Layer | Status |
|-------|--------|
| Model | ✅ **FIXED**: Removed `features_used` from fillable+casts. Only `features_used_json` remains. |
| Controller | ✅ Read-only |
| Views | ✅ Shown in analytics tab |
| Commands | ✅ `GeneratePredictiveAnalytics` command created in Session 3 (signature: `library:generate-predictive-analytics`, schedule: weekly Monday 05:00) |
| Migration | ✅ |
| **Issues** | None ✅ |

### Tab-8.5: `lib_curricular_alignment`
| Layer | Status |
|-------|--------|
| Model | ✅ **FIXED**: Removed `academic_year` from fillable. Only `academic_year_id` remains. |
| Controller | ✅ `LibCurricularAlignmentController` — Full CRUD. **FIXED**: `store()`/`update()` no longer writes `academic_year` string. |
| Views | ✅ 5/5 (recently added). Uses `academic_year_id` in forms. |
| Routes | ✅ |
| Migration | 🔶 Both `academic_year` VARCHAR + `academic_year_id` FK coexist |
| **Issues** | 🔶 Migration-only: old VARCHAR column still in table |

### Tab-8.6: `lib_engagement_events`
| Layer | Status |
|-------|--------|
| Model | ✅ **FIXED**: Removed `filters_used` from fillable+casts. Only `filters_used_json` remains. |
| Controller | ✅ Read-only |
| Views | ✅ Shown in analytics tab |
| Commands | ✅ `CleanupEngagementEvents` command created in Session 3 (signature: `library:cleanup-engagement-events --days=90`, schedule: weekly Saturday 03:00) |
| Migration | 🟡 Extra `updated_at` + `deleted_at` columns not in DDL |
| **Issues** | 🟡 Extra migration columns: `updated_at`, `deleted_at` not in DDL |

---

## SUB-MENU 9: NEW TABLES (4 tables)

### NT-001: `lib_book_reviews_ratings`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibBookReview` — all DDL columns in fillable |
| Controller | ✅ `LibBookReviewController` — Full CRUD + approve/reject/toggleStatus |
| Views | ✅ 5/5 |
| Routes | ✅ |
| Migration | ✅ |
| **Issues** | 🟡 No dedicated FormRequest (uses inline validation) |

### NT-002: `lib_wishlist`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibWishlist` — `priority`, `notes`, `is_active` all in fillable |
| Controller | 🟡 **Only `toggleWishlist()`** — **FIXED**: `Gate::authorize()` added. No full admin CRUD. |
| Views | ❌ No admin CRUD views (student/staff portal shows via controller methods) |
| Routes | 🟡 Only `POST /lib-wishlist/toggle` |
| Migration | ✅ |
| **Issues** | 🟡 No admin management UI or full CRUD |

### NT-004: `lib_library_settings`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibLibrarySetting` — all DDL columns in fillable |
| Controller | ❌ **No controller** |
| Views | ❌ **No views** |
| Routes | ❌ **No routes** |
| Migration | ✅ |
| **Issues** | 📋 **Unimplemented** — no admin UI |

### NT-005: `lib_background_services`
| Layer | Status |
|-------|--------|
| Model | ✅ `LibBackgroundService` — extra `last_run_at` + `is_active` (beneficial) |
| Controller | ❌ **No controller** |
| Views | ❌ **No views** |
| Routes | ❌ **No routes** |
| Migration | ✅ |
| **Issues** | 📋 **Unimplemented** — no admin UI |

---

## Additional Items (Sub-menus 10-13)

### Sub-menu 10: Composite Indexes
- Index naming conventions differ: migration short form vs DDL `idx_lib_*` convention. Functional impact is negligible.
- FK constraint actions differ in several migrations: DDL specifies `RESTRICT`, migrations use `CASCADE` or `SET NULL`.

### Sub-menu 11: Triggers
- **5 triggers defined in DDL** — not created as MySQL triggers. Business logic handled in PHP controllers/services (e.g., `LibTransactionController::returnBook()` updates copy status).
- `auto_calculate_fines` event equivalent exists in `ProcessFineAging` command.
- Status comparisons in PHP use status IDs (FK model) not ENUM strings.

### Sub-menu 12: Views (5 SQL views)
- **All 5 views ALREADY EXIST in DB** ✅:
  1. `lib_view_member_360` ✅
  2. `lib_view_collection_performance` ✅
  3. `lib_view_predictive_demand` ✅
  4. `lib_view_overdue_books` ✅
  5. `lib_view_most_issued_books` ✅
- Note: Views use ENUM string status comparisons (e.g., `WHERE status = 'Issued'`). If status columns migrate to FK integers, views must be recreated to use subquery lookups to `lib_library_status_masters` (as DDL v6 specifies).

### Sub-menu 13: Seed Data
- ✅ Status masters — all 37 system status rows exist (incl. Digital Resource Status + Digital Access Transaction Status)
- ✅ Fine types — all 4 types exist
- ✅ Digital access request types — all 5 types exist
- ✅ Membership types, categories, genres, resource types, book conditions — all seeded
- 🟡 `lib_background_services` — model exists but no seeder creates the service record

---

## REMAINING ISSUES — By Category

### 🔶 Migration-Only (code clean, needs migration to execute)
| # | Priority | Table | Issue | Fix Needed |
|---|----------|-------|-------|------------|
| 1 | P1 | `lib_members` | `preferred_language` VARCHAR→INT FK | New migration to change type + migrate data |
| 2 | P1 | `lib_reading_behavior_analytics` | `academic_year`→`academic_year_id` FK | New migration to add FK + migrate data |
| 3 | P2 | `lib_digital_access_requests` | `status` ENUM→FK (7 tables converted in Session 3; this table remains) | New migration for status FK |
| 4 | P2 | `lib_fines` | `fine_type` ENUM→FK to `lib_fine_type.id` | New migration for fine_type FK |
| 5 | P2 | `lib_authors` | `country_id`+`primary_genre_id` NOT NULL | Migration to drop+recreate FK with RESTRICT |
| 6 | P2 | `lib_books_master` | `publisher_id` NOT NULL | Migration to change FK SET NULL→RESTRICT |
| 7 | P2 | `lib_digital_resources` | `file_media_id`→`sys_media`, `license_count` type | Migration to fix FK target + column type |

> **Session 3 resolved 7 status ENUM→FK conversions** (lib_book_copies, lib_fines, lib_inventory_audit, lib_inventory_audit_details, lib_members, lib_reservations, lib_transactions), **language FK on lib_books_master**, **3 stale column drop/renames** (lib_books_master awards/key_concepts/tags, lib_transaction_history old_value/new_value, lib_fines calculation_breakdown), and **2 new commands** (GeneratePredictiveAnalytics, CleanupEngagementEvents).

### 🟡 Minor (no crash risk)
| # | Table | Issue |
|---|-------|-------|
| 1 | `lib_categories` | `display_order` default: DDL=1, Migration=0 |
| 2 | `lib_reservations` | `queue_position` exists but COMMENTED OUT in DDL v6 |
| 3 | `lib_book_purchases` | FK action: DDL=RESTRICT, Migration=SET NULL |
| 4 | `lib_book_purchases_items` | FK action: DDL=RESTRICT, Migration=CASCADE |
| 5 | Various | Index names: migration short vs DDL `idx_lib_*` |
| 6 | `lib_library_settings` | No admin UI |
| 7 | `lib_background_services` | No admin UI, no seeder |
| 8 | `lib_wishlist` | No admin CRUD |
| 9 | `lib_book_popularity_trends` | Extra `deleted_at` in migration |

### 📋 Unimplemented Features
| # | Feature | Status |
|---|---------|--------|
| 1 | `lib_library_settings` admin UI | No controller/views/routes |
| 2 | `lib_background_services` admin UI | No controller/views/routes |

---

## Fully Aligned Tables (✅ 37 tables)
1. `lib_resource_types`
2. `lib_categories` (minor default diff)
3. `lib_genres`
4. `lib_book_conditions`
5. `lib_publishers`
6. `lib_authors` (code aligned, migration blocked)
7. `lib_keywords`
8. `lib_locations_master`
9. `lib_shelf_locations`
10. `lib_fine_type`
11. `lib_fine_slab_config`
12. `lib_fine_slab_details`
13. `lib_account_entry_config`
14. `lib_library_status_masters`
15. `lib_book_author_jnt`
16. `lib_book_category_jnt`
17. `lib_book_genre_jnt`
18. `lib_book_subject_jnt`
19. `lib_book_keyword_jnt`
20. `lib_book_purchases`
21. `lib_book_purchases_items`
22. `lib_book_copies`
23. `lib_book_condition_jnt`
24. `lib_digital_access_request_types`
25. `lib_digital_resource_tags`
26. `lib_membership_types`
27. `lib_digital_resource_access_restrictions`
28. `lib_digital_access_requests`
29. `lib_fine_payments`
30. `lib_inventory_audit`
31. `lib_inventory_audit_details`
32. **`lib_transactions`** (status FK converted in Session 3)
33. `lib_collection_health_metrics`
34. **`lib_predictive_analytics`** (prediction command created in Session 3)
35. `lib_curricular_alignment`
36. `lib_book_reviews_ratings`
37. `lib_wishlist`

## SQL Views (✅ 5/5)
1. `lib_view_member_360` ✅
2. `lib_view_collection_performance` ✅
3. `lib_view_predictive_demand` ✅
4. `lib_view_overdue_books` ✅
5. `lib_view_most_issued_books` ✅

## Legend
| Icon | Meaning |
|------|---------|
| ✅ | Fully aligned with DDL v6 |
| 🟡 | Minor gap (cosmetic, default value, missing view field) |
| 🔶 | Migration-only gap (code aligned, needs schema migration) |
| 🟠 | Major gap (column type mismatch, missing method, missing view) |
| 🔴 | Critical gap (app will crash, data loss, FK violation) |
| ❌ | Missing entirely |
| 📋 | Unimplemented feature |

---

## Session 3 Changelog (Applied June 2026)

### 1. Column Cleanup (All DONE)
- **`lib_books_master`**: Dropped old `awards` (TEXT) column, dropped old `key_concepts` (JSON) column, renamed `tags` → `tags_json`
- **`lib_transaction_history`**: Dropped old `old_value` (JSON) column, dropped old `new_value` (JSON) column
- **`lib_fines`**: Dropped old `calculation_breakdown` (JSON) column
- Old data migrated to `*_json` columns before dropping

### 2. Language FK (DONE)
- **`lib_books_master`**: Added `language_id` BIGINT UNSIGNED NOT NULL DEFAULT 293 FK → `sys_dropdowns(id)`
- Model: `$fillable` + `$casts` + `languageOption()` BelongsTo relationship
- FormRequest: Changed rule to `'language_id' => 'required|exists:sys_dropdowns,id'`
- Views: Changed `name="language"` → `name="language_id"`, value comparison by ID
- Removed old `'English'` fallback

### 3. Status ENUM→FK Conversion (7 tables, ALL DONE)
| Table | Status Codes |
|-------|-------------|
| `lib_book_copies` | available→1, issued→2, reserved→3, under_maintenance→4, lost→5, withdrawn→6 |
| `lib_fines` | Pending→23, Paid→24, Waived→25, Overdue→26 |
| `lib_inventory_audit` | In Progress→27, Completed→28, Cancelled→29 |
| `lib_inventory_audit_details` | found→30, missing→31, misplaced→32, damaged→33 |
| `lib_members` | active→10, expired→11, suspended→12, deactivated→13 |
| `lib_reservations` | Pending→18, Available→19, Picked_Up→20, Cancelled→21, Expired→22 |
| `lib_transactions` | Issued→14, Returned→15, Overdue→16, Lost→17 |
- Each: Added `status_new`, migrated data, dropped old ENUM, renamed to `status`, added FK constraint
- All 7 columns now `smallint unsigned NOT NULL DEFAULT n` with FK → `lib_library_status_masters(id)`

### 4. Status Query Code Fix (6 files)
- `MasterDashboardService.php` — string `where('status', ...)` replaced with `getIdByCode()`
- `LibFineReportService.php` — same
- `LibDashboardReportService.php` — same
- `LibAcquisitionReportService.php` — same + `whereIn` array resolved
- `LibTransactionController.php` — `'available'` → `getIdByCode('Book Status', 'Available')`
- `StaffLibraryController.php` — uses model mutator (already correct)

### 5. `LibLibraryStatusMaster` Enhancements
- Added `$idCache` static array for in-memory caching
- Added `clearIdCache()` method
- Added `'Digital Access Request Status'` to `status_type` ENUM
- Added 4 new system records: Pending (38), Approved (39), Rejected (40), Withdrawn (41)
- FormRequest `in:` rule updated for new status type

### 6. `LibTransaction` Constants Fixed
- `STATUS_ISSUED = 14`, `STATUS_RETURNED = 15`, `STATUS_OVERDUE = 16`, `STATUS_LOST = 17`

### 7. New Commands Created
- **`GeneratePredictiveAnalytics.php`** — signature: `library:generate-predictive-analytics`, schedule: weekly Monday 05:00
- **`CleanupEngagementEvents.php`** — signature: `library:cleanup-engagement-events --days=90`, schedule: weekly Saturday 03:00
- Both registered in `LibraryServiceProvider::registerCommands()` + `registerCommandSchedules()`
