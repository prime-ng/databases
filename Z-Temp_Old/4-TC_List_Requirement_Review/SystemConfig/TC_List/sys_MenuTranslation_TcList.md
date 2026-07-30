# Menu Translation Management — Test Case List

**Feature:** Menu Translation Management | **REQ-ID:** REQ-SYS-003 | **Controller:** `MenuController` (embedded)

---

## 1. Test Case Summary

| Total TC | Pass | Fail | Blocked | Not Run | Coverage |
|:--------:|:----:|:----:|:-------:|:-------:|:--------:|
| 14 | — | — | — | 14 | 0% |

---

## 2. Index/List — Translated Title Display (`GET /system-config/menu`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-MTR-001 | Verify menu displays translated title when translation exists for language_id=2 | Menu with translation: language_id=2, key=title, value="परीक्षा" | — | Menu shows `translated_title` = "परीक्षा" | — | — | ⬜ |
| TC-SYS-MTR-002 | Verify menu falls back to default title when no translation for language_id=2 | Menu without translation record | — | Menu shows default `title` | — | — | ⬜ |
| TC-SYS-MTR-003 | Verify translated title propagates to child menus (recursive) | Parent and child menus with translations for language_id=2 | — | Both parent and child show translated titles | — | — | ⬜ |
| TC-SYS-MTR-004 | Verify translation key=title only — other keys ignored | Menu with translation key=description | — | Shows default title (translation with key=description not used for title) | — | — | ⬜ |

---

## 3. Store — Create Translation on Menu Creation (`POST /system-config/menu`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-MTR-005 | Verify translation created when menu created with language_id and translateable_value | — | `code=test`, `title=Test`, `language_id=3`, `translateable_key=title`, `translateable_value=परीक्षा` | ⚠️ STUB — Translation create logic COMMENTED OUT. Expected: Translation record created in `glb_translations` | — | — | ⬜ |
| TC-SYS-MTR-006 | Verify translation NOT created when language fields absent | — | `code=test`, `title=Test` (no language fields) | Menu created; no translation record | — | — | ⬜ |

---

## 4. Edit — Translation Display (`GET /system-config/menu/{menu}/edit`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-MTR-007 | Verify edit form shows existing translation for language_id=2 | Menu with translation for language_id=2 | — | Translation value displayed in edit form | — | — | ⬜ |
| TC-SYS-MTR-008 | Verify all available languages listed in language selector | Multiple languages in `glb_languages` | — | ⚠️ Language selector not implemented; language_id hardcoded to 2 | — | — | ⬜ |

---

## 5. Update — Translation Update on Menu Update (`PUT /system-config/menu/{menu}`)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-MTR-009 | Verify translation updated when menu updated with language fields | Menu with existing translation for language_id=3 | `translateable_value=नई परीक्षा` | ⚠️ Translation update NOT implemented in `update()`. Expected: Translation record updated via upsert | — | — | ⬜ |

---

## 6. Upsert Behaviour (BR-SYS-017)

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-MTR-010 | Verify duplicate (menu_id + language_id + key) creates no duplicate — last write wins | Existing translation (menu_id=5, language_id=3, key=title, value="परीक्षा") | Create same combination with value="नई परीक्षा" | Single record updated; no duplicate | — | — | ⬜ |
| TC-SYS-MTR-011 | Verify different language_id on same menu creates separate translation | Translation for language_id=3 exists | Add translation for language_id=4 same menu | Two records: one per language | — | — | ⬜ |

---

## 7. Language Fallback

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-MTR-012 | Verify fallback to default title when language_id has no translation | Menu with no translation for language_id=4 | — | Default `title` displayed as `translated_title` | — | — | ⬜ |
| TC-SYS-MTR-013 | Verify all translated menus properly resolve for different language_ids | Multiple menus with translations in different languages | — | Each language shows its own translated titles | — | — | ⬜ |

---

## 8. Security & Auth

| TC-ID | Test Case | Prerequisites | Test Data | Expected Result | V1 | V2 | Status |
|-------|-----------|---------------|-----------|-----------------|:--:|:--:|:------:|
| TC-SYS-MTR-014 | Verify menu index translation display respects viewAny permission | Authenticated without `system-config.menu.viewAny` | — | 403 Forbidden; translations not exposed | — | — | ⬜ |

---

## 9. Data Table

| TC-ID | REQ-ID | BR-ID | Type | Priority | Test Level | Automated |
|-------|:------:|:-----:|:----:|:--------:|:----------:|:---------:|
| TC-SYS-MTR-001 | REQ-SYS-003 | — | Positive/Display | P1 | Functional | ⬜ |
| TC-SYS-MTR-002 | REQ-SYS-003 | — | Positive/Fallback | P1 | Functional | ⬜ |
| TC-SYS-MTR-003 | REQ-SYS-003 | — | Positive/Recursive | P2 | Functional | ⬜ |
| TC-SYS-MTR-004 | REQ-SYS-003 | — | Filtering | P2 | Functional | ⬜ |
| TC-SYS-MTR-005 | REQ-SYS-003 | BR-SYS-017 | Positive/Create | P1 | Functional | ⬜ |
| TC-SYS-MTR-006 | REQ-SYS-003 | — | Negative/Null | P2 | Functional | ⬜ |
| TC-SYS-MTR-007 | REQ-SYS-003 | — | Positive/Display | P1 | Functional | ⬜ |
| TC-SYS-MTR-008 | REQ-SYS-003 | — | Positive/UI | P1 | Functional | ⬜ |
| TC-SYS-MTR-009 | REQ-SYS-003 | BR-SYS-017 | Positive/Update | P1 | Functional | ⬜ |
| TC-SYS-MTR-010 | REQ-SYS-003 | BR-SYS-017 | Validation/Upsert | P1 | Functional | ⬜ |
| TC-SYS-MTR-011 | REQ-SYS-003 | BR-SYS-017 | Positive/Multi-language | P2 | Functional | ⬜ |
| TC-SYS-MTR-012 | REQ-SYS-003 | — | Positive/Fallback | P1 | Functional | ⬜ |
| TC-SYS-MTR-013 | REQ-SYS-003 | — | Positive/Multi-language | P2 | Functional | ⬜ |
| TC-SYS-MTR-014 | REQ-SYS-003 | BR-SYS-018 | Security/Auth | P0 | Security | ⬜ |

---

## 10. Known Issues

| # | Issue | Linked TC | Severity | Status |
|---|-------|:---------:|:--------:|:------:|
| 1 | Translation create logic commented out in `store()` — TC-SYS-MTR-005 blocked | TC-SYS-MTR-005 | High | ⬜ |
| 2 | Language ID hardcoded to 2 — no dynamic resolution | TC-SYS-MTR-001, TC-SYS-MTR-003, TC-SYS-MTR-008 | Medium | ⬜ |
| 3 | No translation update in `update()` method — TC-SYS-MTR-009 blocked | TC-SYS-MTR-009 | High | ⬜ |
| 4 | No standalone translation management UI | All translation TCs | Medium | ⬜ |
| 5 | No validation on translation fields in `MenuRequest` | TC-SYS-MTR-005, TC-SYS-MTR-006 | Medium | ⬜ |

---

## 11. Route Reference

| Method | URI | Name | Notes |
|--------|-----|------|-------|
| POST | `/system-config/menu` | `system-config.menu.store` | Translation logic commented out |
| PUT | `/system-config/menu/{menu}` | `system-config.menu.update` | No translation logic |
| GET | `/system-config/menu` | `system-config.menu.index` | Reads translations (hardcoded lang=2) |
| GET | `/system-config/menu/{menu}/edit` | `system-config.menu.edit` | Reads translations (hardcoded lang=2) |

---

## 12. Execution Status

| TC-ID | Status | Executed By | Execution Date | Build | Comments |
|-------|:-----:|:-----------:|:--------------:|:-----:|----------|
| TC-SYS-MTR-001 | ⬜ | — | — | — | — |
| TC-SYS-MTR-002 | ⬜ | — | — | — | — |
| TC-SYS-MTR-003 | ⬜ | — | — | — | — |
| TC-SYS-MTR-004 | ⬜ | — | — | — | — |
| TC-SYS-MTR-005 | ⬜ | — | — | — | Translation logic commented out — blocked |
| TC-SYS-MTR-006 | ⬜ | — | — | — | — |
| TC-SYS-MTR-007 | ⬜ | — | — | — | — |
| TC-SYS-MTR-008 | ⬜ | — | — | — | Language selector not implemented |
| TC-SYS-MTR-009 | ⬜ | — | — | — | Translation update not implemented — blocked |
| TC-SYS-MTR-010 | ⬜ | — | — | — | Depends on uncommented upsert logic |
| TC-SYS-MTR-011 | ⬜ | — | — | — | Depends on multi-language support |
| TC-SYS-MTR-012 | ⬜ | — | — | — | — |
| TC-SYS-MTR-013 | ⬜ | — | — | — | Depends on multi-language support |
| TC-SYS-MTR-014 | ⬜ | — | — | — | — |
