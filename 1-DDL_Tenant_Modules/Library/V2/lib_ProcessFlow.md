# COMPLETE PROCESS FLOW FOR LIBRARY MODULE
------------------------------------------

┌─────────────────────────────────────────────────────────────────────────────┐
│                      LIBRARY MANAGEMENT SYSTEM FLOW                         │
└─────────────────────────────────────────────────────────────────────────────┘

A. MASTER DATA SETUP FLOW
   ┌─────────────────────────────────────────────────────────────────────┐
   │ 1. System Configuration (Admin)                                      │
   │    ├── Define Membership Types                                       │
   │    ├── Define Resource Types (Physical/Digital)                      │
   │    ├── Define Categories & Genres                                    │
   │    ├── Define Book Conditions                                        │
   │    ├── Define Shelf Locations                                        │
   │    └── Define Fine Slab Configurations (NEW)                         │
   │        ├── Slab name & applicability (membership/resource type)      │
   │        ├── Day ranges with rates                                     │
   │        ├── Maximum fine caps                                         │
   │        └── Effective date range                                      │
   └─────────────────────────────────────────────────────────────────────┘

B. BOOK ACQUISITION & CATALOGING FLOW
   ┌─────────────────────────────────────────────────────────────────────┐
   │ 2. Book Master Creation (Librarian)                                 │
   │    ├── Manual Entry or ISBN Auto-fetch                              │
   │    ├── Title, Author(s), Publisher, Year                            │
   │    ├── ISBN, Edition, Page Count                                    │
   │    ├── Categories, Genres, Subjects                                 │
   │    ├── Resource Type                                                 │
   │    └── Reference Only Flag                                          │
   │                                                                      │
   │ 3. Book Copy Management                                              │
   │    ├── Generate Accession Number                                    │
   │    ├── Generate Barcode/RFID                                        │
   │    ├── Assign Shelf Location                                        │
   │    ├── Record Purchase Date & Price                                 │
   │    ├── Set Initial Condition                                        │
   │    └── Status = Available                                           │
   │                                                                      │
   │ 4. Digital Resource Management                                       │
   │    ├── Upload File or Link                                          │
   │    ├── Set License Details                                           │
   │    ├── Define Access Restrictions                                   │
   │    └── Set Expiry if applicable                                     │
   └─────────────────────────────────────────────────────────────────────┘

C. MEMBER MANAGEMENT FLOW
   ┌─────────────────────────────────────────────────────────────────────┐
   │ 5. Member Registration (Auto/Semi-auto)                             │
   │    ├── Data Source:                                                  │
   │    │   ├── users table (existing user data)                         │
   │    │   ├── sch_students (for students)                              │
   │    │   ├── sch_staff (for staff)                                    │
   │    │   └── Manual Entry (for external members)                      │
   │    │                                                                 │
   │    ├── Process:                                                      │
   │    │   ├── Select User from existing users                          │
   │    │   ├── Assign Membership Type                                   │
   │    │   ├── Generate Membership Number                               │
   │    │   ├── Generate Library Card Barcode                            │
   │    │   ├── Set Registration & Expiry Date                           │
   │    │   └── Status = Active                                          │
   │    │                                                                 │
   │    └── Automated Updates:                                            │
   │        ├── Expiry reminders                                         │
   │        ├── Auto-renewal if enabled                                  │
   │        └── Status updates based on fines/activity                   │
   └─────────────────────────────────────────────────────────────────────┘

D. CIRCULATION FLOW
   ┌─────────────────────────────────────────────────────────────────────┐
   │ 6. Book Issue Process                                                │
   │    ├── Scan Member Card/Lookup Member                               │
   │    ├── Verify:                                                       │
   │    │   ├── Membership active & not expired                          │
   │    │   ├── Outstanding fines < threshold                            │
   │    │   ├── Within borrowing limit                                   │
   │    │   └── No existing issues overdue                               │
   │    ├── Scan Book Barcode/RFID                                       │
   │    ├── Verify Book available                                        │
   │    ├── Calculate Due Date based on membership type                  │
   │    ├── Record Issue Condition                                       │
   │    ├── Create Transaction (Status = Issued)                         │
   │    ├── Update Copy Status = Issued                                  │
   │    └── Update Member:                                                │
   │        ├── total_books_borrowed +1                                  │
   │        └── last_activity_date = today                               │
   │                                                                      │
   │ 7. Book Return Process                                               │
   │    ├── Scan Book Barcode                                            │
   │    ├── Verify Transaction exists                                    │
   │    ├── Check Condition & Update if needed                           │
   │    ├── Calculate:                                                    │
   │    │   ├── Days overdue (if any)                                    │
   │    │   └── Applicable fine (using slab system)                      │
   │    ├── If Overdue:                                                   │
   │    │   ├── Calculate fine using slab system                         │
   │    │   ├── Store calculation breakdown                              │
   │    │   ├── Create Fine record (Pending)                             │
   │    │   └── Update Member outstanding_fines                          │
   │    ├── Update Transaction:                                           │
   │    │   ├── return_date = now                                        │
   │    │   ├── return_condition_id                                      │
   │    │   └── status = Returned                                        │
   │    ├── Update Copy:                                                  │
   │    │   ├── status = Available                                       │
   │    │   ├── current_condition_id (if changed)                        │
   │    │   └── location (if returned to different shelf)                │
   │    └── Check for pending reservations                               │
   │                                                                      │
   │ 8. Book Renewal Process                                              │
   │    ├── Verify renewal allowed for membership                        │
   │    ├── Check renewal count < max_renewals                           │
   │    ├── No pending reservations for this book                        │
   │    ├── Update Transaction:                                           │
   │    │   ├── is_renewed = true                                        │
   │    │   ├── renewal_count +1                                         │
   │    │   └── due_date = due_date + loan_period                        │
   │    └── Create Renewal History                                       │
   └─────────────────────────────────────────────────────────────────────┘

E. RESERVATION FLOW
   ┌─────────────────────────────────────────────────────────────────────┐
   │ 9. Book Reservation Process                                          │
   │    ├── Member searches & finds book                                 │
   │    ├── Check if all copies issued                                   │
   │    ├── Create Reservation:                                           │
   │    │   ├── Calculate queue position                                 │
   │    │   ├── Expected available date (based on earliest return)      │
   │    │   └── Status = Pending                                         │
   │    ├── When copy returned:                                           │
   │    │   ├── Check next in queue                                      │
   │    │   ├── Update reservation: status = Available                   │
   │    │   ├── Set pickup_by_date (e.g., +2 days)                       │
   │    │   └── Send notification to member                              │
   │    └── If not picked up by date:                                     │
   │        ├── Mark reservation as Expired                              │
   │        ├── Move to next in queue                                    │
   │        └── Make copy available                                      │
   └─────────────────────────────────────────────────────────────────────┘

F. FINE MANAGEMENT FLOW (ENHANCED)
   ┌─────────────────────────────────────────────────────────────────────┐
   │ 10. Fine Calculation & Collection                                    │
   │    ├── Daily Scheduled Job:                                          │
   │    │   ├── Identify overdue transactions                            │
   │    │   ├── For each overdue:                                        │
   │    │   │   ├── Get membership & resource type                       │
   │    │   │   ├── Find applicable fine slab config                     │
   │    │   │   ├── Calculate days overdue                               │
   │    │   │   ├── Apply slab rates:                                    │
   │    │   │   │   ├── Days 1-10: Rs 10/day                             │
   │    │   │   │   ├── Days 11-20: Rs 20/day                            │
   │    │   │   │   ├── Days 21-30: Rs 30/day                            │
   │    │   │   │   └── Days 31+: Rs 50/day                              │
   │    │   │   ├── Apply max cap (if configured)                        │
   │    │   │   ├── Store calculation breakdown (JSON)                   │
   │    │   │   └── Create/Update Fine record                            │
   │    │   └── Update member outstanding_fines                          │
   │    │                                                                 │
   │    ├── Fine Payment:                                                 │
   │    │   ├── Member pays fine (Cash/Card/Online)                      │
   │    │   ├── Create Fine Payment record                               │
   │    │   ├── Update Fine status = Paid                                │
   │    │   ├── Update Member:                                            │
   │    │   │   ├── total_fines_paid + amount                            │
   │    │   │   └── outstanding_fines - amount                           │
   │    │   └── Generate Receipt                                         │
   │    │                                                                 │
   │    └── Fine Waiver:                                                  │
   │        ├── Authorized staff approves waiver                         │
   │        ├── Record waived_by, reason, date                           │
   │        ├── Update Fine status = Waived                              │
   │        └── Update Member outstanding_fines - waived_amount          │
   └─────────────────────────────────────────────────────────────────────┘

G. ANALYTICS & REPORTING FLOW
   ┌─────────────────────────────────────────────────────────────────────┐
   │ 11. Analytics Generation (Scheduled Jobs)                            │
   │    ├── Daily:                                                       │
   │    │   ├── Update book popularity trends                            │
   │    │   ├── Update collection health metrics                         │
   │    │   └── Send overdue notifications                               │
   │    │                                                                 │
   │    ├── Weekly:                                                      │
   │    │   ├── Update reading behavior analytics                        │
   │    │   ├── Calculate member engagement scores                       │
   │    │   ├── Generate predictive demand forecasts                     │
   │    │   └── Update curricular alignment scores                       │
   │    │                                                                 │
   │    └── Monthly:                                                     │
   │        ├── Member churn risk calculation                            │
   │        ├── Collection weeding recommendations                       │
   │        ├── Acquisition recommendations                              │
   │        └── Budget utilization reports                               │
   └─────────────────────────────────────────────────────────────────────┘

