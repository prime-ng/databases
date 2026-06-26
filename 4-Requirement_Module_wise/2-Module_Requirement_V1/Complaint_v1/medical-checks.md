# Medical Checks — Requirements

## What It Does
Records medical/safety compliance checks linked to complaints. Supports alcohol tests, drug tests, and fitness checks with media evidence upload. Typically used for safety-related complaints involving drivers, staff, or students.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `complaint_id` | BIGINT FK → `cmp_complaints` | Required. Parent complaint. |
| `check_type` | BIGINT FK → `sys_dropdowns` | AlcoholTest / DrugTest / FitnessCheck. |
| `conducted_by` | VARCHAR | Name of person who conducted the check. |
| `conducted_at` | DATETIME | When the check was performed. |
| `result` | BIGINT FK → `sys_dropdowns` | Positive / Negative / Inconclusive. |
| `reading_value` | VARCHAR | Numeric or qualitative reading. |
| `remarks` | TEXT | Additional notes. |
| `evidence_uploaded` | BOOLEAN | Whether media evidence was attached. |

## Media Handling
- Uses Spatie Media Library
- Collection name: `medical_img`
- Supports multi-image upload
- Image conversions: small, medium, large

## CRUD Operations

**Create**
- Route: `GET /medical-checks/create` → form
- Submit: `POST /medical-checks` → validates → saves with media → redirects to master view

**List**
- Displayed as "Medical Checks/Inspection" tab in the master view at `/complaint/complaint-mgt`
- Shows table with check type, conducted by, result, and linked complaint

**View**
- Route: `GET /medical-checks/{id}`
- Shows full medical check details with evidence images

**Edit/Update**
- Route: `GET /medical-checks/{id}/edit` → pre-filled form
- Submit: `PUT /medical-checks/{id}` → validates → updates → redirects

**Delete (Soft)**
- Route: `DELETE /medical-checks/{id}`
- Triggered via SweetAlert2 confirmation popup

**Restore**
- Route: `GET /medical-checks/{id}/restore`
- Trash page: `GET /medical-checks/trash/view`

**Force Delete**
- Route: `DELETE /medical-checks/{id}/force-delete`

## Permissions

| Operation | Permission Key |
|---|---|
| View medical checks tab | `tenant.medical-check.viewAny` |
| View medical check details | `tenant.medical-check.view` |
| Create medical check | `tenant.medical-check.create` |
| Update medical check | `tenant.medical-check.update` |
| Delete medical check | `tenant.medical-check.delete` |
| Restore medical check | `tenant.medical-check.restore` |
| Force delete medical check | `tenant.medical-check.forceDelete` |
