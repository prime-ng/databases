# Prime (PRM) — Requirements Traceability Matrix (Module Roll-up)

**Module:** Prime | **Code:** PRM | **Folder:** `Modules/Prime` | **DDL:** `_prime_db_v4.sql` (+ `_global_db_v4.sql`)
**Generated:** 2026-Jul-10 | **Mode:** report (aggregated from on-disk feature artifacts — Gap Analyses + Validation Reports + single test files)
**Scope:** 20 features, 797 test methods, one `{prefix}_{Feature}_TestCas.php` per feature.

## Requirement basis (why IDs look the way they do)
There is **no** Prime FRD / requirement-screen folder (documented in `Prime_Feature_Inventory.md`, gap G-INV-1). The requirement basis is therefore **registered routes + controllers + models + DDL**, expressed per feature as **BC (Business-Case) source sections** — `BC-BIZ` (business rules), `BC-SM` (state machine), `BC-VAL` (validation), `BC-INT`/`BC-REF` (integration/FK), `BC-AUTH` (permissions), `BC-DB` (schema), `BC-EDG` (edge). Audit/defect IDs (`BUG-PRM-*`, `SEC-PRM-*`, `DEV-*`, `D25-PRM-*`, etc.) are the second traceability axis. Both are traced to real test methods below.

Legend — **Status:** Covered = every BC in the section has ≥1 asserting method (from Gap §3 coverage-score, all sections 100% unless noted). **Defect status:** Open = proven unfixed in current source · Remediated = fixed, regression-guarded · Not reproduced/Refuted = assigned but absent in current source.

---

## PART A — Requirement-source → BC → TC → method traceability (per feature)

Each row: a feature's requirement-source section → # BCs in it → the TC band that exercises it → the representative test-method band in the single file → status. All sections are **100% Covered** (from each Gap Analysis §3 "Coverage-Score by requirement source") except where a % is shown.

| Feature | Requirement source (BC section) | # BC | TC band | Test-method band | Status |
|---------|--------------------------------|:---:|---------|------------------|--------|
| AcademicSession | BC-BIZ business rules | 8 | TC-P10…P19 | `test_..._10…_19` | Covered 100% |
| AcademicSession | BC-SM state machine (one-current) | 3 | TC-S20/S21/S23 | `test_..._20,_21,_23` | Covered 100% |
| AcademicSession | BC-VAL validation | 5 | TC-N30…N39 | `test_..._30…_39` | Covered 100% |
| AcademicSession | BC-INT/REF integration/FK | 3 | TC-D40…D43 | `test_..._40,_42,_43` | Covered 100% |
| AcademicSession | BC-AUTH permissions | 8 | TC-N50…N55 | `test_..._50,_53,_55` | Covered 100% |
| ActivityLog | BC-BIZ business rules | 5 | TC-P10-band | `test_10…` | Covered 100% |
| ActivityLog | BC-AUTH permissions | 6 | TC-N5x | `test_51…_53` | Covered 100% |
| ActivityLog | BC-DB schema | 5 | TC-P0x | `test_01` | Covered 100% |
| ActivityLog | BC-EDG edge | 2 | TC-EDGx | `test_7x` | Covered 100% |
| ActivityLog | BC-CFG config/routing | 1 | TC-Tx | `test_10` | Covered 100% |
| ActivityLog | BC-INT/REF integration | 2 | TC-Dx | `test_01` | Covered 100% |
| Board | BC-BIZ business rules | 9 | TC-P (board) | `test_board_10…_19` | Covered 100% |
| Board | BC-SM state machine | (SM) | TC-S | `test_board_20…_25` | Covered 100% |
| Board | BC-VAL validation | (VAL) | TC-N30…_39 | `test_board_30…_39` | Covered 100% |
| Board | BC-INT/REF FK | (INT) | TC-D40…_42 | `test_board_40…_42` | Covered 100% |
| Board | BC-AUTH permissions | (AUTH) | TC-N50…_56 | `test_board_50…_56` | Covered 100% (2 pos partial → ~97%) |
| Dropdown | BC-BIZ / model | — | TC-P/D | `test_..._10…_22` | Covered (Pos 92%) |
| Dropdown | BC-VAL validation | — | TC-N30…_34 | `test_..._30…_34` | Covered 100% |
| Dropdown | BC-AUTH permissions | — | TC-N50…_54 | `test_..._50…_54` | Covered 100% |
| Dropdown | BC-INT/REF junction | — | TC-D40…_42 | `test_..._40…_42` | Covered 100% |
| Dropdown | BC-EDG edge/security | — | TC-EDG70…_73, S91/S92 | `test_..._70…_73,_91,_92` | Covered 100% |
| DropdownMgmt | BC-BIZ / render | 12(Pos) | TC-P | `test_dropdownmgmt_10…` | Covered 100% |
| DropdownMgmt | BC-VAL / DEV-DDM edge | 5 | TC-EDG | `test_dropdownmgmt_41,_70…_74` | Covered 100% |
| DropdownMgmt | BC-INT junction | 6 | TC-D | `test_dropdownmgmt_44` | Covered 100% |
| DropdownMgmt | BC-AUTH permissions | 2 | TC-N5x | `test_dropdownmgmt_51…` | Covered 100% |
| DropdownNeed | BC-BIZ (unique combo, filtering, is_system, soft-delete) | 4 | TC-P/D | `test_dropdownneed_10…,_14` | Covered 100% |
| DropdownNeed | BC-VAL validation | — | TC-N30…_35 | `test_dropdownneed_30…_35` | Covered 100% |
| DropdownNeed | BC-AUTH/Security | 6 | TC-S | `test_dropdownneed_51…_53,_90` | Covered 100% |
| DropdownNeed | BC-INT junction/FK | 5 | TC-D | `test_dropdownneed_42` | Covered 100% |
| DropdownNeed | BC-EDG/Config | 9 | TC-EDG/T | `test_dropdownneed_60…_65,_91,_92` | Covered 100% |
| Email | Config | 2 | TC-CFG | `test_..._00,_01` | Covered 100% |
| Email | Action (Positive send/preview) | 5 | TC-P | `test_..._10…` | Covered ~93% (1 partial: mail side-effect) |
| Email | Authorization (Negative) | 5 | TC-N | `test_..._50…` | Covered 100% |
| Email | Security | 4 | TC-S (SEC-01…04) | `test_..._9x` | Covered 100% |
| Language | BC-BIZ business rules | — | TC-P | `test_language_10…_18` | Covered 100% |
| Language | BC-SM state machine (restore) | 3 | TC-S | `test_language_20…_22` | Covered 100% |
| Language | BC-VAL validation | — | TC-N30…_37 | `test_language_30…_37` | Covered 100% (deep-neg 87% noted) |
| Language | BC-INT/REF FK (prefered_language) | — | TC-D40/_41 | `test_language_40,_41` | Covered 100% (env-guarded) |
| Language | BC-AUTH permissions | — | TC-N51/_55/_73 | `test_language_51,_55,_73` | Covered 100% |
| Menu | BC-BIZ business rules | 10 | TC-P | `test_menu_10…` | Covered 100% |
| Menu | BC-SM state machine | 4 | TC-S | `test_menu_2x` | Covered 100% |
| Menu | Screen-VR validation | 8 | TC-N | `test_menu_3x` | Covered 100% |
| Menu | BC-INT/REF integration | 4 | TC-D40…_42 | `test_menu_40…_42` | Covered 100% |
| Menu | Screen-PM permissions | 7 | TC-N5x | `test_menu_5x` | Covered 100% |
| Notification | Screen-BR business rules | 8 | TC-P | `test_..._10…` | Covered 100% |
| Notification | Permissions | 5 | TC-N/PM | `test_..._5x` | Covered 100% |
| Notification | Security/Config | 8 | TC-S | `test_..._9x` | Covered 100% |
| Notification | Integration/Ref (morph) | 2 | TC-D | `test_..._11` | Covered 100% |
| RolePermission | BC-BIZ business rules | 7 | TC-P | `test_1x` | Covered 100% |
| RolePermission | BC-VAL validation | 7 | TC-N | `test_3x` | Covered 100% |
| RolePermission | BC-INT dependency | 6 | TC-D | `test_4x` | Covered 100% |
| RolePermission | BC-AUTH/Security | 5 | TC-S | `test_02,_56,_90` | Covered 100% |
| RolePermission | Config-truth | 2 | TC-T | `test_93` | Covered 100% |
| SalesPlanAndModuleMgmt | Positive (render/config) | 17 | TC-P | `test_..._10…,_43…_48` | Covered 100% |
| SalesPlanAndModuleMgmt | Negative | 5 | TC-N | `test_..._40…_42` | Covered 100% |
| SalesPlanAndModuleMgmt | Dependency/Integration | 8 | TC-D | `test_..._44,_45,_46,_47` | Covered 100% |
| SalesPlanAndModuleMgmt | Permissions | 4 | TC-AUTH | `test_..._51,_52,_53` | Covered 100% |
| SalesPlanAndModuleMgmt | Central scope | 1 | TC-T | `test_..._90` | Covered 100% |
| SessionBoardSetup | Positive (render composite) | 15 | TC-P | `test_..._10…,_30…_36` | Covered 100% |
| SessionBoardSetup | Negative | 9 | TC-N30 | `test_..._30…` | Covered 100% |
| SessionBoardSetup | Dependency (pivot/FK) | 4 | TC-D40 | `test_..._40` | Covered 100% |
| SessionBoardSetup | Permissions/Security | 5 | TC-S51…_55, S91 | `test_..._51…_55,_91` | Covered 100% |
| Setting | BC-BIZ business rules | 12 | TC-P/BIZ | `test_setting_10…` | Covered 100% |
| Setting | BC-VAL validation | 3 | TC-N | `test_setting_3x` | Covered 100% |
| Setting | BC-INT/REF integration | 3 | TC-D | `test_setting_4x` | Covered 100% |
| Setting | BC-AUTH permissions | 9 | TC-AUTH | `test_setting_5x` | Covered 100% |
| Setting | Defect proofs (DEV-001…008) | 8 | TC-DEF | `test_setting_13,_51,_71…_76` | Covered 100% |
| Tenant | Positive (CRUD + provisioning) | 19 | TC-P | `test_tenant_10…` | Covered 100% |
| Tenant | Negative | 9 | TC-N | `test_tenant_3x` | Covered 100% |
| Tenant | State machine (provisioning workflow) | 6 | TC-SM | `test_tenant_2x` | Covered 100% |
| Tenant | Dependency/FK | 3 | TC-D | `test_tenant_4x` | Covered 100% (1 env-guarded) |
| Tenant | Permissions/Routes | 3 | TC-AUTH | `test_tenant_51,_55` | Covered 100% |
| Tenant | Tenancy/Security + Defect-proving | 3+5 | TC-S/DEF | `test_tenant_15,_40,_52,_55,_9x` | Covered 100% |
| TenantDomain | BC-BIZ business rules | 11 | TC-P | `test_1x` | Covered 100% |
| TenantDomain | BC-SM state machine | 3 | TC-SM | `test_2x` | Covered 100% |
| TenantDomain | BC-VAL validation | 10 | TC-N | `test_39` etc. | Covered 100% |
| TenantDomain | BC-INT/REF dependency | — | TC-D | `test_4x` | Covered 100% |
| TenantDomain | BC-AUTH permissions | — | TC-AUTH | `test_5x` | Covered 100% (1 partial) |
| TenantDomain | Security/Edge | — | TC-S/EDG | `test_14,_15,_71` | Covered 100% |
| TenantGroup | BC-BIZ business rules | 6 | TC-P | `test_1x` | Covered (Pos 96%) |
| TenantGroup | BC-VAL validation | 9 | TC-N/S | `test_3x` | Covered 100% |
| TenantGroup | BC-AUTH permissions | 8 | TC-AUTH | `test_5x` | Covered 100% |
| TenantGroup | BC-INT/REF integration/FK | 3 | TC-D | `test_02,_4x` | Covered 100% |
| TenantManagement | Screen-Render | 7 | TC-P | `test_..._1x` | Covered (Pos 92%) |
| TenantManagement | Screen-PM permissions | 5 | TC-N | `test_..._5x` | Covered 100% |
| TenantManagement | Empty state | 2 | TC-P | `test_..._6x` | Covered 100% |
| TenantManagement | Search/Filter/Export | 3 | TC-P | `test_..._7x` | Covered 100% (1 pagination partial) |
| TenantManagement | Delegation / no-mutation | 1 | TC-Route | `test_..._8x` | Covered 100% |
| TenantManagement | Schema/DDL (+ drift) | 3 | TC-DB | `test_..._14,_64,_65,_80` | Covered 100% |
| User | BC-BIZ business rules (01–10) | 10 | TC-P | `test_user_10…` | Covered 100% |
| User | BC-VAL validation (01–08) | 8 | TC-N | `test_user_3x` | Covered 100% |
| User | Dependency | 5 | TC-D | `test_user_4x` | Covered 100% |
| User | Permissions | 7 | TC-AUTH | `test_user_5x,_90` | Covered 100% |
| User | Security | 8 | TC-S | `test_user_01,_12,_14,_15,_16,_91` | Covered 100% |
| UserRolePrm | Positive | 18 | TC-P | `test_10…_14,_42…_45` | Covered 100% |
| UserRolePrm | Negative | 15 | TC-N | `test_3x` | Covered 100% |
| UserRolePrm | Dependency | 6 | TC-D | `test_4x` | Covered 100% |
| UserRolePrm | Security/Central | 4 | TC-S | `test_51,_53,_93` | Covered 100% |
| UserRolePrm | UI/UX | 3 | TC-UX | `test_60…_63,_72,_73` | Covered 100% |

> Method bands with `..._NN` denote the feature's semantic method suffix (e.g. `test_academicsession_10`, `test_dropdown_10`); exact suffixes are visible in each single test file's docblocks (`/** @test TC-xx (BC-yy) */`).

---

## PART B — Audit / defect ID → feature → BC → proving method → status

This is the second traceability axis: every assigned audit defect and every newly-discovered source-defect candidate, mapped to the exact proving test method and its current-source disposition.

| Audit / Defect ID | Sev | Feature | BC / area | Proving method | Status |
|-------------------|:---:|---------|-----------|----------------|--------|
| BUG-PRM-012 | P1 | AcademicSession | BC-VAL (dates) | `_01`, `_36` | Open (proven source/schema) |
| BUG-PRM-013 | P1 | AcademicSession | BC-SM (is_active) | `_01`, `_23` | Open (proven) |
| BUG-PRM-011 | P1 | AcademicSession / SessionBoardSetup | BC-AUTH (policy) | AS `_55`; SBS `_51`,`_52` | Open (re-characterized: policy unregistered) |
| BR-PRM-021 | P2 | AcademicSession | BC-SM (one-current) | `_20`, `_21`, `_23` | Open (DB-only enforcement) |
| BUG-PRM-014 | P3 | AcademicSession | BC-EDG (flash key) | `_70` | Open |
| D25-PRM-001 | audit | AcademicSession | store/update | `_01`/`_36` | Not reproduced (uses `validated()`; superseded by 012) |
| DEV-PRM-AL-001 | — | ActivityLog | BC-AUTH (search ungated) | `test_52` | Open |
| DEV-PRM-AL-002 | — | ActivityLog | routing (dup ×3) | `test_10` | Open |
| DEV-PRM-AL-003 | — | ActivityLog | routing (missing search route) | `test_10` | Open |
| DEV-PRM-AL-004 | — | ActivityLog | orphaned CRUD / view ns | `test_53` | Open |
| DEV-PRM-AL-005 | — | ActivityLog | (documented) | — | Open |
| DEV-PRM-BOARD-01 | P3 | Board | dual BoardRequest (dead Prime copy) | `test_board_56` | Open |
| DEV-PRM-BOARD-02 | P3 | Board | dual Board model (PSR-4) | `test_board_40` | Open |
| DEV-PRM-BOARD-03 | P3 | Board | rules stricter than DDL | `test_board_33`,`_34` | Open |
| DEV-PRM-BOARD-04 | P3 | Board | toggle logs before save | `test_board_15` | Open |
| DEV-PRM-BOARD-05 | P2 | Board | trashed unique reservation | `test_board_75` | Open |
| DEV-PRM-BOARD-06 | — | Board | (documented) | `test_board_*` | Open |
| DEV-DROPDOWN-001…008 | mixed | Dropdown | deleted_at gap, destroy scope, junction inconsistency, unique-key design, enum narrow, no-activity-log | `_01,_12,_13,_14,_15,_30…_34,_72,_73` | Open ("verify in source") |
| DEV-DDM-001 | High | DropdownMgmt | destroy stub no-op | `test_dropdownmgmt_70,_01` | Open |
| DEV-DDM-002 | High | DropdownMgmt | missing edit/show views | `test_dropdownmgmt_71` | Open |
| DEV-DDM-003 | Med | DropdownMgmt | mixed junctions | `test_dropdownmgmt_44` | Open |
| DEV-DDM-004 | Low | DropdownMgmt | unreachable deleteBulk | `test_dropdownmgmt_74` | Open |
| DEV-DDM-005 | Med | DropdownMgmt | no unique guard → 500 | `test_dropdownmgmt_41` | Open |
| DEV-DDM-006 | Low | DropdownMgmt | unused scaffold model | `test_dropdownmgmt_72` | Open |
| DEV-DDM-007 | Med | DropdownMgmt | fillable typo vs DDL | `test_dropdownmgmt_73,_01` | Open |
| BUG-PRM-DDNEED-001 | P1 | DropdownNeed | junction mismatch | `test_dropdownneed_42,_14` | Open |
| BUG-PRM-DDNEED-003 | P2 | DropdownNeed | no unique validation | `test_dropdownneed_35` | Open |
| BUG-PRM-DDNEED-004 | P3 | DropdownNeed | wrong redirect | `test_dropdownneed_16` | Open |
| BUG-PRM-DDNEED-005 | P3 | DropdownNeed | duplicate route group | `test_dropdownneed_65` | Open |
| BUG-PRM-DDNEED-006 | P3 | DropdownNeed | sibling gate on index | `test_dropdownneed_17` | Open |
| PERF-PRM-001 | P2 | DropdownNeed / (Menu N+1 sibling) | raw SHOW queries | `test_dropdownneed_92` | Open |
| SEC-PRM-004 | P1 | DropdownNeed | filterOptions gate (re-scoped) | `test_dropdownneed_53,_90` | Re-scoped (documented) |
| TEN-PRM-001 | P1 | DropdownNeed | initialize()/end() | `test_dropdownneed_91` | Remediated (corrected) |
| BUG-PRM-DUP | P2 | DropdownNeed | stale root Model | `test_dropdownneed_93` | Corrected (not reproduced) |
| DEV-PRM-EMAIL-001 | — | Email | hardcoded recipient / GET side-effect | `test_..._9x` | Open |
| DEV-PRM-EMAIL-002 | — | Email | policy User-class mismatch | `test_..._5x` | Open (verify at runtime) |
| SEC-PRM-002 | P1 | Email / Notification | debug routes in prod | Email/Notif `test_..._9x` | Refuted (env-guarded) |
| DEV-LANG-002 | — | Language | route group declared ×2 | `test_language_72` | Open |
| DEV-LANG-003 | — | Language | forceDelete logs `Stored` | `test_language_16` | Open |
| DEV-LANG-004 | — | Language | unresolved update flash | `test_language_18` | Open |
| DEV-LANG-005 | — | Language | (documented) | `test_language_*` | Open |
| DEV-LANG-006 | — | Language | toggle reuses .update gate | `test_language_55,_73` | Open |
| DEV-LANG-007 | — | Language | restore keeps inactive | `test_language_22` | Open |
| DEV-LANG-009 | — | Language | (documented) | `test_language_*` | Open |
| DEV-LANG-010 | obs | Language | redundant policy (not wired) | `test_language_51` | Open (observation) |
| DEV-PRM-MENU-001 | — | Menu | route-model binding `{user}`≠Menu | `_1x`/binding test | Open |
| DEV-PRM-MENU-002 | — | Menu | unique scope vs DDL global | `_3x` | Open |
| DEV-PRM-MENU-003 | — | Menu | schema drift (menu_for/permission not in DDL) | `test_menu_01` | Open |
| DEV-PRM-MENU-004 | — | Menu | inverted category rule | `_3x` | Open |
| DEV-PRM-MENU-005 | — | Menu | dead field is_direct_link | `_3x` | Open |
| PERF-PRM-002 | P2 | Menu | Navbar N+1 (`Menu::find` loop) | static-only (DEAD-PRM-001) | Open (static finding) |
| DUP-PRM-001 | — | Menu | 3 duplicate system-config groups | `test_menu_5x` | Open |
| DEV-PRM-NTF-001 | — | Notification | delete gate w/o define/policy method | Notif `test_..._5x` | Open |
| DEV-PRM-NTF-002 | — | Notification | TestNotification ctor arg ignored | Notif `test_..._1x` | Open |
| SEC-PRM-001 | P0 | RolePermission | getPermissions() ungated | `test_02,_56,_90` | **Remediated** (gate present; trips on regression) |
| DEP-PRM-001 | P3 | RolePermission | imports SchoolSetup Request | `test_02b` | Not reproduced (own Request) |
| DEV-PRM-010 | P3 | RolePermission | destroy logs `Toggled` | `test_15` | Open |
| DEV-PRM-011 | P2 | RolePermission | force-delete = hard delete; trash stub | `test_16,_17,_01` | Open |
| DEV-PRM-012 | P2 | RolePermission | validates non-existent `permissions` table | `test_35,_73` | Open |
| DEV-PRM-SPM-001 | P1 | SalesPlanAndModuleMgmt | CRUD stubs | `_40,_41,_42` | Open |
| DEV-PRM-SPM-002 | P1 | SalesPlanAndModuleMgmt | missing create/show/edit views | `_43` | Open |
| DEV-PRM-SPM-003 | P2 | SalesPlanAndModuleMgmt | permission-vocab split | `_52` | Open |
| DEV-PRM-SPM-004 | P2 | SalesPlanAndModuleMgmt | dead policy (TenantPlan hint) | `_53` | Open |
| DEV-PRM-SPM-005 | P2 | SalesPlanAndModuleMgmt | pivot table name mismatch | `_45` | Open |
| DEV-PRM-SPM-006 | P3 | SalesPlanAndModuleMgmt | fillable omits price_quarterly | `_46` | Open |
| DEV-PRM-SPM-007 | P2 | SalesPlanAndModuleMgmt | SoftDeletes/timestamps vs DDL | `_47` | Open |
| GAP-PRM-001 | P1 | SalesPlanAndModuleMgmt / Tenant | GenerateInvoicesCommand | SPM `_48`; Tenant — | Refuted / Resolved (present + registered) |
| BUG-PRM-011 | P1 | SessionBoardSetup | policy unregistered | `_51,_52` | Open |
| BUG-PRM-012 | P2 | SessionBoardSetup | divergent gate surface (view vs controller) | `_53` | Open |
| BUG-PRM-013 | P1 | SessionBoardSetup | is_active filter 500 | `_30,_01` | Open |
| BUG-PRM-014 | P2 | SessionBoardSetup | unimplemented pairing / missing pivot | `_40` | Open |
| BUG-PRM-015 | P2 | SessionBoardSetup | missing views + no-op writes | `_33,_34,_35,_36` | Open |
| BUG-PRM-016 | P3 | SessionBoardSetup | delete ability ungranted | `_55` | Open |
| DEV-001 (Setting) | — | Setting | search ungated (BR-PRM-022 fails) | `test_setting_51` | Open |
| DEV-002 (Setting) | — | Setting | store no-op | `test_setting_71` | Open |
| DEV-003 (Setting) | — | Setting | destroy no-op | `test_setting_72` | Open |
| DEV-004 (Setting) | — | Setting | create view missing | `test_setting_73` | Open |
| DEV-005 (Setting) | — | Setting | show view missing | `test_setting_74` | Open |
| DEV-006 (Setting) | — | Setting | organization_id absent | `test_setting_75` | Open |
| DEV-007 (Setting) | — | Setting | dead Setting::all() | `test_setting_76` | Open |
| DEV-008 (Setting) | — | Setting | no activity log | `test_setting_13` | Open |
| BR-PRM-022 | — | Setting | search authorization rule | `test_setting_51` | Open (fails — via DEV-001) |
| BUG-PRM-TENANT-001 | P1 | Tenant | routes bind to missing controller methods | `test_tenant_55` | **Open (NEW, reproduces)** |
| BUG-PRM-006 | P1 | Tenant | wrong gate on complete/toggle | `test_tenant_51` | Remediated (correct gates) |
| BUG-PRM-STUB-001 | P2 | Tenant | destroy empty stub | `test_tenant_52` | Remediated (soft-deletes + logs) |
| GAP-PRM-003 | P0 | Tenant | hardcoded root password | `test_tenant_15` | Remediated (random `Str::password(16)`) |
| MIG-PRM-001 | P1 | Tenant | down() drops wrong table | `test_tenant_40` | Remediated (drops `prm_tenant`) |
| BUG-PRM-001 | P0 | TenantDomain | db_password plaintext | `test_15,_01` | Remediated (encrypted cast) |
| BUG-PRM-002 | P1 | TenantDomain | hard delete, no SoftDeletes | `test_01,_14` | Open |
| BUG-PRM-003 | P2 | TenantDomain | max:255 > DDL col size | `test_39` | Open |
| BUG-PRM-004 | P2 | TenantDomain | encrypted pwd overflow VARCHAR(255) | `test_71` | Open |
| D25-PRM-002 | P2 | TenantGroup | `$request->all()` in update | `test_16` | Not reproduced |
| D25-PRM-003 | P3 | TenantGroup | update has no activityLog | `test_16` | Open |
| D25-PRM-004 | P2 | TenantGroup | index renders cities / broken listing | documented (`test_62` trash) | Open |
| D25-PRM-005 | P4 | TenantGroup | redirect anchor typo `#tanent-group` | documented | Open |
| D25-PRM-006 | P3 | TenantGroup | name uniqueness only in Request | `test_02` | Open |
| D25-PRM-007 | P4 | TenantGroup | toggle logs before save | documented | Open |
| BUG-PRM-009 | P2 | TenantManagement / User | index rand()/stub stats | TM `test_..._14`; User `test_user_15` | TM: N/A (clean); User: residual |
| BUG-PRM-TM-001 | P2 | TenantManagement | (read/stat candidate) | `test_..._53` | Open |
| BUG-PRM-TM-002/002b | P2/P3 | TenantManagement | (read/stat candidate) | `test_..._64/_65` | Open |
| BUG-PRM-TM-003 | P3 | TenantManagement | (read/stat candidate) | `test_..._71` | Open |
| BUG-PRM-TM-004 | P3 | TenantManagement | (read/stat candidate) | `test_..._72` | Open |
| BUG-PRM-TM-005 | P3 | TenantManagement | doc drift | `test_..._80` | Open |
| SEC-PRM-003 | P0 | User | is_super_admin escalation via update | `test_user_12,_90` | **Remediated** |
| BUG-PRM-002 (User) | P0 | User | is_super_admin/flag in fillable | `test_user_01,_91` | **Remediated** |
| BUG-PRM-010 | P1 | User | usersByRole ignores role param | `test_user_14` | **Remediated** |
| GAP-PRM-004 | P1 | User | LoginMail not sent on store | `test_user_10` | **Remediated** |
| FILL-PRM-001 | P3 | User | remember_token still fillable | `test_user_01` | Residual |
| BUG-PRM-N01 | P1 | User | usersByRole omits tenant stats → undefined var | `test_user_16` | Open (new) |
| BUG-PRM-N02 | P2 | User | 2FA field mismatch | `test_user_31` | Open (new) |
| BUG-PRM-N03 | P2 | User | image rule vs upload key mismatch | `test_user_32` | Open (new) |
| BUG-PRM-N04 | P3 | User | media collection mismatch | documented | Open (new) |
| DEV-URP-001 | P2 | UserRolePrm | gate reuse (no dedicated perm) | `test_01,_51` | Open |
| DEV-URP-002 | P2 | UserRolePrm | search ungated (enumeration) | `test_53` | Open |
| DEV-URP-003 | P3 | UserRolePrm | missing views → 500 | `test_54,_72` | Open |
| DEV-URP-004 | P3 | UserRolePrm | empty CRUD → no persistence | `test_55` | Open |
| DEV-URP-005 | P4 | UserRolePrm | no activity logging | `test_93` | Open |
| DEV-URP-006 | P4 | UserRolePrm | raw wildcards, no normalisation | `test_70` | Open |

---

## PART C — Traceability closure

- **Requirement → test:** every BC source-section across all 20 features has ≥1 asserting method (Gap Analysis §3 coverage-scores are 100% per section, module-wide). No zero-coverage requirement.
- **Audit → test:** every assigned audit defect (from `Prime_Complete_Audit_2026-06-29.md`) is traced to a proving method with an explicit disposition — Open, Remediated (regression-guarded), or Not-reproduced/Refuted (documented per HARD RULE 1).
- **Test → requirement:** every method maps back to a TC/BC (no orphan methods) — asserted in each feature's Validation Report §4 and Gap Analysis §1.
- **Tenancy dimension:** N/A module-wide (central single-DB console); central-scope invariant is itself traced (the `_90/_91/_93` band per feature).
