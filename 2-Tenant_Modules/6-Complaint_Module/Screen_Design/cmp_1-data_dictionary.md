# Complaint Management Module - Data Dictionary (Deliverable B)

## Overview
This document details the database schema for the **Complaint Management Module**. The module serves as a central registry for all grievances (Transport, Food, Academics, Infrastructure, etc.) with a robust **5-Level Escalation Matrix**, **SLA Tracking**, and **AI-Driven Analytics**.

## Schema Summary

| Table Name | Description | Key Functional Area |
| :--- | :--- | :--- |
| `cmp_complaint_categories` | Hierarchical master for complaint types and default SLAs. | Configuration |
| `cmp_department_sla` | Granular SLA & Escalation rules per Department/User. | Configuration (SLA) |
| `cmp_complaints` | The core transaction table for all tickets. | Core Operations |
| `cmp_complaint_actions` | Audit trail for status changes, comments, and escalations. | Audit & History |
| `cmp_medical_checks` | Specialized log for Safety/Medical compliance (e.g., Alcohol Tests). | Compliance |
| `cmp_ai_insights` | Stores Machine Learning predictions (Sentiment, Risk Score). | Analytics |
| *sch_entity_groups* | Grouping mechanism for diverse entities (Helpers, Ref tables). | *Shared Component* |

---

## Table Details

### 1. `cmp_complaint_categories`
**Purpose**: Defines the taxonomy of complaints (e.g., "Transport" -> "Rash Driving") and sets baseline expectations for resolution times.
**Key Relationships**:
- Parent-Child relationship (`parent_id`) for hierarchy.
- Linked to `sys_groups` for default escalation targets.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique Identifier. |
| `parent_id` | BIGINT FK | Self-reference. If NULL, it's a Root Category (e.g., "Transport"). If set, it's a Sub-category. |
| `name` | VARCHAR | Display name (e.g., "Rash Driving"). |
| `code` | VARCHAR | Short code for integrations (e.g., "RASH_DRV"). |
| `severity_level_id` | BIGINT FK | Default severity (1-10) from `sys_dropdown_table`. |
| `priority_score_id` | BIGINT FK | Default priority (1-5) from `sys_dropdown_table`. |
| `default_expected_resolution_hours` | INT | Baseline Service Level Agreement (SLA) in hours. |
| `default_escalation_hours_l[1-5]` | INT | Hours before auto-escalation to respective level. |
| `is_medical_check_required` | BOOL | Flag triggers the UI to ask for medical/safety evidence. |

---

### 2. `cmp_department_sla`
**Purpose**: Overrides default Category SLAs for specific Departments, Users, or Vendors. Allows highly specific rules (e.g., "Principal's complaints escalated faster").
**Key Relationships**:
- Links `complaint_category_id` to specific Targets (`target_department_id`, `target_vendor_id`, etc.).

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique Identifier. |
| `complaint_category_id` | BIGINT FK | The category this rule applies to. |
| `target_department_id` | BIGINT FK | (Optional) If set, rule applies only to this Dept. |
| `target_user_id` | BIGINT FK | (Optional) Rule applies to specific user. |
| `dept_expected_resolution_hours` | INT | Override for resolution time. |
| `escalation_l[1-5]_entity_group_id` | BIGINT FK | **Escalation Target**: The Group of users who receive the escalation at Level X. |

---

### 3. `cmp_complaints`
**Purpose**: The central ticket registry. Handles polymorphic Complainants (Student/Parent/Staff) and Targets (Driver/Teacher/Asset).
**Key Relationships**:
- Linked to `sys_users` (Complainant & Assignees).
- Linked to `cmp_complaint_categories` (Classification).
- Linked to `sys_dropdown_table` (Status, Priority).

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique Identifier. |
| `ticket_no` | VARCHAR | Human-readable unique ID (e.g., CMP-2025-001). |
| `complainant_type_id` | BIGINT FK | Defines WHO raised it (Student, Parent, Anonymous). |
| `complainant_user_id` | BIGINT FK | ID of the user (NULL if Anonymous). |
| `target_user_type_id` | BIGINT FK | Defines TARGET type (Driver, Staff, Facility). |
| `target_selected_id` | BIGINT | ID of the target entity. |
| `category_id` | BIGINT FK | The nature of the complaint. |
| `status_id` | BIGINT FK | Current State (Open, Resolved, Closed). |
| `assigned_to_user_id` | BIGINT FK | The specific officer currently working on it. |
| `resolution_due_at` | DATETIME | Calculated Deadline based on SLA. |
| `is_escalated` | BOOL | Flag if SLA was breached. |
| `current_escalation_level` | TINYINT | 0-5 indicating how high it has gone. |
| `dept_specific_info` | JSON | Flexible storage for domain-specific data (e.g., "Route No" for Transport). |

---

### 4. `cmp_complaint_actions`
**Purpose**: An immutable audit log of everything that happens to a complaint.
**Key Relationships**:
- Child of `cmp_complaints`.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique Identifier. |
| `complaint_id` | BIGINT FK | Parent Ticket. |
| `action_type_id` | BIGINT FK | Event type (Comment, Status Change, Escalation). |
| `performed_by_user_id` | BIGINT FK | Who performed the action (NULL for System/Bot). |
| `notes` | TEXT | Comments or System Messages. |
| `is_private_note` | BOOL | Visibility flag (Internal vs External). |
| `action_timestamp` | TIMESTAMP | When it happened. |

---

### 5. `cmp_medical_checks`
**Purpose**: Stores structured compliance data for complaints involving safety/health risks (e.g., Alcohol verification for drivers).
**Key Relationships**:
- Child of `cmp_complaints`.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique Identifier. |
| `complaint_id` | BIGINT FK | Parent Ticket. |
| `check_type_id` | BIGINT FK | Type of Test (Alcohol, Drug, Injury). |
| `result` | VARCHAR | (Positive/Negative/Inconclusive) - Mapped to Dropdown. |
| `reading_value` | VARCHAR | Numeric result (e.g., BAC 0.08). |
| `evidence_uploded` | BOOL | Flag indicating files exist in `sys_media`. |

---

### 6. `cmp_ai_insights`
**Purpose**: Stores AI-generated metadata for predictive analysis and risk scoring.
**Key Relationships**:
- One-to-One with `cmp_complaints`.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT PK | Unique Identifier. |
| `complaint_id` | BIGINT FK | Parent Ticket. |
| `sentiment_score` | DECIMAL | -1.0 (Angry) to +1.0 (Happy). |
| `escalation_risk_score` | DECIMAL | 0-100% (Probability of breaching SLA). |
| `predicted_category_id` | BIGINT FK | AI's guess at the category (for auto-triage). |
| `safety_risk_score` | DECIMAL | 0-100% (Probability of safety violation). |
