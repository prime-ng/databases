# Transport Module Testing & QA (Deliverable F)

Stack: Laravel (PHP) + MySQL  
Module: Transport Management  
Scope: Dashboards, Analytics, GPS (Future)

---

## 1. Screens Covered
1. Transport Head Dashboard
2. Principal / Management Dashboard
3. Accountant Dashboard
4. Driver Dashboard
5. Parent / Student Dashboard
6. Parent Live GPS Dashboard (Future)

---

## 2. Global Assumptions
- Academic Session active
- Routes, Vehicles, Drivers mapped
- Role-based access enabled
- Analytics are read-only
- Tenant isolation enforced

---

## 3. Global Reference Test Data
```
Route: R-03
Vehicle: BUS-07 (Capacity 40)
Students Allocated: 35
Students Paying Fee: 31
Driver: DR-05
Session: 2025–26
```

---

## SCREEN F1 — Transport Head Dashboard

### Developer Checklist
- KPIs load < 3 sec
- Utilization logic correct
- Leakage logic correct
- Filters refresh widgets
- Drilldowns work
- Read-only enforced

### QA Checklist
- Role access enforced
- Cross-tenant isolation
- Empty states handled
- Export matches UI

### Test Cases
| TC | Scenario | Input | Expected |
|----|----------|-------|----------|
| TH-01 | View dashboard | Transport Head | Dashboard loads |
| TH-02 | Filter route | R-03 | Widgets filtered |
| TH-03 | Leakage | 4 unpaid | Leakage=4 |
| TH-04 | Drilldown | Click route | Detail opens |
| TH-05 | Unauthorized | Teacher | Access denied |

---

## SCREEN F2 — Principal / Management Dashboard

### Developer Checklist
- Cost vs revenue correct
- Profit/Loss accurate
- Compliance alerts valid

### QA Checklist
- Read-only access
- Financial rounding correct

### Test Cases
| TC | Scenario | Input | Expected |
|----|----------|-------|----------|
| PM-01 | View | Principal | Dashboard loads |
| PM-02 | Loss route | Cost>Revenue | Status LOSS |
| PM-03 | Compliance | Expired doc | Highlighted |
| PM-04 | Filter session | 2025–26 | Data updated |

---

## SCREEN F3 — Accountant Dashboard

### Developer Checklist
- Fee vs usage correct
- Leakage rows accurate
- Export correct

### QA Checklist
- Finance-only access
- No student leakage

### Test Cases
| TC | Scenario | Input | Expected |
|----|----------|-------|----------|
| AC-01 | View | Accountant | Dashboard loads |
| AC-02 | Leakage | Unpaid | Listed |
| AC-03 | Paid | Paid student | Not listed |
| AC-04 | Export | CSV | Matches UI |

---

## SCREEN F4 — Driver Dashboard

### Developer Checklist
- Only assigned route visible
- Attendance mark works
- No edit history

### QA Checklist
- No finance visible
- Mobile friendly

### Test Cases
| TC | Scenario | Input | Expected |
|----|----------|-------|----------|
| DR-01 | Login | Driver | Dashboard |
| DR-02 | Other route | Not assigned | Blocked |
| DR-03 | Attendance | Valid QR | Success |
| DR-04 | Duplicate | Same student | Blocked |

---

## SCREEN F5 — Parent / Student Dashboard

### Developer Checklist
- Own child only
- Attendance read-only
- Fee status accurate

### QA Checklist
- No other students visible
- No driver data

### Test Cases
| TC | Scenario | Input | Expected |
|----|----------|-------|----------|
| PA-01 | Login | Parent | Dashboard |
| PA-02 | Other child | Not own | Blocked |
| PA-03 | Fee pending | No payment | Pending |
| PA-04 | Attendance | 7 days | Correct |

---

## SCREEN F6 — Parent Live GPS (Future)

### Developer Checklist
- Stop-level masking
- Auto disable post trip

### QA Checklist
- Consent enforced
- Route hidden

### Test Cases
| TC | Scenario | Input | Expected |
|----|----------|-------|----------|
| GPS-01 | Live trip | GPS on | Map shown |
| GPS-02 | GPS off | Device off | Message |
| GPS-03 | After trip | Ended | Disabled |

---

END OF DELIVERABLE F
