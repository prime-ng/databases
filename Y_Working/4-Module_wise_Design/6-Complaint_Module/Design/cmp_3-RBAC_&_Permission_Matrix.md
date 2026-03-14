# RBAC & Permission Matrix — Complaint & Grievance Management

Role-Based Access Control (RBAC) & Permission Matrix
RBAC engine and aligns with legal, privacy, and school-safety requirements.

## 1. RBAC DESIGN OBJECTIVES

- The RBAC system must:
- Protect student & parent privacy
- Ensure fair and unbiased complaint handling
- Support multi-level escalation
- Restrict sensitive medical & alcohol test data
- Enable analytics without data leakage

## 2. ROLE CATEGORIES (HIGH LEVEL)

### A. Complainant Roles

- Parent
- Student
- Staff

### B. Operational Roles

- Complaint Officer
- Transport Incharge
- Department Head
- Compliance Officer

### C. Management Roles

- Principal
- Director / Management
- Trust / Board (View only)

### D. System Roles

- System (Auto escalation / SLA engine)
- Auditor (Read-only)

## 3. PERMISSION DIMENSIONS

Each role is evaluated across six dimensions:

- Create Complaint
- View Complaint
- Edit Complaint
- Take Action
- Escalate
- View Analytics

## 4. MASTER PERMISSION MATRIX

🧩 LEGEND

✅ Allowed

🔒 Restricted

❌ Not Allowed

🕶 Partial (masked / own scope)

### 5. ROLE PERMISSION MATRIX

🧩 LEGEND

✅ Allowed

🔒 Restricted

❌ Not Allowed

🕶 Partial (masked / own scope)

| Role	| Create	| View	| Edit	| Action	| Escalate	| Analytics
| --- | --- | --- | --- | --- | --- | ---
Parent	| ✅	| 🕶 (Own)	| ❌	| ❌	| ❌	| ❌
Student	| ✅	| 🕶 (Own)	| ❌	| ❌	| ❌	| ❌
Staff (Complainant)	| ✅	| 🕶 (Own)	| ❌	| ❌	| ❌	| ❌
Complaint Officer	    | ❌	| ✅	| 🔒	| ✅	| 🔒	| 🕶
Transport Incharge	| ❌	| 🕶 (Transport)	| 🔒	| ✅	| 🔒	| 🕶
Department Head	    | ❌	| 🕶 (Dept)	| 🔒	| ✅	| ✅	| 🕶
Compliance Officer	| ❌	| ✅	| 🔒	| ✅	| ✅	| ✅
Principal	        | ❌	| ✅	| ❌	| ❌	| ✅	| ✅
Director / Mgmt	    | ❌	| ✅	| ❌	| ❌	| ✅	| ✅
Auditor	            | ❌	| 🕶	| ❌	| ❌	| ❌	| 🕶
System	            | ❌	| ❌	| ❌	| ✅	| ✅	| ❌



## 6. SCOPE RESTRICTIONS (CRITICAL)

### 6.1 Scope Rules

Scope Type	Rule
Own	Only complaints created by user
Department	Complaints targeting own department
Transport	Complaints where is_transport_related = 1
Medical	Only Compliance Officer & Principal
Alcohol Test	Compliance Officer only

## 7. SENSITIVE DATA MASKING RULES

### 7.1 Medical / Alcohol Data

Role	Access
Compliance Officer	Full
Principal	View result only
Transport Head	View status only
Others	❌
Example:
Result: Positive → visible
Test values → hidden

## 8. ACTION-LEVEL PERMISSIONS

### 8.1 Action Mapping

Action Type	Allowed Roles
Assign	Complaint Officer
Investigate	Officer, Transport Incharge
MedicalCheck	Compliance Officer
WarningIssued	Department Head
Suspension	Principal
Escalated	System / Head
Closed	Compliance Officer

## 9. RBAC TECHNICAL MODEL (DB-AGNOSTIC)

### 9.1 Recommended RBAC Entities

roles

permissions

role_permissions

user_roles

data_scopes

Permission Naming Convention
complaint.create
complaint.view.own
complaint.view.transport
complaint.action.medical
complaint.escalate
complaint.analytics.view

## 10. AUDIT & LEGAL COMPLIANCE

✔ Every action logged
✔ Role & user ID captured
✔ IP / Device optional
✔ No silent privilege escalation

## 10. WHY THIS RBAC MODEL IS ENTERPRISE-GRADE

✔ Prevents data misuse
✔ Supports school safety laws
✔ Scales across modules
✔ Analytics without privacy breach
✔ AI-ready permissions