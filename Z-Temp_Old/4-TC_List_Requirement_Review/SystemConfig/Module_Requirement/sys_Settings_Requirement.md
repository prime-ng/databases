# SystemConfig — Platform Settings (App Level Settings)

**Feature:** Platform Settings Management | **REQ-ID:** REQ-SYS-001 | **Priority:** P0 (MUST)

---

## 1. Description

The Platform Settings feature enables Super Admin users to view and update application-level configuration values (key-value store) that control platform behaviour — SMTP credentials, SMS provider keys, password policy, OTP/MFA settings, and other operational configuration. Settings are stored in the `sys_settings` table within each tenant database.

---

## 2. Controller & Model

| Artifact | Path | Lines | Status |
|----------|------|:-----:|--------|
| Controller | `Modules/SystemConfig/app/Http/Controllers/SettingController.php` | 72 | PARTIAL |
| Model | `Modules/SystemConfig/app/Models/Setting.php` | 38 | PARTIAL |
| View (index) | `systemconfig::setting.index` | — | EXISTS |
| View (edit) | `systemconfig::setting.edit` | — | EXISTS |

---

## 3. Routes

| Method | URI | Action | Permission | Status |
|--------|-----|--------|------------|--------|
| GET | `/system-config/setting` | `index` | `system-config.setting.viewAny` | ✅ Gate check present |
| GET | `/system-config/setting/{id}/edit` | `edit` | `system-config.setting.update` | ✅ Gate check present |
| PUT | `/system-config/setting/{id}` | `update` | `system-config.setting.update` | ✅ Gate check present |

Route registration: `routes/tenant.php` — tenant-scoped, requires `InitializeTenancyByDomain` middleware.

---

## 4. Data Model

### 4.1 Setting (`sys_settings` — tenant database)

| Column | Type | Required | Default | Notes |
|--------|------|:--------:|:-------:|-------|
| `id` | BIGINT UNSIGNED AUTO_INCREMENT | ✅ | — | Primary key |
| `key` | VARCHAR(100) | ✅ | — | UNIQUE; auto `Str::snake()` via setter; permanent after creation |
| `value` | TEXT | ✅ | — | Updatable field |
| `type` | ENUM(string/int/boolean/json/date) | ✅ | — | Determines input control in edit form |
| `is_public` | TINYINT(1) | ✅ | 0 | If false, value masked as `••••••••` in list view |
| `description` | VARCHAR(255) | — | — | Searchable |
| `created_at` | TIMESTAMP | — | — | DDL gap: missing in some schemas |
| `updated_at` | TIMESTAMP | — | — | DDL gap: missing in some schemas |

### 4.2 Model Getters/Setters

| Method | Behaviour |
|--------|-----------|
| `setKeyAttribute($value)` | Auto-converts key to `Str::snake()` |
| `getDisplayKeyAttribute()` | Returns `ucwords(str_replace('_', ' ', $this->key))` |

---

## 5. Controller Implementation Details

### 5.1 `index(Request $request)`

- **Gate:** `Gate::authorize('system-config.setting.viewAny')`
- **Search:** Filters by `key`, `description`, `value` using `LIKE %search%`
- **Type Filter:** Filters by `type` column when `?type=` query param present
- **Pagination:** 20 records per page, query string preserved
- **View:** `systemconfig::setting.index` with `compact('settings')`

### 5.2 `edit(int $id)`

- **Gate:** `Gate::authorize('system-config.setting.update')`
- **Logic:** `Setting::findOrFail($id)`
- **View:** `systemconfig::setting.edit` with `compact('setting')`
- **Note:** Sensitive keys (containing `password`, `api_key`, `secret`, `token`) should render `type="password"` input in the view — but this is view-level, not enforced in controller.

### 5.3 `update(Request $request, int $id)`

- **Gate:** `Gate::authorize('system-config.setting.update')`
- **Validation:** Manual `$request->validate(['value' => ['required', 'string', 'max:1000']])`
- **Note:** Validates against non-existent table `settings` — this is a **known bug** (RISK-SYS-005). Should use a Form Request validating against `sys_settings`.
- **Logic:** Reads `$validated['value']`, updates only the `value` column
- **Key Protection:** The `key` field is **not explicitly stripped** from the update — relies on `$fillable` only containing `key`, `value`, `type`, `is_public`. However, `$request->validate()` only permits `value`, so key cannot leak via mass-assignment.
- **Audit:** `activityLog($setting, 'updated', ['key' => $setting->key])`
- **Redirect:** `route('system-config.setting.index')` with success flash

---

## 6. Business Rules

| BR-ID | Rule | Verification |
|-------|------|:-----------:|
| BR-SYS-001 | Setting key is permanent — edit endpoint must strip it even if submitted | 🔲 View enforces read-only key field; controller validates only `value` |
| BR-SYS-005 | Settings with `is_public=false` are masked (`••••••••`) in all list views | 🔲 View-level masking |
| BR-SYS-006 | Keys containing `password`, `api_key`, `secret`, `token` → value excluded from audit log; edit form uses password input type | 🔲 audit log uses hidden string; password input type is view-level |
| BR-SYS-012 | Every mutation must produce an audit log entry with entity type, entity ID, user, event, IP, before+after JSON | ✅ `activityLog()` helper called in `update()` |
| BR-SYS-013 | Authoritative Setting model is `Modules\SystemConfig\Models\Setting`; duplicate in Prime module must be deleted | ⚠️ Known risk |

---

## 7. Security Rules

| Rule | Implementation |
|------|---------------|
| Gate check on `viewAny` | ✅ `SettingController@index` |
| Gate check on `update` | ✅ `SettingController@edit` and `update` |
| Sensitive value masking | View-level `is_public=false` → bullets |
| Audit log sensitive exclusion | Keys with `password`/`api_key`/`secret`/`token`: audit log uses placeholder |
| No CSRF bypass | All routes on `web` middleware (CSRF protected) |
| No `$request->all()` | Controller uses `$request->validate()` + explicit `$validated['value']` |

---

## 8. Gaps & Known Issues

| # | Issue | Impact | Severity | Status |
|---|-------|--------|:--------:|:------:|
| 1 | `update()` validates against wrong table `settings` instead of `sys_settings` — validation will always pass on table existence check | Low (no table-exists rule in current validation) | Low | ⬜ |
| 2 | No Form Request — uses inline `$request->validate()` | Maintainability | Medium | ⬜ |
| 3 | `store()` endpoint missing — there is no Create/Store route; settings are assumed to be seeded | Feature gap | Medium | ⬜ |
| 4 | Duplicate Setting model in `Modules\Prime\Models\Setting` — code may reference wrong model | Import ambiguity | High | ⬜ |
| 5 | No `SoftDeletes` on `sys_settings` — violates project convention | DDL gap | Low | ⬜ |
| 6 | Audit log entry in `update()` passes `['key' => $setting->key]` but not full before/after `properties` JSON | Audit incompleteness | Medium | ⬜ |
| 7 | No feature tests for settings CRUD | Testing gap | High | ⬜ |

---

## 9. FRD References

| Reference | Source | Summary |
|-----------|--------|---------|
| REQ-SYS-001 | FRD §2 | Platform Settings Management |
| BR-SYS-001 | FRD §4 | Key is permanent |
| BR-SYS-005 | FRD §4 | `is_public=false` masking |
| BR-SYS-006 | FRD §4 | Sensitive key audit exclusion |
| BR-SYS-012 | FRD §4 | Audit log requirement |
| BR-SYS-013 | FRD §4 | Canonical Setting model |
| WF-1 | FRD §6 | Setting Update workflow |
| US-SYS-001 | FRD §8 | User story for setting update |

---

## 10. Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| V1 | — | — | — |
| V2 | — | — | — |
