# MNT — Maintenance Management Module
## Complete Development Plan
**Version:** 1.0 | **Date:** 2026-03-27 | **Developer:** Brijesh
**Source:** MNT_FeatureSpec.md + MNT_Maintenance_Requirement.md v2

---

## Section 1 — Controller Inventory (9 Controllers)

### 1.1 Web Controllers

---

#### `MaintenanceController`
**File:** `Modules/Maintenance/app/Http/Controllers/MaintenanceController.php`
**Namespace:** `Modules\Maintenance\app\Http\Controllers`

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `dashboard()` | GET | `/maintenance/dashboard` | `mnt.dashboard` | — | `tenant.mnt-report.view` |
| `calendar()` | GET | `/maintenance/calendar` | `mnt.calendar` | — | `tenant.mnt-report.view` |

**Notes:** `dashboard()` aggregates KPI counts directly from `mnt_tickets`, `mnt_pm_work_orders`, `mnt_amc_contracts`. `calendar()` returns JSON of PM WO due dates, WO scheduled dates, AMC visit dates for the requested month.

---

#### `AssetCategoryController`
**File:** `Modules/Maintenance/app/Http/Controllers/AssetCategoryController.php`
**FR Coverage:** FR-MNT-01

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index()` | GET | `/maintenance/asset-categories` | `mnt.asset-categories.index` | — | `tenant.mnt-asset-category.view` |
| `create()` | GET | `/maintenance/asset-categories/create` | `mnt.asset-categories.create` | — | `tenant.mnt-asset-category.manage` |
| `store()` | POST | `/maintenance/asset-categories` | `mnt.asset-categories.store` | `StoreAssetCategoryRequest` | `tenant.mnt-asset-category.manage` |
| `show()` | GET | `/maintenance/asset-categories/{id}` | `mnt.asset-categories.show` | — | `tenant.mnt-asset-category.view` |
| `edit()` | GET | `/maintenance/asset-categories/{id}/edit` | `mnt.asset-categories.edit` | — | `tenant.mnt-asset-category.manage` |
| `update()` | PUT | `/maintenance/asset-categories/{id}` | `mnt.asset-categories.update` | `StoreAssetCategoryRequest` | `tenant.mnt-asset-category.manage` |
| `destroy()` | DELETE | `/maintenance/asset-categories/{id}` | `mnt.asset-categories.destroy` | — | `tenant.mnt-asset-category.manage` |
| `toggle()` | PATCH | `/maintenance/asset-categories/{id}/toggle` | `mnt.asset-categories.toggle` | — | `tenant.mnt-asset-category.manage` |

---

#### `AssetController`
**File:** `Modules/Maintenance/app/Http/Controllers/AssetController.php`
**FR Coverage:** FR-MNT-02, FR-MNT-03

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index()` | GET | `/maintenance/assets` | `mnt.assets.index` | — | `tenant.mnt-asset.view` |
| `create()` | GET | `/maintenance/assets/create` | `mnt.assets.create` | — | `tenant.mnt-asset.manage` |
| `store()` | POST | `/maintenance/assets` | `mnt.assets.store` | `StoreAssetRequest` | `tenant.mnt-asset.manage` |
| `show()` | GET | `/maintenance/assets/{id}` | `mnt.assets.show` | — | `tenant.mnt-asset.view` |
| `edit()` | GET | `/maintenance/assets/{id}/edit` | `mnt.assets.edit` | — | `tenant.mnt-asset.manage` |
| `update()` | PUT | `/maintenance/assets/{id}` | `mnt.assets.update` | `StoreAssetRequest` | `tenant.mnt-asset.manage` |
| `destroy()` | DELETE | `/maintenance/assets/{id}` | `mnt.assets.destroy` | — | `tenant.mnt-asset.manage` |
| `qrCode()` | GET | `/maintenance/assets/{id}/qr` | `mnt.assets.qr` | — | `tenant.mnt-asset.view` |
| `depreciation()` | GET | `/maintenance/assets/{id}/depreciation` | `mnt.assets.depreciation` | — | `tenant.mnt-asset.view` |
| `storeDepreciation()` | POST | `/maintenance/assets/{id}/depreciation` | `mnt.assets.depreciation.store` | `StoreAssetDepreciationRequest` | `tenant.mnt-asset.manage` |

**Notes:** `store()` triggers QR code generation via `Asset::saved` observer. `qrCode()` returns PNG download from `sys_media`.

---

#### `TicketController`
**File:** `Modules/Maintenance/app/Http/Controllers/TicketController.php`
**FR Coverage:** FR-MNT-04, FR-MNT-05, FR-MNT-06

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index()` | GET | `/maintenance/tickets` | `mnt.tickets.index` | — | `tenant.mnt-ticket.view` |
| `create()` | GET | `/maintenance/tickets/create` | `mnt.tickets.create` | — | `tenant.mnt-ticket.create` |
| `store()` | POST | `/maintenance/tickets` | `mnt.tickets.store` | `StoreTicketRequest` | `tenant.mnt-ticket.create` |
| `show()` | GET | `/maintenance/tickets/{id}` | `mnt.tickets.show` | — | `tenant.mnt-ticket.view` |
| `update()` | PUT | `/maintenance/tickets/{id}` | `mnt.tickets.update` | `StoreTicketRequest` | `tenant.mnt-ticket.update` |
| `updateStatus()` | PATCH | `/maintenance/tickets/{id}/status` | `mnt.tickets.status` | `UpdateTicketStatusRequest` | `tenant.mnt-ticket.update` |
| `updatePriority()` | PATCH | `/maintenance/tickets/{id}/priority` | `mnt.tickets.priority` | `OverridePriorityRequest` | `tenant.mnt-ticket.manage` |
| `assign()` | POST | `/maintenance/tickets/{id}/assign` | `mnt.tickets.assign` | `AssignTicketRequest` | `tenant.mnt-ticket.manage` |
| `storeTimeLog()` | POST | `/maintenance/tickets/{id}/time-log` | `mnt.tickets.time-log` | `StoreTimeLogRequest` | `tenant.mnt-ticket.update` |
| `rate()` | POST | `/maintenance/tickets/{id}/rate` | `mnt.tickets.rate` | — | `tenant.mnt-ticket.create` |

**Notes:** `create()` accepts `?asset_id=` query param for QR scan pre-fill. `store()` calls `TicketService::createTicket()`. `updateStatus()` calls `TicketService::updateStatus()` — FSM enforcement + photo check + breakdown history hook.

---

#### `WorkOrderController`
**File:** `Modules/Maintenance/app/Http/Controllers/WorkOrderController.php`
**FR Coverage:** FR-MNT-09

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index()` | GET | `/maintenance/work-orders` | `mnt.work-orders.index` | — | `tenant.mnt-work-order.manage` |
| `create()` | GET | `/maintenance/work-orders/create` | `mnt.work-orders.create` | — | `tenant.mnt-work-order.manage` |
| `store()` | POST | `/maintenance/work-orders` | `mnt.work-orders.store` | `StoreWorkOrderRequest` | `tenant.mnt-work-order.manage` |
| `show()` | GET | `/maintenance/work-orders/{id}` | `mnt.work-orders.show` | — | `tenant.mnt-work-order.manage` |
| `edit()` | GET | `/maintenance/work-orders/{id}/edit` | `mnt.work-orders.edit` | — | `tenant.mnt-work-order.manage` |
| `update()` | PUT | `/maintenance/work-orders/{id}` | `mnt.work-orders.update` | `StoreWorkOrderRequest` | `tenant.mnt-work-order.manage` |
| `updateStatus()` | PATCH | `/maintenance/work-orders/{id}/status` | `mnt.work-orders.status` | — | `tenant.mnt-work-order.manage` |
| `pdf()` | GET | `/maintenance/work-orders/{id}/pdf` | `mnt.work-orders.pdf` | — | `tenant.mnt-work-order.manage` |

**Notes:** `updateStatus()` on Completed: captures `actual_cost`, triggers `asset.total_maintenance_cost` recalculation (BR-MNT-012), stubs FAC cost posting hook. `pdf()` uses DomPDF with school header/logo.

---

#### `PmScheduleController`
**File:** `Modules/Maintenance/app/Http/Controllers/PmScheduleController.php`
**FR Coverage:** FR-MNT-07

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index()` | GET | `/maintenance/pm-schedules` | `mnt.pm-schedules.index` | — | `tenant.mnt-pm-schedule.manage` |
| `create()` | GET | `/maintenance/pm-schedules/create` | `mnt.pm-schedules.create` | — | `tenant.mnt-pm-schedule.manage` |
| `store()` | POST | `/maintenance/pm-schedules` | `mnt.pm-schedules.store` | `StorePmScheduleRequest` | `tenant.mnt-pm-schedule.manage` |
| `show()` | GET | `/maintenance/pm-schedules/{id}` | `mnt.pm-schedules.show` | — | `tenant.mnt-pm-schedule.manage` |
| `edit()` | GET | `/maintenance/pm-schedules/{id}/edit` | `mnt.pm-schedules.edit` | — | `tenant.mnt-pm-schedule.manage` |
| `update()` | PUT | `/maintenance/pm-schedules/{id}` | `mnt.pm-schedules.update` | `StorePmScheduleRequest` | `tenant.mnt-pm-schedule.manage` |
| `destroy()` | DELETE | `/maintenance/pm-schedules/{id}` | `mnt.pm-schedules.destroy` | — | `tenant.mnt-pm-schedule.manage` |
| `generateNow()` | POST | `/maintenance/pm-schedules/{id}/generate` | `mnt.pm-schedules.generate` | — | `tenant.mnt-pm-schedule.manage` |
| `workOrderIndex()` | GET | `/maintenance/pm-work-orders` | `mnt.pm-work-orders.index` | — | `tenant.mnt-pm-schedule.manage` |
| `workOrderShow()` | GET | `/maintenance/pm-work-orders/{id}` | `mnt.pm-work-orders.show` | — | `tenant.mnt-pm-work-order.update` |
| `updateChecklist()` | PATCH | `/maintenance/pm-work-orders/{id}/checklist` | `mnt.pm-work-orders.checklist` | — | `tenant.mnt-pm-work-order.update` |

---

#### `AmcContractController`
**File:** `Modules/Maintenance/app/Http/Controllers/AmcContractController.php`
**FR Coverage:** FR-MNT-08

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `index()` | GET | `/maintenance/amc-contracts` | `mnt.amc-contracts.index` | — | `tenant.mnt-amc-contract.manage` |
| `create()` | GET | `/maintenance/amc-contracts/create` | `mnt.amc-contracts.create` | — | `tenant.mnt-amc-contract.manage` |
| `store()` | POST | `/maintenance/amc-contracts` | `mnt.amc-contracts.store` | `StoreAmcContractRequest` | `tenant.mnt-amc-contract.manage` |
| `show()` | GET | `/maintenance/amc-contracts/{id}` | `mnt.amc-contracts.show` | — | `tenant.mnt-amc-contract.manage` |
| `edit()` | GET | `/maintenance/amc-contracts/{id}/edit` | `mnt.amc-contracts.edit` | — | `tenant.mnt-amc-contract.manage` |
| `update()` | PUT | `/maintenance/amc-contracts/{id}` | `mnt.amc-contracts.update` | `StoreAmcContractRequest` | `tenant.mnt-amc-contract.manage` |
| `destroy()` | DELETE | `/maintenance/amc-contracts/{id}` | `mnt.amc-contracts.destroy` | — | `tenant.mnt-amc-contract.manage` |
| `renew()` | PATCH | `/maintenance/amc-contracts/{id}/renew` | `mnt.amc-contracts.renew` | — | `tenant.mnt-amc-contract.manage` |

**Notes:** `renew()` creates new contract record, resets `renewal_alert_sent_*` flags, updates previous contract status to `Pending_Renewal`.

---

#### `MaintenanceReportController`
**File:** `Modules/Maintenance/app/Http/Controllers/MaintenanceReportController.php`
**FR Coverage:** FR-MNT-11

| Method | HTTP | URI | Route Name | FormRequest | Permission |
|---|---|---|---|---|---|
| `ticketSummary()` | GET | `/maintenance/reports/ticket-summary` | `mnt.reports.ticket-summary` | — | `tenant.mnt-report.view` |
| `sla()` | GET | `/maintenance/reports/sla` | `mnt.reports.sla` | — | `tenant.mnt-report.view` |
| `technician()` | GET | `/maintenance/reports/technician` | `mnt.reports.technician` | — | `tenant.mnt-report.view` |
| `assetHistory()` | GET | `/maintenance/reports/asset-history` | `mnt.reports.asset-history` | — | `tenant.mnt-report.view` |
| `pmCompliance()` | GET | `/maintenance/reports/pm-compliance` | `mnt.reports.pm-compliance` | — | `tenant.mnt-report.view` |

**Notes:** All reports support `?export=csv` query param for CSV download via `fputcsv()` to `php://temp`.

---

### 1.2 Mobile API Controller

#### `MobileMaintenanceController`
**File:** `Modules/Maintenance/app/Http/Controllers/Api/MobileMaintenanceController.php`
**Namespace:** `Modules\Maintenance\app\Http\Controllers\Api`
**Middleware:** `auth:sanctum`
**FR Coverage:** FR-MNT-04, FR-MNT-06, FR-MNT-07 (mobile surfaces)

| Method | HTTP | URI | Route Name | Description |
|---|---|---|---|---|
| `myTickets()` | GET | `/api/v1/maintenance/tickets` | `api.mnt.tickets` | Technician's assigned open tickets; paginated 20; select() essential fields only |
| `ticketDetail()` | GET | `/api/v1/maintenance/tickets/{id}` | `api.mnt.tickets.show` | Full ticket detail with checklist (PM WO context) |
| `updateStatus()` | PATCH | `/api/v1/maintenance/tickets/{id}/status` | `api.mnt.tickets.status` | Update ticket status from mobile; calls `TicketService::updateStatus()` |
| `addTimeLog()` | POST | `/api/v1/maintenance/tickets/{id}/time-log` | `api.mnt.tickets.time-log` | Log work time from mobile field |
| `uploadPhotos()` | POST | `/api/v1/maintenance/tickets/{id}/photos` | `api.mnt.tickets.photos` | Upload before/after photos; stored to `sys_media` |
| `myPmWorkOrders()` | GET | `/api/v1/maintenance/pm-work-orders` | `api.mnt.pm-work-orders` | Technician's PM WOs (Pending/In_Progress); paginated 20 |
| `updateChecklist()` | PATCH | `/api/v1/maintenance/pm-work-orders/{id}/checklist` | `api.mnt.pm-work-orders.checklist` | Update checklist item completion from mobile |
| `qrLookup()` | GET | `/api/v1/maintenance/assets/qr-lookup` | `api.mnt.assets.qr-lookup` | Look up asset by `?asset_code=MNT-AST-XXXXXX` after QR scan |
| `quickCreate()` | POST | `/api/v1/maintenance/tickets/quick-create` | `api.mnt.tickets.quick-create` | Create ticket from mobile QR scan flow |

**Response format (all endpoints):**
```json
{ "success": true, "data": { ... } }
{ "success": false, "message": "...", "errors": { ... } }
```

---

## Section 2 — Service Inventory (5 Services)

### 2.1 TicketService

```
File:        Modules/Maintenance/app/Services/TicketService.php
Namespace:   Modules\Maintenance\app\Services
Inject:      AssignmentService $assignmentService, EscalationService $escalationService
Fires:       Notification (assignment, status-change), sys_activity_logs writes
```

| Method | Signature | Description |
|---|---|---|
| `createTicket` | `createTicket(array $data, User $requester): Ticket` | 10-step ticket creation with keyword priority, SLA calc, lock-for-update number, auto-assign |
| `updateStatus` | `updateStatus(Ticket $ticket, string $newStatus, array $data, User $actor): Ticket` | FSM transition with photo enforcement, breakdown history hook, cost rollup |
| `manualAssign` | `manualAssign(Ticket $ticket, User $technician, string $reason, User $actor): void` | Reassign ticket; mark previous assignment released; notify technician |
| `overridePriority` | `overridePriority(Ticket $ticket, string $priority, string $reason, User $actor): void` | Admin priority override; logs to sys_activity_logs; re-triggers assign if Critical |
| `storeTimeLog` | `storeTimeLog(Ticket $ticket, array $data, User $technician): TicketTimeLog` | Create time log entry; recalculate ticket totals |
| `rate` | `rate(Ticket $ticket, int $rating, ?string $feedback, User $requester): void` | Store requester rating (1–5) and optional feedback on Closed ticket |
| `resolvePriority` | `resolvePriority(string $description, AssetCategory $category): array` | Case-insensitive keyword scan; returns `['priority'=>'High','source'=>'Auto_Keyword']` |
| `recalculateAssetCost` | `recalculateAssetCost(Asset $asset): void` | SUM ticket parts_cost + WO actual_cost → update asset.total_maintenance_cost (BR-MNT-012) |

**createTicket() — 10-Step Pseudocode:**
```
createTicket(array $data, User $requester): Ticket
  Step 1:  DB::beginTransaction()
  Step 2:  $category = AssetCategory::findOrFail($data['category_id'])
           resolvePriority($data['description'], $category)
           → Case-insensitive LIKE scan against priority_keywords_json
           → Critical > High > Medium > Low → fallback: category.default_priority
           → Sets $priority, $priority_source
  Step 3:  $timezone = sys_settings('timezone', 'Asia/Kolkata')
           $sla_due_at = Carbon::now($timezone)->addHours($category->sla_hours)
  Step 4:  DB::table('mnt_tickets')->lockForUpdate()
           $seq = DB::table('mnt_tickets')->max('id') + 1  // or a counter table
           $ticket_number = 'MNT-' . now()->year . '-' . str_pad($seq, 8, '0', STR_PAD_LEFT)
  Step 5:  INSERT mnt_tickets (status='Open', priority, priority_source, sla_due_at,
                               requester_user_id, requested_date=today, ...)
  Step 6:  DB::commit()
  Step 7:  AssignmentService::autoAssign($ticket) — runs OUTSIDE transaction
  Step 8:  If $assignedUser:
           → INSERT mnt_ticket_assignments (is_current=1, type='Auto', assigned_at=now())
           → UPDATE ticket.assigned_to_user_id = $assignedUser->id
           → Dispatch NTF: 'New ticket: {title} — {location} — Priority: {level}'
  Step 9:  If unassigned ($assignedUser === null):
           → Dispatch NTF to Maintenance Incharge: 'Unassigned ticket requires manual routing'
  Step 10: Log to sys_activity_logs (event='ticket.created', subject_type=Ticket, subject_id,
                                     properties=JSON{category,priority,sla_due_at})
```

---

### 2.2 AssignmentService

```
File:        Modules/Maintenance/app/Services/AssignmentService.php
Namespace:   Modules\Maintenance\app\Services
Inject:      (none)
Fires:       (delegates NTF dispatch to TicketService caller)
```

| Method | Signature | Description |
|---|---|---|
| `autoAssign` | `autoAssign(Ticket $ticket): ?User` | Filter by role; score by open ticket count + location bonus; return best candidate or null |
| `autoAssignPmWo` | `autoAssignPmWo(PmSchedule $schedule): ?User` | Filter by schedule.assign_to_role_id; score by open PM WO count |
| `getWorkloadByRole` | `getWorkloadByRole(int $roleId): Collection` | Return technicians in role with open_ticket_count for dashboard display |

---

### 2.3 PmScheduleService

```
File:        Modules/Maintenance/app/Services/PmScheduleService.php
Namespace:   Modules\Maintenance\app\Services
Inject:      AssignmentService $assignmentService
Fires:       Notification (PM WO assignment), sys_activity_logs
```

| Method | Signature | Description |
|---|---|---|
| `generateWorkOrders` | `generateWorkOrders(?Carbon $date = null): int` | Daily batch: query due schedules, skip duplicates (BR-MNT-006), create WOs, advance next_due_date |
| `completeWorkOrder` | `completeWorkOrder(PmWorkOrder $wo, array $checklistData): void` | Validate all items done; update WO; update asset last_pm_date + condition; advance next_due_date |
| `markOverdue` | `markOverdue(): int` | Batch UPDATE Pending/In_Progress WOs past due_date → Overdue; returns count (BR-MNT-013) |
| `advanceNextDueDate` | `advanceNextDueDate(PmSchedule $schedule): void` | Calculate and set new next_due_date based on recurrence |

**generateWorkOrders() — Pseudocode:**
```
generateWorkOrders(?Carbon $date = null): int
  $date = $date ?? Carbon::today()
  $count = 0

  Step 1: $dueSchedules = PmSchedule::active()
                          ->where('next_due_date', '<=', $date)
                          ->get()

  Step 2: foreach $schedule in $dueSchedules:
    Step 2a: $existingWo = PmWorkOrder::where('pm_schedule_id', $schedule->id)
                           ->whereIn('status', ['Pending', 'In_Progress'])
                           ->exists()
             If $existingWo → continue (BR-MNT-006: skip this schedule)

    Step 2b: DB::beginTransaction()

    Step 2c: $assignedUser = AssignmentService::autoAssignPmWo($schedule)

    Step 2d: INSERT mnt_pm_work_orders (
               pm_schedule_id, asset_id=$schedule->asset_id,
               due_date=$schedule->next_due_date,
               status='Pending',
               assigned_to_user_id=$assignedUser?->id
             )

    Step 2e: advanceNextDueDate($schedule)
             UPDATE pm_schedules.last_generated_at = now()

    Step 2f: DB::commit()
             $count++

    Step 2g: If $assignedUser → Dispatch NTF: 'PM Work Order assigned: {title} due {due_date}'
             Else → Dispatch NTF to Maintenance Incharge: 'PM WO needs manual assignment'

  Step 3: return $count
```

---

### 2.4 EscalationService

```
File:        Modules/Maintenance/app/Services/EscalationService.php
Namespace:   Modules\Maintenance\app\Services
Inject:      (none)
Fires:       Notification (L1 to Maint Incharge, L2 to Principal), sys_activity_logs
```

| Method | Signature | Description |
|---|---|---|
| `checkEscalations` | `checkEscalations(Ticket $ticket): void` | Read sla_escalation_json; fire L1/L2 notifications based on ticket age (BR-MNT-011) |

**checkEscalations() — Pseudocode:**
```
checkEscalations(Ticket $ticket): void
  Step 1: $config = $ticket->category->sla_escalation_json
          If $config is NULL → return (no escalation configured for this category)

  Step 2: $ticket_age_hours = Carbon::now()->diffInHours($ticket->created_at)

  Step 3: If isset($config['L2'])
          AND $ticket_age_hours > $config['L2']['after_hours']
          AND $ticket->escalation_level < 2:
           → $role = $config['L2']['notify_role']  // e.g. 'principal'
           → Dispatch NTF to sys_users with role name = $role:
             'Critical escalation (L2): Ticket {number} is {X} hours overdue'
           → UPDATE ticket.escalation_level = 2
           → Log to sys_activity_logs (event='ticket.escalated',
                                       properties={level:2, after_hours: $ticket_age_hours})
           → return  (L2 subsumes L1 — do not fire L1 if L2 already triggered)

  Step 4: If isset($config['L1'])
          AND $ticket_age_hours > $config['L1']['after_hours']
          AND $ticket->escalation_level < 1:
           → $role = $config['L1']['notify_role']
           → Dispatch NTF to sys_users with role name = $role:
             'SLA breach escalated (L1): Ticket {number} is {X} hours overdue'
           → UPDATE ticket.escalation_level = 1
           → Log to sys_activity_logs (event='ticket.escalated',
                                       properties={level:1, after_hours: $ticket_age_hours})
```

---

### 2.5 DepreciationService

```
File:        Modules/Maintenance/app/Services/DepreciationService.php
Namespace:   Modules\Maintenance\app\Services
Inject:      (none)
Fires:       FAC hook scaffold log to sys_activity_logs
```

| Method | Signature | Description |
|---|---|---|
| `calculateSLM` | `calculateSLM(Asset $asset, string $financialYear): AssetDepreciation` | SLM: annual_charge = (cost−salvage)/useful_life; validates UNIQUE (BR-MNT-016) |
| `calculateWDV` | `calculateWDV(Asset $asset, string $financialYear): AssetDepreciation` | WDV: annual_charge = opening_book_value × rate/100; validates UNIQUE (BR-MNT-016) |
| `recalculateBookValue` | `recalculateBookValue(Asset $asset): void` | SUM all annual_charge → update accumulated_depreciation + current_book_value |

---

## Section 3 — FormRequest Inventory (11 FormRequests)

**Namespace:** `Modules\Maintenance\app\Http\Requests`
**Base:** `Illuminate\Foundation\Http\FormRequest`

| # | Class | Controller Method | Key Validation Rules |
|---|---|---|---|
| 1 | `StoreAssetCategoryRequest` | `AssetCategoryController@store/update` | `name` required\|string\|max:100\|unique:mnt_asset_categories,name,{id}, `code` nullable\|string\|max:20\|unique:mnt_asset_categories, `default_priority` required\|in:Low,Medium,High,Critical, `sla_hours` required\|integer\|min:1\|max:8760, `auto_assign_role_id` nullable\|exists:sys_roles,id, `priority_keywords_json` nullable\|json |
| 2 | `StoreAssetRequest` | `AssetController@store/update` | `name` required\|string\|max:150, `category_id` required\|exists:mnt_asset_categories,id, `location_building` nullable\|string\|max:100, `purchase_date` nullable\|date, `purchase_cost` nullable\|numeric\|min:0, `depreciation_method` nullable\|in:SLM,WDV, `useful_life_years` nullable\|integer\|min:1\|max:50\|required_if:depreciation_method,SLM, `salvage_value` nullable\|numeric\|min:0\|required_if:depreciation_method,SLM, `depreciation_rate` nullable\|numeric\|min:0\|max:100\|required_if:depreciation_method,WDV |
| 3 | `StoreTicketRequest` | `TicketController@store/update` | `title` required\|string\|max:200, `category_id` required\|exists:mnt_asset_categories,id, `description` required\|string\|min:20, `location_building` required\|string\|max:100, `asset_id` nullable\|exists:mnt_assets,id |
| 4 | `UpdateTicketStatusRequest` | `TicketController@updateStatus` | `status` required\|in:Open,Accepted,In_Progress,On_Hold,Resolved,Closed,Cancelled, `resolution_notes` required_if:status,Resolved\|min:20 (BR-MNT-004), `before_photos` required_if:status,In_Progress (when `sys_settings.mnt_require_photos=1`), `after_photos` required_if:status,Resolved (when `sys_settings.mnt_require_photos=1`) |
| 5 | `AssignTicketRequest` | `TicketController@assign` | `user_id` required\|exists:sys_users,id, `reason` nullable\|string\|max:500 |
| 6 | `OverridePriorityRequest` | `TicketController@updatePriority` | `priority` required\|in:Low,Medium,High,Critical, `override_reason` required\|string\|min:10\|max:500 |
| 7 | `StoreTimeLogRequest` | `TicketController@storeTimeLog` | `work_date` required\|date\|before_or_equal:today, `start_time` required\|date_format:H:i, `end_time` required\|date_format:H:i\|after:start_time, `hours_spent` required\|numeric\|min:0.25\|max:24, `parts_used` nullable\|string, `parts_cost` nullable\|numeric\|min:0 |
| 8 | `StorePmScheduleRequest` | `PmScheduleController@store/update` | `asset_id` required\|exists:mnt_assets,id, `title` required\|string\|max:200, `recurrence` required\|in:Daily,Weekly,Monthly,Quarterly,Yearly, `checklist_items_json` required\|json\|array\|min:1, `checklist_items_json.*` required\|string\|min:3, `start_date` required\|date, `assign_to_role_id` nullable\|exists:sys_roles,id, `estimated_hours` nullable\|numeric\|min:0.5 |
| 9 | `StoreAmcContractRequest` | `AmcContractController@store/update` | `contract_title` required\|string\|max:200, `start_date` required\|date, `end_date` required\|date\|after:start_date, `contract_value` nullable\|numeric\|min:0, `vendor_id` nullable\|exists:vnd_vendors,id, `payment_frequency` nullable\|in:Monthly,Quarterly,Half_Yearly,Yearly |
| 10 | `StoreWorkOrderRequest` | `WorkOrderController@store/update` | `work_description` required\|string\|min:20, `scheduled_date` nullable\|date, `estimated_cost` nullable\|numeric\|min:0, `vendor_id` nullable\|exists:vnd_vendors,id, `ticket_id` nullable\|exists:mnt_tickets,id, `amc_contract_id` nullable\|exists:mnt_amc_contracts,id |
| 11 | `StoreAssetDepreciationRequest` | `AssetController@storeDepreciation` | `financial_year` required\|regex:/^\d{4}-\d{4}$/, `method` required\|in:SLM,WDV, `opening_book_value` required\|numeric\|min:0, `depreciation_rate` required\|numeric\|min:0\|max:100, custom rule: unique (asset_id + financial_year) → 422 if exists (BR-MNT-016) |

---

## Section 4 — Blade View Inventory (~35 Views)

**Base path:** `Modules/Maintenance/resources/views/`
**Layout:** `layouts.tenant` (AdminLTE 4 + Bootstrap 5)

### Dashboard & Calendar

| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `dashboard.blade.php` | `mnt.dashboard` | `MaintenanceController@dashboard` | KPI cards: open tickets by priority, SLA breached count, resolved today, PM WOs due this week, AMC expiring 60 days, technician workload bar chart (Alpine.js) |
| `calendar.blade.php` | `mnt.calendar` | `MaintenanceController@calendar` | Monthly calendar with PM WO due dates, vendor WO dates, AMC visit dates as colour-coded events; click through to detail |

### Asset Categories

| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `asset-categories/index.blade.php` | `mnt.asset-categories.index` | `AssetCategoryController@index` | Table list with SLA hours, default priority, keyword rule count, active/inactive toggle |
| `asset-categories/form.blade.php` | `mnt.asset-categories.create/edit` | `AssetCategoryController@create/edit` | Name, code, default priority, SLA hours, JSON keyword rules editor, escalation level builder |

### Assets

| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `assets/index.blade.php` | `mnt.assets.index` | `AssetController@index` | Filterable list by category, condition, location; QR code download button per row |
| `assets/show.blade.php` | `mnt.assets.show` | `AssetController@show` | Asset detail with 4 tabs: Overview, Breakdown History (mnt_breakdown_history), PM History (mnt_pm_work_orders), Cost Summary (total_maintenance_cost breakdown) |
| `assets/form.blade.php` | `mnt.assets.create/edit` | `AssetController@create/edit` | All asset fields + conditional depreciation section (SLM/WDV) |

### Tickets

| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `tickets/index.blade.php` | `mnt.tickets.index` | `TicketController@index` | Filterable list: status, priority, category, technician, date; SLA breached rows highlighted red |
| `tickets/create.blade.php` | `mnt.tickets.create` | `TicketController@create` | Category select → keyword hint; location fields; asset lookup (QR prefill via `?asset_id=`); photo upload (up to 5) |
| `tickets/show.blade.php` | `mnt.tickets.show` | `TicketController@show` | Full detail: status timeline, assignment history, time logs tab, before/after photos tab, rating widget (on Closed) |
| `tickets/_status_modal.blade.php` | — | — | Inline modal: status dropdown, resolution notes (required on Resolved), photo upload |

### PM Schedules

| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `pm-schedules/index.blade.php` | `mnt.pm-schedules.index` | `PmScheduleController@index` | List with asset name, recurrence, next due date, last generated date |
| `pm-schedules/form.blade.php` | `mnt.pm-schedules.create/edit` | `PmScheduleController@create/edit` | Asset select, recurrence settings, checklist builder (add/remove rows dynamically via Alpine.js) |

### PM Work Orders

| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `pm-work-orders/index.blade.php` | `mnt.pm-work-orders.index` | `PmScheduleController@workOrderIndex` | Filterable list: status, asset, date; Overdue rows highlighted |
| `pm-work-orders/show.blade.php` | `mnt.pm-work-orders.show` | `PmScheduleController@workOrderShow` | Checklist with completion checkboxes + notes per item; hours spent entry; Completed button enabled when all items checked |

### AMC Contracts

| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `amc-contracts/index.blade.php` | `mnt.amc-contracts.index` | `AmcContractController@index` | List with expiry date, days-remaining badge (yellow <30, red <7), covered assets |
| `amc-contracts/form.blade.php` | `mnt.amc-contracts.create/edit` | `AmcContractController@create/edit` | Vendor fields, date range, covered assets multi-select, document upload |

### Work Orders

| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `work-orders/index.blade.php` | `mnt.work-orders.index` | `WorkOrderController@index` | Vendor WO list filterable by status, vendor, date |
| `work-orders/form.blade.php` | `mnt.work-orders.create/edit` | `WorkOrderController@create/edit` | Link to source ticket/AMC, vendor fields, cost fields, scheduled date |
| `work-orders/show.blade.php` | `mnt.work-orders.show` | `WorkOrderController@show` | Full WO detail with PDF print button |

### Reports

| View File | Route Name | Controller Method | Description |
|---|---|---|---|
| `reports/ticket-summary.blade.php` | `mnt.reports.ticket-summary` | `MaintenanceReportController@ticketSummary` | Date-range bar charts + table by category/priority/status; CSV export |
| `reports/sla.blade.php` | `mnt.reports.sla` | `MaintenanceReportController@sla` | % within SLA; avg resolution time by category; breach trend chart |
| `reports/technician.blade.php` | `mnt.reports.technician` | `MaintenanceReportController@technician` | Per-technician: assigned, resolved, avg resolution time, hours logged |
| `reports/asset-history.blade.php` | `mnt.reports.asset-history` | `MaintenanceReportController@assetHistory` | Asset selector → chronological event timeline + total cost |
| `reports/pm-compliance.blade.php` | `mnt.reports.pm-compliance` | `MaintenanceReportController@pmCompliance` | Scheduled vs completed vs overdue per asset per period |

### Shared Partials

| Partial | Usage |
|---|---|
| `_partials/pagination.blade.php` | Common pagination across all list views |
| `_partials/status-badge.blade.php` | Ticket/WO status badge with colour coding |
| `_partials/priority-badge.blade.php` | Priority badge: Critical=red, High=orange, Medium=yellow, Low=green |
| `_partials/sla-highlight.blade.php` | Row highlight logic for SLA breached tickets |
| `_partials/ticket-timeline.blade.php` | Status transition timeline for ticket detail view |

---

## Section 5 — Complete Route List

### 5.1 Web Routes
**Middleware:** `['auth', 'verified', 'tenant', 'EnsureTenantHasModule:Maintenance']`
**File:** `Modules/Maintenance/routes/web.php`

| # | Method | URI | Route Name | Controller@Method | FR |
|---|---|---|---|---|---|
| 1 | GET | `/maintenance/dashboard` | `mnt.dashboard` | `MaintenanceController@dashboard` | MNT-11 |
| 2 | GET | `/maintenance/calendar` | `mnt.calendar` | `MaintenanceController@calendar` | MNT-10 |
| 3 | GET | `/maintenance/asset-categories` | `mnt.asset-categories.index` | `AssetCategoryController@index` | MNT-01 |
| 4 | GET | `/maintenance/asset-categories/create` | `mnt.asset-categories.create` | `AssetCategoryController@create` | MNT-01 |
| 5 | POST | `/maintenance/asset-categories` | `mnt.asset-categories.store` | `AssetCategoryController@store` | MNT-01 |
| 6 | GET | `/maintenance/asset-categories/{id}` | `mnt.asset-categories.show` | `AssetCategoryController@show` | MNT-01 |
| 7 | GET | `/maintenance/asset-categories/{id}/edit` | `mnt.asset-categories.edit` | `AssetCategoryController@edit` | MNT-01 |
| 8 | PUT | `/maintenance/asset-categories/{id}` | `mnt.asset-categories.update` | `AssetCategoryController@update` | MNT-01 |
| 9 | DELETE | `/maintenance/asset-categories/{id}` | `mnt.asset-categories.destroy` | `AssetCategoryController@destroy` | MNT-01 |
| 10 | PATCH | `/maintenance/asset-categories/{id}/toggle` | `mnt.asset-categories.toggle` | `AssetCategoryController@toggle` | MNT-01 |
| 11 | GET | `/maintenance/assets` | `mnt.assets.index` | `AssetController@index` | MNT-02 |
| 12 | GET | `/maintenance/assets/create` | `mnt.assets.create` | `AssetController@create` | MNT-02 |
| 13 | POST | `/maintenance/assets` | `mnt.assets.store` | `AssetController@store` | MNT-02 |
| 14 | GET | `/maintenance/assets/{id}` | `mnt.assets.show` | `AssetController@show` | MNT-02 |
| 15 | GET | `/maintenance/assets/{id}/edit` | `mnt.assets.edit` | `AssetController@edit` | MNT-02 |
| 16 | PUT | `/maintenance/assets/{id}` | `mnt.assets.update` | `AssetController@update` | MNT-02 |
| 17 | DELETE | `/maintenance/assets/{id}` | `mnt.assets.destroy` | `AssetController@destroy` | MNT-02 |
| 18 | GET | `/maintenance/assets/{id}/qr` | `mnt.assets.qr` | `AssetController@qrCode` | MNT-02 |
| 19 | GET | `/maintenance/assets/{id}/depreciation` | `mnt.assets.depreciation` | `AssetController@depreciation` | MNT-03 |
| 20 | POST | `/maintenance/assets/{id}/depreciation` | `mnt.assets.depreciation.store` | `AssetController@storeDepreciation` | MNT-03 |
| 21 | GET | `/maintenance/tickets` | `mnt.tickets.index` | `TicketController@index` | MNT-04 |
| 22 | GET | `/maintenance/tickets/create` | `mnt.tickets.create` | `TicketController@create` | MNT-04 |
| 23 | POST | `/maintenance/tickets` | `mnt.tickets.store` | `TicketController@store` | MNT-04 |
| 24 | GET | `/maintenance/tickets/{id}` | `mnt.tickets.show` | `TicketController@show` | MNT-04 |
| 25 | PUT | `/maintenance/tickets/{id}` | `mnt.tickets.update` | `TicketController@update` | MNT-04 |
| 26 | PATCH | `/maintenance/tickets/{id}/status` | `mnt.tickets.status` | `TicketController@updateStatus` | MNT-06 |
| 27 | PATCH | `/maintenance/tickets/{id}/priority` | `mnt.tickets.priority` | `TicketController@updatePriority` | MNT-04 |
| 28 | POST | `/maintenance/tickets/{id}/assign` | `mnt.tickets.assign` | `TicketController@assign` | MNT-05 |
| 29 | POST | `/maintenance/tickets/{id}/time-log` | `mnt.tickets.time-log` | `TicketController@storeTimeLog` | MNT-06 |
| 30 | POST | `/maintenance/tickets/{id}/rate` | `mnt.tickets.rate` | `TicketController@rate` | MNT-06 |
| 31 | GET | `/maintenance/work-orders` | `mnt.work-orders.index` | `WorkOrderController@index` | MNT-09 |
| 32 | GET | `/maintenance/work-orders/create` | `mnt.work-orders.create` | `WorkOrderController@create` | MNT-09 |
| 33 | POST | `/maintenance/work-orders` | `mnt.work-orders.store` | `WorkOrderController@store` | MNT-09 |
| 34 | GET | `/maintenance/work-orders/{id}` | `mnt.work-orders.show` | `WorkOrderController@show` | MNT-09 |
| 35 | GET | `/maintenance/work-orders/{id}/edit` | `mnt.work-orders.edit` | `WorkOrderController@edit` | MNT-09 |
| 36 | PUT | `/maintenance/work-orders/{id}` | `mnt.work-orders.update` | `WorkOrderController@update` | MNT-09 |
| 37 | PATCH | `/maintenance/work-orders/{id}/status` | `mnt.work-orders.status` | `WorkOrderController@updateStatus` | MNT-09 |
| 38 | GET | `/maintenance/work-orders/{id}/pdf` | `mnt.work-orders.pdf` | `WorkOrderController@pdf` | MNT-09 |
| 39 | GET | `/maintenance/pm-schedules` | `mnt.pm-schedules.index` | `PmScheduleController@index` | MNT-07 |
| 40 | GET | `/maintenance/pm-schedules/create` | `mnt.pm-schedules.create` | `PmScheduleController@create` | MNT-07 |
| 41 | POST | `/maintenance/pm-schedules` | `mnt.pm-schedules.store` | `PmScheduleController@store` | MNT-07 |
| 42 | GET | `/maintenance/pm-schedules/{id}` | `mnt.pm-schedules.show` | `PmScheduleController@show` | MNT-07 |
| 43 | GET | `/maintenance/pm-schedules/{id}/edit` | `mnt.pm-schedules.edit` | `PmScheduleController@edit` | MNT-07 |
| 44 | PUT | `/maintenance/pm-schedules/{id}` | `mnt.pm-schedules.update` | `PmScheduleController@update` | MNT-07 |
| 45 | DELETE | `/maintenance/pm-schedules/{id}` | `mnt.pm-schedules.destroy` | `PmScheduleController@destroy` | MNT-07 |
| 46 | POST | `/maintenance/pm-schedules/{id}/generate` | `mnt.pm-schedules.generate` | `PmScheduleController@generateNow` | MNT-07 |
| 47 | GET | `/maintenance/pm-work-orders` | `mnt.pm-work-orders.index` | `PmScheduleController@workOrderIndex` | MNT-07 |
| 48 | GET | `/maintenance/pm-work-orders/{id}` | `mnt.pm-work-orders.show` | `PmScheduleController@workOrderShow` | MNT-07 |
| 49 | PATCH | `/maintenance/pm-work-orders/{id}/checklist` | `mnt.pm-work-orders.checklist` | `PmScheduleController@updateChecklist` | MNT-07 |
| 50 | GET | `/maintenance/amc-contracts` | `mnt.amc-contracts.index` | `AmcContractController@index` | MNT-08 |
| 51 | GET | `/maintenance/amc-contracts/create` | `mnt.amc-contracts.create` | `AmcContractController@create` | MNT-08 |
| 52 | POST | `/maintenance/amc-contracts` | `mnt.amc-contracts.store` | `AmcContractController@store` | MNT-08 |
| 53 | GET | `/maintenance/amc-contracts/{id}` | `mnt.amc-contracts.show` | `AmcContractController@show` | MNT-08 |
| 54 | GET | `/maintenance/amc-contracts/{id}/edit` | `mnt.amc-contracts.edit` | `AmcContractController@edit` | MNT-08 |
| 55 | PUT | `/maintenance/amc-contracts/{id}` | `mnt.amc-contracts.update` | `AmcContractController@update` | MNT-08 |
| 56 | DELETE | `/maintenance/amc-contracts/{id}` | `mnt.amc-contracts.destroy` | `AmcContractController@destroy` | MNT-08 |
| 57 | PATCH | `/maintenance/amc-contracts/{id}/renew` | `mnt.amc-contracts.renew` | `AmcContractController@renew` | MNT-08 |
| 58 | GET | `/maintenance/reports/ticket-summary` | `mnt.reports.ticket-summary` | `MaintenanceReportController@ticketSummary` | MNT-11 |
| 59 | GET | `/maintenance/reports/sla` | `mnt.reports.sla` | `MaintenanceReportController@sla` | MNT-11 |
| 60 | GET | `/maintenance/reports/technician` | `mnt.reports.technician` | `MaintenanceReportController@technician` | MNT-11 |
| 61 | GET | `/maintenance/reports/asset-history` | `mnt.reports.asset-history` | `MaintenanceReportController@assetHistory` | MNT-11 |
| 62 | GET | `/maintenance/reports/pm-compliance` | `mnt.reports.pm-compliance` | `MaintenanceReportController@pmCompliance` | MNT-11 |

**Web Routes Total: 62**

---

### 5.2 Mobile API Routes
**Middleware:** `['auth:sanctum', 'tenant', 'EnsureTenantHasModule:Maintenance']`
**File:** `Modules/Maintenance/routes/api.php` — prefix `/api/v1/maintenance`

| # | Method | URI | Route Name | Controller@Method | FR |
|---|---|---|---|---|---|
| 63 | GET | `/api/v1/maintenance/tickets` | `api.mnt.tickets` | `MobileMaintenanceController@myTickets` | MNT-04 |
| 64 | GET | `/api/v1/maintenance/tickets/{id}` | `api.mnt.tickets.show` | `MobileMaintenanceController@ticketDetail` | MNT-04 |
| 65 | PATCH | `/api/v1/maintenance/tickets/{id}/status` | `api.mnt.tickets.status` | `MobileMaintenanceController@updateStatus` | MNT-06 |
| 66 | POST | `/api/v1/maintenance/tickets/{id}/time-log` | `api.mnt.tickets.time-log` | `MobileMaintenanceController@addTimeLog` | MNT-06 |
| 67 | POST | `/api/v1/maintenance/tickets/{id}/photos` | `api.mnt.tickets.photos` | `MobileMaintenanceController@uploadPhotos` | MNT-06 |
| 68 | GET | `/api/v1/maintenance/pm-work-orders` | `api.mnt.pm-work-orders` | `MobileMaintenanceController@myPmWorkOrders` | MNT-07 |
| 69 | PATCH | `/api/v1/maintenance/pm-work-orders/{id}/checklist` | `api.mnt.pm-work-orders.checklist` | `MobileMaintenanceController@updateChecklist` | MNT-07 |
| 70 | GET | `/api/v1/maintenance/assets/qr-lookup` | `api.mnt.assets.qr-lookup` | `MobileMaintenanceController@qrLookup` | MNT-02 |
| 71 | POST | `/api/v1/maintenance/tickets/quick-create` | `api.mnt.tickets.quick-create` | `MobileMaintenanceController@quickCreate` | MNT-04 |

**Mobile API Routes Total: 9**

**Grand Total: 71 routes**

---

## Section 6 — Implementation Phases (11 Phases)

---

### Phase 1 — Foundation: Migrations, Models, Module Scaffold

**FRs Covered:** All (schema foundation)
**Priority:** Critical

**Files to Create:**
- `database/migrations/tenant/2026_03_27_000000_create_mnt_tables.php` (from MNT_Migration.php)
- 11 Eloquent Models (all in `Modules/Maintenance/app/Models/`):
  - `AssetCategory.php` — `$fillable`, `$casts` (JSON columns), `tickets()`, `assets()`, `pmSchedules()`
  - `Asset.php` — `$fillable`, `$casts`, QR code generated via `Asset::saved` observer (BR-MNT-015)
  - `AssetDepreciation.php` — no `SoftDeletes`; `$guarded = []`
  - `Ticket.php` — `$fillable`, `$casts`, `assignments()`, `timeLogs()`, `breakdownHistory()`
  - `TicketAssignment.php` — `$fillable`
  - `TicketTimeLog.php` — `$fillable`
  - `BreakdownHistory.php` — no `SoftDeletes`, no `is_active`
  - `PmSchedule.php` — `$fillable`, `$casts`, `workOrders()`
  - `PmWorkOrder.php` — `$fillable`, `$casts` (checklist_completion_json)
  - `AmcContract.php` — `$fillable`, `$casts`
  - `WorkOrder.php` — `$fillable`
- `Modules/Maintenance/app/Providers/MaintenanceServiceProvider.php`
- `Modules/Maintenance/database/seeders/MntAssetCategorySeeder.php`
- `Modules/Maintenance/database/seeders/MntSeederRunner.php`
- 5 Model Factories (AssetCategoryFactory, AssetFactory, TicketFactory, PmScheduleFactory, PmWorkOrderFactory)

**Tests:**
- Verify all 11 models instantiate with correct FK relationships (model structure test)
- Verify factories produce valid model instances

---

### Phase 2 — Asset Categories & Asset Register

**FRs Covered:** MNT-01, MNT-02 (partial — CRUD + QR)
**Priority:** Critical

**Files to Create:**
- `AssetCategoryController.php` — full CRUD (8 methods) + keyword JSON validation
- `AssetController.php` — CRUD (7 methods) + `qrCode()` (QR download from sys_media)
- `StoreAssetCategoryRequest.php`
- `StoreAssetRequest.php`
- `AssetCategoryPolicy.php` — view/manage gates
- `AssetPolicy.php` — view/manage gates
- Observer: `AssetObserver.php` — `saved()` triggers QR generation via SimpleSoftwareIO (BR-MNT-015)
- Views: `asset-categories/index`, `asset-categories/form`, `assets/index`, `assets/form`

**Tests:**
- `AssetCategoryTest` — keyword JSON stored and retrieved; category code unique constraint enforced
- `AssetCreationTest` — QR code generated on first save; `qr_code_media_id` populated; QR content decodes to correct `/maintenance/tickets/create?asset_id={id}` URL

---

### Phase 3 — Ticketing Core (Create + Auto-Assign)

**FRs Covered:** MNT-04, MNT-05
**Priority:** Critical

**Files to Create:**
- `TicketController.php` — `index()`, `create()`, `store()`, `show()` methods
- `TicketService.php` — full 10-step `createTicket()` + `resolvePriority()` + `manualAssign()`
- `AssignmentService.php` — `autoAssign()` (role filter + open ticket score + location bonus) + `getWorkloadByRole()`
- `StoreTicketRequest.php`
- `AssignTicketRequest.php`
- `TicketPolicy.php` — create/view/update/manage gates with technician scope check (BR-MNT-008)
- `TicketAssignmentPolicy.php`
- Views: `tickets/index`, `tickets/create`, `tickets/show` (basic — status transitions added Phase 4)

**Tests:**
- `TicketCreationTest` — "water leakage" → priority=High; no keyword → fallback to default_priority; ticket_number format correct; sla_due_at set
- `AutoAssignmentTest` — two technicians; assign to lower open-ticket count; no match → unassigned; Maintenance Incharge notified

---

### Phase 4 — Ticket Lifecycle, Time Logs & SLA

**FRs Covered:** MNT-06
**Priority:** Critical

**Files to Create:**
- `TicketController::updateStatus()` + `updatePriority()` + `storeTimeLog()` + `rate()` methods
- `TicketService::updateStatus()` — FSM validation (BR-MNT-003) + photo enforcement (BR-MNT-010) + totals recalc
- `TicketService::storeTimeLog()` — time log entry + running total updates
- `UpdateTicketStatusRequest.php` — resolution_notes validation (BR-MNT-004) + photo conditional rules
- `OverridePriorityRequest.php`
- `StoreTimeLogRequest.php`
- `TicketTimeLogPolicy.php`
- Job: `CheckSlaBreachesJob.php` — every 30 min: SET is_sla_breached=1 WHERE sla_due_at < NOW() AND status NOT IN (Resolved, Closed)
- Views: `tickets/_status_modal` (inline modal), update `tickets/show` with timeline + time log tab

**Tests:**
- `TicketStatusTransitionTest` — all valid transitions succeed; Open→Resolved returns 422; Cancelled from In_Progress by admin
- `SlaBreachTest` — sla_due_at in past → `CheckSlaBreachesJob` sets is_sla_breached=1; already resolved not affected
- `ResolutionNotesTest` — Resolved without notes → 422; notes <20 chars → 422

---

### Phase 5 — Dashboard, Escalation & Breakdown History

**FRs Covered:** MNT-06 (escalation), MNT-11 (dashboard)
**Priority:** High

**Files to Create:**
- `MaintenanceController::dashboard()` — KPI aggregates (open by priority, SLA breached, resolved today, PM due week, AMC expiring 60d, technician workload via `AssignmentService::getWorkloadByRole()`)
- `EscalationService.php` — `checkEscalations()` full implementation with sla_escalation_json parsing + L1/L2 NTF dispatch
- `TicketService::updateStatus()` — add post-hook: on Resolved with asset_id → INSERT `mnt_breakdown_history` (BR-MNT-014)
- Views: `dashboard.blade.php` with Alpine.js KPI cards + chart

**Tests:**
- `SlaEscalationTest` — ticket age > L1.after_hours → L1 notification; escalation_level=1; further → L2; no double-fire
- `BreakdownHistoryTest` — ticket with asset_id Resolved → `mnt_breakdown_history` record inserted; downtime_hours calculated correctly

---

### Phase 6 — Preventive Maintenance

**FRs Covered:** MNT-07
**Priority:** High

**Files to Create:**
- `PmScheduleController.php` — all 11 methods
- `PmScheduleService.php` — `generateWorkOrders()` + `completeWorkOrder()` + `markOverdue()` + `advanceNextDueDate()`
- `StorePmScheduleRequest.php`
- `PmSchedulePolicy.php`
- `PmWorkOrderPolicy.php`
- Job: `GeneratePmWorkOrdersJob.php` — daily 06:00; calls `PmScheduleService::generateWorkOrders()`
- Job: `MarkOverduePmWorkOrdersJob.php` — daily 07:00; calls `PmScheduleService::markOverdue()`
- Views: `pm-schedules/index`, `pm-schedules/form` (checklist builder), `pm-work-orders/index`, `pm-work-orders/show` (checklist completion)

**Tests:**
- `PmWorkOrderGenerationTest` — schedule next_due_date = today → WO created; next_due_date advanced
- `PmWorkOrderDuplicateTest` — Pending WO exists → second WO not created (BR-MNT-006)
- `PmChecklistCompletionTest` — all items checked → WO Completed; asset.last_pm_date updated

---

### Phase 7 — AMC Contracts

**FRs Covered:** MNT-08
**Priority:** High

**Files to Create:**
- `AmcContractController.php` — all 8 methods
- `StoreAmcContractRequest.php`
- `AmcContractPolicy.php`
- Job: `SendAmcExpiryAlertsJob.php` — daily 08:00; fires at 60/30/7 days using `renewal_alert_sent_*` flags (BR-MNT-007); auto-expires past-end-date contracts
- Views: `amc-contracts/index` (expiry badges), `amc-contracts/form`

**Tests:**
- `AmcExpiryAlertTest` — end_date 30 days away → alert dispatched; `renewal_alert_sent_30=1`; job runs again → no second dispatch; 7-day fires separately on different run

---

### Phase 8 — External Vendor Work Orders

**FRs Covered:** MNT-09
**Priority:** Medium

**Files to Create:**
- `WorkOrderController.php` — all 8 methods including `pdf()` (DomPDF)
- `StoreWorkOrderRequest.php`
- `WorkOrderPolicy.php`
- DomPDF view: `work-orders/pdf.blade.php` — A4 portrait; school header + logo; vendor details, scope, cost, PO number
- `WorkOrderController::updateStatus()` on Completed → `TicketService::recalculateAssetCost()` (BR-MNT-012) + FAC hook scaffold stub
- Views: `work-orders/index`, `work-orders/form`, `work-orders/show`

**Tests:**
- `WorkOrderCostTest` — WO completed with actual_cost → `asset.total_maintenance_cost` updated correctly (BR-MNT-012)

---

### Phase 9 — Asset Depreciation

**FRs Covered:** MNT-03
**Priority:** Medium

**Files to Create:**
- `AssetController::depreciation()` + `storeDepreciation()` methods
- `DepreciationService.php` — `calculateSLM()`, `calculateWDV()`, `recalculateBookValue()`
- `StoreAssetDepreciationRequest.php` — custom unique validation for (asset_id, financial_year) → BR-MNT-016
- `AssetDepreciationPolicy.php`
- Views: `assets/show.blade.php` — depreciation schedule tab/modal (extend from Phase 2)

**Tests:**
- `AssetDepreciationTest` — SLM formula; WDV formula; UNIQUE constraint → duplicate year raises 422

---

### Phase 10 — Reports & Calendar

**FRs Covered:** MNT-10, MNT-11 (full)
**Priority:** Medium

**Files to Create:**
- `MaintenanceReportController.php` — all 5 report methods with CSV export (`?export=csv`)
- `MaintenanceController::calendar()` — JSON endpoint for calendar events (PM WO due, WO scheduled, AMC visits)
- Views: 5 report views + `calendar.blade.php` (JS calendar — FullCalendar or equivalent)
- `MaintenanceReportPolicy.php`

**Tests:**
- Report data structure tests; CSV export content verification; calendar JSON structure

---

### Phase 11 — Mobile API

**FRs Covered:** MNT-04, MNT-06, MNT-07 (mobile surfaces)
**Priority:** Medium

**Files to Create:**
- `MobileMaintenanceController.php` — all 9 API endpoints
  - `myTickets()`: select() essential fields, paginate(20), JSON < 20 KB per page
  - `qrLookup()`: lookup by `?asset_code=` param; returns asset + location + active PM schedules
  - `quickCreate()`: calls `TicketService::createTicket()` (reuses same service)
  - `uploadPhotos()`: store to `sys_media` via `collection_name='mnt-ticket-photos'`

**Tests:**
- `MobileApiTest` — ticket status update via API; checklist update via API; qrLookup returns correct asset; quickCreate triggers auto-assign

---

## Section 7 — Seeder Execution Order

```
php artisan module:seed Maintenance --class=MntSeederRunner

MntSeederRunner
  └─→ MntAssetCategorySeeder
        Seeds 9 categories (no table dependencies):
        Electrical | Plumbing | IT/Computer | Carpentry | Cleaning
        HVAC | Fire Safety | Civil/Structural | Sports/Ground
```

**For test environments** — minimum seed required for all test classes:
```php
// In TestCase::setUp() or via RefreshDatabase + seeder trait:
$this->seed(MntAssetCategorySeeder::class);
```

**Artisan Scheduled Jobs** — register in `routes/console.php`:

```php
// Maintenance Module — Scheduled Jobs
Schedule::job(new GeneratePmWorkOrdersJob())    ->dailyAt('06:00')->withoutOverlapping();
Schedule::job(new CheckSlaBreachesJob())         ->everyThirtyMinutes()->withoutOverlapping();
Schedule::job(new SendAmcExpiryAlertsJob())      ->dailyAt('08:00')->withoutOverlapping();
Schedule::job(new MarkOverduePmWorkOrdersJob())  ->dailyAt('07:00')->withoutOverlapping();
```

| Job Class | Schedule | Purpose |
|---|---|---|
| `GeneratePmWorkOrdersJob` | Daily at 06:00 | Generate PM WOs for schedules where next_due_date ≤ today (BR-MNT-006) |
| `CheckSlaBreachesJob` | Every 30 minutes | Set is_sla_breached=1; trigger EscalationService::checkEscalations() (BR-MNT-011) |
| `SendAmcExpiryAlertsJob` | Daily at 08:00 | Fire expiry alerts at 60/30/7 days; auto-expire past-end-date contracts (BR-MNT-007) |
| `MarkOverduePmWorkOrdersJob` | Daily at 07:00 | Mark PM WOs as Overdue where due_date < today (BR-MNT-013) |

---

## Section 8 — Testing Strategy

### Framework & Setup

```
Feature tests: Pest (uses(Tests\TestCase::class, RefreshDatabase::class))
Unit tests:    PHPUnit (bare — no Laravel app boot for pure formula tests)
```

**Common Test Setup (all Feature test files):**
```php
uses(Tests\TestCase::class, RefreshDatabase::class);

beforeEach(function () {
    $this->seed(MntAssetCategorySeeder::class);  // required for all ticket tests
    Queue::fake();           // GeneratePmWorkOrdersJob, CheckSlaBreachesJob, SendAmcExpiryAlertsJob
    Notification::fake();    // assignment, SLA escalation, AMC expiry alerts
    Storage::fake();         // QR code PNG, before/after photos, DomPDF
});
```

**Carbon time control** (for SLA + expiry tests):
```php
Carbon::setTestNow('2026-04-01 10:00:00');  // freeze time for deterministic SLA assertions
// cleanup in afterEach: Carbon::setTestNow();
```

---

### Feature Test Files (11 files)

| # | File | Path | Test Count | Covers T# |
|---|---|---|---|---|
| 1 | `TicketCreationTest` | `tests/Feature/Maintenance/TicketCreationTest.php` | 4 | T1, T2 |
| 2 | `AutoAssignmentTest` | `tests/Feature/Maintenance/AutoAssignmentTest.php` | 3 | T3, T4 |
| 3 | `TicketStatusTransitionTest` | `tests/Feature/Maintenance/TicketStatusTransitionTest.php` | 5 | T5, T6, T9 |
| 4 | `SlaBreachTest` | `tests/Feature/Maintenance/SlaBreachTest.php` | 2 | T7 |
| 5 | `SlaEscalationTest` | `tests/Feature/Maintenance/SlaEscalationTest.php` | 3 | T8 |
| 6 | `ResolutionNotesTest` | `tests/Feature/Maintenance/ResolutionNotesTest.php` | 2 | T9 |
| 7 | `TimeLogTest` | `tests/Feature/Maintenance/TimeLogTest.php` | 2 | T10 |
| 8 | `PmWorkOrderGenerationTest` | `tests/Feature/Maintenance/PmWorkOrderGenerationTest.php` | 2 | T11 |
| 9 | `PmWorkOrderDuplicateTest` | `tests/Feature/Maintenance/PmWorkOrderDuplicateTest.php` | 2 | T12 |
| 10 | `PmChecklistCompletionTest` | `tests/Feature/Maintenance/PmChecklistCompletionTest.php` | 2 | T13 |
| 11 | `AmcExpiryAlertTest` | `tests/Feature/Maintenance/AmcExpiryAlertTest.php` | 3 | T14 |
| 12 | `TechnicianAuthorizationTest` | `tests/Feature/Maintenance/TechnicianAuthorizationTest.php` | 3 | T15 |
| 13 | `QrCodeTest` | `tests/Feature/Maintenance/QrCodeTest.php` | 2 | T18 |
| 14 | `BreakdownHistoryTest` | `tests/Feature/Maintenance/BreakdownHistoryTest.php` | 2 | T19 |
| 15 | `WorkOrderCostTest` | `tests/Feature/Maintenance/WorkOrderCostTest.php` | 2 | T20 |

**Business Rule → Test Coverage Map:**

| BR | Rule | Test File | Assertion |
|---|---|---|---|
| BR-MNT-001 | Ticket number lock-for-update unique | `TicketCreationTest` | ticket_number matches `MNT-YYYY-XXXXXXXX` format |
| BR-MNT-003 | FSM invalid transition → 422 | `TicketStatusTransitionTest` | PATCH status=Resolved from Open → 422 |
| BR-MNT-004 | resolution_notes mandatory on Resolved | `ResolutionNotesTest` | missing notes → 422; short notes → 422 |
| BR-MNT-006 | No duplicate PM WOs | `PmWorkOrderDuplicateTest` | Pending WO exists → `generateWorkOrders()` returns 0 for that schedule |
| BR-MNT-007 | AMC alert fires once per threshold | `AmcExpiryAlertTest` | `renewal_alert_sent_30=1` after first fire; Notification::assertCount(1) after second job run |
| BR-MNT-008 | Technician cannot update other's ticket | `TechnicianAuthorizationTest` | PATCH by technician B on technician A's ticket → 403 |
| BR-MNT-011 | Escalation level set after threshold | `SlaEscalationTest` | ticket.escalation_level=1 after L1.after_hours; Notification::assertSentTo($maintIncharge) |
| BR-MNT-014 | Breakdown history auto-insert | `BreakdownHistoryTest` | mnt_breakdown_history count increases on Resolved; downtime_hours = diff in hours |
| BR-MNT-016 | Depreciation UNIQUE per year | `AssetDepreciationTest` | second POST with same financial_year → 422 |

---

### Unit Test Files (3 files)

| # | File | Path | Tests | Formula Verified |
|---|---|---|---|---|
| 1 | `AssetDepreciationTest` | `tests/Unit/Maintenance/AssetDepreciationTest.php` | 3 | SLM: `(cost-salvage)/life`; WDV: `opening × rate/100`; unique constraint |
| 2 | `KeywordPriorityTest` | `tests/Unit/Maintenance/KeywordPriorityTest.php` | 3 | Case-insensitive match; Critical > High precedence; no-match fallback |
| 3 | `SlaCalculationTest` | `tests/Unit/Maintenance/SlaCalculationTest.php` | 3 | `sla_due_at = created_at + sla_hours`; `Asia/Kolkata` timezone; Carbon::setTestNow |

---

### Policy Test Files (2 files)

| File | Tests |
|---|---|
| `tests/Feature/Maintenance/TicketPolicyTest.php` | Technician cannot update other's ticket (403); own ticket (200); Admin any ticket (200); Teacher create only |
| `tests/Feature/Maintenance/PmWorkOrderPolicyTest.php` | Technician can update assigned PM WO; cannot update unassigned PM WO |

---

### Factory Definitions

```php
// AssetCategoryFactory
AssetCategory::factory()->create([
    'name' => 'Electrical',
    'code' => 'ELEC',
    'default_priority' => 'Medium',
    'sla_hours' => 8,
    'priority_keywords_json' => ['High' => ['short circuit'], 'Critical' => ['fire']],
    'sla_escalation_json' => ['L1' => ['after_hours' => 4, 'notify_role' => 'maintenance-incharge']],
]);

// AssetFactory
Asset::factory()->create(['category_id' => $category->id, 'current_condition' => 'Good']);

// TicketFactory — generate ticket_number with sequence
Ticket::factory()->create(['status' => 'Open', 'priority' => 'High', 'sla_due_at' => now()->addHours(8)]);

// PmScheduleFactory
PmSchedule::factory()->create([
    'recurrence' => 'Monthly',
    'checklist_items_json' => ['Clean filter', 'Check pressure'],
    'next_due_date' => today(),
]);

// PmWorkOrderFactory
PmWorkOrder::factory()->create(['status' => 'Pending', 'due_date' => today()]);
```

---

*MNT_Dev_Plan.md — Phase 3 Complete*
