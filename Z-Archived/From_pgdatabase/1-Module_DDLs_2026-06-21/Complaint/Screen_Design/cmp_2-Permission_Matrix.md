# Complaint Module - RBAC & Permission Matrix

This matrix defines the granular permissions for the Complaint & Grievance Management system across 9 distinct roles.

## 1. Role Definitions

| Role | Scope & Responsibility |
| :--- | :--- |
| **SuperAdmin** | Full system control, SLA configuration, Tenant management. |
| **Management** | Oversight, High-level reporting, Critical escalation handler (L4/L5). |
| **Principal** | School-level Head (L3/L4), handles academic & behaviour escalations. |
| **School Admin** | Operational admin, assigns tickets, initial triage (L1). |
| **Teacher** | Subject/Class grievance handler, target of some complaints. |
| **Transport Manager** | Dedicated handler for Transport/Safety-related complaints (L2). |
| **Transport Staff** | Drivers/Helpers/Conductors (Can usually only View/Reply to assigned, not resolve). |
| **Parent** | Complainant (Submitter), Tracks own tickets. |
| **Student** | Complainant (Submitter), Tracks own tickets (Age-appropriate UI). |

---

## 2. Permission Matrix

| Permission | SuperAdmin | Management | Principal | School Admin | Teacher | Tpt Manager | Tpt Staff | Parent | Student |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Create Ticket** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **View (Own)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **View (Dept/Class)**| ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| **View (All)** | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Edit (Metadata)**| ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| **Delete** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Assign/Reassign**| ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| **Resolve** | ✅ | ✅ | ✅ | ✅ | ✅* | ✅ | ❌ | ❌ | ❌ |
| **Escalate** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅* | ✅* |
| **Reopen** | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | ✅ |
| **View Reports** | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| **Config SLAs** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

**Notes:**
- **Teacher (Resolve)*:** Can only resolve tickets assigned to them (e.g., Homework/Academic issues).
- **Parent/Student (Escalate)*:** Can "Request Escalation" if SLA is breached or unsatisfied with resolution (triggered via UI button).
- **Tpt Manager**: Has Full access specifically to `category = 'Transport'`.

---

## 3. Workflow Permissions

### A. Submission Phase
- **Parents/Students** can file complaints anonymously (Optional configuration).
- **Teachers** can file complaints against Transport/Facilities on behalf of students.

### B. Investigation Phase
- **Tpt Manager** can upload Medical Reports/Alcohol Test Evidences (`cmp_medical_checks`).
- **Principal** can view private notes added by Tpt Manager.
- **Parent** CANNOT view private internal investigation notes.

### C. Resolution Phase
- **School Admin** acts as the Dispatcher (L1), assigning tickets to Teachers or Transport Mgr.
- **Principal/Management** intervenes only on L3/L4 escalations.
