# Transport Tab 7: Vehicle Inspection & Maintenance

This screen manages the complete vehicle health workflow — daily pre-trip inspections, service requests, and maintenance history. When an inspection fails, the system automatically triggers a service request, which after approval becomes a maintenance record.

---

## How It Works

The screen is organized into three sub-tabs: **Inspection**, **Service Request**, and **Maintenance**.

**Inspection:** Before a trip begins, the driver performs a daily vehicle inspection covering tires, lights, brakes, engine, battery, fire extinguisher, first aid kit, seat belts, headlights, tail lights, wipers, mirrors, steering wheel, emergency tools, and cleanliness. Each item is marked as OK or Not OK. If any issue is found, the `any_issues_found` flag is set to 1 and the driver describes the issues. The inspection is then reviewed by an authorized person who sets the status to Passed or Failed.

**Service Request:** If an inspection fails, the system automatically creates a service request entry with the available information. The administrator can also manually create a service request at any time. The request must be approved by an authorized person before work can begin.

**Maintenance:** Once a service request is approved, a maintenance record is created. Maintenance includes the initiation date, maintenance type (manual entry), cost, workshop details, in-service and out-of-service dates, and next due date. Direct creation of maintenance records is not allowed — they can only be created from an approved service request. Once the maintenance is approved, a vendor bill due for payment entry is generated.

---

## Important Business Rules

- The inspection must be completed before the trip can begin for the day. This is a business process rule enforced at the application level.
- If any inspection item is marked as Not OK (`any_issues_found` = 1), the inspection status is set to Pending until reviewed.
- When an inspection is marked Failed, the vehicle's `availability_status` in tpt_vehicle is automatically set to 0 (Not Available).
- When an inspection is marked Failed, a new entry is automatically created in `tpt_vehicle_service_request`.
- Service requests can be created manually by any authorized user at any time (not only from failed inspections).
- Maintenance records cannot be created directly — they must originate from an approved service request. Edits to existing maintenance records are allowed.
- Approval of both service requests and maintenance records is done by authorized personnel only, typically from an Approval sub-tab.
- Once a maintenance record is approved, a bill due for payment entry is created in the vendor billing system (`vnd_vendor_bill_due_for_payment`).
- The `next_due_date` on maintenance helps schedule recurring service intervals.

---

## Database Columns & Behavior

### tpt_daily_vehicle_inspection
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `vehicle_id` — INT UNSIGNED, NOT NULL. FK to tpt_vehicle.
- `driver_id` — INT UNSIGNED, nullable. FK to tpt_personnel.
- `inspection_date` — TIMESTAMP, NOT NULL. When the inspection was performed.
- `odometer_reading` — INT UNSIGNED, nullable. Current odometer at inspection time.
- `fuel_level_reading` — DECIMAL(6,2), nullable. Current fuel level.
- `tire_condition_ok` through `cleanliness_ok` — 16 TINYINT(1) columns, each default 0. Individual inspection check items.
- `any_issues_found` — TINYINT(1), default 0. 1 = one or more items failed.
- `issues_description` — VARCHAR(512), nullable. Description of any issues found.
- `remarks` — VARCHAR(512), nullable. Additional remarks.
- `inspection_status` — ENUM('Passed','Failed','Pending'), default 'Pending'. Overall status.
- `inspected_by` — INT UNSIGNED, nullable. FK to sys_users. Who reviewed the inspection.
- `inspected_at` — TIMESTAMP, nullable. When the review was done.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamp fields.

### tpt_vehicle_service_request
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `vehicle_inspection_id` — INT UNSIGNED, NOT NULL. FK to tpt_daily_vehicle_inspection.
- `request_date` — TIMESTAMP, NOT NULL. When the request was created.
- `reason` — VARCHAR(512), nullable. Reason for the service request.
- `Vehicle_status` — INT UNSIGNED, nullable. FK to sys_dropdown_table. Values: Due for Service, In-Service, Service Done.
- `service_completion_date` — TIMESTAMP, nullable. When service was completed.
- `request_approval_status` — ENUM('Approved','Pending','Rejected'), default 'Pending'.
- `approved_by` — INT UNSIGNED, nullable. FK to sys_users.
- `approved_at` — TIMESTAMP, nullable.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamp fields.

### tpt_vehicle_maintenance
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `vehicle_service_request_id` — INT UNSIGNED, NOT NULL. FK to tpt_vehicle_service_request.
- `maintenance_initiation_date` — DATE, NOT NULL. Date the vehicle entered the workshop.
- `maintenance_type` — VARCHAR(120), NOT NULL. Free-text description of work done.
- `cost` — DECIMAL(12,2), NOT NULL. Total cost of maintenance.
- `in_service_date` — DATE, nullable. Date maintenance work began.
- `out_service_date` — DATE, nullable. Date maintenance work was completed.
- `workshop_details` — VARCHAR(512), nullable. Workshop name, address, or notes.
- `next_due_date` — DATE, nullable. Next scheduled maintenance date.
- `remarks` — VARCHAR(512), nullable.
- `status` — ENUM('Approved','Pending','Rejected'), default 'Pending'.
- `approved_by` — INT UNSIGNED, nullable. FK to sys_users.
- `approved_at` — TIMESTAMP, nullable.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamp fields.

---

## Deep Analysis

### Business Workflows & State Machines

- **Inspection State Machine:** `Pending` (driver submitted) → (admin reviews) → `Passed` or `Failed`.
- **Inspection → Service Request:** If `Failed` → Auto-create `tpt_vehicle_service_request` entry → Also set `tpt_vehicle.availability_status = 0`.
- **Service Request State Machine:** `Pending` → (authorized approval) → `Approved` or `Rejected`.
- **Service Request → Maintenance:** When `Approved` → Auto-create `tpt_vehicle_maintenance` entry.
- **Maintenance State Machine:** `Pending` → (admin approves) → `Approved` or `Rejected`. On approval, auto-create `vnd_vendor_bill_due_for_payment`.
- **Manual Service Request:** An authorized user can also create a service request directly (not only via failed inspection).

### Validation Rules & Edge Cases

- **Inspection before trip:** Business rule — inspection must be completed and passed before the first trip of the day for that vehicle; enforce at application level.
- **16 inspection items:** All are TINYINT(1) default 0; if ANY is 0 (Not OK), `any_issues_found` must be set to 1.
- **Inspection status logic:** If `any_issues_found = 1`, inspection cannot auto-Pass; must stay `Pending` until admin review.
- **Failed inspection cascade:** Must atomically create service request AND set vehicle `availability_status = 0` in one transaction.
- **No direct maintenance creation:** Application must enforce that `tpt_vehicle_maintenance` rows are only created via approved service requests. Direct INSERT is forbidden.
- **Approval cascade:** Approved maintenance → `vnd_vendor_bill_due_for_payment` creation must be atomic.
- **Vehicle_status:** Service request has its own vehicle status dropdown (Due for Service, In-Service, Service Done) independent of `tpt_vehicle.availability_status`.

### Integration Points

- **tpt_vehicle** — `availability_status` updated on inspection failure.
- **tpt_personnel** — `driver_id` for who performed the inspection.
- **sys_users** — `inspected_by`, `approved_by` across all three tables.
- **tpt_vehicle_service_request** — Auto-created from failed inspection.
- **tpt_vehicle_maintenance** — Auto-created from approved service request.
- **vnd_vendor_bill_due_for_payment** — Created when maintenance is approved.
- **sys_dropdown_table** — `Vehicle_status` values for service request.

### Permissions Matrix

| Role | Inspect Vehicle | Review Inspection | Create Service Request | Approve Service Request | Approve Maintenance |
|---|---|---|---|---|---|
| Super Admin | Yes | Yes | Yes | Yes | Yes |
| School Admin | Yes | Yes | Yes | Yes | Yes |
| Transport Manager | Yes | No | Yes | No | No |
| Driver | Own vehicle | No | No | No | No |
| Helper | No | No | No | No | No |
