# Complaint Module — Requirements and Specifications

> This document outlines the comprehensive requirements, business logic, and functional specifications for the Complaint Management Module. It covers all CRUD operations for every sub-feature including Categories, SLA, Complaints, Medical Checks, AI Insights, and Reports.

---

## Table of Contents

1. [Core Functional Overview](#1-core-functional-overview)
2. [Complaint Categories](#2-complaint-categories)
3. [Department SLA](#3-department-sla)
4. [Complaints (Core)](#4-complaints-core)
5. [Complaint Actions](#5-complaint-actions)
6. [Medical Checks](#6-medical-checks)
7. [AI Insights](#7-ai-insights)
8. [Reports & Dashboard](#8-reports--dashboard)

---

## 1. Core Functional Overview

### 1.1 Purpose
The Complaint Management Module provides a centralized system for logging, tracking, escalating, and resolving grievances across all school domains — Transport, Food, Academics, Infrastructure, Safety, etc.

### 1.2 Key Capabilities
- **Hierarchical Categories** with Parent-Child relationships
- **5-Level Escalation Matrix** with SLA tracking
- **Polymorphic Targeting** — complaints can target departments, staff, vehicles, vendors, or any entity
- **AI-Driven Analysis** — sentiment scoring, risk prediction, safety assessment (rule-based engine)
- **Medical Compliance** — specialized checks for alcohol/drug/fitness tied to complaints
- **Audit Trail** — immutable action log for every state change
- **Role-Based Access** — granular permissions per operation

### 1.3 Database Tables
| Table | Purpose |
|---|---|
| `cmp_complaint_categories` | Hierarchical category master with default SLA values |
| `cmp_department_sla` | Per-department/user/vendor SLA rule overrides |
| `cmp_complaints` | Core ticket registry |
| `cmp_complaint_actions` | Immutable audit trail |
| `cmp_medical_checks` | Medical compliance records |
| `cmp_ai_insights` | AI analysis results |

### 1.4 Tabbed Master View
All management screens are accessed through a single tabbed interface at `/complaint/complaint-mgt` with these tabs:
- **Dashboard** — overview stats and charts
- **Categories** — CRUD for complaint categories
- **SLA** — CRUD for department-level SLA rules
- **Manage Complaints** — complaint listing and management
- **Medical Checks** — medical compliance records
- **Complaint Actions** — audit trail viewer
- **AI Insights** — sentiment and risk data

---

## 2. Complaint Categories

### 2.1 What It Does
Manages the hierarchical taxonomy of complaint types. Each category defines:
- A name and optional short code
- Default severity level and priority score
- Expected resolution time (in hours)
- 5-level escalation timeline (strictly increasing hours L1 < L2 < L3 < L4 < L5)
- Active/inactive status
- Optional parent category for sub-categorization

### 2.2 Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT PK | Auto-increment |
| `parent_id` | BIGINT FK → self | Nullable. If NULL = root category. If set = sub-category. FK uses `restrictOnDelete`. |
| `name` | VARCHAR(100) | Required. Max 100 characters. |
| `code` | VARCHAR(30) | Nullable. Must be unique across all categories (validated at application level). |
| `description` | VARCHAR(512) | Nullable. |
| `severity_level_id` | BIGINT FK → `sys_dropdowns` | Nullable. References system dropdown for severity levels. |
| `priority_score_id` | BIGINT FK → `sys_dropdowns` | Nullable. References system dropdown for priority scores. |
| `expected_resolution_hours` | UNSIGNED INT | Required. Minimum 1 hour. Baseline SLA for this category. |
| `escalation_hours_l1` | UNSIGNED INT | Required. Hours before first escalation. |
| `escalation_hours_l2` | UNSIGNED INT | Required. Must be greater than L1. |
| `escalation_hours_l3` | UNSIGNED INT | Required. Must be greater than L2. |
| `escalation_hours_l4` | UNSIGNED INT | Required. Must be greater than L3. |
| `escalation_hours_l5` | UNSIGNED INT | Required. Must be greater than L4. |
| `is_active` | BOOLEAN | Default true. Controls whether category is available for selection. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

### 2.3 Business Rules

**Escalation Chain Validation**
All 5 escalation levels must form a strictly increasing sequence:
```
L1 < L2 < L3 < L4 < L5
```
This is enforced at the form validation level. If any level is not greater than the previous, the form is rejected with a validation error.

**Parent-Child Hierarchy**
- A category with `parent_id = NULL` is a root-level category
- A category with `parent_id` set is a sub-category
- A category cannot be set as its own parent (enforced during edit)
- Only root-level categories appear in the parent dropdown when creating/editing
- When editing, the category itself is excluded from its parent dropdown

**Soft Delete Behavior**
- Soft-deleting a category does NOT check for children (children can exist with a soft-deleted parent)
- Before soft delete, the category is automatically deactivated (`is_active = false`)
- Soft-deleted categories are hidden from the main listing

**Force Delete Behavior**
- Only applies to already soft-deleted records
- Blocked if the category has any child categories
- Error message: "Cannot delete category having subcategories"
- The `restrictOnDelete` FK constraint on `parent_id` provides database-level protection

**Status Toggle**
- Active/inactive state can be toggled via AJAX POST
- The toggle endpoint accepts `is_active` as a boolean parameter
- Returns JSON with the new state
- Works even on soft-deleted records

### 2.4 CRUD Operations

**Create**
- Route: `GET /complaint/complaint-categories/create` → form
- Submit: `POST /complaint/complaint-categories` → validates → saves → redirects to master view
- After successful creation: redirects to `/complaint/complaint-mgt` with success flash message
- On validation failure: returns to create form with error messages and old input preserved

**List**
- Displayed as a tab panel in the master view at `/complaint/complaint-mgt`
- Shows table with columns: Name, Code, Parent Category, Severity, Priority, Status, Actions
- Supports filtering by: search text, status (active/inactive), severity level, priority score, parent category
- Paginated with standard Laravel pagination
- Columns and actions are permission-gated

**View**
- Route: `GET /complaint/complaint-categories/{id}`
- Loads with relationships: children, parent, severityLevel, priorityScore
- Two rendering modes:
  - AJAX: Used by the index modal (clicking "View" in the list)
  - Full page: Direct browser visit with breadcrumbs and action buttons
- Shows all category details in a table layout

**Edit**
- Route: `GET /complaint/complaint-categories/{id}/edit` → pre-filled form
- Submit: `PUT /complaint/complaint-categories/{id}` → validates → detects changes → updates → logs activity → redirects
- Validation differs from create: parent_id cannot be self, code uniqueness ignores own ID, is_active is required
- On update, an activity log entry is created recording old and new values for each changed field
- After successful update: redirects to master view with success flash message

**Delete (Soft)**
- Route: `DELETE /complaint/complaint-categories/{id}`
- Triggered via SweetAlert2 confirmation popup
- Pre-delete: sets `is_active = false`
- Records a "Deleted" activity log entry
- After deletion: redirects to master view with success flash message

**Restore**
- Route: `GET /complaint/complaint-categories/{id}/restore`
- Trash page: `GET /complaint/complaint-categories/trash/view` — lists soft-deleted records with pagination
- Triggered via SweetAlert2 confirmation popup
- Restores `deleted_at` to null
- Records a "Restored" activity log entry
- After restore: redirects to master view with success flash message

**Force Delete**
- Route: `DELETE /complaint/complaint-categories/{id}/force-delete`
- Only available for soft-deleted records
- Checks for existing children before deletion — blocked if children exist
- Records a "Force Deleted" activity log entry
- After force delete: record is permanently removed from database

**Toggle Status**
- Route: `POST /complaint/complaint-categories/{id}/toggle-status`
- AJAX endpoint that accepts `{ is_active: boolean }`
- Returns JSON: `{ success: true, is_active: bool, message: string }`
- Records a "Toggled" activity log entry

### 2.5 Permissions

| Operation | Permission Key |
|---|---|
| View category tab | `tenant.complaint-category.viewAny` |
| View category details | `tenant.complaint-category.view` |
| Show create form | `tenant.complaint-category.create` |
| Save new category | `tenant.complaint-category.store` |
| Edit/update category | `tenant.complaint-category.update` |
| Soft delete category | `tenant.complaint-category.delete` |
| View trash & restore | `tenant.complaint-category.restore` |
| Force delete category | `tenant.complaint-category.forceDelete` |

---

## 3. Department SLA

### 3.1 What It Does
Defines granular SLA and escalation rules that override the default category-level settings for specific departments, users, roles, or vendors. Allows rules like "Principal's complaints escalate in half the standard time."

### 3.2 Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT PK | Auto-increment |
| `complaint_category_id` | BIGINT FK → `cmp_complaint_categories` | Required. The category this rule applies to. |
| `complaint_subcategory_id` | BIGINT FK → `cmp_complaint_categories` | Nullable. Further narrows to a specific sub-category. |
| `target_department_id` | BIGINT FK → `sch_departments` | Nullable. If set, rule applies only to this department. |
| `target_designation_id` | BIGINT FK → `sch_designation` | Nullable. |
| `target_role_id` | BIGINT FK → `sys_roles` | Nullable. |
| `target_entity_group_id` | BIGINT FK → `sch_entity_groups` | Nullable. |
| `target_user_id` | BIGINT FK → `sys_users` | Nullable. Rule applies to a specific user. |
| `target_vehicle_id` | BIGINT FK → `tpt_vehicle` | Nullable. |
| `target_vendor_id` | BIGINT FK → `vnd_vendors` | Nullable. |
| `dept_expected_resolution_hours` | INT | Required. Override resolution time in hours. |
| `dept_escalation_hours_l1` | INT | Required. Override escalation L1 hours. |
| `dept_escalation_hours_l2` | INT | Required. Must be greater than L1. |
| `dept_escalation_hours_l3` | INT | Required. Must be greater than L2. |
| `dept_escalation_hours_l4` | INT | Required. Must be greater than L3. |
| `dept_escalation_hours_l5` | INT | Required. Must be greater than L4. |
| `escalation_l1_entity_group_id` | BIGINT FK → `sch_entity_groups` | Nullable. Who gets notified at L1. |
| `escalation_l2_entity_group_id` | BIGINT FK → `sch_entity_groups` | Nullable. |
| `escalation_l3_entity_group_id` | BIGINT FK → `sch_entity_groups` | Nullable. |
| `escalation_l4_entity_group_id` | BIGINT FK → `sch_entity_groups` | Nullable. |
| `escalation_l5_entity_group_id` | BIGINT FK → `sch_entity_groups` | Nullable. |
| `is_active` | BOOLEAN | Default true. |

### 3.3 Business Rules
- Same escalation chain validation as categories (L1 < L2 < L3 < L4 < L5)
- Targets are polymorphic — only one target field is typically set per rule
- The SLA rule with the most specific match takes priority when computing resolution dates

### 3.4 CRUD Operations
Same CRUD pattern as categories: create, list, show, edit, update, soft delete, restore, force delete, toggle status.

---

## 4. Complaints (Core)

### 4.1 What It Does
The central ticket registry for all grievances. Supports:
- Auto-generated ticket numbers (`CMP-YYYY-000001` format)
- Polymorphic complainants (Student, Staff, Anonymous)
- Polymorphic targets (Department, Staff, Vehicle, Vendor, etc.)
- Category + subcategory classification
- Severity and priority auto-filled from subcategory
- Status workflow: Open → In Progress → Resolved / Rejected / Closed
- 5-level escalation tracking
- SLA-driven resolution deadlines
- Medical check linkage
- Image upload support via Spatie Media Library

### 4.2 Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT PK | Auto-increment |
| `ticket_no` | VARCHAR | Auto-generated: `CMP-YYYY-NNNNNN`. Lock-guarded to prevent duplicates. |
| `ticket_date` | DATE | Date of complaint registration. |
| `complainant_type_id` | BIGINT FK → `sys_dropdowns` | Required. Defines complainant category (Student/Staff/Anonymous). |
| `complainant_user_id` | BIGINT FK → `sys_users` | Nullable. Set when complainant is a system user. NULL for anonymous. |
| `complainant_name` | VARCHAR | Used when complainant is anonymous or not a system user. |
| `complainant_contact` | VARCHAR | Contact details of complainant. |
| `target_type_id` | BIGINT FK → `sys_dropdowns` | Defines target entity type (Department/Staff/Vehicle/etc.). |
| `target_id` | INTEGER | Unconstrained ID of the target entity (no FK for flexibility). |
| `target_name` | VARCHAR | Display name of the target. |
| `target_table_name` | VARCHAR | Table name for dynamic polymorphic resolution. |
| `category_id` | BIGINT FK → `cmp_complaint_categories` | Required. Primary category. |
| `subcategory_id` | BIGINT FK → `cmp_complaint_categories` | Nullable. Further classification. |
| `severity_level_id` | BIGINT FK → `sys_dropdowns` | Auto-filled via AJAX when subcategory is selected. |
| `priority_score_id` | BIGINT FK → `sys_dropdowns` | Auto-filled via AJAX when subcategory is selected. |
| `title` | VARCHAR | Required. Brief summary of the complaint. |
| `description` | TEXT | Detailed description. |
| `location_details` | VARCHAR | Where the incident occurred. |
| `incident_date` | DATETIME | When the incident happened. |
| `incident_time` | TIME | Time of the incident. |
| `status_id` | BIGINT FK → `sys_dropdowns` | Default: 124 (Open). Workflow: Open → In Progress → Resolved/Rejected/Closed. |
| `assigned_to_role_id` | BIGINT FK → `sys_roles` | Role assigned to handle this complaint. |
| `assigned_to_user_id` | BIGINT FK → `sys_users` | Specific user assigned. |
| `resolution_due_at` | DATETIME | Calculated from SLA: ticket_date + category/department resolution hours. |
| `actual_resolved_at` | DATETIME | Nullable. When the complaint was actually resolved. |
| `resolved_by_role_id` | BIGINT FK → `sys_roles` | Role of the resolver. |
| `resolved_by_user_id` | BIGINT FK → `sys_users` | User who resolved it. |
| `resolution_summary` | TEXT | Notes on how it was resolved. |
| `escalation_level` | INTEGER | Current escalation level (0-5). |
| `is_escalated` | BOOLEAN | True if past all escalation windows. |
| `source_id` | BIGINT FK → `sys_dropdowns` | How the complaint was submitted (Portal/Verbal/Email/etc.). |
| `is_anonymous` | BOOLEAN | Whether complainant identity is hidden. |
| `dept_specific_info` | JSON | Flexible storage for department-specific metadata. |
| `is_medical_check_required` | BOOLEAN | Whether a medical check is needed for this complaint. |
| `support_file` | BOOLEAN | Whether an image was uploaded. |
| `created_by` | BIGINT FK → `sys_users` | Who created the ticket. |

### 4.3 Business Rules

**Complainant Type Logic**
- When complainant type is "Anonymous": complainant_name is required, complainant_user_id is disabled and set to null
- When complainant type is named (Student/Staff): complainant_user_id is required, complainant_name is disabled and set to null
- Switching between types dynamically enables/disables the respective fields via JavaScript

**Category → Subcategory AJAX Flow**
1. User selects a category from the dropdown
2. An AJAX call fetches subcategories for that category
3. The subcategory dropdown is populated with only child categories
4. If the category has no children, the subcategory dropdown is cleared

**Subcategory → Severity/Priority AJAX Flow**
1. After selecting a subcategory, another AJAX call fetches the subcategory's meta data
2. The hidden `severity_level_id` and `priority_score_id` fields are auto-filled
3. These fields are not manually editable — they come from the category definition

**Ticket Number Auto-Generation**
- Format: `CMP-YYYY-NNNNNN` (e.g., `CMP-2026-000001`)
- Year is locked to the ticket's year
- Sequence increments per year
- Lock-guarded to prevent duplicate ticket numbers under concurrent creation

**Status Workflow**
- Default on create: "Open" (status_id = 124)
- Allowed transitions: Open → In Progress → Resolved / Rejected → Closed
- Each status change is logged in `cmp_complaint_actions`

**Resolution Validation**
- `actual_resolved_at` must be on or after `resolution_due_at`
- At least one of `resolved_by_role_id` or `resolved_by_user_id` must be set when marking as resolved

**Escalation Calculation**
- Computed at runtime via Carbon diff on `ticket_date + category SLA hours`
- If current time > expected_resolution: escalation starts
- 5 levels defined by escalation_hours_l1 through l5
- "Breached" when past all escalation windows

### 4.4 CRUD Operations

**Create**
- Route: `GET /complaint/complaints/create` → form with category dropdown, complainant type selector
- Submit: `POST /complaint/complaints` → validates (with inline validation) → creates with auto-generated ticket number → logs "Created" action → notifies super admins → redirects
- Success redirect: `/complaint/complaints` with success flash containing the ticket number
- Image upload: optional `complaint_img` via Spatie Media Library

**List**
- Route: `/complaint/complaint-mgt` → tabbed interface with "Manage Complaints" tab
- Shows table with search, status filter, date range filter
- Each row has actions for view, edit, update status

**View**
- Route: `GET /complaint/complaints/{id}`
- Shows full complaint details with all dropdown labels resolved
- Includes action timeline, medical checks, and AI insights

**Edit/Update**
- Route: `GET /complaint/complaints/{id}/edit` → pre-filled form
- Submit: `PUT /complaint/complaints/{id}`
- Change detection: logs "StatusChange", "Assigned", "Resolved" actions based on diffs
- Resolution date validation enforced

**Manage/Update Status**
- Route: `/complaint/complaint-mgt` → "Update Status" accordion per complaint
- Two panels: (1) read-only complaint details (2) form for assignment, status, resolution

---

## 5. Complaint Actions

### 5.1 What It Does
Immutable audit trail for every state change on a complaint. Every create, status change, assignment, resolution, and delete generates an action record.

### 5.2 Database Fields

| Field | Type | Conditions |
|---|---|---|
| `complaint_id` | BIGINT FK → `cmp_complaints` | Required. Parent complaint. |
| `action_type_id` | BIGINT FK → `sys_dropdowns` | Created / Assigned / StatusChange / Resolved / Deleted. |
| `performed_by_user_id` | BIGINT FK → `sys_users` | Nullable (NULL = system action). |
| `performed_by_role_id` | BIGINT FK → `sys_roles` | Role of the performer. |
| `assigned_to_user_id` | BIGINT FK → `sys_users` | Applicable for "Assigned" actions. |
| `assigned_to_role_id` | BIGINT FK → `sys_roles` | Applicable for "Assigned" actions. |
| `notes` | TEXT | Action details. |
| `is_private_note` | BOOLEAN | Whether this note is internal only. |

### 5.3 How Actions Are Generated
- **Created**: Auto-logged when a complaint is submitted
- **StatusChange**: Logged when complaint status is updated (tracks old → new)
- **Assigned**: Logged when assignment changes (tracks assigner, assignee)
- **Resolved**: Logged when complaint is marked resolved (tracks resolver details)

---

## 6. Medical Checks

### 6.1 What It Does
Records medical/safety compliance checks linked to complaints. Supports alcohol tests, drug tests, and fitness checks with media evidence upload.

### 6.2 Database Fields

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

### 6.3 Media Handling
- Uses Spatie Media Library
- Collection name: `medical_img`
- Supports multi-image upload
- Image conversions: small, medium, large

### 6.4 CRUD Operations
Standard CRUD with soft delete, restore, force delete, and Spatie media management.

---

## 7. AI Insights

### 7.1 What It Does
Stores AI-generated analysis for each complaint. The current engine is rule-based (keyword matching), not ML-based. Processed automatically when a complaint is saved.

### 7.2 Database Fields

| Field | Type | Conditions |
|---|---|---|
| `complaint_id` | BIGINT FK → `cmp_complaints` | Required. One-to-one with complaint (unique FK). |
| `sentiment_score` | DECIMAL(3,2) | Range -1 to 1. Computed from keyword analysis. |
| `sentiment_label_id` | BIGINT FK → `sys_dropdowns` | Angry / Calm / Urgent / Neutral. |
| `escalation_risk_score` | DECIMAL(5,2) | Range 0–100. Weighted formula. |
| `predicted_category_id` | BIGINT FK → `cmp_complaint_categories` | Currently returns the same category (stub). |
| `safety_risk_score` | DECIMAL(5,2) | Range 0–100. Keyword-severity mapping. |
| `model_version` | VARCHAR | Currently `rules-v1`. |
| `processed_at` | DATETIME | When analysis was completed. |

### 7.3 AI Engine Logic

**Sentiment Calculation** (keyword matching)
- Keywords like "angry", "delay", "harassment" → negative score
- Keywords like "urgent", "unsafe" → urgency score
- Keywords like "worst", "threat" → high severity score
- Final score mapped to label: Calm / Neutral / Urgent / Angry

**Risk Score Formula**
```
risk = (severity_weight × 35%) + (target_frequency × 30%) + (sentiment_weight × 20%) + (pending_days × 15%)
```

**Safety Risk Calculation**
- Keyword severity mapping: accident=90, injury=95, violence=100
- Boosted by severity level of the category

### 7.4 Processing Flow
1. Complaint is saved → dispatches `ComplaintSaved` event
2. `ProcessComplaintAIInsights` listener picks it up
3. `ComplaintAIInsightEngine::processComplaint()` runs the analysis
4. Results stored in `cmp_ai_insights` table

---

## 8. Reports & Dashboard

### 8.1 Dashboard Tabs
The master view includes a Dashboard tab showing:
- Open tickets count
- New today
- Average resolution hours
- SLA breach count
- Category distribution pie chart

### 8.2 Report Types

**Summary Report**
- Overall complaint statistics
- Status distribution
- Priority vs status breakdown

**SLA Report**
- Violation types: breached / at_risk / all
- Per-department SLA compliance

**Pareto Analysis**
- Category/subcategory severity-weighted frequency
- Identifies the 20% categories causing 80% of complaints

**Hotspot Analysis**
- Target-based complaint clustering
- Risk score aggregation by target

**AI Risk/Sentiment Report**
- Bubble chart: sentiment × escalation × safety
- Trend analysis over time

### 8.3 Dashboard Charts (AJAX Endpoints)
- `/dashboard/donut/severity-vs-department` — Severity distribution per department
- `/dashboard/donut/department-vs-severity` — Department distribution per severity
- `/dashboard/donut/department-status` — Pending vs resolved by department

---

*End of Requirements Document*
