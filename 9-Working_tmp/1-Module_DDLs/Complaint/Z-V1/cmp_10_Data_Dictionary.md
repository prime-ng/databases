# Complaint Module - Data Dictionary

## 1. cmp_complaint_categories
**Purpose:** Master table for hierarchical categorization of complaints to enable granular reporting and department alignment.
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT | Primary Key. |
| `tenant_id` | BIGINT | Multi-tenant isolation. |
| `parent_id` | BIGINT | FK to Self. If NULL, it's a Main Category. If set, it's a Sub-category. |
| `name` | VARCHAR | Name of the category (e.g., "Transport", "Rash Driving"). |
| `department_name`| VARCHAR | Name of the department responsible for this category. |
| `is_active` | BOOL | Soft delete flag. |

## 2. cmp_sla_configs
**Purpose:** Stores configuration for Service Level Agreements (SLA) to calculate deadlines.
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT | Primary Key. |
| `severity_level` | VARCHAR | FK to sys_dropdown (Low, Med, High). |
| `category_id` | BIGINT | FK to cmp_complaint_categories. Optional override for specific categories. |
| `expected_resolution_hours` | INT | SLA target in hours. |

## 3. cmp_complaints
**Purpose:** The central table storing all grievance tickets.
| Column | Type | Description |
| :--- | :--- | :--- |
| `ticket_no` | VARCHAR | Human-readable ID (CMP-2023-001). |
| `complainant_type` | VARCHAR | Polymorphic type (Parent, Student). |
| `target_type` | VARCHAR | Polymorphic target (Staff, Vehicle). |
| `category_id` | BIGINT | FK to cmp_complaint_categories (Main Category). |
| `subcategory_id` | BIGINT | FK to cmp_complaint_categories (Sub Category). |
| `priority_score` | TINYINT | Calculated urgency (1-5). |
| `status` | VARCHAR | Lifecycle state (Open -> Resolved). |
| `resolution_due_at` | DATETIME | Deadline calculated from SLA config. |

## 4. cmp_complaint_actions
**Purpose:** Audit trail of every activity performed on a ticket.
| Column | Type | Description |
| :--- | :--- | :--- |
| `action_type` | VARCHAR | If Action is 'StatusChange', 'Comment', etc. |
| `performed_by_user` | BIGINT | User who did the action. |

## 5. cmp_medical_checks
**Purpose:** Specialized table for Transport compliance (Alcohol/fitness tests).
| Column | Type | Description |
| :--- | :--- | :--- |
| `check_type` | VARCHAR | Alcohol, Drug, Vision test. |
| `result` | VARCHAR | Positive/Negative. |

## 6. cmp_ai_insights
**Purpose:** Stores machine-learning derived metadata for decision support.
| Column | Type | Description |
| :--- | :--- | :--- |
| `sentiment_score` | DECIMAL | -1 (Negative) to 1 (Positive). |
| `escalation_risk_score` | DECIMAL | 0-100% Probability of breach. |
