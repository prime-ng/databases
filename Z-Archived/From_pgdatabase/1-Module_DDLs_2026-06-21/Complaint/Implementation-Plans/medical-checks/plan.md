# Medical Checks — Implementation Plan

## Purpose
Medical/safety compliance records linked to complaints. Supports alcohol tests, drug tests, fitness checks with media evidence via Spatie Media Library.

## Documented But Not Implemented

### Item 1: Store/Update Should Use FormRequest

**Source:** `Requirements/medical-checks.md:27-29` — create with validation

**Current Behavior:** Inline validation in controller.

**Implement:**
- [ ] Create `StoreMedicalCheckRequest.php`:
  - `complaint_id`: `required|exists:cmp_complaints,id`
  - `check_type`: `required|exists:sys_dropdowns,id` (AlcoholTest/DrugTest/FitnessCheck)
  - `conducted_by`: `required|string|max:255`
  - `conducted_at`: `required|date`
  - `result`: `required|exists:sys_dropdowns,id` (Positive/Negative/Inconclusive)
  - `reading_value`: `nullable|string`
  - `remarks`: `nullable|string`
  - `evidence`: `nullable|file|mimes:jpg,png,pdf|max:5120` (optional media)
- [ ] Create `UpdateMedicalCheckRequest.php` with same rules

### Item 2: `is_medical_check_required` Flag Not Linked to Workflow

**Source:** `Requirements/complaints.md:53` — `is_medical_check_required` boolean in complaints table

**Current Behavior:** Flag is stored on complaint but never triggers any workflow.

**Implement:**
- [ ] When complaint is created/updated with `is_medical_check_required = 1`:
  - Option A: Auto-create a pending MedicalCheck record linked to the complaint
  - Option B: Dispatch notification to medical staff to perform the check
- [ ] Add medical check status indicator on complaint view page

### Item 3: Migration Exists — Verify Schema

**Source:** `database/migrations/tenant/2025_12_22_072653_create_medical_checks_table.php`

**Current Behavior:** Migration exists. Verify it matches the spec.

**Implement:**
- [ ] Review the migration for all required columns
- [ ] Ensure Spatie Media Library integration works with collection name `medical_img`

### Item 4: Missing Feature Tests

**Current Behavior:** Zero tests.

**Implement:**
- [ ] `MedicalCheckCrudTest.php`:
  - Create medical check linked to complaint
  - Upload evidence image via Spatie Media Library
  - Update result
  - Soft delete and restore
  - Verify Spatie media conversions (small, medium, large)
