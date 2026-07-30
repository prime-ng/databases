# ParentPortal — Account Settings (TC List)

## 1. Feature Overview

| Attribute | Details |
|-----------|---------|
| Feature | Account Settings |
| Module | ParentPortal (PPT) |
| Priority | P1 |
| Type | Write (Profile, Password, Notifications, Devices, Language) |
| Test Strategy | Functional + Validation + Security + Multi-tab |

## 2. Test Environment

| Parameter | Value |
|-----------|-------|
| Base URL | `{tenant_url}/parent-portal/account` |
| Auth Required | Yes (Parent role) |
| Database | Tenant database with ppt_parent_sessions, sys_users, std_guardians, ntf_user_preferences |

## 3. Test Case Matrix

### 3.1 UI / Screen Navigation

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-ACC-001 | Verify Account Settings page loads with all tabs | 1. Login as Parent<br>2. Navigate to Account | Page renders with Profile, Password, Notifications, Devices, Language tabs | ⬜ | ◌ |
| TC-PPT-ACC-002 | Verify Profile tab shows user info | 1. Navigate to Account<br>2. Ensure Profile tab active | Name, email, mobile, guardian details shown | ⬜ | ◌ |
| TC-PPT-ACC-003 | Verify Password tab has current + new password fields | 1. Click Password tab | Current password, new password, confirm password fields visible | ⬜ | ◌ |
| TC-PPT-ACC-004 | Verify Notifications tab shows channel toggles | 1. Click Notifications tab | Per-channel toggle switches displayed | ⬜ | ◌ |
| TC-PPT-ACC-005 | Verify Devices tab lists active sessions | 1. Click Devices tab | Active device sessions listed with details (device type, last active) | ⬜ | ◌ |
| TC-PPT-ACC-006 | Verify Language tab shows language selector | 1. Click Language tab | 7 language options displayed | ⬜ | ◌ |

### 3.2 Profile Update

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-ACC-007 | Update profile with valid data | 1. Fill valid name, email, mobile<br>2. Submit | Profile updated; redirected with success message; tab=profile | ⬜ | ◌ |
| TC-PPT-ACC-008 | Update profile with empty name | 1. Leave name blank<br>2. Submit | Validation error for name | ⬜ | ◌ |
| TC-PPT-ACC-009 | Update profile with name exceeding 100 chars | 1. Enter 101-char name<br>2. Submit | Validation error: name too long | ⬜ | ◌ |
| TC-PPT-ACC-010 | Update profile with invalid email | 1. Enter invalid email format<br>2. Submit | Validation error for email | ⬜ | ◌ |
| TC-PPT-ACC-011 | Update profile with existing email (different user) | 1. Enter another user's email<br>2. Submit | Validation error: email already taken | ⬜ | ◌ |
| TC-PPT-ACC-012 | Update profile with own email unchanged | 1. Submit with current email<br>2. Check | Profile updated (unique ignores own ID) | ⬜ | ◌ |
| TC-PPT-ACC-013 | Update profile with mobile_no null | 1. Clear mobile field<br>2. Submit | Previous value preserved; profile updated | ⬜ | ◌ |
| TC-PPT-ACC-014 | Update profile — verify sys_users and std_guardians both updated | 1. Update name and first_name<br>2. Check DB | Both users table and guardians table updated | ⬜ | ◌ |
| TC-PPT-ACC-015 | Update profile with all valid optional fields | 1. Fill phone_no, first_name, last_name, occupation<br>2. Submit | All fields updated successfully | ⬜ | ◌ |

### 3.3 Password Change

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-ACC-016 | Change password with valid current + new password | 1. Enter correct current password<br>2. Enter valid new password + confirm<br>3. Submit | Password changed; redirected with success; tab=password | ⬜ | ◌ |
| TC-PPT-ACC-017 | Change password with wrong current password | 1. Enter incorrect current password<br>2. Submit | Error: "The current password is incorrect."; active_tab = password | ⬜ | ◌ |
| TC-PPT-ACC-018 | Change password with empty current password | 1. Leave current_password blank<br>2. Submit | Validation error for current_password | ⬜ | ◌ |
| TC-PPT-ACC-019 | Change password with new password < 8 chars | 1. Enter 7-char password<br>2. Submit | Validation error: password must be at least 8 characters | ⬜ | ◌ |
| TC-PPT-ACC-020 | Change password without mixed case | 1. Enter all-lowercase 8-char password<br>2. Submit | Validation error: must contain mixed case | ⬜ | ◌ |
| TC-PPT-ACC-021 | Change password without numbers | 1. Enter mixed-case 8-char password with no numbers<br>2. Submit | Validation error: must contain numbers | ⬜ | ◌ |
| TC-PPT-ACC-022 | Change password with mismatched confirmation | 1. Enter different confirm password<br>2. Submit | Validation error: password confirmation mismatch | ⬜ | ◌ |
| TC-PPT-ACC-023 | Verify password actually changed on next login | 1. Change password<br>2. Logout<br>3. Login with new password | Login successful | ⬜ | ◌ |
| TC-PPT-ACC-024 | Verify old password no longer works after change | 1. Change password<br>2. Try login with old password | Login fails | ⬜ | ◌ |

### 3.4 Notification Preferences

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-ACC-025 | Enable a notification channel | 1. Toggle channel ON<br>2. Submit | Channel enabled in UserPreference | ⬜ | ◌ |
| TC-PPT-ACC-026 | Disable a notification channel | 1. Toggle channel OFF<br>2. Submit | Channel disabled in UserPreference | ⬜ | ◌ |
| TC-PPT-ACC-027 | Submit empty notifications array | 1. Submit with no channel toggles<br>2. Check DB | All channels upserted as disabled | ⬜ | ◌ |
| TC-PPT-ACC-028 | Toggle multiple channels simultaneously | 1. Toggle channel A ON, channel B OFF<br>2. Submit | A enabled, B disabled | ⬜ | ◌ |
| TC-PPT-ACC-029 | Verify notification preferences persist after page reload | 1. Save preferences<br>2. Refresh page | Preferences still showing correct toggles | ⬜ | ◌ |

### 3.5 Quiet Hours

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-ACC-030 | Set valid quiet hours | 1. Enter start=22:00, end=07:00<br>2. Submit | Quiet hours saved; success message; tab=notifications | ⬜ | ◌ |
| TC-PPT-ACC-031 | Set quiet hours with empty start | 1. Leave start blank<br>2. Submit | Stored as null (no quiet hours start) | ⬜ | ◌ |
| TC-PPT-ACC-032 | Set quiet hours with empty end | 1. Leave end blank<br>2. Submit | Stored as null (no quiet hours end) | ⬜ | ◌ |
| TC-PPT-ACC-033 | Set quiet hours with invalid time format | 1. Enter start=22:00:00 (with seconds)<br>2. Submit | Validation error: format must be H:i | ⬜ | ◌ |
| TC-PPT-ACC-034 | Set quiet hours with non-time value | 1. Enter start=abc<br>2. Submit | Validation error | ⬜ | ◌ |
| TC-PPT-ACC-035 | Verify quiet hours stored with :00 seconds appended | 1. Set quiet_hours_start=22:00<br>2. Check DB | Stored as 22:00:00 | ⬜ | ◌ |
| TC-PPT-ACC-036 | Clear quiet hours (set both to empty) | 1. Submit with both fields empty<br>2. Check DB | Both stored as null | ⬜ | ◌ |

### 3.6 Device Management

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-ACC-037 | View device list populated | 1. Have multiple active sessions<br>2. View Devices tab | All sessions listed with device type, last active | ⬜ | ◌ |
| TC-PPT-ACC-038 | Logout a specific device | 1. Click Logout on a device<br>2. Confirm | Device session set to inactive; success message | ⬜ | ◌ |
| TC-PPT-ACC-039 | Verify logged-out device no longer appears in list | 1. Logout a device<br>2. Refresh Devices tab | Logged-out device no longer in list | ⬜ | ◌ |
| TC-PPT-ACC-040 | Logout another parent's device (IDOR attempt) | 1. Attempt to logout device belonging to different parent | 403 Forbidden | ⬜ | ◌ |
| TC-PPT-ACC-041 | Verify device list empty when no sessions exist | 1. Clear all sessions for guardian<br>2. View Devices tab | Empty state shown | ⬜ | ◌ |

### 3.7 Language

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-ACC-042 | Switch language to Hindi | 1. Select Hindi (hi)<br>2. Submit | Language switched; success message | ⬜ | ◌ |
| TC-PPT-ACC-043 | Switch language to each available option | 1. Select each of 7 languages<br>2. Submit each | Each language switch succeeds | ⬜ | ◌ |
| TC-PPT-ACC-044 | Submit with invalid language code | 1. Enter non-existent language code<br>2. Submit | Validation error: language must be valid | ⬜ | ◌ |
| TC-PPT-ACC-045 | Verify language persists after page reload | 1. Switch to Hindi<br>2. Refresh page | Language preference retained | ⬜ | ◌ |
| TC-PPT-ACC-046 | Verify language persists in session after browser close (if DB persisted) | 1. Switch language<br>2. Close browser<br>3. Reopen login | Language retains last setting | ⬜ | ◌ |

### 3.8 Security Tests

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-ACC-047 | Access account page without auth | 1. Logout<br>2. Navigate to Account | Redirected to login | ⬜ | ◌ |
| TC-PPT-ACC-048 | PUT profile without CSRF token | 1. Submit form without CSRF | 419 CSRF mismatch | ⬜ | ◌ |
| TC-PPT-ACC-049 | PUT password without CSRF token | 1. Submit form without CSRF | 419 CSRF mismatch | ⬜ | ◌ |
| TC-PPT-ACC-050 | PUT notifications without CSRF token | 1. Submit without CSRF | 419 CSRF mismatch | ⬜ | ◌ |

### 3.9 Audit Logging

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-ACC-051 | Verify audit log on account view | 1. Access account page<br>2. Check sys_activity_logs | "Viewed" event logged | ⬜ | ◌ |
| TC-PPT-ACC-052 | Verify audit log on profile update | 1. Update profile<br>2. Check logs | "Updated" event logged | ⬜ | ◌ |
| TC-PPT-ACC-053 | Verify audit log on password change | 1. Change password<br>2. Check logs | "PasswordChanged" event logged | ⬜ | ◌ |
| TC-PPT-ACC-054 | Verify audit log on notification preferences update | 1. Save preferences<br>2. Check logs | "PreferencesUpdated" event logged | ⬜ | ◌ |
| TC-PPT-ACC-055 | Verify audit log on quiet hours update | 1. Update quiet hours<br>2. Check logs | "QuietHoursUpdated" event logged | ⬜ | ◌ |
| TC-PPT-ACC-056 | Verify audit log on device logout | 1. Logout device<br>2. Check logs | "DeviceLoggedOut" event with device_session_id | ⬜ | ◌ |
| TC-PPT-ACC-057 | Verify audit log on language update | 1. Change language<br>2. Check logs | "LanguageUpdated" event with language code | ⬜ | ◌ |

## 4. API / Form Contracts

### Profile Update — Success
Redirect to `route('parent-portal.account.index', ['tab' => 'profile'])` with success flash.

### Password Change — Error
Redirect back with `errors` bag for `current_password` and `active_tab = 'password'`.

### Language Update
Redirect back (no tab parameter — language is global).

## 5. Test Data Setup

| Entity | Required Records |
|--------|-----------------|
| User | Test parent user with known password |
| Guardian | Guardian record linked to user |
| ParentSession | At least 2-3 device sessions for the guardian |
| ChannelMaster | At least 3 notification channels |
| UserPreference | Existing preferences for some channels |

## 6. Database Assertions

| Assertion | Query / Check |
|-----------|--------------|
| Profile updated | `SELECT name, email, mobile_no FROM sys_users WHERE id = ?` |
| Guardian updated | `SELECT first_name, last_name, occupation FROM std_guardians WHERE user_id = ?` |
| Password changed | `SELECT password FROM sys_users WHERE id = ?` — hash different from old |
| Device inactive | `SELECT is_active FROM ppt_parent_sessions WHERE id = ?` = 0 |
| Preference upserted | `SELECT is_enabled FROM ntf_user_preferences WHERE user_id = ? AND channel_id = ?` |
| Quiet hours stored | `SELECT quiet_hours_start, quiet_hours_end FROM ntf_user_preferences WHERE user_id = ?` |
| Language stored (session) | Check `Session::get('ppt_language')` |

## 7. Browser / Device Compatibility

| Platform | Support |
|----------|---------|
| Chrome (Desktop) | ✅ |
| Firefox (Desktop) | ✅ |
| Chrome (Android) | ✅ |
| Safari (iOS) | ✅ |

## 8. Known Issues

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | Quiet hours stored in UserPreference, not ppt_parent_sessions (DDL specifies session table) | Medium | ⬜ |
| 2 | No profile photo/avatar upload endpoint | Low | ⬜ |
| 3 | LogoutDeviceParentAccountRequest has empty rules() | Low | ⬜ |
| 4 | Language column on sys_users may not exist — silent catch | Low | ⬜ |
| 5 | No way to identify current device in device list | Low | ⬜ |

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/parent-portal/account` | `account.index` | `index` |
| PUT | `/parent-portal/account/profile` | `account.profile.update` | `updateProfile` |
| PUT | `/parent-portal/account/password` | `account.password.update` | `updatePassword` |
| PUT | `/parent-portal/account/notifications` | `account.notifications.update` | `updateNotificationPreferences` |
| PUT | `/parent-portal/account/quiet-hours` | `account.quiet-hours.update` | `updateQuietHours` |
| POST | `/parent-portal/account/devices/{device}/logout` | `account.devices.logout` | `logoutDevice` |
| PUT | `/parent-portal/account/language` | `account.language.update` | `updateLanguage` |

## 10. Execution Status

| TC Count | Automated | Manual | Pass | Fail | Blocked | Not Run |
|----------|-----------|--------|------|------|---------|---------|
| 57 | 0 | 0 | 0 | 0 | 0 | 57 |
