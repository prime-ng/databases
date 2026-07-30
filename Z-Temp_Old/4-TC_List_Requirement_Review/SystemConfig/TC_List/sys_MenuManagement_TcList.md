# Navigation Menu Management — Test Case List

**Feature:** Navigation Menu Management | **REQ-ID:** REQ-SYS-002 | **Controller:** `MenuController`

---

## 1. Test Case Summary

| Total TC | Pass | Fail | Blocked | Not Run | Coverage |
|:--------:|:----:|:----:|:-------:|:-------:|:--------:|
| 34 | — | — | — | 34 | 0% |

---

## 2. Index/List — Menu Tree (`GET /system-config/menu`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-MEN-001 | Verify menu tree loads with parent menus and recursive children | At least 2 parent menus with children | — | Tree renders parent menus ordered by `sort_order`; children nested under parents | — | — | ⬜ |
| TC-SYS-MEN-002 | Verify translated title loaded for language_id=2 | Menu with translation where language_id=2, key=title | — | Menu displays translated_title instead of default title | — | — | ⬜ |
| TC-SYS-MEN-003 | Verify fallback to default title when no translation exists | Menu without translation for language_id=2 | — | Menu displays default `title` | — | — | ⬜ |
| TC-SYS-MEN-004 | Verify empty tree renders "No menus found" message | No menus in `glb_menus` | — | Empty state message displayed | — | — | ⬜ |
| TC-SYS-MEN-005 | Verify user without `viewAny` permission receives 403 | Authenticated without permission | — | 403 Forbidden | — | — | ⬜ |
| TC-SYS-MEN-006 | Verify unauthenticated user redirected to login | No active session | — | Redirected to login | — | — | ⬜ |

---

## 3. Create Form (`GET /system-config/menu/create`) — STUB

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-MEN-007 | Verify create form loads for permitted user | Authenticated with `system-config.menu.create` | — | ⚠️ STUB — returns empty response; form not implemented | — | — | ⬜ |

---

## 4. Store — Create Menu (`POST /system-config/menu`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-MEN-008 | Verify valid menu creation with all required fields | — | `code=dashboard`, `title=Dashboard`, `icon=fa-home`, `route=home`, `sort_order=1`, `menu_for=tenant` | Menu created; redirected to index with success flash; audit log entry created | — | — | ⬜ |
| TC-SYS-MEN-009 | Verify category heading creation with null parent | — | `code=setup`, `title=Setup`, `is_category=true`, `parent_id=null`, `icon=fa-gear`, `sort_order=1`, `menu_for=tenant` | Category created with `parent_id=null` | — | — | ⬜ |
| TC-SYS-MEN-010 | Verify duplicate code rejected | Menu with code `dashboard` exists | `code=dashboard` | Validation error: code must be unique | — | — | ⬜ |
| TC-SYS-MEN-011 | Verify duplicate title rejected | Menu with title `Dashboard` exists | `title=Dashboard` | Validation error: title must be unique | — | — | ⬜ |
| TC-SYS-MEN-012 | Verify missing required `code` rejected | — | `code=` | Validation error: code is required | — | — | ⬜ |
| TC-SYS-MEN-013 | Verify missing required `icon` rejected | — | `icon=` | Validation error: icon is required | — | — | ⬜ |
| TC-SYS-MEN-014 | Verify non-category item requires route | `is_category=false`, `parent_id=1` | `route=` | Validation error: route is required for non-category items | — | — | ⬜ |
| TC-SYS-MEN-015 | Verify sort_order boundary values accepted | — | `sort_order=0` and `sort_order=255` | Both accepted | — | — | ⬜ |
| TC-SYS-MEN-016 | Verify sort_order out of range rejected | — | `sort_order=-1` or `sort_order=256` | Validation error | — | — | ⬜ |
| TC-SYS-MEN-017 | Verify user without `create` permission receives 403 | Authenticated without permission | — | 403 Forbidden | — | — | ⬜ |

---

## 5. Edit Form (`GET /system-config/menu/{menu}/edit`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-MEN-018 | Verify edit form loads with pre-populated data | Menu with ID=1 exists | — | Edit form displays with fields populated; parent menu tree shown | — | — | ⬜ |
| TC-SYS-MEN-019 | Verify non-existent menu returns 404 | No menu with ID=9999 | — | 404 Not Found | — | — | ⬜ |
| TC-SYS-MEN-020 | Verify user without `update` permission receives 403 | Authenticated without permission | — | 403 Forbidden | — | — | ⬜ |

---

## 6. Update — Update Menu (`PUT /system-config/menu/{menu}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-MEN-021 | Verify valid update saves changes and redirects | Menu with ID=1 | `title=New Title`, `sort_order=5` | Title and sort_order updated; redirect with success flash; audit log written | — | — | ⬜ |
| TC-SYS-MEN-022 | Verify code submitted in payload does NOT change | Menu with code `dashboard` | `code=new_code` | ⚠️ KNOWN BUG: code MAY change — currently in `$fillable`; expected: code unchanged | — | — | ⬜ |
| TC-SYS-MEN-023 | Verify audit log captures changed attributes with before/after | Menu update performed | — | `sys_activity_logs.properties` contains structured `{field: {old: x, new: y}}` | — | — | ⬜ |
| TC-SYS-MEN-024 | Verify update with no changes still logs | Update with same values | — | Audit log says "No attributes changed" | — | — | ⬜ |
| TC-SYS-MEN-025 | Verify user without `update` permission receives 403 | Authenticated without permission | — | 403 Forbidden | — | — | ⬜ |

---

## 7. Drag-Drop Reorder — `updateMenu` (`POST /system-config/menu/update-menu`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-MEN-026 | Verify moving a menu item to a new parent updates parent_id | Menu item with ID=2, parent=null | `menu_id=2`, `parent_id=1`, `sort_order=1` | Menu 2's parent_id becomes 1; siblings renumbered | — | — | ⬜ |
| TC-SYS-MEN-027 | Verify moving a category to a parent returns 422 | Menu with `is_category=true` | `menu_id=cat1`, `parent_id=2`, `sort_order=1` | 422 error: "Category headings cannot have a parent item." | — | — | ⬜ |
| TC-SYS-MEN-028 | Verify siblings renumbered sequentially after reorder | 3 siblings at same level | Move item to position 2 | Siblings have sort_order 1, 2, 3 (sequential) | — | — | ⬜ |
| TC-SYS-MEN-029 | Verify invalid menu_id returns validation error | — | `menu_id=9999` | Validation error: menu_id must exist in `glb_menus` | — | — | ⬜ |
| TC-SYS-MEN-030 | Verify audit log written for drag-drop | Valid reorder performed | — | `activityLog()` called with event `Draggable Menu` | — | — | ⬜ |
| TC-SYS-MEN-031 | Verify user without `update` permission receives 403 on AJAX reorder | Authenticated without permission | — | 403 returned as JSON | — | — | ⬜ |

---

## 8. Trash/Restore/ForceDelete

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-MEN-032 | Verify trashed menus list loads | At least 1 soft-deleted menu | — | Trash page shows soft-deleted menus | — | — | ⬜ |
| TC-SYS-MEN-033 | Verify force-delete permanently removes menu | Soft-deleted menu with ID=5 | — | Menu permanently removed; redirect with success flash; audit log written | — | — | ⬜ |
| TC-SYS-MEN-034 | Verify restore restores menu from trash | Soft-deleted menu with ID=5 | — | ⚠️ STUB — method empty; menu NOT restored | — | — | ⬜ |
| TC-SYS-MEN-035 | Verify force-delete on non-existent ID returns 404 | No menu with ID=9999 | — | 404 Not Found | — | — | ⬜ |

---

## 9. Status Toggle

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-MEN-036 | Verify toggle active/inactive status | Menu with ID=1, `is_active=true` | — | ⚠️ STUB — method empty; no toggle performed | — | — | ⬜ |

---

## 10. Edge Cases

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-MEN-037 | Verify menu tree depth — 5+ levels of nesting supported | Menus with 5 levels of parent-child | — | All levels rendered correctly | — | — | ⬜ |
| TC-SYS-MEN-038 | Verify `is_direct_link=true` menu item renders with external link indicator | Menu with `is_direct_link=true`, `route=https://example.com` | — | Menu renders as external link | — | — | ⬜ |
| TC-SYS-MEN-039 | Verify soft-deleted menu not shown in index | Menu that has been soft-deleted | — | Deleted menu not visible in index; visible in trash | — | — | ⬜ |
| TC-SYS-MEN-040 | Verify `menu_for=prime` filters correctly | Mixed `tenant` and `prime` menus | — | Only `tenant` menus shown on tenant side; `prime` on prime/admin side | — | — | ⬜ |

---

## 11. Permissions Matrix

| Role | View | Create | Edit | Delete | Restore | ForceDelete | Toggle | Reorder |
|------|:----:|:------:|:----:|:------:|:-------:|:-----------:|:------:|:-------:|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Platform Manager | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ |
| Platform Support | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| School Admin | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

---

## 12. Data Table

| TC-ID | REQ-ID | BR-ID | Type | Priority | Test Level | Automated |
|-------|:------:|:-----:|:----:|:--------:|:----------:|:---------:|
| TC-SYS-MEN-001 | REQ-SYS-002 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-SYS-MEN-002 | REQ-SYS-003 | — | Positive | P1 | Functional | ⬜ |
| TC-SYS-MEN-003 | REQ-SYS-003 | — | Positive/Fallback | P1 | Functional | ⬜ |
| TC-SYS-MEN-004 | REQ-SYS-002 | — | Negative/Empty | P2 | Functional | ⬜ |
| TC-SYS-MEN-005 | REQ-SYS-002 | BR-SYS-018 | Security/Auth | P0 | Security | ⬜ |
| TC-SYS-MEN-006 | REQ-SYS-002 | BR-SYS-018 | Security/Auth | P0 | Security | ⬜ |
| TC-SYS-MEN-007 | REQ-SYS-002 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-SYS-MEN-008 | REQ-SYS-002 | — | Positive | P0 | Functional | ⬜ |
| TC-SYS-MEN-009 | REQ-SYS-002 | BR-SYS-003 | Positive/Category | P1 | Functional | ⬜ |
| TC-SYS-MEN-010 | REQ-SYS-002 | — | Negative/Duplicate | P1 | Functional | ⬜ |
| TC-SYS-MEN-011 | REQ-SYS-002 | — | Negative/Duplicate | P1 | Functional | ⬜ |
| TC-SYS-MEN-012 | REQ-SYS-002 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-SYS-MEN-013 | REQ-SYS-002 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-SYS-MEN-014 | REQ-SYS-002 | — | Negative/Validation | P1 | Functional | ⬜ |
| TC-SYS-MEN-015 | REQ-SYS-002 | — | Boundary | P2 | Functional | ⬜ |
| TC-SYS-MEN-016 | REQ-SYS-002 | — | Boundary | P2 | Functional | ⬜ |
| TC-SYS-MEN-017 | REQ-SYS-002 | BR-SYS-018 | Security/Auth | P0 | Security | ⬜ |
| TC-SYS-MEN-018 | REQ-SYS-002 | — | Positive | P1 | Functional | ⬜ |
| TC-SYS-MEN-019 | REQ-SYS-002 | — | Negative/404 | P2 | Functional | ⬜ |
| TC-SYS-MEN-020 | REQ-SYS-002 | BR-SYS-018 | Security/Auth | P0 | Security | ⬜ |
| TC-SYS-MEN-021 | REQ-SYS-002 | BR-SYS-012 | Positive | P0 | Functional | ⬜ |
| TC-SYS-MEN-022 | REQ-SYS-002 | BR-SYS-002 | Security/Data | P0 | Security | ⬜ |
| TC-SYS-MEN-023 | REQ-SYS-002 | BR-SYS-012 | Audit | P0 | Audit | ⬜ |
| TC-SYS-MEN-024 | REQ-SYS-002 | BR-SYS-012 | Audit | P1 | Audit | ⬜ |
| TC-SYS-MEN-025 | REQ-SYS-002 | BR-SYS-018 | Security/Auth | P0 | Security | ⬜ |
| TC-SYS-MEN-026 | REQ-SYS-002 | BR-SYS-004 | Positive/Reorder | P1 | Functional | ⬜ |
| TC-SYS-MEN-027 | REQ-SYS-002 | BR-SYS-003 | Negative/Validation | P0 | Functional | ⬜ |
| TC-SYS-MEN-028 | REQ-SYS-002 | BR-SYS-004 | Calculation | P1 | Functional | ⬜ |
| TC-SYS-MEN-029 | REQ-SYS-002 | — | Negative/Validation | P2 | Functional | ⬜ |
| TC-SYS-MEN-030 | REQ-SYS-002 | BR-SYS-012 | Audit | P1 | Audit | ⬜ |
| TC-SYS-MEN-031 | REQ-SYS-002 | BR-SYS-018 | Security/Auth | P0 | Security | ⬜ |
| TC-SYS-MEN-032 | REQ-SYS-002 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-SYS-MEN-033 | REQ-SYS-002 | BR-SYS-012 | Positive | P1 | Functional | ⬜ |
| TC-SYS-MEN-034 | REQ-SYS-002 | — | Positive | P1 | Functional | ⬜ |
| TC-SYS-MEN-035 | REQ-SYS-002 | — | Negative/404 | P2 | Functional | ⬜ |
| TC-SYS-MEN-036 | REQ-SYS-002 | — | Positive | P1 | Functional | ⬜ |
| TC-SYS-MEN-037 | REQ-SYS-002 | — | Edge/Load | P2 | Functional | ⬜ |
| TC-SYS-MEN-038 | REQ-SYS-002 | — | Positive/UI | P2 | Functional | ⬜ |
| TC-SYS-MEN-039 | REQ-SYS-002 | — | Positive/SoftDelete | P1 | Functional | ⬜ |
| TC-SYS-MEN-040 | REQ-SYS-002 | — | Filtering | P1 | Functional | ⬜ |

---

## 13. Known Issues

| # | Issue | Linked TC | Severity | Status |
|---|-------|:---------:|:--------:|:------:|
| 1 | `create()` is empty stub — no create form | TC-SYS-MEN-007 | High | ⬜ |
| 2 | `destroy()` is empty stub — no soft-delete | — | High | ⬜ |
| 3 | `restore()` is empty stub — no restore | TC-SYS-MEN-034 | High | ⬜ |
| 4 | `toggleStatus()` is empty stub — no status toggle | TC-SYS-MEN-036 | High | ⬜ |
| 5 | Code NOT stripped in `update()` — violates BR-SYS-002 | TC-SYS-MEN-022 | High | ⬜ |
| 6 | Translation language hardcoded to ID=2 | TC-SYS-MEN-002 | Medium | ⬜ |
| 7 | Translation create logic commented out in `store()` | — | Medium | ⬜ |
| 8 | View notation `systemconfig.menu.trash` may be wrong | — | Medium | ⬜ |

---

## 14. Route Reference

| Method | URI | Name | Middleware |
|--------|-----|------|-----------|
| GET | `/system-config/menu` | `system-config.menu.index` | `web`, `auth`, `verified` |
| GET | `/system-config/menu/create` | `system-config.menu.create` | Same |
| POST | `/system-config/menu` | `system-config.menu.store` | Same |
| GET | `/system-config/menu/{menu}` | `system-config.menu.show` | Same |
| GET | `/system-config/menu/{menu}/edit` | `system-config.menu.edit` | Same |
| PUT | `/system-config/menu/{menu}` | `system-config.menu.update` | Same |
| DELETE | `/system-config/menu/{menu}` | `system-config.menu.destroy` | Same |
| GET | `/system-config/menu/trash` | `system-config.menu.trash` | Same |
| POST | `/system-config/menu/{id}/restore` | `system-config.menu.restore` | Same |
| DELETE | `/system-config/menu/{id}/force-delete` | `system-config.menu.forceDelete` | Same |
| POST | `/system-config/menu/{menu}/toggle-status` | `system-config.menu.toggle-status` | Same |
| POST | `/system-config/menu/update-menu` | `system-config.menu.update-menu` | Same |

---

## 15. Execution Status

| TC-ID | Status | Executed By | Execution Date | Build | Comments |
|-------|:-----:|:-----------:|:--------------:|:-----:|----------|
| TC-SYS-MEN-001 | ⬜ | — | — | — | — |
| TC-SYS-MEN-002 | ⬜ | — | — | — | — |
| TC-SYS-MEN-003 | ⬜ | — | — | — | — |
| TC-SYS-MEN-004 | ⬜ | — | — | — | — |
| TC-SYS-MEN-005 | ⬜ | — | — | — | — |
| TC-SYS-MEN-006 | ⬜ | — | — | — | — |
| ... | ⬜ | — | — | — | — |
| TC-SYS-MEN-040 | ⬜ | — | — | — | — |

*All 40 TC entries follow the same ⬜ pattern.*
