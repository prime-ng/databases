# Prime (PRM) — Notification — Gap Analysis & Coverage

**Test file:** `prm_Notification_TestCas.php` · **33 methods** · single comprehensive suite
**Screen type:** read/action-focused (no create/edit form → no store/update validation matrix)

---

## 1. Manual TC ↔ Dusk method mapping

### Config truth

| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-P01 | `test_..._01` | Full |
| TC-P02 | `test_..._02` | Full |
| TC-P03 | `test_..._03` | Full |
| TC-P04 | `test_..._04` | Full |
| TC-P05 | `test_..._05` | Full |

### Business rules

| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-P10 | `test_..._10` | Full |
| TC-S11 | `test_..._11` | Full |
| TC-P12 | `test_..._12` | Full |
| TC-S13 (DEV-PRM-NTF-002) | `test_..._13` | Full |

### Permissions

| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-A50 | `test_..._50` | Full |
| TC-A51 | `test_..._51` | Full |
| TC-A52 (DEV-PRM-NTF-001) | `test_..._52` + `test_..._05` | Full |
| TC-A53 | `test_..._53` | Full |
| TC-A54 | `test_..._54` | Full |

### UI / render

| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-P60 | `test_..._60` | Full |
| TC-P61 | `test_..._61` | Full |
| TC-P62 | `test_..._62` | Full |
| TC-P63 | `test_..._63` | Full |

### Actions / API

| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-P70 | `test_..._70` | Full |
| TC-P71 | `test_..._71` | Full |
| TC-P72 | `test_..._72` | Full |
| TC-P73 | `test_..._73` | Full |

### Negative / Auth / Security

| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-N30 | `test_..._30` | Full |
| TC-N31 | `test_..._31` | Full |
| TC-N93 | `test_..._93` | Full |
| TC-S80 (SEC-PRM-002) | `test_..._80` | Full |
| TC-S81 | `test_..._81` | Full |
| TC-S82 | `test_..._82` | Full |
| TC-S90 | `test_..._90` | Full |
| TC-S91 | `test_..._91` | Full |
| TC-S92 | `test_..._92` | Full |

### Integration / Ref

| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-P40 | `test_..._40` | Full |
| TC-P41 | `test_..._41` | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % |
|----------|----------|------|---------|-----|---|
| Positive | 17 | 17 | 0 | 0 | 100% |
| Negative | 3 | 3 | 0 | 0 | 100% |
| Permissions | 5 | 5 | 0 | 0 | 100% |
| Security / Config | 8 | 8 | 0 | 0 | 100% |
| Integration/Ref | 2 | 2 | 0 | 0 | 100% |
| **Overall** | **35 TC → 33 methods** | **35** | **0** | **0** | **100%** |

> Positive ≥ 90% ✅ · Negative 100% ✅ · Dependency/Integration ≥ 90% ✅ (100%) · Tenancy N/A (central single-DB feature — no cross-tenant surface). Screen has no create/edit form, so field-level validation TCs are intentionally absent (documented, not a gap).

---

## 3. Coverage-Score by requirement source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`) | 8 | 8 | 100% |
| State-Machine (`Screen-SM`) | 1 | 1 | 100% |
| Validation Rules (`Screen-VR`) | 0 | 0 | n/a (no form) |
| Integration Points (`Screen-IP`) | 2 | 2 | 100% |
| Permissions (`Screen-PM`) | 3 | 3 | 100% |
| Config / Env (`Screen-SEC`) | 3 | 3 | 100% |

Every `Source`-tagged BC maps to ≥ 1 TC.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compared | Finding |
|---|-------|----------|---------|
| 2 | Route registration | Blade `route('central.dashboard.*')` vs `routes/web.php` | All names registered ✅ |
| 3 | Gate vs Policy | Controller `Gate::authorize('prime.notification.delete')` vs Policy | **DEV-PRM-NTF-001** — string gate with **no** `Gate::define` and **no** policy `delete()` method |
| 3b | Gate vs Policy | `viewAny`/`create` vs Policy | Both defined + backed ✅ |
| 6 | Debug/prod guard | Route registration env guard vs brief SEC-PRM-002 | **SEC-PRM-002 REFUTED** — route env-guarded; residual: no internal method env check |
| 7 | State machine | unread→read→deleted vs controller | Implemented via markAsRead/markAllAsRead/destroy ✅ |
| 10 | Permissions | Gate strings `prime.notification.*` vs Spatie perms `tenant.notification.*` | Policy delegates prime.* → tenant.* (naming inconsistency, intentional) |
| 11 | Integration/morph | `notifiable` morph vs migration | `morphs('notifiable')` present ✅ |
| — | Notification payload | `TestNotification($user)` ctor vs body | **DEV-PRM-NTF-002** — ctor arg ignored; uses `User::inRandomOrder()->first()` |

---

## 5. Defect Register (feature)

| ID | Sev | Description | Proving test | Status |
|----|-----|-------------|--------------|--------|
| SEC-PRM-002 | REFUTED | test-notification claimed unguarded; source has env guard at registration | `test_..._80`, `_82` | Documented / refuted |
| DEV-PRM-NTF-001 | P3 | `destroy` authorizes undefined `prime.notification.delete` (no define, no policy method); non-super-admin cannot delete | `test_..._52`, `_05` | Open |
| DEV-PRM-NTF-002 | P4 | `TestNotification` ignores ctor `$user`, uses random user for message body | `test_..._13` | Open |

---

## 6. Deliberately not covered (with reason)

| Dimension | Reason |
|-----------|--------|
| Field validation (required/format/length) | No create/edit form — nothing to validate |
| Tenancy isolation (TC-T) | Central single-DB feature; notifications are per-user via `notifiable_id`, not per-tenant |
| Force-delete / soft-delete / restore | Notifications use hard `delete()`; no SoftDeletes trait on the morph table |
| Activity-log assertions | Controller writes no activity logs for notification actions |

**Legend:** Full = behaviour asserted end-to-end or via authoritative source assertion · Partial = indirect · Gap = none.
