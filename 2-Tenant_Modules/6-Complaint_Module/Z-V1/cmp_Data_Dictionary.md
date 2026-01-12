# Complaint Module - Data Dictionary

## 1. cmp_sla_configs
**Purpose:** Stores configuration for Service Level Agreements (SLA) to calculate deadlints.
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | BIGINT | Primary Key. |
| `tenant_id` | BIGINT | Multi-tenant isolation. |
| `severity_level` | VARCHAR | FK to sys_dropdown (Low, Med, High). |
| `is_transport_related` | BOOL | Distinguishes safety-critical transport issues. |
| `expected_resolution_hours` | INT | SLA target in hours. |

## 2. cmp_complaints
**Purpose:** The central table storing all grievance tickets.
| Column | Type | Description |
| :--- | :--- | :--- |
| `ticket_no` | VARCHAR | Human-readable ID (CMP-2023-001). |
| `complainant_type` | VARCHAR | Polymorphic type (Parent, Student). |
| `complainant_user_id` | BIGINT | ID of the user filing the complaint. |
| `target_type` | VARCHAR | Polymorphic target (Staff, Vehicle). |
| `target_id` | BIGINT | ID of the entity being complained about. |
| `category` | VARCHAR | Main classification (Transport, Academic). |
| `priority_score` | TINYINT | Calculated urgency (1-5). |
| `status` | VARCHAR | Lifecycle state (Open -> Resolved). |
| `resolution_due_at` | DATETIME | Deadline calculated from SLA config. |

## 3. cmp_complaint_actions
**Purpose:** Audit trail of every activity performed on a ticket.
| Column | Type | Description |
| :--- | :--- | :--- |
| `action_type` | VARCHAR | Event type (Comment, Status Change). |
| `performed_by_user` | BIGINT | User who did the action. |
| `is_private_note` | BOOL | If true, hidden from Complainant. |

## 4. cmp_medical_checks
**Purpose:** Specialized table for Transport compliance (Alcohol/fitness tests).
| Column | Type | Description |
| :--- | :--- | :--- |
| `check_type` | VARCHAR | Alcohol, Drug, Vision test. |
| `result` | VARCHAR | Positive/Negative. |
| `evidence_file_path` | VARCHAR | Path to test report/image. |

## 5. cmp_ai_insights
**Purpose:** Stores machine-learning derived metadata for decision support.
| Column | Type | Description |
| :--- | :--- | :--- |
| `sentiment_score` | DECIMAL | -1 (Negative) to 1 (Positive). |
| `escalation_risk_score` | DECIMAL | 0-100% Probability of breach. |
