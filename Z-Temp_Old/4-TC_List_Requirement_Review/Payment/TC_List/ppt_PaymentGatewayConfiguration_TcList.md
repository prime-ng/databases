# Payment Gateway Configuration — Test Case List

## 1. Module / Feature Under Test

| Attribute | Value |
|-----------|-------|
| **Module** | Payment |
| **Feature** | Payment Gateway Configuration |
| **Feature Code** | PAY-001 |
| **Controller** | `Modules\Payment\Http\Controllers\PaymentGatewayController` |
| **Form Request** | `Modules\Payment\Http\Requests\PaymentGatewayRequest` |
| **Policy** | `Modules\Payment\Policies\PaymentGatewayPolicy` |
| **Model** | `Modules\Payment\Models\PaymentGateway` (table: `ptm_payment_gateways`) |

## 2. Test Objective

Verify that the Payment Gateway Configuration feature correctly implements CRUD operations, status toggle, soft delete lifecycle, unique code constraint, single-active-gateway-per-type rule, credential encryption, permission-based access control, and audit logging behavior as specified in the requirement document.

## 3. Test Environment

| Item | Value |
|------|-------|
| **Backend** | Laravel 12 (PHP 8.2+) |
| **Database** | MySQL 8 (tenant database) |
| **Testing Framework** | Pest 4.x / PHPUnit |
| **Auth** | Sanctum (web guard) |
| **Session** | Laravel web session (authenticated admin user) |
| **Permissions** | Tenant-level permission gates |
| **Encryption** | Laravel APP_KEY based encryption |

## 4. Test Data Setup

| Entity | Details |
|--------|---------|
| **Admin User** | User with `tenant.payment.gateway.*` permissions |
| **Unauthorized User** | User WITHOUT any `tenant.payment.gateway.*` permissions |
| **Active Online Gateway** | Razorpay, code: `razorpay`, type: `online`, is_active: true |
| **Active Offline Gateway** | Offline, code: `offline`, type: `offline`, is_active: true |
| **Inactive Gateway** | PhonePe, code: `phonepe`, type: `online`, is_active: false |
| **Trashed Gateway** | Paytm, code: `paytm`, is_active: false, deleted_at: not null |

## 5. Test Cases

### 5.1 Permission / Access Control Tests

| TC ID | Test Case | Precondition | Test Steps | Expected Result | V1 | V2 | Status | CR |
|-------|-----------|-------------|------------|-----------------|----|----|--------|----|
| TC-PAY-001-001 | Verify unauthorized user cannot view gateway list | User without `tenant.payment.gateway.viewAny` permission | 1. Login as unauthorized user<br>2. GET `/payment/payment-gateway` | 403 Forbidden or redirect with error | — | — | ⬜ | ◌ |
| TC-PAY-001-002 | Verify unauthorized user cannot access create form | User without `tenant.payment.gateway.create` permission | 1. Login as unauthorized user<br>2. GET `/payment/payment-gateway/create` | 403 Forbidden or redirect with error | — | — | ⬜ | ◌ |
| TC-PAY-001-003 | Verify unauthorized user cannot store gateway | User without `tenant.payment.gateway.create` permission | 1. Login as unauthorized user<br>2. POST `/payment/payment-gateway` with valid data | 403 Forbidden or redirect with error | — | — | ⬜ | ◌ |
| TC-PAY-001-004 | Verify unauthorized user cannot edit gateway | User without `tenant.payment.gateway.update` permission | 1. Login as unauthorized user<br>2. GET `/payment/payment-gateway/{id}/edit` | 403 Forbidden or redirect with error | — | — | ⬜ | ◌ |
| TC-PAY-001-005 | Verify unauthorized user cannot update gateway | User without `tenant.payment.gateway.update` permission | 1. Login as unauthorized user<br>2. PUT `/payment/payment-gateway/{id}` with valid data | 403 Forbidden or redirect with error | — | — | ⬜ | ◌ |
| TC-PAY-001-006 | Verify unauthorized user cannot delete gateway | User without `tenant.payment.gateway.delete` permission | 1. Login as unauthorized user<br>2. DELETE `/payment/payment-gateway/{id}` | 403 Forbidden or redirect with error | — | — | ⬜ | ◌ |
| TC-PAY-001-007 | Verify unauthorized user cannot view trashed gateways | User without `tenant.payment.gateway.restore` permission | 1. Login as unauthorized user<br>2. GET `/payment/payment-gateway/trash/view` | 403 Forbidden or redirect with error | — | — | ⬜ | ◌ |
| TC-PAY-001-008 | Verify unauthorized user cannot restore gateway | User without `tenant.payment.gateway.restore` permission | 1. Login as unauthorized user<br>2. GET `/payment/payment-gateway/{id}/restore` | 403 Forbidden or redirect with error | — | — | ⬜ | ◌ |
| TC-PAY-001-009 | Verify unauthorized user cannot force delete gateway | User without `tenant.payment.gateway.forceDelete` permission | 1. Login as unauthorized user<br>2. DELETE `/payment/payment-gateway/{id}/force-delete` | 403 Forbidden or redirect with error | — | — | ⬜ | ◌ |
| TC-PAY-001-010 | Verify unauthorized user cannot toggle gateway status | User without `tenant.payment.gateway.update` permission | 1. Login as unauthorized user<br>2. POST `/payment/payment-gateway/{id}/toggle-status` | 403 Forbidden or redirect with error | — | — | ⬜ | ◌ |
| TC-PAY-001-011 | Verify authorized user can view gateway list | User with `tenant.payment.gateway.viewAny` permission | 1. Login as authorized user<br>2. GET `/payment/payment-gateway` | 200 OK; paginated gateway list displayed | — | — | ⬜ | ◌ |
| TC-PAY-001-012 | Verify authorized user can access create form | User with `tenant.payment.gateway.create` permission | 1. Login as authorized user<br>2. GET `/payment/payment-gateway/create` | 200 OK; create form with driver dropdown | — | — | ⬜ | ◌ |

### 5.2 CRUD — Create / Store

| TC ID | Test Case | Precondition | Test Steps | Expected Result | V1 | V2 | Status | CR |
|-------|-----------|-------------|------------|-----------------|----|----|--------|----|
| TC-PAY-001-013 | Verify creating gateway with all valid fields | No gateway with code 'razorpay_test' | 1. POST `/payment/payment-gateway` with name="Razorpay Test", code="razorpay_test", type="online", driver="Modules\Payment\Gateways\RazorpayGateway", credentials[key]="key123", credentials[secret]="secret456", extra_config[mode]="test", priority=1 | 302 redirect to index; success flash message; record created in `ptm_payment_gateways` | — | — | ⬜ | ◌ |
| TC-PAY-001-014 | Verify creating gateway with offline type | No gateway with code 'offline_cash' | 1. POST `/payment/payment-gateway` with name="Offline Cash", code="offline_cash", type="offline", driver="Modules\Payment\Gateways\OfflineGateway", credentials[key]="n/a", credentials[secret]="n/a" | 302 redirect; gateway created with type='offline' | — | — | ⬜ | ◌ |
| TC-PAY-001-015 | Verify creating gateway without name fails | — | 1. POST `/payment/payment-gateway` with name="" | 302 back with validation error: "Gateway name is required." | — | — | ⬜ | ◌ |
| TC-PAY-001-016 | Verify creating gateway without code fails | — | 1. POST `/payment/payment-gateway` with code="" | 302 back with validation error: "Gateway code is required." | — | — | ⬜ | ◌ |
| TC-PAY-001-017 | Verify creating gateway with duplicate code fails | Existing gateway with code='razorpay' | 1. POST `/payment/payment-gateway` with code="razorpay" | 302 back with validation error: "This gateway code already exists." | — | — | ⬜ | ◌ |
| TC-PAY-001-018 | Verify creating gateway without type fails | — | 1. POST `/payment/payment-gateway` with type="" | 302 back with validation error: "Gateway type is required." | — | — | ⬜ | ◌ |
| TC-PAY-001-019 | Verify creating gateway with invalid type fails | — | 1. POST `/payment/payment-gateway` with type="crypto" | 302 back with validation error: "Gateway type must be online or offline." | — | — | ⬜ | ◌ |
| TC-PAY-001-020 | Verify creating gateway without driver fails | — | 1. POST `/payment/payment-gateway` with driver="" | 302 back with validation error: "Gateway driver class path is required." | — | — | ⬜ | ◌ |
| TC-PAY-001-021 | Verify creating gateway without credentials fails | — | 1. POST `/payment/payment-gateway` with credentials=[] | 302 back with validation error: "Gateway credentials are required." | — | — | ⬜ | ◌ |
| TC-PAY-001-022 | Verify creating gateway without credentials.key fails | — | 1. POST `/payment/payment-gateway` with credentials={secret: "x"} | 302 back with validation error: "API key is required." | — | — | ⬜ | ◌ |
| TC-PAY-001-023 | Verify creating gateway without credentials.secret fails | — | 1. POST `/payment/payment-gateway` with credentials={key: "x"} | 302 back with validation error: "API secret is required." | — | — | ⬜ | ◌ |
| TC-PAY-001-024 | Verify creating second active gateway of same type fails | Existing active online gateway (razorpay, is_active=true) | 1. POST `/payment/payment-gateway` with type="online", is_active=true | 302 back with validation error: "An active gateway of type [online] already exists." | — | — | ⬜ | ◌ |
| TC-PAY-001-025 | Verify creating second active gateway of different type succeeds | Existing active online gateway (razorpay) | 1. POST `/payment/payment-gateway` with type="offline", is_active=true | 302 redirect; gateway created successfully (different type allowed) | — | — | ⬜ | ◌ |
| TC-PAY-001-026 | Verify creating gateway with extra_config[mode]=live | — | 1. POST with extra_config[mode]="live" | Gateway created; extra_config JSON contains mode: "live" | — | — | ⬜ | ◌ |
| TC-PAY-001-027 | Verify creating gateway with name exceeding 100 chars | — | 1. POST with name=str_repeat('A', 101) | Validation error on name field | — | — | ⬜ | ◌ |
| TC-PAY-001-028 | Verify creating gateway with code exceeding 50 chars | — | 1. POST with code=str_repeat('a', 51) | Validation error on code field | — | — | ⬜ | ◌ |
| TC-PAY-001-029 | Verify creating gateway with priority < 1 | — | 1. POST with priority=0 | Validation error on priority field | — | — | ⬜ | ◌ |
| TC-PAY-001-030 | Verify creating gateway with priority > 100 | — | 1. POST with priority=101 | Validation error on priority field | — | — | ⬜ | ◌ |
| TC-PAY-001-031 | Verify default values on create: extra_config | — | 1. POST without extra_config | Gateway created; extra_config defaults to {"mode":"test"} | — | — | ⬜ | ◌ |
| TC-PAY-001-032 | Verify default values on create: priority | — | 1. POST without priority | Gateway created; priority defaults to 1 | — | — | ⬜ | ◌ |
| TC-PAY-001-033 | Verify default values on create: is_active | — | 1. POST without is_active | Gateway created; is_active defaults to false | — | — | ⬜ | ◌ |
| TC-PAY-001-034 | Verify create logs audit entry | — | 1. Create gateway<br>2. Check activity_log | 'Stored' event logged with gateway_code, gateway_name, performed_by | — | — | ⬜ | ◌ |

### 5.3 CRUD — Read / Index / Show

| TC ID | Test Case | Precondition | Test Steps | Expected Result | V1 | V2 | Status | CR |
|-------|-----------|-------------|------------|-----------------|----|----|--------|----|
| TC-PAY-001-035 | Verify index lists all gateways sorted by priority | 3 gateways with priorities 3, 1, 2 | 1. GET `/payment/payment-gateway` | Gateways displayed in order: priority 1, 2, 3 | — | — | ⬜ | ◌ |
| TC-PAY-001-036 | Verify index paginates at 15 per page | 20 gateways | 1. GET `/payment/payment-gateway` | First page shows 15 gateways; pagination links visible | — | — | ⬜ | ◌ |
| TC-PAY-001-037 | Verify index shows gateway mode badge | Gateway with extra_config[mode]="live" | 1. GET `/payment/payment-gateway` | "Live" badge (bg-success) displayed for gateway | — | — | ⬜ | ◌ |
| TC-PAY-001-038 | Verify index shows test mode badge | Gateway with extra_config[mode]="test" | 1. GET `/payment/payment-gateway` | "Test" badge (bg-warning text-dark) displayed | — | — | ⬜ | ◌ |
| TC-PAY-001-039 | Verify index shows status toggle | Gateway with is_active=true | 1. GET `/payment/payment-gateway` | Status toggle component rendered for gateway | — | — | ⬜ | ◌ |
| TC-PAY-001-040 | Verify index shows code as badge | — | 1. GET `/payment/payment-gateway` | Gateway code displayed in badge bg-dark | — | — | ⬜ | ◌ |
| TC-PAY-001-041 | Verify show displays gateway details | Existing gateway with id=1 | 1. GET `/payment/payment-gateway/1` | 200 OK; gateway fields displayed | — | — | ⬜ | ◌ |
| TC-PAY-001-042 | Verify show for non-existent gateway returns 404 | No gateway with id=999 | 1. GET `/payment/payment-gateway/999` | 404 Not Found | — | — | ⬜ | ◌ |
| TC-PAY-001-043 | Verify index shows actions column | — | 1. GET `/payment/payment-gateway` | Each row has view/edit/delete action buttons | — | — | ⬜ | ◌ |

### 5.4 CRUD — Update / Edit

| TC ID | Test Case | Precondition | Test Steps | Expected Result | V1 | V2 | Status | CR |
|-------|-----------|-------------|------------|-----------------|----|----|--------|----|
| TC-PAY-001-044 | Verify updating gateway name | Existing gateway (razorpay) | 1. PUT `/payment/payment-gateway/{id}` with name="Updated Razorpay" | Gateway name updated; redirect with success message | — | — | ⬜ | ◌ |
| TC-PAY-001-045 | Verify updating gateway to duplicate code fails | Two gateways: razorpay, phonepe | 1. PUT `/payment/payment-gateway/{razorpay_id}` with code="phonepe" | 302 back with validation error: "This gateway code already exists." | — | — | ⬜ | ◌ |
| TC-PAY-001-046 | Verify updating gateway allows same code on self | Existing gateway with code='razorpay' | 1. PUT `/payment/payment-gateway/{id}` with code="razorpay" | Gateway updated successfully (unique rule excludes self) | — | — | ⬜ | ◌ |
| TC-PAY-001-047 | Verify updating gateway type | Existing gateway | 1. PUT `/payment/payment-gateway/{id}` with type="offline" | Gateway type updated to 'offline' | — | — | ⬜ | ◌ |
| TC-PAY-001-048 | Verify updating gateway active flag | Existing inactive gateway | 1. PUT `/payment/payment-gateway/{id}` with is_active=true | Gateway activated (single-active rule enforced) | — | — | ⬜ | ◌ |
| TC-PAY-001-049 | Verify updating gateway logs changes in audit | Existing gateway | 1. PUT with changed name<br>2. Check activity_log | 'Updated' event logged with changes array showing old/new values | — | — | ⬜ | ◌ |
| TC-PAY-001-050 | Verify editing gateway pre-populates form fields | Existing gateway with known values | 1. GET `/payment/payment-gateway/{id}/edit` | Form fields pre-populated with existing values; driver selected correctly | — | — | ⬜ | ◌ |
| TC-PAY-001-051 | Verify updating gateway with no changes | Existing gateway | 1. PUT with same values (no changes) | Gateway updated; no meaningful changes; audit log may show empty changes | — | — | ⬜ | ◌ |

### 5.5 Status Toggle

| TC ID | Test Case | Precondition | Test Steps | Expected Result | V1 | V2 | Status | CR |
|-------|-----------|-------------|------------|-----------------|----|----|--------|----|
| TC-PAY-001-052 | Verify toggling active gateway to inactive | Gateway with is_active=true | 1. POST `/payment/payment-gateway/{id}/toggle-status` | JSON response: success=true, is_active=false; gateway now inactive | — | — | ⬜ | ◌ |
| TC-PAY-001-053 | Verify toggling inactive gateway to active | Gateway with is_active=false | 1. POST `/payment/payment-gateway/{id}/toggle-status` | JSON response: success=true, is_active=true; gateway now active | — | — | ⬜ | ◌ |
| TC-PAY-001-054 | Verify toggle status logs audit entry | — | 1. Toggle gateway<br>2. Check activity_log | 'Toggled' event logged with new_status (Active/Inactive) | — | — | ⬜ | ◌ |
| TC-PAY-001-055 | Verify toggle returns appropriate JSON structure | — | 1. Toggle gateway | JSON has keys: success, is_active, message | — | — | ⬜ | ◌ |

### 5.6 Soft Delete / Restore / Force Delete

| TC ID | Test Case | Precondition | Test Steps | Expected Result | V1 | V2 | Status | CR |
|-------|-----------|-------------|------------|-----------------|----|----|--------|----|
| TC-PAY-001-056 | Verify deleting (soft) a gateway | Active gateway with is_active=true | 1. DELETE `/payment/payment-gateway/{id}` | 302 redirect; gateway set to is_active=false; deleted_at set; not in index list | — | — | ⬜ | ◌ |
| TC-PAY-001-057 | Verify trashed gateway appears in trash list | Soft-deleted gateway | 1. GET `/payment/payment-gateway/trash/view` | Gateway visible in trashed list paginated at 10 per page | — | — | ⬜ | ◌ |
| TC-PAY-001-058 | Verify restoring a trashed gateway | Soft-deleted gateway | 1. GET `/payment/payment-gateway/{id}/restore` | 302 redirect; deleted_at=NULL; is_active=true; gateway appears in active list | — | — | ⬜ | ◌ |
| TC-PAY-001-059 | Verify force deleting a gateway | Soft-deleted gateway | 1. DELETE `/payment/payment-gateway/{id}/force-delete` | 302 redirect; record permanently removed from ptm_payment_gateways | — | — | ⬜ | ◌ |
| TC-PAY-001-060 | Verify restoring non-existent gateway fails | No trashed gateway with id=999 | 1. GET `/payment/payment-gateway/999/restore` | 404 Not Found | — | — | ⬜ | ◌ |
| TC-PAY-001-061 | Verify force deleting non-existent gateway fails | No trashed gateway with id=999 | 1. DELETE `/payment/payment-gateway/999/force-delete` | 404 Not Found | — | — | ⬜ | ◌ |
| TC-PAY-001-062 | Verify delete logs audit entry | — | 1. Delete gateway<br>2. Check activity_log | 'Trashed' event logged with gateway_code, gateway_name | — | — | ⬜ | ◌ |
| TC-PAY-001-063 | Verify restore logs audit entry | — | 1. Restore gateway<br>2. Check activity_log | 'Restored' event logged | — | — | ⬜ | ◌ |
| TC-PAY-001-064 | Verify force delete logs audit entry | — | 1. Force delete<br>2. Check activity_log | 'Deleted' event logged (N/A fallback for already-removed values) | — | — | ⬜ | ◌ |

### 5.7 Credential Encryption

| TC ID | Test Case | Precondition | Test Steps | Expected Result | V1 | V2 | Status | CR |
|-------|-----------|-------------|------------|-----------------|----|----|--------|----|
| TC-PAY-001-065 | Verify credentials are stored encrypted | — | 1. Create gateway with credentials={key:"test123", secret:"topsecret"}<br>2. Query raw DB `ptm_payment_gateways` | Raw `credentials` column contains encrypted text, not plain JSON | — | — | ⬜ | ◌ |
| TC-PAY-001-066 | Verify credentials are decrypted when read via Eloquent | — | 1. Create gateway<br>2. Read via `PaymentGateway::find()` | Credentials returned as decrypted array with key/secret values | — | — | ⬜ | ◌ |
| TC-PAY-001-067 | Verify credential encryption changes on different APP_KEY | — | 1. Create gateway with known credentials<br>2. Change APP_KEY<br>3. Attempt to read | Decryption fails (unable to decrypt) | — | — | ⬜ | ◌ |

### 5.8 Validation Edge Cases

| TC ID | Test Case | Precondition | Test Steps | Expected Result | V1 | V2 | Status | CR |
|-------|-----------|-------------|------------|-----------------|----|----|--------|----|
| TC-PAY-001-068 | Verify code accepts lowercase with underscores | — | 1. POST with code="my_gateway_01" | Gateway created; code saved as "my_gateway_01" | — | — | ⬜ | ◌ |
| TC-PAY-001-069 | Verify code rejects spaces | — | 1. POST with code="my gateway" | Validation error (note: DB varchar, unique may allow; front-end should guide) | — | — | ⬜ | ◌ |
| TC-PAY-001-070 | Verify type 'online' accepts all online drivers | — | 1. POST with type="online", driver="RazorpayGateway" | Gateway created with online type | — | — | ⬜ | ◌ |
| TC-PAY-001-071 | Verify type 'offline' only works with OfflineGateway | — | 1. POST with type="offline", driver="OfflineGateway" | Gateway created with offline type | — | — | ⬜ | ◌ |
| TC-PAY-001-072 | Verify creating active gateway when none of that type exists | No active gateway of type 'online' | 1. POST with type="online", is_active=true | Gateway created and active (no conflict) | — | — | ⬜ | ◌ |
| TC-PAY-001-073 | Verify creating inactive gateway when one of same type is active | Existing active online gateway | 1. POST with type="online", is_active=false | Gateway created (inactive); no conflict | — | — | ⬜ | ◌ |

### 5.9 UI Display Tests

| TC ID | Test Case | Precondition | Test Steps | Expected Result | V1 | V2 | Status | CR |
|-------|-----------|-------------|------------|-----------------|----|----|--------|----|
| TC-PAY-001-074 | Verify index displays empty state | No gateways configured | 1. GET `/payment/payment-gateway` | "No payment gateways found." message displayed | — | — | ⬜ | ◌ |
| TC-PAY-001-075 | Verify create form has all required fields | — | 1. GET `/payment/payment-gateway/create` | Form contains: name, code, type, driver, priority, credentials key/secret, webhook secret, mode, active, test mode | — | — | ⬜ | ◌ |
| TC-PAY-001-076 | Verify driver dropdown shows all 6 drivers | — | 1. GET `/payment/payment-gateway/create` | Dropdown has: Razorpay, PhonePe, Paytm, CCAvenue, BillDesk, Offline | — | — | ⬜ | ◌ |
| TC-PAY-001-077 | Verify edit form is pre-populated | Existing gateway | 1. GET `/payment/payment-gateway/{id}/edit` | Form fields show existing values; correct driver selected; mode reflects extra_config | — | — | ⬜ | ◌ |
| TC-PAY-001-078 | Verify trash view lists only soft-deleted gateways | Mix of active + trashed gateways | 1. GET `/payment/payment-gateway/trash/view` | Only soft-deleted gateways shown; no active gateways in list | — | — | ⬜ | ◌ |
| TC-PAY-001-079 | Verify validation errors display on form | — | 1. POST with invalid data<br>2. Check response | Validation errors displayed in alert-danger box above form | — | — | ⬜ | ◌ |

## 6. Boundary Value Analysis

| Field | Min Boundary | Max Boundary | Notes |
|-------|-------------|-------------|-------|
| `name` | 1 char | 100 chars | Required; max length 100 |
| `code` | 1 char | 50 chars | Required; max length 50; unique |
| `priority` | 1 | 100 | Default 1 if not provided |
| `is_active` | false (0) | true (1) | Boolean; default false |
| `type` | 'online' | 'offline' | Only two valid values |
| `credentials` | Non-empty key+secret | Any valid JSON | Required array with key+secret |

## 7. Error Scenarios

| Scenario | Expected Behavior |
|----------|------------------|
| Unauthenticated access to any route | Redirect to login |
| Unauthorized access (no permission) | 403 Forbidden or redirect with error |
| Invalid form data | Validation errors returned (302 back with errors in session) |
| Duplicate code on create | "This gateway code already exists." |
| Duplicate code on update (other record) | "This gateway code already exists." |
| Same code on self-update | Allowed (unique excludes current ID) |
| Two active gateways of same type | "An active gateway of type [{type}] already exists." |
| Non-existent gateway ID | 404 Not Found |
| Restore already-active gateway | Not applicable (onlyTrashed scope) |
| Force delete active gateway | Must soft-delete first (or use withTrashed) |
| Missing required credentials field | "API key is required." / "API secret is required." |

## 8. Known Issues

| # | Issue | Impact | Workaround |
|---|-------|--------|------------|
| KI-001 | The `destroy()` method first sets `is_active=false`, then calls `delete()`. If the save() fails before delete(), the gateway remains active but the user sees a success redirect. | Low — potential inconsistency | Ensure transactional behavior on destroy |
| KI-002 | The `PaymentGatewayPolicy` uses `can()` which assumes the `User` model has the `can()` method from Laravel's Authorizable trait. If `Modules\SchoolSetup\Models\User` does not use the trait, all policy checks will fail. | High — complete auth bypass | Verify User model uses `Authorizable` trait |
| KI-003 | The `PaymentGatewayRequest::authorize()` uses complex ternary logic to determine create vs update ability by checking route parameter existence. The fallback `route('id')` is not a standard resource route parameter. | Medium — potential miscategorized permission | Ensure route model binding resolves `{id}` consistently |
| KI-004 | No CSRF token validation is exempted on the web routes; if any external system needs to POST to toggle-status, it will fail. | Low — by design for web context | Web routes are session-based; CSRF protection is expected |

## 9. Route Reference

All routes in this feature use the following middleware stack:
- `web` — session, cookies, CSRF
- `InitializeTenancyByDomain` — tenant resolution
- `PreventAccessFromCentralDomains` — central domain guard
- `EnsureTenantIsActive` — tenant active check
- `EnsureTenantHasModule:Payment` — module availability check
- `auth` — authenticated user guard
- `verified` — email verification guard

| Method | URI | Name | Controller Action |
|--------|-----|------|-------------------|
| GET | `/payment/payment-gateway` | `payment.payment-gateway.index` | `index` |
| GET | `/payment/payment-gateway/create` | `payment.payment-gateway.create` | `create` |
| POST | `/payment/payment-gateway` | `payment.payment-gateway.store` | `store` |
| GET | `/payment/payment-gateway/{payment_gateway}` | `payment.payment-gateway.show` | `show` |
| GET | `/payment/payment-gateway/{payment_gateway}/edit` | `payment.payment-gateway.edit` | `edit` |
| PUT/PATCH | `/payment/payment-gateway/{payment_gateway}` | `payment.payment-gateway.update` | `update` |
| DELETE | `/payment/payment-gateway/{payment_gateway}` | `payment.payment-gateway.destroy` | `destroy` |
| POST | `/payment/payment-gateway/{payment_gateway}/toggle-status` | `payment.payment-gateway.toggleStatus` | `toggleStatus` |
| GET | `/payment/payment-gateway/trash/view` | `payment.payment-gateway.trashed` | `trashedPaymentGateways` |
| GET | `/payment/payment-gateway/{id}/restore` | `payment.payment-gateway.restore` | `restore` |
| DELETE | `/payment/payment-gateway/{id}/force-delete` | `payment.payment-gateway.forceDelete` | `forceDelete` |

## 10. Execution Status

| Section | Total TCs | Pass | Fail | Blocked | Not Run | Coverage % |
|---------|-----------|------|------|---------|---------|------------|
| 5.1 Permission / Access Control | 12 | — | — | — | — | — |
| 5.2 CRUD — Create / Store | 22 | — | — | — | — | — |
| 5.3 CRUD — Read / Index / Show | 9 | — | — | — | — | — |
| 5.4 CRUD — Update / Edit | 8 | — | — | — | — | — |
| 5.5 Status Toggle | 4 | — | — | — | — | — |
| 5.6 Soft Delete / Restore / Force Delete | 9 | — | — | — | — | — |
| 5.7 Credential Encryption | 3 | — | — | — | — | — |
| 5.8 Validation Edge Cases | 6 | — | — | — | — | — |
| 5.9 UI Display Tests | 8 | — | — | — | — | — |
| **Total** | **81** | — | — | — | — | — |

**Legend:**
- V1/V2: Version columns — `—` = not applicable
- Status: `⬜` = Not Run, `✅` = Pass, `❌` = Fail, `⛔` = Blocked
- CR: `◌` = No Change Request, `🔄` = Change Requested

**Test Execution Notes:**
- All tests assume authenticated admin session with appropriate permissions unless specified as unauthorized
- Form validation errors assume Laravel's standard validation error response (302 redirect with errors in session)
- Credential encryption tests require direct database inspection (not via Eloquent)
