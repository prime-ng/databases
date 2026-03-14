# 08 — Integrations and External Services

## 1. Razorpay Payment Gateway

**Package:** `razorpay/razorpay` v2.9
**Module:** Payment (`/Modules/Payment/`)

### Architecture

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  StudentFee  │     │   Payment    │     │   Razorpay   │
│   Module     │────►│   Service    │────►│    API       │
│              │     │              │     │              │
│  Fee Invoice │     │ GatewayMgr   │     │ Orders       │
│  Checkout    │     │ RazorpayGW   │     │ Payments     │
│              │     │              │     │ Webhooks     │
└──────────────┘     └──────────────┘     └──────────────┘
```

### Components

| Component | Location | Purpose |
|-----------|----------|---------|
| **PaymentService** | `Services/PaymentService.php` | Business logic: create payment records, initiate gateway transactions |
| **GatewayManager** | `Services/GatewayManager.php` | Resolves gateway drivers (pluggable interface) |
| **RazorpayGateway** | `Gateways/RazorpayGateway.php` | Razorpay API integration (order creation, signature verification) |
| **PaymentController** | `Controllers/PaymentController.php` | Payment processing endpoints |
| **PaymentCallbackController** | `Controllers/PaymentCallbackController.php` | Webhook handling |
| **PaymentGatewayController** | `Controllers/PaymentGatewayController.php` | Gateway configuration CRUD |

### Models

| Model | Table | Purpose |
|-------|-------|---------|
| Payment | `pmt_payments` | Transaction records (amount, currency, status, gateway_id) |
| PaymentGateway | `pmt_payment_gateways` | Gateway configuration (key, secret, mode) |
| PaymentHistory | `pmt_payment_histories` | Transaction history log |
| PaymentRefund | `pmt_payment_refunds` | Refund records |
| PaymentWebhook | `pmt_payment_webhooks` | Webhook event logs |

### Flow

1. Student initiates payment from StudentFee/StudentPortal module
2. `PaymentService.createPayment()` creates `pmt_payments` record
3. `GatewayManager.resolve('razorpay')` instantiates `RazorpayGateway`
4. `RazorpayGateway` creates order via Razorpay API
5. Frontend renders Razorpay checkout (Blade: `razorpay/process-payment.blade.php`)
6. On completion, `PaymentCallbackController` handles webhook
7. Signature verification ensures payment authenticity
8. Payment record updated, fee invoice marked as paid

### Configuration

- API Key & Secret from `.env` variables
- Supports test/live mode switching
- Webhook URL configured in Razorpay dashboard

---

## 2. Email Service

**Package:** Laravel Mail (built-in)
**Configuration:** `/config/mail.php`

### Supported Mailers

| Mailer | Status | Configuration |
|--------|--------|---------------|
| SMTP | Primary | MAIL_HOST, MAIL_PORT, MAIL_USERNAME, MAIL_PASSWORD |
| Sendmail | Available | System sendmail binary |
| Amazon SES | Available | AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY |
| Mailgun | Available | MAILGUN_DOMAIN, MAILGUN_SECRET |
| Log | Dev default | Logs emails to `storage/logs/` |

### Mailable Classes

| Class | Module | Purpose |
|-------|--------|---------|
| `InvoiceMail` | Billing | Invoice email with PDF attachment |
| `VendorInvoiceMail` | Vendor | Vendor invoice notification |
| `LoginMail` | Prime | Login notification email |

### Email Jobs (Queued)

| Job | Module | Purpose |
|-----|--------|---------|
| `SendInvoiceEmailJob` | Billing | Async invoice email with DomPDF attachment |
| `SendVendorInvoiceEmailJob` | Vendor | Async vendor invoice dispatch |
| `SendScheduledEmail` | Prime | Process scheduled email queue |

### Email Templates

Located in module Blade views:
- `/Modules/Billing/resources/views/billing-management/partials/invoicing/email.blade.php`
- Similar templates in Vendor and other modules

---

## 3. PDF Generation (DomPDF)

**Package:** `barryvdh/laravel-dompdf` v3.1

### Usage Locations

| Module | Views | Purpose |
|--------|-------|---------|
| Billing | `consolidated-payment/pdf.blade.php`, `invoice-audit/pdf.blade.php`, `invoice-payment/print.blade.php` | Invoice PDFs, payment reconciliation |
| StudentFee | Fee invoice PDFs, receipt PDFs | Student fee documents |
| Transport | Report PDFs | Transport reports |

### Pattern

```php
use Barryvdh\DomPDF\Facade\Pdf;

$pdf = Pdf::loadView('module::view.path', $data);
return $pdf->download('filename.pdf');
// or
return $pdf->stream('filename.pdf');
```

---

## 4. Excel Import/Export (Maatwebsite)

**Package:** `maatwebsite/excel` v3.1 (PhpSpreadsheet)
**Configuration:** `/config/excel.php`

### Settings

| Setting | Value |
|---------|-------|
| Chunk size | 1000 rows |
| CSV delimiter | `,` |
| CSV enclosure | `"` |
| Temp storage | `storage/framework/cache/laravel-excel` |
| PDF driver | DomPDF |

### Import Classes

| Class | Module | Purpose |
|-------|--------|---------|
| `LessonImport` | Syllabus | Bulk lesson data import |
| `StudentAllocationImport` | Transport | Student-route allocation import |
| `FeeMasterImport` | Transport | Transport fee master import |

### Export Classes

| Class | Module | Purpose |
|-------|--------|---------|
| `StudentAllocationExport` | Transport | Student allocation data export |
| `FeeCollectionExport` | Transport | Fee collection report export |
| `FeeMasterExport` | Transport | Fee master data export |

### Pattern

```php
// Import
Excel::import(new LessonImport, $request->file('file'));

// Export
return Excel::download(new FeeCollectionExport($filters), 'report.xlsx');
```

---

## 5. QR Code Generation

**Package:** `simplesoftwareio/simple-qrcode` v4.2

### Usage

| Module | View | Purpose |
|--------|------|---------|
| Transport | `driver-attendance/qr.blade.php` | Driver attendance QR codes |
| Transport | `studentattendance/index.blade.php` | Student boarding QR codes |
| StudentProfile | `student-settings/index.blade.php` | Student ID QR codes |

### Pattern

```php
{!! QrCode::size(200)->generate($data) !!}
```

---

## 6. Media Library (Spatie)

**Package:** `spatie/laravel-medialibrary` v11.17
**Configuration:** `/config/media-library.php`

### Integration Points

| Model | Usage |
|-------|-------|
| `User` | Profile photos, documents |
| `Student` | Student photos, certificates |
| `Teacher` (TeacherProfile) | Teacher profile photos |
| `Organization` | School logos, branding |
| `Complaint` | Evidence attachments |
| `Vendor` | Vendor documents |
| `Vehicle` (Transport) | Vehicle photos, insurance documents |

### Features

- Media collections for categorization
- Responsive image generation
- Disk-based storage (local, S3-compatible)
- Polymorphic relationship (any model can have media)
- Tenant-isolated file paths: `storage/tenant_{id}/`

---

## 7. Notification System (Multi-Channel)

**Module:** Notification (`/Modules/Notification/`)

### Architecture

```
Event Code → NotificationService → Channel Dispatch
                  │
                  ├── EMAIL → SMTP/SES
                  ├── IN_APP → Database (ntf_delivery_logs)
                  ├── SMS → (Stubbed, not implemented)
                  └── PUSH → (Stubbed, not implemented)
```

### Models

| Model | Table | Purpose |
|-------|-------|---------|
| Notification | `ntf_notifications` | Notification definitions per event |
| NotificationTemplate | `ntf_notification_templates` | Email/SMS templates with variables |
| NotificationChannel | `ntf_notification_channels` | Active channels per notification |
| ChannelMaster | `ntf_channel_masters` | Channel type registry (EMAIL, IN_APP, SMS) |
| ProviderMaster | `ntf_provider_masters` | Provider configuration |
| NotificationTarget | `ntf_notification_targets` | Target audience definition |
| TargetGroup | `ntf_target_groups` | Pre-defined target groups |
| NotificationDeliveryLog | `ntf_notification_delivery_logs` | Delivery tracking |
| UserDevice | `ntf_user_devices` | Push notification device tokens |
| UserPreference | `ntf_user_preferences` | User notification preferences |
| NotificationThread | `ntf_notification_threads` | Conversation threads |
| ResolvedRecipient | `ntf_resolved_recipients` | Resolved recipient list |
| DeliveryQueue | `ntf_delivery_queues` | Outgoing queue |

### Event-Driven Flow

1. Domain event fires `SystemNotificationTriggered`
2. `ProcessSystemNotification` listener (async/queued)
3. `NotificationService::trigger($eventCode, $context)` processes
4. Template rendered with context variables
5. Dispatched to configured channels

---

## 8. Database Backup

**Package:** `spatie/laravel-backup` v9.3
**Configuration:** `/config/backup.php`

### Features

- Full database backup
- File backup (storage directories)
- Configurable backup destinations (local, S3)
- Backup monitoring and notifications
- Cleanup old backups based on retention policy

---

## 9. Activity Logging

**Custom Implementation:** `/app/Helpers/activityLog.php`

### Function Signature

```php
activityLog($subject, string $event, array $properties = [])
```

### Recorded Data

| Field | Description |
|-------|-------------|
| `subject_type` | Model class name |
| `subject_id` | Model ID |
| `user_id` | Acting user ID |
| `event` | Event type (created, updated, deleted, etc.) |
| `properties` | JSON — Additional context data |
| `ip_address` | Client IP |
| `user_agent` | Browser/client info |
| `created_at` | Timestamp |

### Tables

- `sys_activity_logs` (Central) — Prime/admin actions
- `sys_activity_logs` (Tenant) — Per-school actions
- `glb_activity_logs` (Global) — Global reference data changes

---

## 10. Debugging & Monitoring

### Laravel Telescope

**Package:** `laravel/telescope` v5.18

- Request/response profiling
- Database query monitoring
- Queue job tracking
- Exception logging
- Mail previewing
- Notification tracking
- Cache operations

### Laravel Debugbar

**Package:** `barryvdh/laravel-debugbar` v3.16

- Query count and timing
- Memory usage
- Request/response data
- Route information
- View rendering metrics

---

## 11. File Storage

**Configuration:** `/config/filesystems.php`

| Disk | Path | Purpose |
|------|------|---------|
| `local` | `storage/app/private/` | Private file storage |
| `public` | `storage/app/public/` | Publicly accessible files |
| `s3` | AWS S3 bucket | Cloud storage (configured but not primary) |

### Tenant Isolation

Each tenant gets isolated storage:
- `storage/tenant_{uuid}/` — Tenant-specific files
- Configured via Stancl Tenancy filesystem bootstrapper
- Automatic path resolution based on active tenant

---

## Integration Status Summary

| Integration | Status | Package |
|------------|--------|---------|
| Razorpay Payment | Implemented | razorpay/razorpay 2.9 |
| Email (SMTP) | Implemented | Laravel Mail (built-in) |
| PDF Generation | Implemented | barryvdh/laravel-dompdf 3.1 |
| Excel Import/Export | Implemented | maatwebsite/excel 3.1 |
| QR Code Generation | Implemented | simplesoftwareio/simple-qrcode 4.2 |
| Media Library | Implemented | spatie/laravel-medialibrary 11.17 |
| Database Backup | Implemented | spatie/laravel-backup 9.3 |
| Activity Logging | Implemented | Custom helper |
| Notification (Email) | Implemented | Custom module |
| Notification (In-App) | Implemented | Custom module |
| Notification (SMS) | Stubbed | Not implemented |
| Notification (Push) | Stubbed | Not implemented |
| AWS S3 Storage | Configured | Not primary (local storage used) |
| Redis Cache | Configured | Not primary (database cache used) |
