# Payment Gateway Configuration — Backend Admin Feature

## 1. Feature Identity

| Attribute | Value |
|-----------|-------|
| **Feature Name** | Payment Gateway Configuration |
| **Module** | Payment |
| **Feature Code** | PAY-001 |
| **Controller** | `Modules\Payment\Http\Controllers\PaymentGatewayController` |
| **Model** | `Modules\Payment\Models\PaymentGateway` (table: `ptm_payment_gateways`) |
| **Form Request** | `Modules\Payment\Http\Requests\PaymentGatewayRequest` |
| **Policy** | `Modules\Payment\Policies\PaymentGatewayPolicy` |
| **View Path** | `payment::payment-gateway.*` |
| **Route Prefix** | `/payment/payment-gateway` |
| **Route Name** | `payment.payment-gateway.*` |

## 2. Feature Purpose

Allow authorized admin users to configure, enable/disable, and manage payment gateway drivers that the Payment module uses to process transactions. Each gateway stores its credentials (encrypted), driver class mapping, priority, and operational mode (test/live).

## 3. Feature Type

**CRUD + Status Toggle — Backend Admin UI (Blade)**

Standard resource controller with:
- Index (paginated list with search/filter)
- Create (form with driver picker)
- Store (validation via PaymentGatewayRequest)
- Show (gateway detail)
- Edit (pre-populated form)
- Update (validation via PaymentGatewayRequest)
- Destroy (soft delete + deactivate)
- Trashed list (soft-deleted gateways)
- Restore (restore + reactivate)
- Force Delete (permanent removal)
- Toggle Status (AJAX active/inactive switch)

## 4. Scope

### In-Scope

| Item | Description |
|------|-------------|
| Gateway CRUD | Create, read, update, soft-delete payment gateway records |
| Driver Selection | Pick from 6 available driver classes (Razorpay, PhonePe, Paytm, CCAvenue, BillDesk, Offline) |
| Credential Management | Store API keys, secrets, webhook secrets as encrypted JSON |
| Mode Switching | Toggle between test/live mode per gateway |
| Active/Inactive Toggle | AJAX toggle to activate/deactivate gateway |
| Priority Management | Integer priority for ordering (lower = higher priority) |
| Single-Active Rule | Business rule: only one active gateway per type (online/offline) |
| Soft Delete | Move to trash, restore, or permanently delete |
| Audit Logging | Activity log on every create, update, toggle, trash, restore, force delete |

### Out-of-Scope

| Item | Reason |
|------|--------|
| Gateway payment processing | Handled by PaymentService + GatewayManager |
| Gateway webhook configuration | Webhook secrets stored in credentials; middleware routes registered elsewhere |
| Gateway test transaction | Not part of configuration CRUD |
| Gateway analytics/dashboard | Separate reporting feature |

## 5. DDL — Column Reference

**Table: `ptm_payment_gateways`**

| Column | Type | Constraints | Default | Notes |
|--------|------|-------------|---------|-------|
| `id` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | — | Primary key |
| `name` | VARCHAR(255) | NOT NULL | — | Human-readable name (e.g. "Razorpay") |
| `code` | VARCHAR(255) | NOT NULL, UNIQUE | — | Unique identifier (e.g. "razorpay") |
| `type` | VARCHAR(20) | NOT NULL | `'online'` | Gateway type: online/offline |
| `driver` | VARCHAR(255) | NOT NULL | — | FQCN of driver class |
| `credentials` | TEXT | NULLABLE | — | JSON with api key, secret, webhook secret; cast encrypted:array |
| `extra_config` | JSON | NULLABLE | — | Config like `{"mode": "test"}` |
| `priority` | INT | NOT NULL | `1` | Display priority (1-100, lower first) |
| `is_active` | TINYINT(1) | NOT NULL | `0` | Active flag (default inactive) |
| `deleted_at` | TIMESTAMP | NULLABLE | NULL | Soft delete marker |
| `created_at` | TIMESTAMP | NULLABLE | NULL | Creation timestamp |
| `updated_at` | TIMESTAMP | NULLABLE | NULL | Last update timestamp |

**Indexes:**
- `UNIQUE` on `code`
- `INDEX` on `(type, is_active)` for gateway resolution queries

## 6. Form Request — Validation Rules

### `PaymentGatewayRequest`

**Base Rules:**

| Field | Rules | Error Message |
|-------|-------|---------------|
| `name` | `required, string, max:100` | "Gateway name is required." |
| `code` | `required, string, max:50, unique:ptm_payment_gateways,code,{id}` | "Gateway code is required." / "This gateway code already exists." |
| `type` | `required, string, in:online,offline` | "Gateway type is required." / "Gateway type must be online or offline." |
| `driver` | `required, string, max:255` | "Gateway driver class path is required." |
| `credentials` | `required, array` | "Gateway credentials are required." |
| `credentials.key` | `required, string` | "API key is required." |
| `credentials.secret` | `required, string` | "API secret is required." |
| `credentials.webhook_secret` | `nullable, string` | — |
| `extra_config` | `nullable, array` | — |
| `extra_config.mode` | `nullable, string, in:live,test` | — |
| `priority` | `nullable, integer, min:1, max:100` | — |
| `is_active` | `nullable, boolean` | — |
| `is_test_mode` | `nullable, boolean` | — |

**Custom Business Rule (after validation):**

Only one gateway per type can be active at a time. If `is_active` is true and another gateway of the same type (`online`/`offline`) is already active, the validation fails with:
> "An active gateway of type [{type}] already exists."

This check uses `PaymentGateway::where('type', $type)->where('is_active', true)` and excludes the current record when updating.

**Prepare for Validation Logic:**

- `is_active`: converts `'on'` string (from checkbox) to boolean `true`; defaults to `false`
- `is_test_mode`: same conversion as `is_active`

**Authorization in Request:**

The `authorize()` method determines the ability:
- `POST` → `tenant.payment.gateway.create`
- `PUT/PATCH` → `tenant.payment.gateway.update`

## 7. State Machine — Gateway Lifecycle

```
         ┌──────────────────────────────┐
         │     Draft (created)          │
         │     is_active = false        │
         └──────────┬───────────────────┘
                    │ toggleStatus() / restore()
                    ▼
         ┌──────────────────────────────┐
         │     Active                   │◄──────────────────────┐
         │     is_active = true         │                       │
         └──────────┬───────────────────┘                       │
                    │ toggleStatus()                            │
                    ▼                                           │
         ┌──────────────────────────────┐                       │
         │     Inactive                 │───────────────────────┘
         │     is_active = false        │  toggleStatus()
         └──────────┬───────────────────┘
                    │ destroy()
                    ▼
         ┌──────────────────────────────┐
         │     Trashed (soft-deleted)   │
         │     is_active = false        │
         │     deleted_at = now()       │
         ├──────────────────────────────┤
         │ restore() → Active           │
         │ forceDelete() → Permanently  │
         │ Removed                      │
         └──────────────────────────────┘
```

## 8. Controller Actions — Detailed Breakdown

### 8.1 `index()` — List Gateways

| Attribute | Detail |
|-----------|--------|
| **Route** | `GET /payment/payment-gateway` |
| **Permission** | `tenant.payment.gateway.viewAny` |
| **View** | `payment::payment-gateway.index` (rendered inside tab pane `#payment-gateway-pane`) |
| **Data** | Paginated (15 per page), ordered by `priority` ASC |
| **UI** | Table: #, Code (badge), Name, Driver (badge), Mode (test/live badge), Priority, Status (toggle switch), Actions (view/edit/delete) |
| **Filters** | Search bar, type filter, status filter |

### 8.2 `create()` — Show Create Form

| Attribute | Detail |
|-----------|--------|
| **Route** | `GET /payment/payment-gateway/create` |
| **Permission** | `tenant.payment.gateway.create` |
| **View** | `payment::payment-gateway.create` |
| **Data** | `$drivers` array from `getAvailableDrivers()` |
| **Form Fields** | Gateway Name (text), Gateway Code (text), Type (select: online/offline), Driver (select from driver list), Priority (number 1-100), API Key (text), API Secret (password), Webhook Secret (password), Mode (select: test/live), Active (checkbox), Test Mode (checkbox) |
| **Layout** | Breadcrumb: Payment Management > Create Gateway |

### 8.3 `store(PaymentGatewayRequest)` — Save Gateway

| Attribute | Detail |
|-----------|--------|
| **Route** | `POST /payment/payment-gateway` |
| **Permission** | `tenant.payment.gateway.create` |
| **Request** | `PaymentGatewayRequest` (validated) |
| **Logic** | Create gateway with all validated fields; `extra_config` defaults to `['mode' => 'test']` if not provided |
| **Side Effects** | `activityLog()` — logs 'Stored' event with gateway_code, gateway_name, performed_by |
| **Redirect** | `route('payment.payment-gateway.index')` with `flash('created.payment_gateway')` success message |

### 8.4 `show($id)` — View Gateway Detail

| Attribute | Detail |
|-----------|--------|
| **Route** | `GET /payment/payment-gateway/{id}` |
| **Permission** | `tenant.payment.gateway.viewAny` |
| **View** | `payment::payment-gateway.show` |
| **Data** | Single gateway by ID; shows all fields including credentials (decrypted for display) |

### 8.5 `edit($id)` — Show Edit Form

| Attribute | Detail |
|-----------|--------|
| **Route** | `GET /payment/payment-gateway/{id}/edit` |
| **Permission** | `tenant.payment.gateway.update` |
| **View** | `payment::payment-gateway.edit` |
| **Data** | Gateway + `$drivers` for driver select |
| **Pre-population** | Fields filled with existing values; mode from `extra_config['mode']`; credentials decrypted |

### 8.6 `update(PaymentGatewayRequest, $id)` — Update Gateway

| Attribute | Detail |
|-----------|--------|
| **Route** | `PUT/PATCH /payment/payment-gateway/{id}` |
| **Permission** | `tenant.payment.gateway.update` |
| **Request** | `PaymentGatewayRequest` (validated) |
| **Logic** | Updates all fields; preserves `extra_config` and `is_active` if not sent (using original values as fallback) |
| **Side Effects** | Computes changed attributes (old vs new) for detailed audit; logs 'Updated' with changes array |
| **Redirect** | `route('payment.payment-gateway.index')` with `flash('updated.payment_gateway')` |

### 8.7 `destroy($id)` — Soft Delete Gateway

| Attribute | Detail |
|-----------|--------|
| **Route** | `DELETE /payment/payment-gateway/{id}` |
| **Permission** | `tenant.payment.gateway.delete` |
| **Logic** | Sets `is_active = false` → calls `$gateway->delete()` (SoftDeletes) |
| **Side Effects** | Logs 'Trashed' with deactivation + trash notes |
| **Redirect** | `route('payment.payment-gateway.index')` with `flash('trashed.payment_gateway')` |

### 8.8 `trashedPaymentGateways()` — List Trashed

| Attribute | Detail |
|-----------|--------|
| **Route** | `GET /payment/payment-gateway/trash/view` |
| **Permission** | `tenant.payment.gateway.restore` |
| **View** | `payment::payment-gateway.trash` |
| **Data** | Only soft-deleted gateways, paginated (10 per page), ordered by created_at DESC |

### 8.9 `restore($id)` — Restore Gateway

| Attribute | Detail |
|-----------|--------|
| **Route** | `GET /payment/payment-gateway/{id}/restore` |
| **Permission** | `tenant.payment.gateway.restore` |
| **Logic** | Restores from soft delete → sets `is_active = true` |
| **Side Effects** | Logs 'Restored' |
| **Redirect** | `route('payment.payment-gateway.trashed')` with `flash('restored.payment_gateway')` |

### 8.10 `forceDelete($id)` — Permanent Delete

| Attribute | Detail |
|-----------|--------|
| **Route** | `DELETE /payment/payment-gateway/{id}/force-delete` |
| **Permission** | `tenant.payment.gateway.forceDelete` |
| **Logic** | Permanently removes from database (withTrashed → forceDelete) |
| **Side Effects** | Logs 'Deleted'; handles null gateway fields gracefully (N/A fallback) |
| **Redirect** | `route('payment.payment-gateway.trashed')` with `flash('force_deleted.payment_gateway')` |

### 8.11 `toggleStatus(Request, PaymentGateway)` — AJAX Toggle

| Attribute | Detail |
|-----------|--------|
| **Route** | `POST /payment/payment-gateway/{payment_gateway}/toggle-status` |
| **Permission** | `tenant.payment.gateway.update` |
| **Logic** | Negates `is_active` (`!$paymentGateway->is_active`) |
| **Side Effects** | Logs 'Toggled' with new_status (Active/Inactive) |
| **Response** | JSON `{success: bool, is_active: bool, message: string}` |
| **Behavior** | On save success: `flash('status_updated.payment_gateway')`; on failure: `flash('status_switch_failed.payment_gateway')` |

## 9. Available Drivers

| Display Name | FQCN |
|-------------|------|
| Razorpay | `Modules\Payment\Gateways\RazorpayGateway` |
| PhonePe | `Modules\Payment\Gateways\PhonePeGateway` |
| Paytm | `Modules\Payment\Gateways\PaytmGateway` |
| CCAvenue | `Modules\Payment\Gateways\CCAvenueGateway` |
| BillDesk | `Modules\Payment\Gateways\BillDeskGateway` |
| Offline | `Modules\Payment\Gateways\OfflineGateway` |

The drivers array is returned by the private `getAvailableDrivers()` method in `PaymentGatewayController`.

## 10. Permissions

| Permission | Policy Method | Actions |
|------------|--------------|---------|
| `tenant.payment.gateway.viewAny` | `viewAny()` | index, show |
| `tenant.payment.gateway.create` | `create()` | create, store |
| `tenant.payment.gateway.update` | `update()` | edit, update, toggleStatus |
| `tenant.payment.gateway.delete` | `delete()` | destroy |
| `tenant.payment.gateway.restore` | `restore()` | trashedPaymentGateways, restore |
| `tenant.payment.gateway.forceDelete` | `forceDelete()` | forceDelete |

## 11. Model Configuration

**`PaymentGateway` (`Modules\Payment\Models\PaymentGateway`)**

```php
protected $table = 'ptm_payment_gateways';

protected $fillable = [
    'name', 'code', 'type', 'driver', 'credentials', 'extra_config',
    'supported_modules', 'priority', 'is_active', 'is_test_mode', 'created_by',
];

protected $casts = [
    'credentials'       => 'encrypted:array',   // Auto-encrypt on save, decrypt on read
    'extra_config'      => 'array',
    'supported_modules' => 'array',
    'is_active'         => 'boolean',
    'is_test_mode'      => 'boolean',
];
```

**Relationships:**
- `payments(): HasMany` — All payments processed via this gateway
- `reconciliations(): HasMany` — All reconciliation records for this gateway

**Scopes:**
- `scopeActive(Builder)` — Filters `WHERE is_active = true`

**Traits:**
- `HasFactory` — For testing
- `SoftDeletes` — For soft deletion support

## 12. Views

| View | Path | Purpose |
|------|------|---------|
| Index | `payment::payment-gateway.index` | Tab-pane listing gateways in a table with search, filters, pagination |
| Create | `payment::payment-gateway.create` | Full form with all gateway fields, driver picker, credential inputs |
| Edit | `payment::payment-gateway.edit` | Pre-populated edit form (same layout as create) |
| Show | `payment::payment-gateway.show` | Gateway detail view |
| Trash | `payment::payment-gateway.trash` | List of soft-deleted gateways with restore/forceDelete actions |

## 13. Routes Summary

| Method | URI | Controller Action | Middleware |
|--------|-----|-------------------|------------|
| GET | `/payment/payment-gateway` | `index` | web, auth, verified, tenant |
| GET | `/payment/payment-gateway/create` | `create` | web, auth, verified, tenant |
| POST | `/payment/payment-gateway` | `store` | web, auth, verified, tenant |
| GET | `/payment/payment-gateway/{payment_gateway}` | `show` | web, auth, verified, tenant |
| GET | `/payment/payment-gateway/{payment_gateway}/edit` | `edit` | web, auth, verified, tenant |
| PUT/PATCH | `/payment/payment-gateway/{payment_gateway}` | `update` | web, auth, verified, tenant |
| DELETE | `/payment/payment-gateway/{payment_gateway}` | `destroy` | web, auth, verified, tenant |
| POST | `/payment/payment-gateway/{payment_gateway}/toggle-status` | `toggleStatus` | web, auth, verified, tenant |
| GET | `/payment/payment-gateway/trash/view` | `trashedPaymentGateways` | web, auth, verified, tenant |
| GET | `/payment/payment-gateway/{id}/restore` | `restore` | web, auth, verified, tenant |
| DELETE | `/payment/payment-gateway/{id}/force-delete` | `forceDelete` | web, auth, verified, tenant |

## 14. Messages / Flash Strings

| Flash Key | Context |
|-----------|---------|
| `created.payment_gateway` | Store success |
| `updated.payment_gateway` | Update success |
| `trashed.payment_gateway` | Destroy success |
| `restored.payment_gateway` | Restore success |
| `force_deleted.payment_gateway` | Force delete success |
| `status_updated.payment_gateway` | Toggle success |
| `status_switch_failed.payment_gateway` | Toggle failure |

## 15. Requirements

### MUST Requirements

| # | Requirement |
|---|-------------|
| R1 | The system MUST display a paginated list of all configured payment gateways sorted by priority |
| R2 | The system MUST allow creating a new gateway with name, code, type, driver, credentials, priority, and mode |
| R3 | The system MUST validate that gateway code is unique across all gateways |
| R4 | The system MUST enforce that only one active gateway per type (online/offline) can exist at a time |
| R5 | The system MUST encrypt stored gateway credentials using Laravel's encryption |
| R6 | The system MUST support toggling gateway active/inactive status via AJAX |
| R7 | The system MUST support soft-deleting a gateway (deactivate + move to trash) |
| R8 | The system MUST support restoring a soft-deleted gateway (reactivate + restore) |
| R9 | The system MUST support permanently deleting a gateway via force delete |
| R10 | The system MUST log audit entries for all create, update, toggle, trash, restore, and force-delete actions |
| R11 | The system MUST provide a driver selection dropdown with all 6 available gateway drivers |
| R12 | The system MUST allow administrators to view gateway details including decrypted credential field names |

### SHOULD Requirements

| # | Requirement |
|---|-------------|
| S1 | The system SHOULD display gateway mode (test/live) as a color-coded badge in the list |
| S2 | The system SHOULD paginate the trashed gateway list separately (10 per page) |
| S3 | The system SHOULD show changed fields (old → new) in update audit logs |

### COULD Requirements

| # | Requirement |
|---|-------------|
| C1 | The system COULD support bulk import/export of gateway configurations |
| C2 | The system COULD support gateway connection testing from the edit form |

## 16. Dependencies

| Dependency | Type | Usage |
|------------|------|-------|
| `sys_users` | External (System) | Actor references for audit logging (performed_by) |
| `ptm_payment_gateways` | Self | Foreign key target for payments, refunds, webhooks, reconciliations |
| `nwidart/laravel-modules` | Package | Module structure and route/views registration |
| Laravel `SoftDeletes` | Framework | Soft delete functionality |
| Laravel `encrypted:array` | Framework | Credential encryption cast |
