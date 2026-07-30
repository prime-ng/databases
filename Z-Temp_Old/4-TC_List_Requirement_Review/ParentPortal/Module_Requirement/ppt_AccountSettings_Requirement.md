# ParentPortal — Account Settings (Requirement Analysis)

## 1. Module Overview

| Attribute | Details |
|-----------|---------|
| **Feature Name** | Account Settings |
| **Alias** | ppt_account |
| **Module** | ParentPortal (PPT) |
| **Route Prefix** | `/parent-portal/account` |
| **Primary Controller** | `ParentAccountController` |
| **Primary Models** | `ParentSession`, `UserPreference`, `Guardian`, `ChannelMaster` |
| **Base Table(s)** | `ppt_parent_sessions`, `sys_users`, `std_guardians`, `ntf_user_preferences` |
| **FRD Reference** | REQ-PPT-018 |
| **Priority** | P1 (Should Have) |
| **Type** | Write (Profile, Password, Notifications, Devices, Language) |

## 2. Purpose

Provide parents with a centralized account management hub where they can update their profile information, change password, configure notification preferences and quiet hours, manage active device sessions, and set their portal language preference.

## 3. Business Rules

| ID | Rule | Enforced In |
|----|------|-------------|
| BR-PPT-009 | On explicit logout, device token set inactive | `ParentAccountController::logoutDevice()` — `is_active = false` |
| BR-PPT-010 | Active child stored in DB ppt_parent_sessions (multi-device sync) | ParentContextService manages this |
| BR-PPT-008 | Non-urgent notifications buffered during quiet hours; AbsenceAlert bypasses | `UpdateQuietHoursParentAccountRequest` — quiet hours persistence |
| — | Password change requires current password verification | `UpdatePasswordParentAccountRequest` + `Hash::check()` |
| — | Email uniqueness enforced across sys_users | `UpdateProfileParentAccountRequest` — `Rule::unique('sys_users', 'email')->ignore($user->id)` |

## 4. Screen Inventory

| Screen | Route Name | Controller Method | View | Description |
|--------|-----------|-------------------|------|-------------|
| Account Settings | `parent-portal.account.index` | `index()` | `account/index` | Multi-tab page: Profile, Password, Notifications, Devices, Language |

### Tabs

| Tab | PUT Route | Controller Method | Content |
|-----|-----------|-------------------|---------|
| Profile | `parent-portal.account.profile.update` | `updateProfile()` | Name, email, mobile, photo, guardian details |
| Password | `parent-portal.account.password.update` | `updatePassword()` | Current password, new password, confirm |
| Notifications | `parent-portal.account.notifications.update` | `updateNotificationPreferences()` | Per-channel toggles + quiet hours |
| Devices | `parent-portal.account.devices.logout` | `logoutDevice()` | Active sessions list + logout action |
| Language | `parent-portal.account.language.update` | `updateLanguage()` | Language selector |

## 5. Validation Rules

### UpdateProfileParentAccountRequest

| Field | Rule | Note |
|-------|------|------|
| `name` | `required`, `string`, `max:100` | Display name |
| `email` | `required`, `email`, `max:150`, `unique:sys_users,email,{user_id}` | Unique email |
| `mobile_no` | `nullable`, `string`, `max:20` | Primary mobile |
| `phone_no` | `nullable`, `string`, `max:20` | Alternate phone |
| `first_name` | `nullable`, `string`, `max:60` | Guardian first name |
| `last_name` | `nullable`, `string`, `max:60` | Guardian last name |
| `occupation` | `nullable`, `string`, `max:100` | Guardian occupation |

### UpdatePasswordParentAccountRequest

| Field | Rule |
|-------|------|
| `current_password` | `required`, `string` |
| `password` | `required`, `confirmed`, `Password::min(8)->mixedCase()->numbers()` |

### UpdateNotificationPreferencesParentAccountRequest

| Field | Rule |
|-------|------|
| `notifications` | `nullable`, `array` |
| `notifications.*` | `boolean` |

### UpdateQuietHoursParentAccountRequest

| Field | Rule |
|-------|------|
| `quiet_hours_start` | `nullable`, `date_format:H:i` |
| `quiet_hours_end` | `nullable`, `date_format:H:i` |

### UpdateLanguageParentAccountRequest

| Field | Rule |
|-------|------|
| `language` | `required`, `string`, `in:en,hi,ta,te,bn,mr,gu` |

### LogoutDeviceParentAccountRequest

No specific validation rules defined (empty rules() method).

## 6. Technical Implementation

### 6.1 Dependencies

| Dependency | Type | Purpose |
|-----------|------|---------|
| `Modules\StudentProfile\Models\Guardian` | Model | Guardian profile data (name, mobile, occupation) |
| `Modules\ParentPortal\Models\ParentSession` | Model | Device sessions |
| `Modules\Notification\Models\ChannelMaster` | Model | Available notification channels |
| `Modules\Notification\Models\UserPreference` | Model | Per-user notification channel preferences |
| `ParentContextService` | Service | Resolves active child |

### 6.2 Key Implementation Details

- **Multi-Tab Design:** All tabs are rendered in a single view (`account/index`). The `index()` method loads all required data and passes it to the view.
- **Profile Update:** Updates both `sys_users` (name, email, mobile) and `std_guardians` (first_name, last_name, occupation, mobile, email). Falls back to existing values if not provided.
- **Password Change:** Verifies `current_password` against stored hash. If incorrect, returns error with `active_tab = 'password'`. New password must be min 8 chars + mixed case + numbers.
- **Notification Preferences:** Uses `ChannelMaster` to get all available channels. Accepts a `notifications[channel_id] = 1|0` array. Uses `upsert()` to insert/update all channel preferences in one query.
- **Quiet Hours:** Accepts start/end in `H:i` format. Appends `:00` seconds before storing. Updates all `UserPreference` rows for the user via mass update.
- **Device Logout:** Sets `is_active = false` on the ParentSession record. Ownership verified via `abort_unless($guardian && $device->guardian_id === $guardian->id, 403)`.
- **Language:** Supports 7 languages (English, Hindi, Tamil, Telugu, Bengali, Marathi, Gujarati). Stores in session as `ppt_language` and attempts persistence to `sys_users.language` column.

### 6.3 Available Languages

| Code | Language |
|------|----------|
| `en` | English |
| `hi` | हिन्दी (Hindi) |
| `ta` | தமிழ் (Tamil) |
| `te` | తెలుగు (Telugu) |
| `bn` | বাংলা (Bengali) |
| `mr` | मराठी (Marathi) |
| `gu` | ગુજરાતી (Gujarati) |

### 6.4 Data Flow

```
index() → loads:
  ├── User (auth user)
  ├── Child (active child via context)
  ├── Guardian (guardian record linked to user)
  ├── Channels + Preferences (notification channels + user toggles)
  ├── Devices (ParentSession records for guardian)
  └── Languages (static list)

updateProfile() → sys_users UPDATE + std_guardians UPDATE
updatePassword() → Hash::check → sys_users.password UPDATE
updateNotificationPreferences() → UserPreference UPSERT
updateQuietHours() → UserPreference mass UPDATE
logoutDevice() → ParentSession.is_active = false
updateLanguage() → Session::put('ppt_language') + sys_users.language UPDATE
```

## 7. Edge Cases

| Scenario | Expected Behavior |
|----------|------------------|
| Profile update with same email | Allowed (unique check ignores own user_id) |
| Wrong current password | Error: "The current password is incorrect." with active_tab = 'password' |
| Notification preferences with no channels | Empty array → all channels upserted as disabled |
| Quiet hours with empty start/end | Both set to null (no quiet hours) |
| Logout another parent's device | 403 Forbidden |
| Language persistence fails (no column) | Session value set; silent fail on DB update |
| Update profile with null mobile_no | Previous value preserved |
| All notification channels toggled off | All upserted with is_enabled = 0 |
| Devices list empty | Empty collection passed to view |

## 8. Known Issues / Gaps

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | FRD mentions "photo" update but no avatar/photo upload in controller | Low | ⬜ |
| 2 | Quiet hours stored in UserPreference model, not in ppt_parent_sessions as DDL specifies | Medium | ⬜ |
| 3 | LogoutDeviceParentAccountRequest has empty rules() method — no validation | Low | ⬜ |
| 4 | Language column on sys_users may not exist — try/catch silences error | Low | ⬜ |
| 5 | No password strength meter or validation on client side | Low | ⬜ |
| 6 | Device list shows all sessions for guardian — no way to identify current device | Low | ⬜ |

## 9. Cross-Module Impact

| Module | Impact |
|--------|--------|
| StudentProfile | Guardian model for profile data |
| Notification | ChannelMaster + UserPreference for notification settings |
| SystemConfig | sys_users for auth, profile, and password |

## 10. Route Reference

```php
Route::prefix('account')->name('account.')->group(function () {
    Route::get('/', [ParentAccountController::class, 'index'])->name('index');
    Route::put('/profile', [ParentAccountController::class, 'updateProfile'])->name('profile.update');
    Route::put('/password', [ParentAccountController::class, 'updatePassword'])->name('password.update');
    Route::put('/notifications', [ParentAccountController::class, 'updateNotificationPreferences'])->name('notifications.update');
    Route::put('/quiet-hours', [ParentAccountController::class, 'updateQuietHours'])->name('quiet-hours.update');
    Route::post('/devices/{device}/logout', [ParentAccountController::class, 'logoutDevice'])->name('devices.logout');
    Route::put('/language', [ParentAccountController::class, 'updateLanguage'])->name('language.update');
});
```

## 11. Middleware Stack

```
web → InitializeTenancyByDomain → PreventAccessFromCentralDomains
→ EnsureTenantIsActive → auth → verified → ParentPortalMiddleware
```

## 12. Controller Constructor Dependencies

```php
public function __construct(
    private readonly ParentContextService $context,
) {}
```

## 13. Audit Logging

- Event types: `Viewed` (index), `Updated` (profile), `PasswordChanged` (password), `PreferencesUpdated` (notifications), `QuietHoursUpdated` (quiet hours), `DeviceLoggedOut` (device), `LanguageUpdated` (language)
- Context: student_id (null for account actions), module, route
- Entity reference: device_session_id, language, count, etc.

## 14. Security Considerations

| Concern | Mitigation |
|---------|-----------|
| Unauthorized profile update | Auth middleware + FormRequest authorization |
| Password change without old password | Hash::check validates current_password |
| IDOR on device logout | `abort_unless($guardian && $device->guardian_id === $guardian->id, 403)` |
| Email uniqueness bypass | Rule::unique with ignore for own user |
| CSRF | Laravel CSRF middleware on all POST/PUT routes |

## 15. FRD Gaps

| FRD Statement | Implementation Reality | Gap |
|---------------|----------------------|-----|
| "Photo" shown on profile | Not implemented | Missing avatar upload |
| "Notification preferences updated per REQ-PPT-003" | Implemented via ChannelMaster/UserPreference | Partially met |
| "Device session list shows all active portal sessions" | Implemented via ParentSession | Complete |
| "Parent can logout a specific device" | Implemented via logoutDevice() | Complete |
| "Language preference saved and applied" | Session + DB persistence | Complete |
