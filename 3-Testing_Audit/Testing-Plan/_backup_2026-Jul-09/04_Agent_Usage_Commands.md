# `testcase-creator` — Usage Command Cookbook

**How to invoke:** the agent has no slash command. You delegate to it in natural language by naming it — *"Use the **testcase-creator** agent to …"* (or `@testcase-creator …` in FleetView). It reads four parameters from your request:

| Param | Values | Meaning |
|-------|--------|---------|
| `module` | e.g. `HrStaff`, `Accounting` | **Required.** The app module |
| `feature` | e.g. `LeaveType` | The feature; omit → `module` mode |
| `mode` | `feature` \| `module` \| `report` | Inferred if omitted |
| `execute` | `true` \| `false` | Also run the tests & attach proof (default false) |

**Output:** always under `{OLD_REPO}/3-Testing_Audit/TestCases/[Module]/[Feature]/` — the agent writes nowhere else.

---

## 1. Generate one feature's full 8-artifact suite  (`feature` mode)

> **Use the testcase-creator agent — mode=feature, module=Accounting, feature=TaxRate.**
> Generate the complete 8-artifact test suite. Read the real source, detect the module's test style, verify the prefix against the DDL, and write to the TestCases folder.

**Example:**
> Use testcase-creator to generate the full test suite for the **StudentFee / FeeStructure** feature.

---

## 2. Generate an entire module  (`module` mode)

> **Use the testcase-creator agent — mode=module, module=HrStaff.**
> Discover every feature, confirm the Feature Inventory, then generate the 8 artifacts for each (parents → children → junctions → reports).

**Example:**
> Use testcase-creator to build test suites for **all features of the Library module**.

---

## 3. Feature inventory only (discover, don't generate)

Features come from the screen files: **each `.md` in `{MODULE}_v1/` is one screen = one feature** (e.g. `Accounting_v1/` = 12 files → 12 features).

> Use the testcase-creator agent to **list the Feature Inventory for the Billing module** — one row per screen file in `Billing_v1/`: screen file → feature name → primary table → controller → prefix → type (CRUD/report) → output folder. Do NOT generate any artifacts yet; just return the inventory table so I can approve scope.

---

## 4. Generate + run the tests  (`execute=true`)

> **Use the testcase-creator agent — module=HrStaff, feature=Holiday, execute=true.**
> Generate the suite, then run V1 then V2 via the runner, capture the proof file, and report pass/fail with any failures classified as flake / real defect (DEV-###) / test bug.

---

## 5. Regenerate a single artifact only

Name the one file you want; the agent regenerates just that, consistent with the others.

- **Only the manual test cases:**
  > Use testcase-creator to regenerate **only the `MANUALTESTING_Require.md`** for Accounting / TaxRate.
- **Only the V2 Dusk/feature test:**
  > Use testcase-creator to regenerate **only the V2 test file** for HrStaff / LeaveType and refresh the Gap Analysis + Validation Report to match.
- **Only the TcList (Business Conditions + TC list):**
  > Use testcase-creator to produce **only the `TcList_Require.md`** (BC decomposition + TC-P/N/D list) for StudentFee / Concession.

---

## 6. Add enhanced dimensions to an existing feature

> Use the testcase-creator agent to **add the Tenancy (`TC-T`) and Security (`TC-S`) test packs** to the existing Accounting / TaxRate V2 suite — cross-tenant isolation, IDOR, mass-assignment, CSRF, XSS on every free-text field — then update the Gap Analysis and Validation Report.

**Example (single dimension):**
> Use testcase-creator to add an **API-contract assertion block** (status code + payload shape + required keys) to the Billing / Invoice JSON endpoints.

---

## 7. Fidelity dry run (regenerate an existing feature to scratch, then diff)

> Use the testcase-creator agent to **dry-run regenerate HrStaff / PayGrade into a scratch folder** (not TestCases), then diff against the committed version and report structural fidelity, method counts, and any divergence. Do not execute the tests.

---

## 8. Update tests after a source-code change

> The **Accounting / TaxRate** controller and FormRequest changed. Use testcase-creator to **re-read the source and update the suite** — refresh BC-VAL/BC-AUTH, re-map TCs, bump `test_01` schema/config assertions, and note what changed in the Validation Report.

---

## 9. Validation / lint only (no new tests)

> Use the testcase-creator agent to **run the Validation Report checklist and `php -l`** on the existing HrStaff / LeaveType artifacts — file existence, naming, structure, V2≥2×V1, TC↔method traceability — and report PASS / PASS-WITH-NOTES.

---

## 10. Roll-up reports  (`report` mode)

- **Module coverage dashboard:**
  > **Use the testcase-creator agent — mode=report, module=HrStaff.** Generate `_HrStaff_Coverage_Dashboard.md` (#V1, #V2, coverage % by category, verdict, last run, open DEV-###).
- **Requirement Traceability Matrix:**
  > Use testcase-creator (report mode) to build the **RTM for Accounting** — Requirement/FRD ID → BC → TC → method → status.
- **Program-wide defect register:**
  > Use testcase-creator (report mode) to compile the **Program Defect Register** — all DEV-### from audits + discovered, with severity and proving test.
- **Program test summary:**
  > Use testcase-creator (report mode) to produce the **Program Test Summary** — total features, % automated, % passing, category coverage, top risks.

---

## 11. Batch / phased rollout

> Use the testcase-creator agent to generate suites for **Phase 1 (P0) modules — Accounting, Billing, Payment, StudentFee**, one feature at a time. After each module, also produce its Coverage Dashboard. Pause for my review after the first feature of each module.

---

## Quick reference

| Task | One-liner |
|------|-----------|
| One feature | `testcase-creator: module=X, feature=Y` |
| Whole module | `testcase-creator: mode=module, module=X` |
| Discover features only | `testcase-creator: inventory for module X, don't generate` |
| Generate + run | `testcase-creator: module=X, feature=Y, execute=true` |
| Single artifact | `testcase-creator: regenerate only <file> for X/Y` |
| Add tenancy/security | `testcase-creator: add TC-T/TC-S packs to X/Y` |
| Dry run + diff | `testcase-creator: dry-run X/Y to scratch, diff vs committed` |
| Update after code change | `testcase-creator: re-read source & update X/Y suite` |
| Validate only | `testcase-creator: run Validation + php -l on X/Y` |
| Roll-up report | `testcase-creator: mode=report, module=X` |

> **Tip:** For big jobs (whole module / phase), the agent runs in the background and notifies you on completion. Ask it to **confirm the Feature Inventory before generating** so you approve scope first. Everything it writes lands under `3-Testing_Audit/TestCases/` and nowhere else.
