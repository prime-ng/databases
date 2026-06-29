# Hostel (HST) — Complete Analysis Pack — Index
**Generated:** 2026-06-29 | **By:** Business Analyst (Complete Analysis Pack Mode) | **Spine:** `HST_FRD_2026-06-29.md`

The Functional Requirements Document is the single source of truth. Every artifact below reuses its
`REQ-HST-001..029`, `BR-HST-001..054`, and `RPT-HST-001..014` identifiers — none are renumbered.

| # | Artifact | File | Purpose |
|---|----------|------|---------|
| 0 | **FRD** (spine) | `../../../4-Requirement_Module_wise/0-FRD_Documents/HST_FRD_2026-06-29.md` | 29 REQ · 54 BR · 10 workflows · 14 reports · 10 ENH. The contract all else derives from. |
| 1 | **Requirements Traceability Matrix (RTM)** | `HST_RTM.md` | REQ ↔ BR ↔ workflow ↔ report ↔ test ↔ code-status spine |
| 2 | **Business Rules + Conditions + Validation** | `HST_Rules_Conditions_Validation.md` | BR register (standalone), Requirement-Conditions catalog, Validation & Edge-Case catalog |
| 3 | **Workflows + State Machines (FSM)** | `HST_Workflows_FSM.md` | 10 process flows + the entity FSMs (allotment, leave, complaint, sick bay, reservation, room-change, incident, bed) |
| 4 | **Data Dictionary + Cross-Module Dependency Map** | `HST_DataDictionary_Dependencies.md` | Business-entity dictionary + inbound/outbound integration map |
| 5 | **NFR Catalog + Risk Register** | `HST_NFR_Risk.md` | Measurable NFR-HST + RISK-HST entries |
| 6 | **Prioritization + Effort Estimation + Sprint Tasks** | `HST_Prioritization_Estimation.md` | MoSCoW/RICE + sprint-ready task breakdown |
| 7 | **User Stories + KPI Catalog** | `HST_UserStories_KPI.md` | Gherkin stories (every P0/P1 REQ) + KPI/metrics |

> Also written: `4-Requirement_Module_wise/5-Requirement_Conditions/Hostel_Conditions.md` (canonical conditions location) and the module-knowledge update in `AI_Brain/module-knowledge/HST_Hostel.md`.

**Scope totals (reconciled to FRD §10.4):** 29 REQ (13 P0 / 13 P1 / 3 P2) · 54 BR · 10 workflows · 14 reports · 10 ENH.

**Cross-reference to the technical audit:** the Hostel Mode A audit (`3-Audit_Reports/V1_Jun-2026/Hostel_Technical_Audit_2026-06-29.md`) found the P0 generated-column degradation (DAT-HST-001) that breaks **BR-HST-001/002** (bed/student single-active-allotment) — flagged in the RTM "Code Status" column.
