# Transport Tab 3: Personnel Management

This screen manages all transport personnel — drivers, helpers, and transport managers. Each person is registered with their personal details, license information, police verification status, and assigned vehicle.

---

## How It Works

The administrator sees a table listing all transport personnel. Each row shows the person's name, phone, role, license number, license validity, assigned vehicle, and whether police verification is complete. The administrator can add a new person using the Add Personnel button.

When adding or editing a person, the form captures their name, phone, ID type and number (Aadhaar, PAN, Passport, etc.), role, license details, driving experience in months, address, and optionally links them to a user account in the system. The administrator can also assign a vehicle to the person.

Each personnel record has document upload tracking flags for the ID card, photo, driving license, police verification certificate, and address proof. Each flag is automatically set to 1 when the corresponding document is uploaded.

Personnel can be issued a digital ID card with QR, RFID, NFC, or Barcode technology. The unique `user_qr_code` is used for attendance scanning and identification.

---

## Important Business Rules

- Each personnel record must have a unique `user_qr_code` — no two persons can share the same QR/RFID/NFC identifier.
- The `id_card_type` determines what kind of digital ID the person has (QR, RFID, NFC, or Barcode).
- The role field is a free-text VARCHAR — common values include Driver, Helper, Transport Manager.
- A person can be linked to a system user account (`user_id` FK to sys_users) but this is optional.
- When a person is assigned a vehicle, it is for record-keeping only — actual route assignments happen in the Route Allocation screen.
- If a personnel record is soft-deleted, any active route assignments for that person must be resolved first.
- License validity date is used to show expiry alerts on the dashboard.
- Driving experience is stored in months and can be used for reporting and driver qualification checks.
- Police verification is a simple yes/no flag; the uploaded document is stored in sys.media.

---

## Database Columns & Behavior

### tpt_personnel
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `user_id` — INT UNSIGNED, nullable. FK to sys_users. Links the personnel to a system login account.
- `user_qr_code` — VARCHAR(30), NOT NULL. Unique identifier for QR/RFID/NFC/Barcode scanning.
- `id_card_type` — ENUM('QR','RFID','NFC','Barcode'), NOT NULL, default 'QR'. Digital ID card technology.
- `name` — VARCHAR(100), NOT NULL. Full name of the person.
- `phone` — VARCHAR(30), nullable. Contact number.
- `id_type` — VARCHAR(20), nullable. ID document type (e.g., Aadhaar, PAN, Passport).
- `id_no` — VARCHAR(100), nullable. ID document number.
- `role` — VARCHAR(20), NOT NULL. Role (e.g., Driver, Helper, Transport Manager).
- `license_no` — VARCHAR(50), nullable. Driving license number.
- `license_valid_upto` — DATE, nullable. Driving license expiry date.
- `assigned_vehicle_id` — INT UNSIGNED, nullable. FK to tpt_vehicle. Default assigned vehicle.
- `driving_exp_months` — SMALLINT UNSIGNED, nullable. Total driving experience in months.
- `police_verification_done` — TINYINT(1), NOT NULL, default 0. 0 = Not Done, 1 = Done.
- `address` — VARCHAR(512), nullable. Residential address.
- `id_card_upload` — TINYINT(1) UNSIGNED, default 0. 0 = Not Uploaded, 1 = Uploaded.
- `photo_upload` — TINYINT(1) UNSIGNED, default 0. 0 = Not Uploaded, 1 = Uploaded.
- `driving_license_upload` — TINYINT(1) UNSIGNED, default 0. 0 = Not Uploaded, 1 = Uploaded.
- `police_verification_upload` — TINYINT(1) UNSIGNED, default 0. 0 = Not Uploaded, 1 = Uploaded.
- `address_proof_upload` — TINYINT(1) UNSIGNED, default 0. 0 = Not Uploaded, 1 = Uploaded.
- `is_active` — TINYINT(1), default 1. Soft-delete flag.
- `created_at` — TIMESTAMP. Auto-set on creation.
- `updated_at` — TIMESTAMP. Auto-updated on modification.
- `deleted_at` — TIMESTAMP, nullable. Soft-delete timestamp.

---

## Deep Analysis

### Business Workflows & State Machines

- **Add Personnel Flow:** Select role (Driver/Helper/Transport Manager) → Fill personal + license details → Assign vehicle (optional) → Set ID card type → Upload documents → INSERT.
- **Edit Flow:** Load record → Update fields → Validate unique `user_qr_code` → UPDATE.
- **Soft-Delete Flow:** Before setting `is_active = 0`, verify no active route schedules or trip references exist for this person; reject if conflicts found.
- **License Expiry Alert:** Application-level check on `license_valid_upto`; if within 30 days, flag on dashboard.
- **ID Card Assignment:** `user_qr_code` must be unique; when an ID card type is selected (QR/RFID/NFC/Barcode), the application should generate or accept a unique identifier.

### Validation Rules & Edge Cases

- **user_qr_code uniqueness:** Must be globally unique across all personnel; enforce at DB level (no unique constraint in current DDL — should be added via application validation or index).
- **Role validation:** Free-text VARCHAR(20); application should restrict to a controlled vocabulary (Driver, Helper, Transport Manager) despite no FK enforcement.
- **Assigned vehicle FK:** Must reference an `is_active = 1` vehicle.
- **License date:** `license_valid_upto` must be in the future if provided; null is allowed for non-driver roles.
- **Police verification:** If `police_verification_done = 1`, the uploaded document must be present.
- **User linkage:** Optional FK to `sys_users`; if provided, the user account must exist and not already be linked to another personnel record.
- **Driving experience:** Stored in months; must be a positive integer.

### Integration Points

- **tpt_vehicle** — `assigned_vehicle_id` FK.
- **sys_users** — `user_id` FK for login account linkage.
- **tpt_driver_route_vehicle_jnt** — `driver_id` and `helper_id` FKs.
- **tpt_route_scheduler_jnt** — `driver_id` and `helper_id` FKs.
- **tpt_trip** — `driver_id` and `helper_id` FKs.
- **tpt_driver_attendance** — `driver_id` FK.
- **tpt_attendance_device** — `user_id` FK for device registration.
- **sys.media** — Document uploads (ID card, photo, license, police verification, address proof).

### Permissions Matrix

| Role | View | Create | Edit | Soft-Delete |
|---|---|---|---|---|
| Super Admin | All schools | Yes | Yes | Yes |
| School Admin | Own school | Yes | Yes | Yes |
| Transport Manager | Own school | Yes | Yes | No |
| Driver / Helper | Own record only | No | Limited (own profile) | No |
