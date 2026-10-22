# Role dashboard insights — app-wide candidate list

2026-10-19. **Inventory only — nothing is built.** Every tenant module was scanned (949 tenant
migrations + module migrations, the existing report/dashboard routes, and live row counts on
test.localhost `xyz_school_00000000000040008000_202627`). Central Prime super admin is out of scope.

- **Part A** — what each module can tell us (the catalogue, with IDs).
- **Part B** — which of those IDs go on which role's dashboard.
- **Part C** — open questions.

**Type:** 🔴 ALERT = something is wrong or drifting · 💡 SUGG = an action we recommend (save money,
free capacity, fix quality) · 📊 KPI = a headline number with a trend arrow

**Status:** **R** = tables exist and test.localhost has data · **R-thin** = tables exist, few rows
or short history (works, but the trend rules need more weeks) · **ND** = needs data we do not record today

**Principle (same as the timetable suggestion card):** the dashboard shows the headline + a link to
the existing detail page. Advice only, no action buttons. Most detail pages already exist — the link
column says which.

---

# Part A — Catalogue by module

## A1. LMS — Quiz, Quest, Homework, Exam

Data: 7,725 quiz/quest attempts over 15 weeks, 9,929 homework submissions over 12 weeks, 413 exam
results. Teacher link = `lms_quizzes.created_by` / `*_allocations.assigned_by` (same as the existing
teacher-monthly report); homework = `lms_homework.created_by`.

| ID | Insight | Type | Rule (proposed default) | Detail link | St |
|---|---|---|---|---|---|
| LMS-01 | **Teacher's class average is falling** (from week X) | 🔴 | teacher × class-section × subject: last-4-week avg ≥10 pts below the teacher's own previous 8-week baseline, ≥3 assessments per window | lms-quize/quiz-reports?tab=class-performance | R |
| LMS-02 | Teacher consistently in the bottom 10% for the same subject+class | 🔴 | 6+ weeks | quiz-reports?tab=teacher-monthly | R |
| LMS-03 | Whole section falling in ≥3 subjects at once (class problem, not teacher) | 🔴 | same 4-week window | quiz-reports?tab=class-performance | R |
| LMS-04 | Same subject, sections ≥15 pts apart → pair the teachers / share material | 💡 | | quiz-reports?tab=class-performance | R |
| LMS-05 | Quiz high but term exam ≥20 pts lower (quizzes too easy / malpractice) | 🔴 | | lms-exam/exam-advanced-reports | R |
| LMS-06 | Exam result headline: pass %, avg %, grade split vs previous exam | 📊 | | exam-advanced-reports | R |
| LMS-07 | **Homework grading backlog by teacher** | 🔴 | submitted, graded_at NULL > 7 days (3,864 of 9,929 today) | lms-home-work/home-work-report | R |
| LMS-08 | Exam answers not evaluated N days after exam end (70 today) | 🔴 | | exam-advanced-reports | R |
| LMS-09 | Teacher assigned no quiz/quest/homework for a class they teach in 3 weeks | 🔴 | vs timetable cells | quiz-reports?tab=teacher-monthly | R |
| LMS-10 | Exam grievances open >7 days (6 open); evaluators whose marks changed most | 🔴 | | exam-advanced-reports | R |
| LMS-11 | Exam ended, results not published after N days | 🔴 | | exam-advanced-reports | R |
| LMS-12 | Sections where >30% students skip allocated quizzes | 🔴 | allocation_detail vs attempts | quiz-reports | R |
| LMS-13 | Homework submission rate down ≥15 pts vs baseline | 🔴 | | home-work-report | R |
| LMS-14 | Students sliding ≥15 pts in ≥2 subjects (top 10) | 🔴 | | quiz-reports?tab=student-summary | R |
| LMS-15 | Online-test integrity flags (violation_count > 0) by class/exam | 🔴 | | exam-advanced-reports | R |

## A2. Syllabus, QuestionBank, Recommendation, Marksheet, HPC

| ID | Insight | Type | Rule | Detail link | St |
|---|---|---|---|---|---|
| SYL-01 | **Syllabus behind schedule** by class-section × subject × teacher | 🔴 | scheduled_end < today and not completed (54 of 844 due) | syllabus/report | R |
| SYL-02 | Syllabus completion % by class vs plan | 📊 | | syllabus/report | R |
| SYL-03 | Disruptions not recovered past end date | 🔴 | | syllabus/report | R-thin |
| SYL-04 | ⚠ data-quality: topics scheduled to end in 2042 — a sequencing bug to check, not a dashboard item | — | | — | bug |
| QB-01 | Bad questions → review/retire (discrimination < 0.1, difficulty outside 0.1–0.95, ≥30 attempts) | 💡 | qns_question_statistics | question-bank/question-report | R |
| QB-02 | School's own questions vs PrimeGurukul (37 vs 16,728) | 📊 | | question-bank dashboard | R |
| REC-01 | Remediation ignored: pending/expired/skipped (662 of 1,681) by class | 🔴 | | recommendation/reports | R |
| REC-02 | Is remediation working? score after vs score that triggered it | 📊 | | recommendation/dashboard | R |
| MSH-01 | Marksheet schedule past date but not computed/locked, or computation errors | 🔴 | | marksheet-generation/dashboard | R |
| HPC-01 | Students without an HPC report for the current term | 🔴 | | hpc dashboard | R-thin |

## A3. Behaviour (BA) and student welfare (StudentProfile)

| ID | Insight | Type | Rule | Detail link | St |
|---|---|---|---|---|---|
| BA-01 | Behaviour at-risk / declining students | 🔴 | is_at_risk or trend=declining (needs a 2nd scoring period) | behavioural-assessment/reports | R-thin |
| BA-02 | Open / high-severity / escalated incidents, follow-up date passed | 🔴 | 24 incidents | behavioural-assessment/reports/incidents | R |
| BA-03 | Interventions overdue | 🔴 | | reports/incidents | R |
| BA-04 | Teacher behaviour assessments still draft after the period deadline | 🔴 | | behavioural-assessment/dashboard | R |
| STU-01 | **Chronic absentees** (attendance < 75% in last 30 days) | 🔴 | std_student_attendance — only 209 rows today | student-profile/reports/chronic-absenteeism | R-thin |
| STU-02 | **Dropout radar** — absence + falling marks + fee overdue together | 🔴 | combines STU-01, LMS-14, FEE-02 | student-profile/reports/dropout-radar | R-thin |
| STU-03 | Medical follow-ups open, acute medical cases, allergy/chronic list for trips | 🔴 | std_medical_incidents (644) | student-profile/reports/medical-followup | R |
| STU-04 | Vaccinations due in next 30 days | 🔴 | std_vaccination_records (7,938) | student-profile/reports/medical-safety | R |
| STU-05 | Missing/unverified/expiring student documents | 🔴 | std_student_documents (5,258) | student-profile/reports/document-deficiency | R |
| STU-06 | Students without a valid emergency contact | 🔴 | | student-profile/reports/emergency-contact-alert | R |
| STU-07 | Strength by class/section vs capacity, gender/category mix | 📊 | | student-profile/reports/student-strength | R |
| STU-08 | Student leave applications pending | 🔴 | | student-profile/reports/leave-review | R-thin |

## A4. Admission, Certificate, PTM

| ID | Insight | Type | Rule | Detail link | St |
|---|---|---|---|---|---|
| ADM-01 | **Seat-fill risk** — classes likely to stay under-filled at current conversion | 🔴 | | admission/reports/seat-fill-risk | R |
| ADM-02 | Funnel: enquiry → application → test → offer → admitted, vs last cycle | 📊 | | admission/reports/conversion-funnel | R |
| ADM-03 | Enquiries with no follow-up in N days / counsellor SLA breach | 🔴 | adm_follow_ups | admission/reports/counselor-sla | R |
| ADM-04 | Lead source that converts best → spend more there | 💡 | lead_source × admitted | admission/analytics/funnel | R |
| ADM-05 | Offers expiring unpaid; admission fee pending | 🔴 | adm_allotments | admission/reports/fee-action | R |
| ADM-06 | Pipeline bottleneck stage (applications stuck > N days) | 🔴 | adm_application_stages | admission/reports/pipeline-bottlenecks | R |
| ADM-07 | **Withdrawals / TCs rising** — reasons, by class, vs last year | 🔴 | adm_withdrawals, adm_tc_requests | admission/reports | R |
| ADM-08 | Promotion: detained count by class | 📊 | adm_promotion_batches | admission/reports | R |
| CRT-01 | Certificate requests pending past required-by date | 🔴 | crt_requests, fof_certificate_requests | certificate/reports | R |
| PTM-01 | PTM: booking %, parents not booked, attended % by teacher | 📊 | ptm_slots / ptm_slot_bookings | ptm module | R-thin |
| PTM-02 | Classes where < 50% parents booked a PTM slot → reminder | 💡 | | ptm module | R-thin |

## A5. Fees, Payment, Scholarship

Data: 7,011 invoices, 5,096 transactions, 2,971 gateway logs. **2,736 invoices overdue = ₹2.76 Cr balance today.**

| ID | Insight | Type | Rule | Detail link | St |
|---|---|---|---|---|---|
| FEE-01 | Collection this month vs target / vs same month last year | 📊 | | student-fee/dashboard | R |
| FEE-02 | **Overdue amount + ageing buckets** (0-30/31-60/61-90/90+) by class | 🔴 | fee_invoices | student-fee/dashboard/fee-collection-details | R |
| FEE-03 | **Families who used to pay on time and started paying late** | 🔴 | fee_defaulter_history avg_days_late trend | student-fee/dashboard | R |
| FEE-04 | Cheque bounces / pending clearance | 🔴 | fee_payment_reconciliation | student-fee/dashboard | R |
| FEE-05 | Gateway failure rate (failed ÷ attempted, last 7 days) | 🔴 | fee_payment_gateway_logs | student-fee/dashboard | R |
| FEE-06 | Fine waived total and by whom (leakage) | 🔴 | fee_fine_transactions.waived_by | student-fee/dashboard | R |
| FEE-07 | Concessions/refunds awaiting approval | 🔴 | fee_student_concessions, fee_refunds | student-fee/dashboard | R |
| FEE-08 | Scholarship fund remaining vs pending applications | 📊 | fee_scholarships, *_applications | student-fee/dashboard | R |
| FEE-09 | Students with no fee assignment for the session (revenue missed) | 🔴 | std_student_academic_sessions minus fee_student_assignments | student-fee/dashboard | R |
| FEE-10 | Upcoming installment due next 7 days → send reminder | 💡 | fee_installments | student-fee/dashboard | R |

## A6. Accounting

Mostly configuration so far (30 vouchers). Rules work; numbers will be small until real postings.

| ID | Insight | Type | Rule | Detail link | St |
|---|---|---|---|---|---|
| ACC-01 | Cash + bank position today | 📊 | ledger balances | accounting/report/cash-book, bank-book | R-thin |
| ACC-02 | **Budget vs actual** — cost centres over 90% / 100% of budget | 🔴 | acc_budget_lines vs voucher items | accounting/report/budget-variance | R-thin |
| ACC-03 | Payables overdue (vendor bills) / receivables ageing | 🔴 | acc_bill_reference_balances | accounting/report/outstanding-payables | R-thin |
| ACC-04 | Bank reconciliation not done for last month / unmatched entries | 🔴 | acc_bank_reconciliations | accounting/report/bank-reconciliation | R-thin |
| ACC-05 | Vouchers awaiting approval; self-approvals | 🔴 | acc_voucher_approvals | accounting/dashboard | R-thin |
| ACC-06 | Period not closed / blocking checklist items | 🔴 | acc_period_close_checklist | accounting/dashboard | R |
| ACC-07 | Exceptions raised by the 28 exception rules | 🔴 | acc_exceptions (0 rows today) | accounting/dashboard | R-thin |
| ACC-08 | Module totals not posted to accounts (fee/payroll/inventory vs ledger) | 🔴 | acc_module_reconciliation (0 rows) | accounting/dashboard | ND (no job fills it) |
| ACC-09 | Income vs expense by month, ratio analysis | 📊 | | accounting/report/profit-and-loss | R-thin |
| ACC-10 | TDS due / not deposited | 🔴 | acc_tds_deductions vs acc_tds_payments | accounting | R-thin |

## A7. HR, Staff attendance, Payroll

| ID | Insight | Type | Rule | Detail link | St |
|---|---|---|---|---|---|
| HR-01 | Staff present today / late / absent / on leave | 📊 | sch_employee_attendance | hr-staff/hr-reports | R |
| HR-02 | **Staff whose punctuality got worse** (late days this month vs their 3-month avg) | 🔴 | | hr-staff/hr-reports | R |
| HR-03 | Leave pattern: Mon/Fri or pre-holiday clusters; leave balance exhausted | 🔴 | sch_employee_leave_applications | hr-staff/hr-reports | R |
| HR-04 | Leave approvals pending / escalated | 🔴 | sch_employee_leave_approvals | hr-staff | R |
| HR-05 | Attendance corrections pending | 🔴 | | hr-staff | R |
| HR-06 | Employee documents expiring in 60 days; probation ending | 🔴 | sch_employee_documents, hrs_employment_details | school-setup/employee-reports | R |
| HR-07 | Payroll cost this month vs last, by department | 📊 | pay_payroll_runs / _details | hr-staff/hr-reports | R |
| HR-08 | Payroll run not approved/locked by day N | 🔴 | | hr-staff | R |
| HR-09 | Appraisals pending; increment flags not processed | 🔴 | hrs_appraisals | hr-staff | R |
| HR-10 | Attrition: separations this year, by department | 📊 | sch_employee_separations | hr-staff/hr-reports | R-thin |
| HR-11 | PF/ESI register not computed for last month | 🔴 | hrs_pf/esi_contribution_register | hr-staff | R |

## A8. Timetable (Foundation, Smart, Standard) and substitution

Timetable cells are empty on test.localhost right now (DB reset). The rules exist in code.

| ID | Insight | Type | Rule | Detail link | St |
|---|---|---|---|---|---|
| TT-01 | **Teachers we can free** — freeing plan A/B, periods saved | 💡 | existing optimisation report | timetable-foundation/optimisation-report | R |
| TT-02 | The 30 existing suggestions (load / rooms / class / cover / health) — top 3 | 💡 | TimetableSuggestionService | dashboard/timetable-management | R |
| TT-03 | Overloaded / under-loaded teachers vs min/max allocation | 🔴 | | smart-timetable/analytics/workload | R |
| TT-04 | Rooms underused (< 40%) → merge or repurpose | 💡 | | smart-timetable/analytics/utilization | R |
| TT-05 | Constraint violations in the published timetable | 🔴 | | smart-timetable/analytics/violations | R |
| TT-06 | Substitutions today; teachers taking the most substitutions | 📊 | substitution history | substitute management | R |
| TT-07 | **Teacher change on a class+subject → did results change?** (the academic twin of your driver example) | 🔴 | compare published snapshots for a teacher swap, then LMS-01 before/after | quiz-reports | ND (needs a swap log or snapshot diff job) |

## A9. Transport (Transport + SmartTransport)

Data: 26 vehicles, 56 personnel, 300 trips, 104 fuel entries (Oct 1–18 only), 4,441 boarding logs.

| ID | Insight | Type | Rule | Detail link | St |
|---|---|---|---|---|---|
| TPT-01 | **Mileage dropped after a driver change** (your example) | 🔴 | km/l per vehicle from tpt_vehicle_fuel odometer + quantity (or tpt_trip start/end odometer ÷ fuel); split by driver_id; alert when the new driver's km/l is ≥15% below the vehicle's previous-driver baseline | transport/vehicle-fuel | R-thin · **deferred 2026-10-20**: 4 fills per vehicle, each by a different driver — no baseline to compare |
| TPT-02 | Vehicle with mileage falling regardless of driver → send for service | 💡 | 3-month trend | transport/vehicle-fuel | R-thin · **deferred 2026-10-20**: 18 days of fuel data, no trend yet |
| TPT-03 | Fuel cost per km / per student by route, vs fleet avg | 📊 | | transport/transport-report | R · **deferred 2026-10-20**: a KPI tile — how KPI cards render is still undecided |
| TPT-04 | **Documents expiring**: fitness / insurance / pollution / fire-extinguisher (30 days), driver licences | 🔴 | tpt_vehicle, tpt_personnel (2 fitness, 1 insurance today) | transport/transport-dashboard | R |
| TPT-05 | Late trips: stops reached > 10 min after schedule, by route/driver | 🔴 | tpt_trip_stop_detail | transport/transport-report | R · **deferred 2026-10-20**: reached_flag is 0 on all 2,325 stop rows — no arrival data |
| TPT-06 | Trip incidents open; emergency flags | 🔴 | tpt_trip_incidents (51) | transport/transport-dashboard | R · **built 2026-10-20** (HIGH/MEDIUM unresolved; LOW behind a setting) |
| TPT-07 | Route occupancy: seats used vs capacity → merge under-filled routes | 💡 | tpt_student_route_allocation_jnt vs vehicle capacity | transport/transport-report | R · **built 2026-10-20** (0 cards today: every bus is 40 seats, every route ≥ 25 students) |
| TPT-08 | Students allocated but not boarding for 2 weeks → stop billing / check | 💡 | allocation vs boarding_log | transport/transport-report | R · **built 2026-10-20** (one card per route; routes with no scans at all are skipped) |
| TPT-09 | Failed daily inspections; service requests pending; maintenance due | 🔴 | tpt_daily_vehicle_inspection, tpt_vehicle_maintenance | transport/transport-dashboard | R · **built 2026-10-20** (failed check with no request · request pending > 3d · approved but open > 14d · maintenance due ≤ 15d) |
| TPT-10 | Maintenance cost per vehicle (last 12 months) → replace instead of repair | 💡 | | transport/transport-report | R-thin · **deferred 2026-10-20**: 1 maintenance job per vehicle — nothing to compare |
| TPT-11 | Transport fee overdue | 🔴 | tpt_student_fee_detail | transport/transport-dashboard | R · **built 2026-10-20** (one card per student, via std_academic_sessions_id → std_student_academic_sessions) |
| TPT-12 | Driver attendance gaps | 🔴 | tpt_driver_attendance | transport/transport-dashboard | R · **built 2026-10-20** (≥ 2 absences or ≥ 3 lates in 14 days) |
| TPT-13 | **Route over seating capacity** — more students allocated than the bus has seats (added 2026-10-20) | 🔴 | allocation vs MAX(vehicle capacity) per route | transport/route show | R · **built 2026-10-20** |

## A10. Library

Data is thin: 76 copies, 27 transactions → **51 of 76 copies never issued**.

| ID | Insight | Type | Rule | Detail link | St |
|---|---|---|---|---|---|
| LIB-01 | **Dead stock — titles nobody issues** (no issue in 12 months, > 2 copies) → reduce copies / sell / donate | 💡 | lib_book_copies minus lib_transactions | library/reports/advanced-analytics | R-thin |
| LIB-02 | **Demand exceeds copies** — titles with a reservation queue or all copies out → buy more | 💡 | lib_physical_book_requests queue_position, copies out | library/reports/circulation | R-thin |
| LIB-03 | Popularity trend rising/falling (already computed) | 📊 | lib_book_popularity_trends.trend_direction | library/library-mgt/analytics | R-thin |
| LIB-04 | Overdue books + outstanding fines | 🔴 | lib_transactions, lib_members.outstanding_fines | library/reports/fine-collection | R |
| LIB-05 | Lost / damaged copies this term | 🔴 | lib_book_copies | library/dashboard | R |
| LIB-06 | Classes/students who borrowed nothing this term → reading drive | 💡 | members × transactions | library/reports/circulation | R-thin |
| LIB-07 | Curriculum books with low usage (alignment score high, usage low) | 💡 | lib_curricular_alignment | library/reports/advanced-analytics | R-thin |
| LIB-08 | Stock audit overdue / missing copies found | 🔴 | lib_inventory_audit (0 rows) | library | ND (no audit run yet) |
| LIB-09 | Digital licences expiring | 🔴 | lib_digital_resources.license_end_date | library | R-thin |

## A11. Inventory and Vendor

| ID | Insight | Type | Rule | Detail link | St |
|---|---|---|---|---|---|
| INV-01 | Items at/below reorder level (2 today) | 🔴 | inv_stock_balances vs reorder_level | inventory/reports/reorder-alerts | R |
| INV-02 | **Slow / non-moving stock** → stop buying, use up | 💡 | | inventory/reports/fast-slow-movers | R |
| INV-03 | **Consumption spike by department** vs its 3-month average | 🔴 | inv_stock_issues by department_id | inventory/reports/consumption | R |
| INV-04 | Batches expiring in 30 days | 🔴 | inv_stock_entries.expiry_date | inventory/reports/expiry-alerts | R |
| INV-05 | POs pending delivery past expected date; GRNs with QC rejections | 🔴 | | inventory/reports/pending-po | R |
| INV-06 | **Price creep** — last purchase rate > rate contract / previous rate by 10% | 🔴 | inv_item_vendor_jnt vs inv_rate_contract_items_jnt | inventory/reports/purchase-register | R |
| INV-07 | Stock adjustment variance (physical vs system) | 🔴 | inv_stock_adjustment_items | inventory/reports/stock-balance | R-thin |
| INV-08 | Asset warranty expiring; asset maintenance due | 🔴 | inv_assets, inv_asset_maintenance | inventory/reports/asset-register | R-thin |
| VND-01 | Vendor agreements expiring in 60 days | 🔴 | vnd_agreements | vendor/dashboard/alerts | R |
| VND-02 | Vendor invoices unpaid past payment terms | 🔴 | vnd_invoices / vnd_payments | vendor/vendor-reports | R-thin |
| VND-03 | Usage below min-guarantee qty (paying for unused service) | 💡 | vnd_usage_logs vs min_guarantee_qty | vendor/vendor-reports | R-thin |

## A12. Cafeteria

| ID | Insight | Type | Rule | Detail link | St |
|---|---|---|---|---|---|
| CAF-01 | **Items nobody orders** → drop from menu | 💡 | caf_menu_items with 0 caf_order_items in 30 days | cafeteria/reports-page | R |
| CAF-02 | **Best sellers / demand rising** → prepare more, cut waste on the rest | 💡 | order_items trend | cafeteria/reports-page | R |
| CAF-03 | Wastage: consumption logged vs meals served | 🔴 | caf_consumption_logs vs caf_meal_attendance | cafeteria/reports-page | R |
| CAF-04 | Stock below reorder | 🔴 | caf_stock_items | cafeteria/dashboard | R |
| CAF-05 | FSSAI licence / audit expiring | 🔴 | caf_fssai_records | cafeteria/dashboard | R |
| CAF-06 | Meal-card balances low / negative | 🔴 | caf_meal_cards | cafeteria/dashboard | R |
| CAF-07 | Revenue by day; cancelled orders % | 📊 | caf_orders | cafeteria/dashboard | R |
| CAF-08 | POS cash vs system mismatch | 🔴 | caf_pos_sessions (0 rows) | cafeteria | ND (POS not used) |

## A13. Hostel

The richest operational data (54K mess attendance, 4,960 laundry, 4,149 movements, 3,352 visitors).

| ID | Insight | Type | Rule | Detail link | St |
|---|---|---|---|---|---|
| HST-01 | Occupancy % and empty beds by hostel | 📊 | hst_allotments vs beds | hostel/reports/occupancy | R |
| HST-02 | **Mess: meals planned vs consumed** → cut cooking quantity | 💡 | hst_mess_bills, hst_mess_attendance | hostel/reports/mess-suite | R |
| HST-03 | Students overdue from leave / gate pass not returned | 🔴 | hst_leave_passes.actual_return_date, hst_movement_log | hostel/reports/leave-passes | R |
| HST-04 | Out-of-hours visitor overrides | 🔴 | hst_visitor_log.is_outside_visiting_hours | hostel/reports/visitors | R |
| HST-05 | Sick-bay admissions this week; alarm vitals; hospital referrals | 🔴 | hst_sick_bay_* | hostel/reports/medical-suite | R |
| HST-06 | Hostel complaints past SLA; bed maintenance blocking beds | 🔴 | hst_complaints, hst_bed_maintenance_log | hostel/reports/maintenance-suite | R |
| HST-07 | Hostel fee demand unpaid | 🔴 | hst_fee_demands | hostel/fee-structures/defaulters | R |
| HST-08 | Incidents / warning letters by student (repeat offenders) | 🔴 | hst_incidents | hostel/reports/discipline-suite | R |
| HST-09 | Room-change requests pending (415 rows) | 🔴 | | hostel/reports | R |
| HST-10 | Laundry turnaround late / disputes | 🔴 | hst_laundry_tickets | hostel/reports/laundry-suite | R |

## A14. Front Office, Complaint, Feedback, Notification, System

| ID | Insight | Type | Rule | Detail link | St |
|---|---|---|---|---|---|
| FOF-01 | Visitors today; appointments today | 📊 | fof_visitors, fof_appointments | dashboard/front-desk | R |
| FOF-02 | Keys not returned past expected time | 🔴 | fof_key_register | front-office/keys/overdue | R |
| FOF-03 | Early departures / gate passes this week (repeat students) | 🔴 | fof_early_departures, fof_gate_passes | dashboard/front-desk | R |
| FOF-04 | Phone-diary actions not completed | 🔴 | fof_phone_diary.action_required | dashboard/front-desk | R |
| CMP-01 | **Complaints past department SLA** | 🔴 | cmp_complaints vs cmp_department_sla | complaint/reports/summary-status | R |
| CMP-02 | High escalation / safety risk complaints (AI scores) | 🔴 | cmp_ai_insights.safety_risk_score | complaint/ai-insights | R |
| CMP-03 | Complaint category rising vs last month | 🔴 | | complaint dashboard | R-thin |
| FBK-01 | Feedback cycle results: lowest-scoring categories / teachers | 📊 | fbk_answers by category | feedback/menu/analytics | R-thin |
| FBK-02 | Feedback cycle open, response rate below threshold | 🔴 | fbk_cycles | feedback | R-thin |
| NTF-01 | Notification delivery failures (SMS/WhatsApp/email) last 7 days | 🔴 | ntf_delivery_logs, tpt_notification_log | dashboard/all-notifications | R |
| SYS-01 | Last backup run failed / older than 24h | 🔴 | sys_backup_runs (Maintenance module) | system-config/dashboard | R |
| SYS-02 | Data-quality: students without class/section, teachers without capability, rooms without type | 🔴 | | school-setup/reports/class-subject-matrix | R |
| SYS-03 | Session/term setup incomplete for the coming session | 🔴 | sch_academic_term, sch_org_academic_sessions_jnt | dashboard/foundational-setup | R |

---

# Part B — What each role sees

Each role dashboard has three strips: **🔴 Alerts** (only the ones currently firing, max ~8,
"+N more"), **💡 Suggestions** (max ~5), **📊 KPIs** (tiles). The IDs below are the *eligible*
items; only firing ones render.

### Super Admin (tenant) — "Is the school system healthy, and what is broken?"
Sees everything the other four see, **plus** system items nobody else gets.
- 🔴 SYS-01 backup · SYS-02 data quality · SYS-03 session setup · NTF-01 delivery failures ·
  FEE-05 gateway failures · ACC-08 unposted module totals · SYL-04-type data bugs
- 📊 Active users by role today, module usage (which modules nobody uses) — *ND, needs a usage log query on sys_activity_logs*
- Then a collapsible "All roles" section with every firing alert.

### Principal — "Quality of teaching, safety, and the few numbers that matter"
- 🔴 **Academic:** LMS-01 teacher falling · LMS-02 consistently low · LMS-03 section falling ·
  LMS-05 quiz/exam mismatch · SYL-01 syllabus behind · LMS-11 results unpublished · MSH-01
- 🔴 **Students & safety:** STU-02 dropout radar · STU-01 chronic absentees · BA-01/BA-02 behaviour
  & serious incidents · STU-03 medical · HST-05 sick bay · TPT-06 trip incidents · CMP-02 safety-risk complaints
- 🔴 **Staff:** HR-02 punctuality worse · HR-03 leave patterns · TT-03 overload
- 🔴 **Families:** ADM-07 withdrawals rising · CMP-01 complaints past SLA · FEE-03 families turning late
- 💡 TT-01 teachers we can free · TT-02 top timetable suggestions · LMS-04 pair teachers · QB-01 bad questions
- 📊 LMS-06 exam results · SYL-02 syllabus % · HR-01 staff today · STU-07 strength · FEE-01 collection · ADM-02 funnel · FBK-01 feedback

### Vice Principal — "Day-to-day academic operations: who has to do what this week"
- 🔴 LMS-07 grading backlog · LMS-08 unevaluated answers · LMS-09 no assessments set ·
  LMS-10 grievances · LMS-12/13 students skipping work · LMS-14 sliding students · LMS-15 integrity ·
  SYL-01/SYL-03 syllabus · REC-01 remediation ignored · BA-03/BA-04 interventions & assessments ·
  HPC-01 · STU-01 absentees · STU-08 leave · HR-04 staff leave pending · PTM-01/02
- 💡 LMS-04 · QB-01 · TT-02 (cover/load items) · PTM-02 reminders
- 📊 TT-06 substitutions today · HR-01 staff present · SYL-02 · REC-02 remediation working · LMS-06

### Management — "Money, growth, and cost leakage"
- 🔴 FEE-02 overdue + ageing · FEE-03 late-paying families · FEE-04 bounces · FEE-06 fines waived ·
  FEE-09 unbilled students · ACC-02 over budget · ACC-03 payables · ADM-01 seat-fill risk ·
  ADM-07 withdrawals · HR-08 payroll not locked · INV-06 price creep · VND-01/02 vendor contracts & dues ·
  TPT-01 mileage after driver change · HST-07 hostel dues
- 💡 **Cost savings:** TT-01 teachers we can free · TPT-07 merge under-filled routes · TPT-08 stop
  billing non-boarders · TPT-10 replace vs repair · LIB-01 dead library stock · INV-02 slow stock ·
  CAF-01 menu items nobody orders · HST-02 mess over-cooking · VND-03 unused min-guarantee · TT-04 idle rooms
- 💡 **Growth:** ADM-04 best lead source · LIB-02 buy more of in-demand books · CAF-02 best sellers
- 📊 FEE-01 collection · ACC-01 cash/bank · ACC-09 income vs expense · HR-07 payroll cost · ADM-02 funnel ·
  HST-01 occupancy · TPT-03 cost per km/student · CAF-07 cafeteria revenue · HR-10 attrition
- ❌ No teacher-level academic alerts (LMS-01/07) — summaries only (LMS-06, SYL-02). See C2.

### School Admin — "Operations and compliance: what expires, what is pending, what is late"
- 🔴 **Expiring:** TPT-04 vehicle docs & licences · HR-06 staff docs/probation · STU-05 student docs ·
  STU-04 vaccinations · CAF-05 FSSAI · VND-01 agreements · LIB-09 licences · INV-04 batches · INV-08 warranties
- 🔴 **Pending / late:** CRT-01 certificates · FEE-07 concessions/refunds · HR-05 attendance corrections ·
  HR-11 PF/ESI · ACC-04 bank recon · ACC-05 vouchers to approve · ACC-06 period close · INV-01 reorder ·
  INV-05 POs late · CAF-04 cafeteria stock · TPT-05 late trips · TPT-09 inspections/maintenance ·
  TPT-12 driver attendance · LIB-04 overdue books · HST-03/06/09/10 hostel ops · FOF-02 keys ·
  FOF-04 phone actions · CMP-01 complaints SLA · ADM-03/05/06 admission desk · NTF-01
- 💡 FEE-10 installment reminders · PTM-02 · LIB-06 reading drive · INV-03 consumption spike check
- 📊 FOF-01 visitors/appointments · HR-01 staff today · HST-01 occupancy · TPT-03 · FEE-01

---

# Part C — Open questions (need your call before any build)

1. **Thresholds** — fixed defaults (10 pts / 4 vs 8 weeks, 7-day backlog, 15% mileage drop, 30%
   skip rate …), or a per-school settings screen with these as defaults?
2. **Management and teacher-level alerts** — currently summaries only. Should Management see
   LMS-01 "teacher X falling" too?
3. **LMS-01 score** — quiz/quest only, or a combined quiz + homework + exam score?
4. **Salary figures** — the optimisation report tab is salary-free by your earlier decision. Should
   TT-01 on the Management dashboard show the ₹ saving, or periods only?
5. **ND items** — build the missing pieces (teacher-swap log for TT-07, usage query for Super Admin,
   POS for CAF-08, ACC-08 reconciliation job), or leave them out of v1?
6. **Where it lives** — one shared "Insights" service (like TimetableSuggestionService: one rule per
   method, try/catch per rule, cached) feeding all 5 dashboards, filtered by role? Or each role
   dashboard gets its own service?
7. **Build order** — which role first? (Suggest Principal: highest value, and the dashboard already exists.)
8. **Current role dashboards** — memory says 6 role dashboards still show static demo data.
   Replace their widgets with this, or add an Insights section on top of what is there?

---

## Built — rules live in `Modules/Dashboard/app/Insights/Rules/` (registered in `Modules/Dashboard/config/insights.php`)

All of these show on `/dashboard/principal` → Overview, grouped by module (Principal is in `see_all_roles`).
Counts are the card count from a dry-run against test.localhost on **20 Oct 2026**.

| ID | Rule class | Cards | What the card says |
|---|---|---:|---|
| LMS-07 | GradingBacklogRule | 78 | per teacher, homework waiting to be graded |
| LMS-10 | ExamGrievancesOpenRule | 1 | grievances unresolved > 3 days |
| BA-02 | BehaviourIncidentsOpenRule | 1 | open incidents, major/critical, missed follow-ups |
| STU-04 | VaccinationDueRule | 2 | doses overdue · doses due in 30 days |
| STU-05 | StudentDocumentsRule | 1 | documents unverified (and expired, when any) |
| ADM-03 | AdmissionFollowUpOverdueRule | 0 | missed follow-ups / stale open enquiries (none today) |
| CRT-01 | CertificateRequestsPendingRule | 1 | requests not yet issued, past needed-by |
| FEE-02 | FeeOverdueRule | 1 | overdue amount with 0-30 / 31-60 / 61-90 / 90+ ageing |
| FEE-08 | ScholarshipPendingRule | 1 | applications awaiting a decision |
| ACC-05 | AccountingApprovalsRule | 2 | vouchers · expense claims awaiting approval |
| HR-08 | PayrollNotLockedRule | 1 | per run, computed/approved but not locked |
| TPT-04/06/07/08/09/11/12/13 | Transport* rules | 96 | documents, incidents, load, non-boarding, upkeep, fees, driver attendance |
| LIB-04 | LibraryOverdueRule | 1 | overdue books, members, oldest due date |
| INV-01 | InventoryLowStockRule | 2 | per item at/below reorder level |
| INV-05 | InventoryPoOverdueRule | 2 | per PO past expected delivery |
| VND-01 | VendorAgreementExpiryRule | 0 | active agreements ending within 60 days (none today) |
| CAF-04 | CafeteriaLowStockRule | 6 | per item at/below reorder level |
| HST-03 | HostelLeaveOverdueRule | 1 | boarders past leave return date |
| HST-06 | HostelComplaintSlaRule | 3 | per complaint past SLA |
| HST-09 | HostelRoomChangePendingRule | 1 | room-change requests pending > 3 days |
| FOF-03 | GatePassNotReturnedRule | 3 | per pass, exited and not back |
| FOF-05 | FrontOfficeComplaintsRule | 1 | front-desk complaints open (new ID, not in the list above) |
| CMP-01 | ComplaintsOpenRule | 1 | tickets open, escalated, past resolution due date |
| NTF-01 | NotificationBouncesRule | 1 | bounced / spam deliveries in 30 days |

Notes: FEE-08 here is "applications pending", narrower than the fund-remaining idea in A5. CMP-01 uses each
ticket's own `resolution_due_at`, not `cmp_department_sla`. HST-03 covers leave only; gate passes are FOF-03.
