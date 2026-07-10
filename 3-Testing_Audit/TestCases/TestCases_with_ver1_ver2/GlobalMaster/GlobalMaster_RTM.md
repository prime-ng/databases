# GlobalMaster (GLB) — Requirements Traceability Matrix (RTM)

**Generated:** 2026-Jul-09 · **Mode:** report · **Baseline:** `GLB_FRD_Complete_2026-06-29.md` (15 REQ / 34 BR / 3 RPT) + `GlobalMaster_Complete_Audit_2026-06-29.md`
**Chain:** Requirement/FRD/DDL (Source) → BC → TC → V1/V2 method → (audit-equivalent) defect.
**Note:** there is no `GlobalMaster_v1` requirement screen folder; requirement identity is taken from the FRD REQ IDs + real registered `central.global-master.*` routes.

## Coverage by FRD requirement (only the 5 route-registered screens are generated)

| FRD REQ | Screen | Generated feature | Primary table | Prefix | Key BCs | TC bands covered | Verdict | Blocking defects |
|---------|--------|-------------------|---------------|--------|---------|------------------|---------|------------------|
| REQ-GLB-001 | Country | ✅ Country | `glb_countries` | `glb_` | BC-DB, BC-VAL, BC-AUTH(`prime.country.*`), BC-BIZ(cascade), BC-REF(states RESTRICT), BC-EDG | 01–09,10–19,30–49,50–59,60–79,90–99 | PARTIAL (defective source proven) | SEC-GLB-001, BUG-GLB-004 |
| REQ-GLB-008 | Language | ✅ Language | `glb_languages` | `glb_` | BC-DB, BC-VAL(dir ENUM), BC-AUTH(`prime.language.*` live), BC-BIZ(log labels) | 01–09,30–49,50–59,90–99 | PARTIAL | BUG-GLB-006a/b, D30; SEC-GLB-010/005 **not repro on live central route** |
| REQ-GLB-011 | Dropdown | ✅ Dropdown | `sys_dropdown_table` | `sys_` | BC-DB, BC-VAL(under-validated), BC-AUTH(`prime.dropdown.*`), BC-BIZ(ordinal/org_id), BC-INT(jnt) | 01–09,10–19,30–49,50–59,60–79,90–99 | PARTIAL | VAL-GLB-001, BUG-GLB-005, BUG-GLB-009, PERF-GLB-001 |
| REQ-GLB-013 | Session-Board Hub | ✅ SessionBoardSetup | `glb_academic_sessions`+`glb_boards` | `glb_` | BC-DB, BC-AUTH(`prime.board.viewAny`), BC-BIZ(single-current), BC-EDG(broken CRUD) | 01–09,10–19,50–59,70–79 | BROKEN (proven) | BUG-GLB-001 (reconciled: not-repro), DATA-GLB-002, BUG-GLB-003, dual-ctrl |
| RPT-GLB (audit trail) | Activity Log | ✅ ActivityLog | `sys_activity_logs` / `sys_central_activity_logs` | `sys_` | BC-DB, BC-AUTH(`prime.activity-log.*`), BC-BIZ(morphTo,event strings), BC-EDG | 01–09,50–59,60–79 | PARTIAL | BUG-GLB-ALOG-01/02/03, MIG-GLB-001 |

## Business-rule traceability (selected, audit-critical)

| BR | Rule | Feature | Covered by | Status |
|----|------|---------|-----------|--------|
| BR-GLB-001 | Country deactivation cascades to all descendants (states→districts→cities) | Country | V2 test_42 (proves cities OMITTED) | MISSING in source → BUG-GLB-004 |
| BR-GLB-020 | Only authorised users may create/edit a language | Language | V2 test_51–57 (live Prime gate `prime.language.*`) | Enforced on live central route (GLB module twin latently ungated) |
| BR-GLB-022 | Persist only validated fields | Country, Dropdown | Country V1-17/18; Dropdown V2-30/36 | Violated (mass-assign / under-validation) → SEC-GLB-001, VAL-GLB-001 |
| BR-GLB-007 | Exactly one current academic session | SessionBoardSetup | V2 test_73 (DB `current_flag` unique only) | PARTIAL (DB-only; app never sets) → BUG-GLB-003 |
| BR-GLB-008 | Setting current clears others | SessionBoardSetup | V2 test_73 | MISSING in app layer → BUG-GLB-003 |
| BR-GLB-021 | Permanent removal uses dedicated forceDelete permission | Country, Dropdown, Language | each V2 permission band (50–59) | Feature-verified (District `forceDelete` mis-perm is out-of-scope BUG-GLB-007) |
| BR-GLB-023/024 | Search escapes LIKE wildcards + throttled | Dropdown, ActivityLog | Dropdown V2-48/49 (dead route); ActivityLog V2-53 (ungated search) | Partial/defective → BUG-GLB-005, BUG-GLB-ALOG-01 |

## Not-generated screens (route/registration gaps — see Feature Inventory)

State, District, City, AcademicSession, Board, Module, Plan, GeographySetup/location-setup, GlobalMasterController(api stub) — present in source but not deterministically registered under `central.global-master.*` (SEC-GLB-005, DUP-WEB-001, BUG-GLB-001, BUG-GLB-005). Candidates for a follow-up run after the P0/P1 route-registration + missing-model defects are fixed. Every such screen is listed with its reason in `GlobalMaster_Feature_Inventory.md`.

## Traceability integrity

- Every generated feature: each BC carries a `Source` tag; every TC references ≥1 BC; V2 method count ≥ 2× V1 (82 → 287 module-wide, 3.50×); each V2 method maps back to a TC/BC via the per-feature V2 Method Index.
- Every audit defect in scope has a proving test asserting **current** behaviour (to be inverted once source is fixed).
- Cross-Reference Findings + Coverage-Score tables present in all 5 Gap Analyses.
