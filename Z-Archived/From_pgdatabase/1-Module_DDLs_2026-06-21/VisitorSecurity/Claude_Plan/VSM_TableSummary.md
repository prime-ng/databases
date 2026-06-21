# VSM — Visitor & Security Management Module Table Summary
**13 tables | Prefix:** `vsm_` | **Database:** `tenant_db` | **Generated:** 2026-03-27

---

## Table Inventory

| # | Table | Domain | Description |
|---|---|---|---|
| 1 | `vsm_visitors` | Visitor Core | Master visitor profile; one row per unique visitor; matched by mobile_no on every registration; visit_count denormalised for dashboard |
| 2 | `vsm_visits` | Visitor Core | Per-visit record with 6-state FSM (Pre_Registered→Checked_In→Checked_Out); is_overdue set by scheduler; blacklist_hit set at registration time |
| 3 | `vsm_gate_passes` | Visitor Core | QR gate pass token (UUID v4) per visit (1:1); expires_at server-side only; status: Issued→Used→Expired/Revoked |
| 4 | `vsm_contractors` | Access Control | Multi-day contractor/vendor access with reusable pass_token; access restricted by date range and entry_days_json (BR-VSM-012) |
| 5 | `vsm_pickup_auth` | Access Control | Student pickup authorisation log; is_authorised=1 when guardian in std_student_guardian_jnt.can_pickup=1; supervisor override logged |
| 6 | `vsm_blacklist` | Access Control | Blacklisted persons; checked on every registration by mobile_no OR id_number; valid_until=NULL = permanent; auto-expired by daily job |
| 7 | `vsm_guard_shifts` | Guard Operations | Guard shift schedules and attendance; UNIQUE(guard_user_id, shift_date, shift_start_time) prevents overlap; attendance_status auto-set on clock-in/out |
| 8 | `vsm_patrol_checkpoints` | Guard Operations | Campus checkpoint definitions; each has unique qr_token (UUID v4) placed at physical location; admin-managed |
| 9 | `vsm_patrol_rounds` | Guard Operations | Per-patrol round summary; completion_pct computed by PatrolService; <80% → status=Incomplete + admin alert (BR-VSM-006) |
| 10 | `vsm_patrol_checkpoint_log` | Guard Operations | Immutable per-checkpoint scan log; scanned_at is immutable; one row per checkpoint scan within a round |
| 11 | `vsm_emergency_protocols` | Emergency | SOP templates per emergency type; seeded with 5 standard protocols; school admin updates with school-specific procedures |
| 12 | `vsm_emergency_events` | Emergency | Active emergency events log; is_lockdown_active=1 disables gate pass generation platform-wide and shows lockdown banner (BR-VSM-010) |
| 13 | `vsm_cctv_events` | CCTV Integration | Immutable inbound webhook event log from CCTV systems; linked_visit_id auto-linked when gate camera + active visit within check-in window |

---

## Audit Column Exceptions (DDL Rule 2)

| Table | Missing Columns | Reason |
|---|---|---|
| `vsm_patrol_checkpoint_log` | `is_active`, `updated_at`, `deleted_at`, `created_by`, `updated_by` | Immutable guard scan record — one row per checkpoint scan; never updated or soft-deleted; scanned_at is the authoritative timestamp |
| `vsm_cctv_events` | `is_active`, `updated_at`, `deleted_at`, `created_by`, `updated_by` | Immutable inbound webhook event — system write from unauthenticated endpoint; no user context; never modified after insertion |

---

## Cross-Module FK Summary

| Column | Belongs To | References | Type |
|---|---|---|---|
| `host_user_id` | `vsm_visits` | `sys_users.id` | INT UNSIGNED |
| `checkin_photo_media_id` | `vsm_visits` | `sys_media.id` | INT UNSIGNED |
| `photo_media_id` | `vsm_visitors` | `sys_media.id` | INT UNSIGNED |
| `id_proof_media_id` | `vsm_visitors` | `sys_media.id` | INT UNSIGNED |
| `photo_media_id` | `vsm_contractors` | `sys_media.id` | INT UNSIGNED |
| `photo_media_id` | `vsm_blacklist` | `sys_media.id` | INT UNSIGNED |
| `id_proof_media_id` | `vsm_pickup_auth` | `sys_media.id` | INT UNSIGNED |
| `student_id` | `vsm_pickup_auth` | `std_students.id` | INT UNSIGNED |
| `override_by` | `vsm_pickup_auth` | `sys_users.id` | INT UNSIGNED |
| `processed_by` | `vsm_pickup_auth` | `sys_users.id` | INT UNSIGNED |
| `blacklisted_by` | `vsm_blacklist` | `sys_users.id` | INT UNSIGNED |
| `guard_user_id` | `vsm_guard_shifts` | `sys_users.id` | INT UNSIGNED |
| `guard_user_id` | `vsm_patrol_rounds` | `sys_users.id` | INT UNSIGNED |
| `triggered_by` | `vsm_emergency_events` | `sys_users.id` | INT UNSIGNED |
| `created_by` / `updated_by` | All standard tables | `sys_users.id` | INT UNSIGNED |

**Note:** INT UNSIGNED used for all cross-module FKs to match actual column types in tenant_db_v2.sql (sys_users.id, sys_media.id, std_students.id are INT UNSIGNED). vsm_* PKs and internal FKs use BIGINT UNSIGNED per requirement v2.

---

## Files Generated

| File | Location |
|---|---|
| `VSM_FeatureSpec.md` | `2-Claude_Plan/VSM_FeatureSpec.md` |
| `VSM_DDL_v1.sql` | `2-Claude_Plan/VSM_DDL_v1.sql` |
| `VSM_Migration.php` | `2-Claude_Plan/VSM_Migration.php` (copy to `database/migrations/tenant/2026_03_27_000000_create_vsm_tables.php`) |
| `Seeders/VsmEmergencyProtocolSeeder.php` | `2-Claude_Plan/Seeders/` → `Modules/VisitorSecurity/Database/Seeders/` |
| `Seeders/VsmPatrolCheckpointSeeder.php` | `2-Claude_Plan/Seeders/` → `Modules/VisitorSecurity/Database/Seeders/` |
| `Seeders/VsmSeederRunner.php` | `2-Claude_Plan/Seeders/` → `Modules/VisitorSecurity/Database/Seeders/` |
