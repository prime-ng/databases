# FSSAI Records — Business Requirements

## What This Screen Does

The FSSAI Records screen manages the school's own food safety compliance documentation. Two types of records:

1. **FSSAI Licenses** — The school's food business license (Basic/State/Central) required to operate a cafeteria.
2. **Hygiene Audits** — Periodic audit records tracking hygiene scores, findings, corrective actions, and scheduled next audits.

---

## When This Screen Is Used

- The school's FSSAI license is issued or renewed and needs recording
- A hygiene audit is conducted and results need to be logged
- Admin needs to check when the current license expires
- Past audit records need to be reviewed for compliance history

---

## Key Fields at a Glance

**License Records**

**License Number**
Official FSSAI license number.

**License Type**
Basic (below ₹12 lakh turnover), State, or Central (above ₹20 crore).

**Issue Date / Expiry Date**
Issue and expiry dates. 60-day warning, 30-day critical alert.

**Licensed Entity Name**
School or cafeteria name as on the license.

**Document Upload**
Scanned copy (PDF/JPEG/PNG, max 10 MB).

**Audit Records**

**Audit Date / Auditor Name**
When and by whom the audit was conducted.

**Audit Score**
1-10 scale. < 5 = "Needs Improvement" (red), 5-7 = "Satisfactory" (yellow), >= 8 = "Compliant" (green).

**Audit Remarks / Corrective Actions**
Findings and what was done to address them.

**Next Audit Date**
Scheduled next audit.

---

## Business Rules and Conditions

**No Soft Delete**
Compliance records never soft-deleted. Outdated records deactivated (is_active = 0).

**License Requirements**
License number, type, issue date, and expiry date required. Expiry must be future.

**Audit Requirements**
Audit date, auditor name, and score (1-10) required.

**FSSAI Expiry Alerts (BR-CAF-014)**
60-day warning (yellow), 30-day critical (red + notification). More conservative than supplier (60/30 vs 30/7).

---

## Workflow Steps

**Adding a License**
Select License type → fill license details and dates → optionally upload document → submit.

**Adding an Audit**
Select Audit type → enter audit date, auditor, score, remarks → optionally add corrective actions and next audit → submit.

**Viewing Records**
Both types in one table (blue badge = License, purple badge = Audit). Expiry alert badges.

**Renewing a License**
Mark old license Inactive → create new License record with updated dates.

---

## Example Scenario

School cafeteria gets State-level FSSAI license: 12345678901234, Jan 1, 2026 to Dec 31, 2026.
- Nov 1: Yellow warning "License expires in 60 days."
- Dec 1: Red critical alert "License expires in 30 days — immediate action required."

Quarterly audit in March: Score 8.5/10 — "Compliant" (green). Corrective action: "Exhaust fans upgraded."

---

## Related Screens

- **Suppliers** — Supplier FSSAI tracking in the supplier master screen
- **Stock Items** — Stock & Compliance tab groups these together
