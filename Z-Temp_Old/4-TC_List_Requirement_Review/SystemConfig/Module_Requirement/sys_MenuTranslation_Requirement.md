# SystemConfig — Menu Translation Management

**Feature:** Menu Translation Management | **REQ-ID:** REQ-SYS-003 | **Priority:** P1 (SHOULD)

---

## 1. Description

The Menu Translation Management feature enables Platform Managers to add translated titles for navigation menu items in different languages. Translations are key-value pairs linked to menu items via a polymorphic relationship on the `glb_translations` table. The translated title is used when rendering the sidebar for school applications configured in a language other than the default.

---

## 2. Controller & Model

| Artifact | Path | Lines | Status |
|----------|------|:-----:|--------|
| Controller | `Modules/SystemConfig/app/Http/Controllers/MenuController.php` | 272 | PARTIAL |
| Model | `Modules/SystemConfig/app/Models/Translation.php` | 25 | ✅ |
| Relationship | `Menu::translations()` — `morphMany` on `Menu` model | — | ✅ |

**Note:** There is no dedicated Translation controller. Translation logic is embedded in `MenuController::store()` (commented out) and `MenuController::index()`/`edit()` (read-only).

---

## 3. Routes

| Method | URI | Action | Translation Support | Status |
|--------|-----|--------|:-------------------:|:------:|
| POST | `/system-config/menu` | `store` | ❌ Commented out | ⚠️ |
| PUT | `/system-config/menu/{menu}` | `update` | ❌ Not implemented | ⚠️ |
| GET | `/system-config/menu` | `index` | ✅ Read-only (hardcoded lang=2) | ✅ Partial |
| GET | `/system-config/menu/{menu}/edit` | `edit` | ✅ Read-only (hardcoded lang=2) | ✅ Partial |

---

## 4. Data Model

### 4.1 Translation (`glb_translations` — `global_master_mysql` connection)

| Column | Type | Required | Default | Notes |
|--------|------|:--------:|:-------:|-------|
| `id` | BIGINT UNSIGNED AUTO_INCREMENT | ✅ | — | Primary key |
| `translatable_type` | VARCHAR | ✅ | — | Morph type (e.g. `Modules\SystemConfig\Models\Menu`) |
| `translatable_id` | BIGINT UNSIGNED | ✅ | — | Morph ID (menu item ID) |
| `language_id` | BIGINT UNSIGNED | ✅ | — | FK → `glb_languages.id` |
| `key` | VARCHAR(255) | ✅ | — | Translation key (e.g. `title`, `description`) |
| `value` | TEXT | ✅ | — | Translated text |
| `created_at` | TIMESTAMP | — | — | — |
| `updated_at` | TIMESTAMP | — | — | — |

### 4.2 Unique Constraint

Per BR-SYS-017: One translation record per (translatable_id, translatable_type, language_id, key) combination. Implemented via `updateOrCreate` pattern.

---

## 5. Current Implementation

### 5.1 Read Path (Working)

```php
// MenuController::index() and edit()
$languageId = 2; // HARDCODED
$menus = Menu::whereNull('parent_id')
    ->orderBy('sort_order')
    ->with([
        'children',
        'translations' => function ($query) use ($languageId) {
            $query->where('language_id', $languageId)->where('key', 'title');
        }
    ])
    ->get();

$menus = $this->setTranslatedTitleRecursive($menus, $languageId);
```

The `setTranslatedTitleRecursive()` helper traverses the recursive tree and sets `$menu->translated_title` to the translation value if found, falling back to `$menu->title`.

### 5.2 Write Path (Commented Out)

```php
// MenuController::store() — LINES 74-80 (COMMENTED OUT)
// $translationData = [
//     'language_id' => $data['language_id'],
//     'key' => $data['translateable_key'],
//     'value' => $data['translateable_value'],
// ];
// $menu->translations()->create($translationData);
```

### 5.3 Validation (Request Level)

`MenuRequest` accepts but does not require translation fields:

```php
'language_id' => ['nullable'],
'translateable_key' => ['nullable'],
'translateable_value' => ['nullable']
```

---

## 6. Business Rules

| BR-ID | Rule | Implementation | Status |
|-------|------|---------------|:------:|
| BR-SYS-017 | Translation uses upsert (updateOrCreate) per menu item + language; no duplicates | Commented out in `store()` — not active | ❌ |
| BR-SYS-012 | Every mutation must produce audit log entry | Not applicable for translation (commented out) | ❌ |

---

## 7. Gaps & Known Issues

| # | Issue | Impact | Severity | Status |
|---|-------|--------|:--------:|:------:|
| 1 | Translation create logic **completely commented out** in `store()` — no way to create translations via UI | Feature non-functional | High | ⬜ |
| 2 | `update()` has no translation logic — translations cannot be updated when editing a menu | Feature gap | High | ⬜ |
| 3 | Language ID **hardcoded to 2** in `index()` and `edit()` | Breaks multi-language support | Medium | ⬜ |
| 4 | No standalone translation management UI | Users must manipulate DB directly | Medium | ⬜ |
| 5 | `MenuRequest` passes `language_id`, `translateable_key`, `translateable_value` as nullable — no validation | Data integrity risk | Medium | ⬜ |
| 6 | No feature tests for translations | Testing gap | High | ⬜ |

---

## 8. FRD References

| Reference | Source | Summary |
|-----------|--------|---------|
| REQ-SYS-003 | FRD §2 | Menu Translation Management |
| BR-SYS-017 | FRD §4 | Translation upsert — no duplicates |
| BR-SYS-012 | FRD §4 | Audit log requirement |
| US-SYS-003 | FRD §8 | User story for menu translation |

---

## 9. Suggested Fix Plan

| Step | Task | Effort |
|------|------|:------:|
| 1 | Replace hardcoded `$languageId = 2` with dynamic resolution from `sys_settings` or `glb_languages` | 1 h |
| 2 | Uncomment translation create logic in `store()`; validate fields when present | 1 h |
| 3 | Add translation upsert in `update()` method | 1 h |
| 4 | Add translation section to menu edit form with language selector from `glb_languages` | 2 h |
| 5 | Write feature tests for translation CRUD (create, read during index, update via upsert) | 2 h |
| | **Total** | **7 h** |

---

## 10. Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| V1 | — | — | — |
| V2 | — | — | — |
