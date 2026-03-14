# Complaint Escalation & SLA Rules

Complaint Escalation & SLA Rules, written as a policy + technical implementation document, so it can be directly converted into code, cron jobs, and workflows.



## 1. OBJECTIVES OF SLA & ESCALATION SYSTEM

The escalation system ensures:

Timely resolution
  - Safety-first handling (especially Transport & Medical)
  - Automatic escalation without manual dependency
  - Audit-proof workflow
  - Fair workload distribution

## 2. SLA DEFINITION MODEL
### SLA Dimensions

 Each complaint SLA is determined by:
  - Severity Level
  - Complaint Category
  - Transport-related flag
  - Time since creation
  - Actions already taken

### SLA MASTER MATRIX (LOGICAL)
| Severity | Transport? | First Action | Resolution | Escalation |
| --- | --- | --- | --- | --- |
| Low | No | 24 hrs | 72 hrs | 72 hrs |
| Medium | No | 12 hrs | 48 hrs | 48 hrs |
| High | No | 6 hrs | 24 hrs | 24 hrs |
| High | Yes | 2 hrs | 12 hrs | 12 hrs |
| Critical | Yes | 30 mins | 6 hrs | 6 hrs |

💡 These values populate expected_resolution_hours.

## 3. SLA LIFE CYCLE STATES
    Open
    ↓
    Acknowledged (auto)
    ↓
    In-Progress
    ↓
    Resolved
    ↓
    Closed

### Automatic Transitions

**Open → In-Progress**: On first action

**Resolved → Closed**: After complainant acceptance or auto after X days

**Any → Escalated**: SLA breach or rule trigger

## 4. ESCALATION LEVELS
### Escalation Hierarchy ###
| Level | Escalates To |
| --- | --- |
| L1 | Department Officer |
| L2 | Department Head |
| L3 | Compliance Officer |
| L4 | Principal / Director |
| L5 | Board / Trust |

## 5. ESCALATION RULES (BUSINESS LOGIC)
### RULE 1: SLA TIME BREACH
IF current_time > created_at + expected_resolution_hours
AND complaint_status IN ('Open','In-Progress')
→ Escalate

### RULE 2: SAFETY / ALCOHOL FLAG
IF is_transport_related = 1
AND alcohol_suspected = 1
AND no MedicalCheck action within 2 hours
→ Escalate to L3

### RULE 3: REPEAT OFFENDER
IF target_type IN ('Driver','Staff')
AND complaint_count(target_id) >= 3 in 90 days
→ Escalate to L4

### RULE 4: CRITICAL SEVERITY
IF severity_level = 'Critical'
→ Immediate Escalation to L4
→ Notify Compliance + Management

### RULE 5: REOPENED COMPLAINT
IF complaint reopened more than once
→ Escalate one level higher than last

## 6. ESCALATION ACTION RECORDING

Every escalation must be logged in:

erp_complaint_actions
action_type = 'Escalated'
performed_by_role = 'System'
action_notes = 'Auto escalation due to SLA breach'


This ensures:

Auditability

Legal defensibility

Analytics traceability

## 7. AUTO-ASSIGNMENT RULES
### Assignment Priority Logic
1. Role availability
2. Workload (open complaints count)
3. Specialization (Transport / Medical)
4. Previous handler (continuity)

## 8. SLA BREACH CALCULATION (ANALYTICS)
### Metrics
Metric	Formula
SLA Breach %	(Breached / Total) × 100
Avg Delay	Actual - Expected
Escalation Rate	Escalated / Total

## 9. CRON / SCHEDULER DESIGN
### Recommended Jobs
Job	Frequency
SLA Monitor	Every 15 mins
Escalation Trigger	Every 15 mins
Auto Close Resolved	Daily
Repeat Offender Scan	Nightly
🔧 PSEUDO-CODE (SLA CHECK)
FOR each open complaint
  IF now > created_at + expected_resolution_hours
    IF not already escalated
      escalate_complaint()
      log_action()
      notify_next_level()

## 10. NOTIFICATION RULES
### Event	Notify
Complaint Created	Assigned Officer
Escalated	Next Level
Alcohol Suspected	Transport Head + Compliance
Resolved	Complainant
Closed	Archive

Channels:

In-app

Email

SMS (Critical only)

WhatsApp (optional)

## 11. WHY THIS ESCALATION SYSTEM IS STRONG

✔ Zero manual dependency
✔ Safety-first handling
✔ Fully auditable
✔ Configurable without DB change
✔ AI-ready for prediction