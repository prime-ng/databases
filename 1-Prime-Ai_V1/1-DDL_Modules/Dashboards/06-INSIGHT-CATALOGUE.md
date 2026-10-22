# Insight catalogue — what the dashboards tell you

Every insight the system generates today. The examples are **real cards from test.localhost**
(Demo CBSE Senior Secondary School), taken on 2026-10-20 after the daily run.

**32 rules · 18 modules · 234 live cards** (open, acknowledged, assigned or snoozed)

---

## How an insight works, in one paragraph

Each **rule** checks one condition every morning at 05:30 (e.g. "fee invoices past due"). Each
time the condition is true, the rule raises a **card**: one card for the whole school, or one per
student, teacher, vehicle and so on. A card stays until someone acts on it or the condition
clears, and then it closes by itself. Every card has a **priority score (0-100)**, computed from
how serious, how widespread and how urgent it is. The most urgent five show as "Top today". A
user can Open the linked page, Acknowledge, Assign to a colleague, Snooze or Dismiss.
At 07:00 school leadership also gets their top 5 by email and in-app.

### Types

| Type | Meaning | Rules |
|---|---|---|
| **Alert** | Something is wrong or overdue and needs action | 29 |
| **Suggestion** | Not broken, but worth improving | 3 (HST-09, TPT-07, TPT-08) |

### Categories (area)

| Area | What it covers | Rules |
|---|---|---|
| **Operations** | stock, complaints, buses, library, vendors, messaging | 15 |
| **Students** | safety, wellbeing, academics risk, documents | 7 |
| **Finance** | fees, payroll, approvals, scholarships | 5 |
| **Compliance** | expiring documents, unverified records | 2 |
| **Academics** | grading and exam process | 2 |
| **Staff** | staff attendance | 1 |

### How serious (severity weight)

| Weight | Used for | Examples |
|---|---|---|
| **1.0 Safety** (5 rules) | a child or vehicle could be at risk | FOF-03 gate pass, HST-03 boarders overdue, TPT-06 trip incidents, TPT-09 bus servicing, TPT-13 bus over capacity |
| **0.8 Money / wellbeing** (9) | money owed, students in difficulty, legal documents | FEE-02 fees, TPT-11 transport fees, HR-08 payroll, STU-04 vaccinations, STU-10 at risk, BA-02 behaviour, CMP-01 complaints, TPT-04 vehicle documents, TPT-08 unused seats |
| **0.6 Quality** (14) | the school's service slipping | LMS-07 grading, LMS-10 grievances, ACC-05 approvals, FEE-08 scholarships, CAF-04 / INV-01 stock, LIB-04 books, and others |
| **0.4 Efficiency** (4) | could run better | HST-09 room changes, INV-05 late POs, TPT-07 under-filled routes, VND-01 vendor renewals |

---

## By module

### 🎓 Academics — LMS

| Rule | Insight | Example from the DB |
|---|---|---|
| **LMS-07** Homework grading backlog | One card **per teacher** with homework waiting to be graded | *"SUNITA MIYAN has 73 homework submissions waiting to be graded; the oldest is 14 days old."* (78 cards) |
| **LMS-10** Exam grievances unresolved | Students' exam re-check requests not handled | *"3 exam grievances unresolved for over 3 days (2 not yet picked up); oldest raised 14 Oct 2026."* |

### 👦 Students — Student Profile

| Rule | Insight | Example from the DB |
|---|---|---|
| **STU-10** ⭐ Students at risk | One card **per student** when 2+ warning signs line up **across modules**: low quiz/exam scores, missed homework, behaviour incidents, attendance drop, overdue fees | *"Sita Chatterjee (UKG-A): quiz average 35% over 12 quizzes · fees ₹3,125 overdue 80 days"* (27 cards) |
| **STU-04** Vaccinations overdue or due soon | Health — doses overdue, or due in the next 30 days | *"1,819 students have 7,805 vaccine doses overdue with no later dose recorded."* · *"16 students have a vaccine dose due in the next 30 days."* |
| **STU-05** Student documents unverified/expired | Compliance on admission documents | *"5,472 documents for 1,824 students are uploaded but not verified."* |

### 🧭 Behaviour — Behavioural Assessment

| Rule | Insight | Example from the DB |
|---|---|---|
| **BA-02** Behaviour incidents still open | Open incidents, with the serious ones and missed follow-ups called out | *"8 behaviour incidents open or under review — 4 major/critical, 4 with a missed follow-up."* |

### 💰 Fees — Student Fee

| Rule | Insight | Example from the DB |
|---|---|---|
| **FEE-02** Overdue school fees | One school card with ageing buckets; ⭐ has an **"Email reminders"** button that emails every overdue parent in one click | *"₹2,75,67,656 overdue across 1,277 students (2,736 invoices). Over 90 days: ₹1,88,13,125."* |
| **FEE-08** Scholarships awaiting a decision | Applications nobody has decided on | *"17 scholarship applications awaiting a decision (8 under review), oldest applied 19 Sep 2026."* |

### 🧾 Accounts — Accounting

| Rule | Insight | Example from the DB |
|---|---|---|
| **ACC-05** Accounting approvals pending | Vouchers and expense claims waiting for approval | *"1 voucher worth ₹2,50,000 waiting for approval."* · *"1 staff expense claim worth ₹5,600 waiting for approval."* |

### 👥 HR & Payroll

| Rule | Insight | Example from the DB |
|---|---|---|
| **HR-08** Payroll run not locked | Approved payroll that has not been locked (so it can still change) | *"Payroll for October 2026 is approved but not locked — 145 employees, ₹42,15,647 net pay."* |

### 🚌 Transport (8 rules — the largest module)

| Rule | Insight | Example from the DB |
|---|---|---|
| **TPT-13** Routes over seating capacity | Safety — more students than seats | *"Route 13 - Kapodara, Chikuwadi, Yogi Chauk (Drop) has 67 students allocated for 40 seats — 27 over capacity."* |
| **TPT-06** Trip incidents not resolved | Incidents on a route still open | *"HIGH incident on Route 16 - Simada, Sarthana (vehicle V-021), open for 1 day."* |
| **TPT-09** Inspections & servicing | Vehicles whose service is overdue or stuck | *"Vehicle V-005: service approved 28 days ago and still not completed."* |
| **TPT-04** Vehicle & driver documents expiring | Pollution, insurance, fitness, licence | *"Vehicle V-006: pollution certificate expires in 1 day (21 Oct 2026)."* |
| **TPT-12** Driver attendance gaps | Drivers absent repeatedly | *"Driver Qabool Zachariah: 4 absences in the last 14 days."* |
| **TPT-11** Transport fees overdue | One card per student | *"Ishita Banerjee (ADM000045): 2 transport fee instalments overdue, ₹4,267 outstanding since 11 May 2025."* (38 cards) |
| **TPT-08** Students allocated but not boarding | *Suggestion* — paid-for seats nobody uses | *"Route 17 - Parvat Patiya, Saroli, Saniya Hemad: 37 allocated students have not boarded the bus in 14 days."* |
| **TPT-07** Under-filled routes | *Suggestion* — routes that could be merged | no card today |

### 🏠 Hostel

| Rule | Insight | Example from the DB |
|---|---|---|
| **HST-03** Boarders overdue from leave | Safety — boarders who never came back | *"409 boarders are past their leave return date with no return recorded (oldest ended 21 Aug 2025)."* |
| **HST-06** Hostel complaints past SLA | One card per complaint | *"North Block: High complaint "Room socket sparking when unplugging" is 13 days past SLA."* |
| **HST-09** Room-change requests waiting | *Suggestion* | *"412 room-change requests are pending for more than 3 days (oldest raised 28 Sep 2026)."* |

### 🚪 Front Office

| Rule | Insight | Example from the DB |
|---|---|---|
| **FOF-03** Gate pass not returned | Safety — someone left and did not come back | *"Arjun Mirza (pass GP-20261017-002) was due back at 17 Oct 14:10 — 2 days late, not yet returned."* |
| **FOF-05** Front-office complaints open | | *"9 front-office complaints unresolved (2 escalated)."* |

### 📦 Inventory · 🍲 Cafeteria · 📚 Library · 🤝 Vendor

| Rule | Insight | Example from the DB |
|---|---|---|
| **INV-01** Stock at/below reorder level | One card per item | *"Microscope Slide Set (SLIDE-SET-001): 3 left, reorder level is 5."* |
| **INV-05** Purchase orders past delivery date | One card per PO | *"PO PO-2026-003 from Sharma Stationery Suppliers is 6 days late (not received, ₹33,520)."* |
| **CAF-04** Cafeteria stock running low | One card per ingredient | *"Cooking Oil: -19 L left, reorder level is 25."* (a negative stock — itself a data problem worth fixing) |
| **LIB-04** Overdue library books | | *"4 books are overdue with 3 members; the oldest was due on 23 Sep 2026."* |
| **VND-01** Vendor agreement ending | Contracts to renew | no card today |

### 📣 Complaints · Certificates · Notifications · Admissions

| Rule | Insight | Example from the DB |
|---|---|---|
| **CMP-01** Complaints awaiting resolution | | *"11 complaint tickets unresolved — 1 escalated, 0 past the resolution due date."* |
| **CRT-01** Certificate requests not issued | | *"8 certificate requests not yet issued (8 approved and waiting to be generated)."* |
| **NTF-01** Messages not reaching parents | Bounced / failed SMS and email | *"5 messages failed to reach 5 recipients in the last 30 days (0 marked as spam)."* |
| **ADM-03** Admission follow-ups overdue | Enquiries nobody followed up | no card today |

---

## What makes these different from a normal ERP report

1. **They find you.** Nobody has to open 18 modules. The problems arrive ranked, every morning, by email too.
2. **Across modules.** STU-10 joins LMS, Behaviour, Attendance and Fees into one picture of a child. No single module can show that.
3. **Act from the card.** FEE-02 sends every overdue reminder from the dashboard in one click. Its 7-day lock stops the same parents being emailed twice.
4. **They close themselves.** When the fees are paid or the bus is serviced, the card disappears. Nobody has to tidy up.
5. **Each school tunes them.** Every threshold (e.g. "fees overdue more than 30 days", "quiz average below 40%") can be changed on the insight settings screen. Today only School Admin has permission to open that screen.

## Who sees what

- **Principal** sees every active rule's cards (`see_all_roles` in `config/insights.php`), grouped by module. So does Super Admin.
- **Every other role** sees only the rules that list that role (e.g. STU-10 lists School Admin and Management).
- A card's **Open** link appears only when that user may open the target page. Example: Management has no permission to view a student profile, so it sees STU-10 cards without a link.
- The 07:00 email goes to Principal, Vice Principal, School Admin and Management, showing each person only the cards they would see on their own dashboard.
