# Board Management — Test Case List

**Feature:** Board Management | **REQ-ID:** REQ-PRM-009 | **Controller:** `BoardController`

---

## 1. Test Case Summary

| Total TC | Pass | Fail | Blocked | Not Run | Coverage |
|:--------:|:----:|:----:|:-------:|:-------:|:--------:|
| 30 | — | — | — | 30 | 0% |

---

## 2. Index/List — Board List (`GET /prime/board`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-BO-001 | Verify board list loads with paginated results | 10+ boards exist | — | Page renders 10 boards per page | — | — | ⬜ |
| TC-PRM-BO-002 | Verify unauthenticated user redirected to login | No active session | — | Redirected to login | — | — | ⬜ |
| TC-PRM-BO-003 | Verify user without viewAny permission receives 403 | Authenticated without `prime.board.viewAny` | — | 403 Forbidden | — | — | ⬜ |

---

## 3. Create/Store — Board Create (`GET /prime/board/create` + `POST /prime/board`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-BO-004 | Verify create form loads | Authenticated with `prime.board.create` | — | Create form renders | — | — | ⬜ |
| TC-PRM-BO-005 | Verify valid board creation succeeds | — | name="Central Board of Secondary Education", short_name="CBSE", is_active=true | Board created; activity log written; redirect to session-board-setup#academicboard | — | — | ⬜ |
| TC-PRM-BO-006 | Verify duplicate board name rejected | Existing board "CBSE" | name="CBSE" | Validation error: name already exists | — | — | ⬜ |
| TC-PRM-BO-007 | Verify duplicate short_name rejected | Existing board short_name "CBSE" | short_name="CBSE" | Validation error: short_name already exists | — | — | ⬜ |
| TC-PRM-BO-008 | Verify user without create permission receives 403 | Authenticated without `prime.board.create` | — | 403 Forbidden | — | — | ⬜ |

---

## 4. Show — Board Detail (`GET /prime/board/{board}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-BO-009 | Verify board detail shows all fields | Board exists | — | All board fields displayed | — | — | ⬜ |
| TC-PRM-BO-010 | Verify non-existent board returns 404 | Board ID 99999 | — | 404 Not Found | — | — | ⬜ |
| TC-PRM-BO-011 | Verify user without view permission receives 403 | Authenticated without `prime.board.view` | — | 403 Forbidden | — | — | ⬜ |

---

## 5. Edit/Update — Board Edit (`GET /prime/board/{board}/edit` + `PUT /prime/board/{board}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-BO-012 | Verify edit form loads with pre-filled data | Board exists | — | Edit form with current values | — | — | ⬜ |
| TC-PRM-BO-013 | Verify valid update saves changes | Existing board | name="Updated Board Name" | Board updated; activity log shows changed fields with old/new; redirect | — | — | ⬜ |
| TC-PRM-BO-014 | Verify update with no changes creates audit log | Existing board; submit unchanged data | — | Redirect; activity log: "No attributes changed." | — | — | ⬜ |
| TC-PRM-BO-015 | Verify user without update permission receives 403 | Authenticated without `prime.board.update` | — | 403 Forbidden | — | — | ⬜ |

---

## 6. Delete — Board Soft-Delete (`DELETE /prime/board/{board}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-BO-016 | Verify soft-delete sets is_active=false and deleted_at | Active board | — | Board is_active set to false; deleted_at timestamp set; activity log written; redirect | — | — | ⬜ |
| TC-PRM-BO-017 | Verify user without delete permission receives 403 | Authenticated without `prime.board.delete` | — | 403 Forbidden | — | — | ⬜ |

---

## 7. Trash/Restore/Force-Delete

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-BO-018 | Verify trashed list shows only soft-deleted boards | Soft-deleted boards exist | — | Only soft-deleted boards displayed (paginated) | — | — | ⬜ |
| TC-PRM-BO-019 | Verify restore works correctly | Soft-deleted board | — | Board restored; deleted_at set to NULL; activity log written; redirect | — | — | ⬜ |
| TC-PRM-BO-020 | Verify force-delete permanently removes board | Soft-deleted board | — | Board permanently deleted; activity log written; redirect | — | — | ⬜ |
| TC-PRM-BO-021 | Verify non-existent restore target returns 404 | ID 99999 not in trash | — | 404 Not Found | — | — | ⬜ |
| TC-PRM-BO-022 | Verify non-existent force-delete target returns 404 | ID 99999 | — | 404 Not Found | — | — | ⬜ |
| TC-PRM-BO-023 | Verify user without restore permission receives 403 | Authenticated without `prime.board.restore` | — | 403 Forbidden | — | — | ⬜ |
| TC-PRM-BO-024 | Verify user without forceDelete permission receives 403 | Authenticated without `prime.board.forceDelete` | — | 403 Forbidden | — | — | ⬜ |

---

## 8. Toggle Status (is_active)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-BO-025 | Verify toggle status deactivates board | Active board | is_active=false | JSON success; board is_active=false; activity log written | — | — | ⬜ |
| TC-PRM-BO-026 | Verify toggle status reactivates board | Inactive board | is_active=true | JSON success; board is_active=true; activity log written | — | — | ⬜ |
| TC-PRM-BO-027 | Verify toggle with non-boolean value rejected | — | is_active=invalid | Validation error: is_active must be true or false | — | — | ⬜ |
| TC-PRM-BO-028 | Verify toggle without update permission receives 403 | Authenticated without `prime.board.update` | — | 403 Forbidden | — | — | ⬜ |

---

## 9. Other

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-PRM-BO-029 | Verify deactivated board hidden from school dropdowns | Board deactivated, exists in config | — | Board does not appear in tenant configuration dropdowns | — | — | ⬜ |
| TC-PRM-BO-030 | Verify store uses `$request->all()` — confirm no extra fields leak | — | POST with extra_field=injection | Extra fields not persisted (model $fillable protection) | — | — | ⬜ |

---

## 10. Permissions Matrix

| Role | viewAny | create | view | update | delete | restore | forceDelete |
|------|:-------:|:------:|:----:|:------:|:------:|:-------:|:-----------:|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Platform Manager | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Platform IT/Ops | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Platform Finance | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## 11. Data Table

| TC-ID | REQ-ID | BR-ID | Type | Priority | Test Level | Automated |
|-------|:------:|:-----:|:----:|:--------:|:----------:|:---------:|
| TC-PRM-BO-001 | REQ-PRM-009 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-BO-002 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-BO-003 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-BO-004 | REQ-PRM-009 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-BO-005 | REQ-PRM-009 | BR-PRM-023 | Positive | P0 | Functional | ⬜ |
| TC-PRM-BO-006 | REQ-PRM-009 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-BO-007 | REQ-PRM-009 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-BO-008 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-BO-009 | REQ-PRM-009 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-BO-010 | REQ-PRM-009 | — | Negative/404 | P2 | Functional | ⬜ |
| TC-PRM-BO-011 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-BO-012 | REQ-PRM-009 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-BO-013 | REQ-PRM-009 | BR-PRM-023 | Positive | P0 | Functional | ⬜ |
| TC-PRM-BO-014 | REQ-PRM-009 | BR-PRM-023 | Positive/Edge | P1 | Functional | ⬜ |
| TC-PRM-BO-015 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-BO-016 | REQ-PRM-009 | BR-PRM-023 | Positive/Soft-Delete | P0 | Functional | ⬜ |
| TC-PRM-BO-017 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-BO-018 | REQ-PRM-009 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-PRM-BO-019 | REQ-PRM-009 | BR-PRM-023 | Positive/Restore | P0 | Functional | ⬜ |
| TC-PRM-BO-020 | REQ-PRM-009 | BR-PRM-023 | Positive/Force-Delete | P0 | Functional | ⬜ |
| TC-PRM-BO-021 | REQ-PRM-009 | — | Negative/404 | P2 | Functional | ⬜ |
| TC-PRM-BO-022 | REQ-PRM-009 | — | Negative/404 | P2 | Functional | ⬜ |
| TC-PRM-BO-023 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-BO-024 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-BO-025 | REQ-PRM-009 | BR-PRM-023 | Positive/Toggle | P0 | Functional | ⬜ |
| TC-PRM-BO-026 | REQ-PRM-009 | BR-PRM-023 | Positive/Toggle | P0 | Functional | ⬜ |
| TC-PRM-BO-027 | REQ-PRM-009 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-PRM-BO-028 | REQ-PRM-009 | — | Security/Auth | P0 | Security | ⬜ |
| TC-PRM-BO-029 | REQ-PRM-009 | — | Integration | P1 | Integration | ⬜ |
| TC-PRM-BO-030 | REQ-PRM-009 | NFR-PRM-004 | Security/MassAssignment | P0 | Security | ⬜ |

---

## 12. Known Issues

| # | Issue | Linked TC | Severity | Status |
|---|-------|:---------:|:--------:|:------:|
| 1 | `store()` and `update()` use `$request->all()` instead of `$request->validated()` — potential mass assignment risk | TC-PRM-BO-030 | High | ⬜ |
| 2 | No feature tests exist for BoardController | All TCs | High | ⬜ |

---

## 13. Route Reference

| Method | URI | Name |
|--------|-----|------|
| GET | `/prime/board` | `central.prime.board.index` |
| GET | `/prime/board/create` | `central.prime.board.create` |
| POST | `/prime/board` | `central.prime.board.store` |
| GET | `/prime/board/{board}` | `central.prime.board.show` |
| GET | `/prime/board/{board}/edit` | `central.prime.board.edit` |
| PUT | `/prime/board/{board}` | `central.prime.board.update` |
| DELETE | `/prime/board/{board}` | `central.prime.board.destroy` |
| GET | `/prime/board/trash/view` | `central.prime.board.trashed` |
| GET | `/prime/board/{id}/restore` | `central.prime.board.restore` |
| DELETE | `/prime/board/{id}/force-delete` | `central.prime.board.forceDelete` |
| POST | `/prime/board/{board}/toggle-status` | `central.prime.board.toggleStatus` |

---

## 14. Execution Status

| TC-ID | Status | Executed By | Execution Date | Build | Comments |
|-------|:-----:|:-----------:|:--------------:|:-----:|----------|
| TC-PRM-BO-001 | ⬜ | — | — | — | — |
| ... (all 30 TCs) | ⬜ | — | — | — | — |
