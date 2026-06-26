# Cross-Module Dependency Map — Prime-AI Platform
**Date:** 2026-03-26
**Version:** V2.0
**Purpose:** Document all inter-module data flows, dependency chains, integration contracts, and circular dependency risks across all 46 Prime-AI modules.

---

## 1. Dependency Map Legend

| Symbol | Meaning |
|--------|---------|
| → | Produces data for / pushes events to |
| ← | Consumes data from / receives events from |
| ↔ | Bidirectional / shared reference |
| D21 | Accounting integration event bus |
| REF | Read-only reference lookup |
| EVT | Event-driven (async, queue-based) |
| SYNC | Synchronous API call |

---

## 2. Full Dependency Matrix

| Module | Depends On (Consumes) | Consumed By (Produces For) |
|--------|----------------------|---------------------------|
| **PRM** | GLB (boards, countries), SYS (roles) | BIL (tenant subscriptions), ALL (tenant context) |
| **BIL** | PRM (tenants, plans), PAY (payments), GLB (currencies) | FAC (billing journal entries via D21), PRM (invoice status) |
| **GLB** | — (seed data only) | ALL modules (lookup tables: boards, countries, states, currencies, languages) |
| **SYS** | GLB (dropdowns seed) | ALL modules (roles, permissions, settings, media, audit logs) |
| **SCH_JOB** | SYS (scheduler config), ALL (job triggers) | ALL modules (scheduled task execution) |
| **SCH** | GLB (boards, state), SYS (permissions) | TTF, STT, TTS, STD, ATT, ACD, EXA, HRS (academic year, class-section master) |
| **TTF** | SCH (classes, periods), HRS/STD (teacher-subject mapping) | STT, TTS, DSH (foundation data for timetable) |
| **STT** | TTF (foundation), SCH (periods, days), HRS (teacher availability), SYS (constraints) | TTS (published timetable), DSH (timetable widget), ATT (period-based attendance), PAY (teacher period count) |
| **TTS** | TTF, SCH, HRS | DSH (standard timetable view), ATT, STP, PPT |
| **DSH** | ALL modules (KPI data aggregation) | — (display only, no downstream producers) |
| **STD** | SCH (class/section), GLB (nationality, religion), SYS (media) | STP, ATT, FIN, ACD, EXA, ADM, CRT, PPT, HMW, QUZ, QST, EXM, LXP, PAN, COM, HST, TPT |
| **STP** | STD, ATT, FIN, HMW, QUZ, EXM, SLB, NTF | PPT (parent sees same data), COM (student messaging) |
| **SLB** | SCH (subjects, classes), GLB (board curriculum) | SLK (book lists), HMW, QUZ, QST, EXM (topic mapping), LXP (curriculum alignment) |
| **SLK** | SLB (syllabus chapters), VND (publisher/supplier) | DOC (booklist documents), INV (book stock control) |
| **DOC** | STD, ACD, EXA, CRT (template data) | STP, PPT (downloadable documents) |
| **HMW** | SLB (topics), QNS (questions), STD (enrolled students), NTF | ACD (marks contribution), LXP (activity feed), PAN (engagement data) |
| **QUZ** | QNS (question bank), SLB (topics), STD | ACD (quiz scores), LXP (quiz activity), PAN (performance data) |
| **QST** | SLB, QNS, STD | LXP (gamification events), PAN (quest completion data) |
| **EXM** | QNS (question bank), SLB (topics), STD, ATT (exam attendance) | ACD (exam results), CRT (exam pass trigger), LXP (exam activity), PAN |
| **QNS** | SLB (topic taxonomy), SYS (media for images) | HMW, QUZ, QST, EXM, LXP (shared question repository) |
| **FIN** | STD (student enrollment), SCH (fee schedule), PAY (payment status) | FAC (fee revenue journal — D21), PAY (challan/payment request), HST (hostel fee sub-ledger), TPT (transport fee sub-ledger), PAN (fee default risk) |
| **PAY** | FIN (challans), BIL (SaaS invoices), HST, TPT, CAF | FAC (payment receipts — D21), NTF (payment confirmation), PPT (payment history) |
| **NTF** | ALL modules (trigger events), SYS (templates), COM (delivery channel) | COM (dispatch queue), STP, PPT (in-app notifications) |
| **CMP** | STD/HRS/PPT (complainant), SYS (escalation rules), COM (notifications) | NTF (escalation alerts), FAC (penalty/adjustment if applicable), PAN (complaint trend data) |
| **REC** | LXP, QNS, EXM, QUZ, PAN (performance signals) | STP, PPT, DSH (recommendation widgets) |
| **TPT** | SCH (routes/zones), STD (enrolled students), VND (vehicle contractors) | FIN (transport fee billing), FAC (fuel/maintenance costs — D21), NTF (route alerts), PPT |
| **LIB** | SLK (catalog reference), STD/HRS (borrowers), VND (book suppliers) | FIN (library fine billing), FAC (procurement cost — D21), INV (book stock overlap) |
| **VND** | GLB (GST/tax master), SYS (approval workflows) | INV (supplier for PO), LIB (book suppliers), SLK (publisher), MNT (contractors), FAC (vendor payables — D21) |
| **HPC** | SCH (lab schedule), STD (lab bookings), TTF/STT (lab period slots) | FAC (HPC usage billing — D21), DSH (HPC utilization widget) |
| **ADM** | GLB (board, state), SCH (academic year, class capacity), COM (admission communications) | STD (on enrollment convert to student), FIN (admission fee), NTF (status updates) |
| **ATT** | STD (student roster), HRS (staff roster), TTF/STT (period schedule), SYS (leave types) | ACD (attendance-linked grade), FIN (attendance-based fee deduction), HRS (leave deduction for payroll), PAN (absenteeism signals), PPT/STP (daily attendance view) |
| **ACD** | STD, ATT, EXM, EXA, HMW, QUZ (marks sources), SCH (class/section/subject) | CRT (grade triggers), DOC (marksheet/report card), PAN (academic performance), PPT/STP (report card view) |
| **EXA** | SCH (exam schedule), STD (roll numbers), HRS (invigilators), QNS (offline paper) | ACD (marks upload), CRT (pass/fail certificate), DOC (hall tickets, marksheets) |
| **FOF** | STD, HRS, VSM (visitor data), COM | NTF (caller/visitor alerts), CMP (reception complaints), DSH (front office widget) |
| **HRS** | SCH (departments), GLB (designations), SYS (roles), ATT (leave balance) | FAC (payroll journal — D21), ATT (staff schedule), TTF (teacher availability), CRT (staff certificates), DSH (HR widget), COM (staff messaging) |
| **FAC** | FIN (fee revenue), PAY (receipts), HRS (payroll), INV (purchase), TPT (transport cost), LIB (procurement), HPC (usage), VND (vendor payables), BIL (SaaS billing) | DSH (financial KPI), PAN (financial health indicators), external audit exports |
| **INV** | VND (suppliers), SCH (department stores), SYS (approval chain) | FAC (purchase vouchers — D21), CAF (consumables stock), MNT (spare parts), LIB (book stock), DSH (inventory widget) |
| **HST** | STD (resident students), SCH (hostel buildings), CAF (meal plans) | FIN (hostel fee billing), FAC (hostel costs — D21), ATT (hostel attendance), NTF (hostel alerts), PPT (hostel info) |
| **COM** | NTF (trigger source), SYS (channel config), ALL (content originators) | STP, PPT, HRS portal (message delivery) — terminal delivery layer |
| **LXP** | SLB (curriculum), QNS (question bank), EXM/QUZ (assessment), STD (learner profile), PAN (adaptive signals) | REC (learning signals for recommendations), PAN (engagement metrics), CRT (course completion certificates), DSH (LXP widget) |
| **PAN** | ATT, EXM, EXA, ACD, FIN, LXP, HMW, QUZ, HRS, CMP (data feeds) | REC (risk-based recommendations), DSH (predictive widgets), PPT/STP (parent/student alerts) |
| **CRT** | EXM, EXA, ACD, LXP, HRS (trigger conditions) | DOC (certificate PDF generation), STP/PPT (certificate download), COM (certificate issue notification) |
| **PPT** | STD, ATT, FIN, PAY, ACD, EXA, HMW, COM, NTF, TPT, HST, CRT, DOC (all aggregated read-only) | COM (parent messaging), CMP (parent complaint), PAY (fee payment action) |
| **CAF** | STD (student meal plan), HST (hostel mess), INV (consumable stock), VND (food suppliers) | FIN (cafeteria billing), FAC (food procurement costs — D21), INV (consumption records) |
| **VSM** | FOF (visitor desk), STD/HRS (host lookup), COM (alert dispatch) | NTF (visitor arrival alerts), FAC (visitor billing if applicable), DSH (security widget) |
| **MNT** | INV (spare parts), VND (contractors), SCH (asset register), SYS (work order approval) | FAC (maintenance costs — D21), INV (parts consumption update), DSH (maintenance widget) |

---

## 3. Critical Dependency Chains

### Chain A — Student Finance Flow
```
STD → FIN → PAY → FAC
       ↓          ↑
      NTF     (D21 journal entries)
       ↓
      PPT (parent payment portal)
```
- STD enrollment triggers FIN fee assignment
- FIN generates challans → PAY handles gateway
- PAY receipts posted to FAC via D21 integration event
- NTF sends payment confirmation to parents via COM

### Chain B — LMS Assessment Flow
```
SLB → QNS → HMW / QUZ / QST / EXM
                      ↓
                     ACD (marks aggregation)
                      ↓
             CRT (pass trigger) + DOC (marksheet)
                      ↓
                  STP / PPT (view)
```
- SLB topic taxonomy is the shared spine
- QNS is the single question repository consumed by all LMS modules
- ACD aggregates all marks sources for final report
- CRT fires on grade thresholds defined in ACD

### Chain C — HR to Payroll to Accounting
```
HRS (staff master + leave) → ATT (attendance/leave deduction)
                                   ↓
                             HRS (payroll input)
                                   ↓
                             FAC (payroll journal — D21)
```
- ATT leave records are mandatory input for HRS payroll calculation
- HRS payroll run creates journal entries in FAC via D21

### Chain D — Inventory to Accounting
```
VND (supplier + PO) → INV (GRN + stock) → FAC (purchase voucher — D21)
                              ↓
                         CAF (consumables)
                         MNT (spare parts)
                         LIB (books)
```
- All inventory receipts trigger FAC vouchers
- INV is the hub for CAF, MNT, and LIB stock

### Chain E — Admission to Enrollment
```
ADM (enquiry → application → selection) → STD (student created)
                                                 ↓
                                    FIN (fee assignment)
                                    ATT (roster added)
                                    SCH (class assigned)
                                    COM (welcome notification)
```

### Chain F — Timetable Foundation
```
SCH (academic year, class/section) + HRS (teacher-subject mapping)
                              ↓
                            TTF (foundation config)
                              ↓
                   STT (smart auto-gen) / TTS (manual)
                              ↓
             ATT (period attendance) + PAY (period-based pay)
             STP / PPT (timetable view)
```

### Chain G — Analytics Intelligence
```
ATT + EXM + ACD + FIN + LXP + HMW + CMP
                  ↓
                 PAN (predictive analytics)
                  ↓
           REC (recommendations) + DSH (alerts) + PPT/STP (notifications)
```
- PAN has the widest upstream dependency set (7+ modules)
- REC is downstream of both PAN and LXP

---

## 4. D21 Integration Hub — FAC as Accounting Backbone

FAC (Finance Accounting) acts as the central accounting engine. All financial transactions from operational modules post to FAC via the **D21 integration event bus** (asynchronous queue).

```
┌─────────────────────────────────────────────────────────────┐
│                    FAC — Accounting Hub                      │
│            (Chart of Accounts + Voucher Engine)              │
└─────────────────────────────────────────────────────────────┘
         ↑              ↑              ↑              ↑
       [FIN]          [HRS]          [INV]          [PAY]
    Fee Revenue     Payroll       Purchase        Receipts
    Challan post    Journal       Vouchers        Posted
         ↑              ↑              ↑              ↑
       [TPT]          [LIB]          [CAF]          [BIL]
    Transport      Procurement    Food Cost      SaaS Billing
    Cost            Cost         Vouchers        (prime_db)
         ↑              ↑
       [MNT]          [VND]
    Maintenance    Vendor
    Cost           Payables
```

**D21 Event Contract:**
- All posting modules emit: `{ source_module, voucher_type, amount, ledger_code, reference_id, posted_at }`
- FAC consumes from a dedicated `acc_integration_queue` table
- FAC posts back: `{ voucher_id, status: posted|rejected, error_message }`
- Failed posts trigger NTF alert to finance admin

---

## 5. Event-Driven Integration Contracts

| Source Module | Event | Consumer(s) | Trigger Condition |
|--------------|-------|-------------|-------------------|
| STD | student.enrolled | FIN, ATT, SCH, COM, ADM | New student record created |
| STD | student.transferred | ACD, ATT, FIN, CRT, DOC | School transfer initiated |
| ATT | attendance.marked | ACD, HRS (for staff), PPT, STP | Daily attendance finalized |
| ATT | leave.approved | HRS (payroll deduction), FIN (fee adjustment) | Leave request approved |
| FIN | fee.challan.generated | PAY, NTF, PPT | Challan created for student |
| PAY | payment.received | FIN (receipt), FAC (D21), NTF | Payment gateway callback |
| PAY | payment.failed | FIN (overdue flag), NTF | Payment gateway failure |
| HMW | homework.submitted | ACD (marks input), LXP (activity) | Student submission |
| EXM | exam.result.published | ACD (marks), CRT (trigger), NTF | Result publication action |
| ACD | result.finalized | CRT (certificate trigger), DOC (marksheet), PPT | Term result locked |
| ADM | application.selected | STD (create student), FIN (admission fee), COM | Selection decision made |
| HRS | payroll.run.completed | FAC (D21 journal), NTF (salary slip) | Monthly payroll processed |
| INV | grn.approved | FAC (D21 purchase voucher), VND (update PO) | GRN approved |
| INV | stock.low | NTF (reorder alert), VND (auto PO if configured) | Stock below reorder level |
| MNT | workorder.completed | FAC (D21 maintenance cost), INV (parts consumed) | Work order closed |
| VSM | visitor.checkin | NTF (host alert), FOF (desk log) | Visitor gate entry |
| HST | hostel.fee.due | FIN (hostel fee challan), NTF, PPT | Monthly hostel billing run |
| CAF | meal.consumed | FIN (cafeteria billing), INV (stock deduction) | Meal swipe/token recorded |
| CMP | complaint.escalated | NTF (escalation alert), FOF (log) | SLA breached |
| LXP | course.completed | CRT (completion certificate), PAN (data feed) | Final module marked done |
| CRT | certificate.issued | DOC (PDF generated), COM (delivery), STP/PPT | Certificate generated |
| NTF | notification.triggered | COM (dispatch), STP/PPT (in-app) | Any module emits alert |
| PAN | risk.alert.generated | REC, DSH, COM | Dropout or failure risk score threshold crossed |

---

## 6. Module Dependency Depth

Ranked by number of upstream dependencies (most dependent first):

| Rank | Module | Upstream Deps | Risk if Dependency Fails |
|------|--------|--------------|--------------------------|
| 1 | PAN | 8+ (ATT, EXM, ACD, FIN, LXP, HMW, QUZ, CMP, HRS) | Analytics broken |
| 2 | FAC | 8+ (FIN, PAY, HRS, INV, TPT, LIB, CAF, MNT, BIL) | Accounting broken |
| 3 | PPT | 8+ (STD, ATT, FIN, ACD, EXM, COM, NTF, TPT, HST, CRT, DOC) | Parent portal blank |
| 4 | DSH | 6+ (all KPI sources) | Dashboard empty |
| 5 | ACD | 5 (ATT, EXM, EXA, HMW, QUZ) | No consolidated marks |
| 6 | REC | 4 (LXP, QNS, EXM, PAN) | No recommendations |
| 7 | CRT | 4 (EXM, EXA, ACD, LXP) | No certificates |
| 8 | DOC | 4 (STD, ACD, EXA, CRT) | No document generation |
| 9 | FIN | 3 (STD, SCH, PAY) | No fee management |
| 10 | LXP | 4 (SLB, QNS, EXM, PAN) | Adaptive learning broken |

---

## 7. Circular Dependency Warnings

| Warning | Modules | Nature | Resolution |
|---------|---------|--------|------------|
| WARN-01 | FIN ↔ PAY | FIN creates challans for PAY; PAY posts receipts back to FIN | Not truly circular — FIN is upstream (creates), PAY is downstream (fulfills). Status callback is one-way. |
| WARN-02 | HRS ↔ ATT | HRS needs ATT for leave deductions; ATT needs HRS for staff roster | Bootstrapped via SCH — SCH creates staff record first, HRS and ATT then reference it independently. |
| WARN-03 | INV ↔ CAF | INV tracks CAF consumable stock; CAF deducts from INV | INV is master, CAF creates consumption records. Handled via event (CAF → INV deduction event, not direct FK loop). |
| WARN-04 | NTF ↔ COM | NTF triggers COM for delivery; COM may trigger NTF for failed delivery | Handled via dead-letter queue — COM failure posts back to NTF retry table, not a function call back. |
| WARN-05 | PAN ↔ REC | PAN feeds risk signals to REC; REC outcomes may update PAN feedback | Async only — REC writes to a feedback log; PAN re-reads on next analytics run. No synchronous loop. |
| WARN-06 | STP ↔ PPT | STP (student portal) and PPT (parent portal) share much of the same data | Not a dependency — both READ from the same module APIs (FIN, ATT, ACD). No write dependency between STP and PPT. |

---

## 8. Shared Reference Tables (Used by All Modules)

These tables in `global_db` and `tenant_db` are consumed read-only by virtually every module:

| Table | Module | Used By |
|-------|--------|---------|
| `glb_countries` | GLB | ADM, STD, HRS, VND, SCH |
| `glb_states` | GLB | ADM, STD, HRS, VND, TPT, SCH |
| `glb_boards` | GLB | SCH, SLB, EXA, ADM |
| `glb_languages` | GLB | STD, SLB, COM, NTF |
| `glb_currencies` | GLB | FIN, PAY, BIL, FAC, INV |
| `sys_roles` | SYS | ALL (RBAC) |
| `sys_permissions` | SYS | ALL (gate checks) |
| `sys_settings` | SYS | ALL (configuration) |
| `sys_dropdowns` | SYS | ALL (enum values) |
| `sys_media` | SYS | STD, HRS, DOC, CRT, SLB, INV |
| `sys_activity_logs` | SYS | ALL (audit trail) |

---

## 9. Integration Readiness Matrix

| Module Pair | Integration Type | Status (code) | Priority |
|-------------|-----------------|---------------|----------|
| FIN → FAC | D21 event bus | Designed, pending impl | P1 |
| HRS → FAC | D21 payroll journal | Designed, pending impl | P1 |
| INV → FAC | D21 purchase voucher | Designed, pending impl | P1 |
| PAY → FAC | D21 receipt posting | Designed, pending impl | P1 |
| STD → FIN | Direct FK (enrollment) | Implemented | — |
| QNS → EXM/QUZ/HMW | Direct table ref | Implemented | — |
| ATT → ACD | Marks input reference | Pending ACD dev | P2 |
| LXP → REC | Analytics signals | Pending LXP dev | P2 |
| PAN ← all | Analytics data feeds | Pending PAN dev | P2 |
| CRT → DOC | PDF generation trigger | Pending DOC dev | P2 |
| NTF → COM | Delivery dispatch | Implemented (NTF done) | — |

---

*Dependency map V2.0 — 2026-03-26. Update after each new module integration is completed.*
