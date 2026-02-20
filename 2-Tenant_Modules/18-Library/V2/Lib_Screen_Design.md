# DATA SOURCES & CAPTURE REQUIREMENTS
-------------------------------------

## A. Data Fetched from Other Modules
| Module             | Table        | Data Used                                                                                               |
|--------------------|--------------|---------------------------------------------------------------------------------------------------------|
| User Management    | users        | User ID, Name, Email, Phone                                                                             |
| Student Management | sch_students | Student details, Class, Roll No                                                                         |
| Staff Management   | sch_staff    | Staff details, Department, Designation                                                                  |
| Academic           | sch_classes  | Class information for subject mapping                                                                   |
| Academic           | sch_subjects | Subject information for curricular alignment                                                            |
| Vendor Management  | vnd_vendors  | Book vendor details                                                                                     |
| Media Management   | media_files  | Digital resource files                                                                                  |

## B. Manual Data Entry Requirements
| Screen                 | Data to Capture                                                                                                                         |
|------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| Book Master            | Title, Subtitle, Edition, ISBN, ISSN, DOI, Publication Year, Publisher, Language, Page Count, Summary, Table of Contents, Cover Image,  |
|                        | Resource Type, Reference Only Flag, Lexile Level, Reading Age, Series Name/Position                                                     |
| Author Management      | Author Name, Short Name, Country, Primary Genre, Notes                                                                                  |
| Book Copy              | Accession Number, Barcode, RFID Tag, Shelf Location, Purchase Date, Purchase Price, Vendor, Initial Condition                           |
| Digital Resource       | File Name, File Upload, License Key/Type, License Dates, Access Restrictions                                                            |
| Member Registration    | Select User, Membership Type, Registration Date, Expiry Date, Auto-renew Flag, Notes                                                    |
| Fine Slab Config (NEW) | Slab Name, Applicable Membership/Resource Type, Max Fine Amount/Cap Type, Effective Dates, Priority, Day Ranges with Rates              |

--------------------------------------------------------------------------------------------------------------------------------------------------------------------

SCREEN 1: FINE SLAB CONFIGURATION LIST

================================================================================
                        FINE SLAB CONFIGURATION
================================================================================

[+ Add New Slab]                                    [Search: ____________] [Go]

-------------------------------------------------------------------------------
ID | Slab Name          | Applicable To    | Effective From | To        | Status
-------------------------------------------------------------------------------
1  | Student Late Fine  | Student          | 01-Jan-2025    | 31-Dec-25 | Active
   |                    |                  |                |           |
   | Day Ranges: 1-10: Rs10, 11-20: Rs20, 21-30: Rs30, 31+: Rs50            |
   | Max Cap: Rs500                                                          |
   |--------------------------------------------------------------------------
2  | Staff Late Fine    | Staff            | 01-Jan-2025    | 31-Dec-25 | Active
   |                    |                  |                |           |
   | Day Ranges: 1-15: Rs5, 16-30: Rs10, 31+: Rs20                          |
   | Max Cap: Unlimited                                                      |
   |--------------------------------------------------------------------------
3  | Premium Student    | Premium Student  | 01-Jan-2025    | 31-Dec-25 | Active
   |                    |                  |                |           |
   | Day Ranges: 1-10: Rs8, 11-20: Rs15, 21-30: Rs25, 31+: Rs40             |
   | Max Cap: Rs1000                                                         |
-------------------------------------------------------------------------------

[Edit] [View] [Deactivate] [Delete]                                    [<<] [>>]


SCREEN 2: ADD/EDIT FINE SLAB CONFIGURATION

================================================================================
                      ADD/EDIT FINE SLAB CONFIGURATION
================================================================================

Slab Name:* ________________________________________________________

Fine Type:*     [Late Return ▼]  [Lost Book]  [Damaged Book]  [Processing Fee]

Applicable To:
  Membership Type:  [All ▼]  OR Select: [Student ▼] [Staff ▼] [External ▼]
  Resource Type:    [All ▼]  OR Select: [Physical ▼] [Digital ▼] [Audio ▼]

Effective Period:
  From:* [ 25/01/2025 ]  To:* [ 31/12/2025 ]  (Leave blank if no end date)

Maximum Fine Cap:
  [X] Fixed Amount:  [  500.00  ]
  [ ] Book Cost
  [ ] Unlimited

Priority:* [ 10 ] (Higher number = higher priority)

-------------------------------------------------------------------------------
                          DAY RANGE CONFIGURATION
-------------------------------------------------------------------------------
[+ Add Day Range]

# | From Day | To Day  | Rate Type | Rate Value | Actions
-------------------------------------------------------------------------------
1 |    1     |   10    | Fixed     |  10.00     | [Edit] [Delete]
2 |   11     |   20    | Fixed     |  20.00     | [Edit] [Delete]
3 |   21     |   30    | Fixed     |  30.00     | [Edit] [Delete]
4 |   31     |   999   | Fixed     |  50.00     | [Edit] [Delete]
-------------------------------------------------------------------------------

[*Required fields]

                                                   [Cancel] [Save Configuration]


SCREEN 3: ADD DAY RANGE (POPUP/MODAL)

+----------------------------------------------------------+
|                    ADD DAY RANGE                         |
+----------------------------------------------------------+
|                                                           |
|  From Day:* [ 31 ]                                        |
|  To Day:*   [ 999 ] (Use 999 for infinite)                |
|                                                           |
|  Rate Type:* [X] Fixed Amount  [ ] % of Book Cost        |
|                                                           |
|  Rate Value:* [ 50.00 ]                                   |
|                                                           |
|  [Cancel] [Add]                                           |
+----------------------------------------------------------+


SCREEN 4: MEMBER 360 VIEW WITH FINE DETAILS

================================================================================
                        MEMBER 360 VIEW - John Doe
================================================================================

╔══════════════════════════════════════════════════════════════════════════════╗
║ Membership: STD-2025-00123         | Status: ACTIVE         | Expires: 31-Dec-2025
║ Type: Standard Student             | Cards Issued: 3/5      | Outstanding: Rs 450.00
║ Since: 15-Jan-2025                 | Last Active: 20-Feb-2025
╚══════════════════════════════════════════════════════════════════════════════╝

[TAB: Current Issues] [TAB: History] [TAB: Reservations] [TAB: Fines] [TAB: Analytics]

=============================== FINE DETAILS ===================================
Show: [All Fines ▼]   From: [01-Jan-2025]   To: [28-Feb-2025]   [Apply]

-------------------------------------------------------------------------------
ID | Transaction | Type      | Days  | Fine Amount | Paid/Waived | Status
-------------------------------------------------------------------------------
FN-001 | HP & Philo | Late Return | 15    | Rs 250.00   | Rs 0.00     | PENDING
       | (Due: 05-Feb) |             |       |             |             |
       | Fine Breakdown:                                                       |
       |   Days 1-10 (10 days @ Rs10) : Rs 100.00                              |
       |   Days 11-15 (5 days @ Rs20) : Rs 100.00                              |
       |   Subtotal                    : Rs 200.00                             |
       |   Late Fee Surcharge (25%)    : Rs 50.00                              |
       |   TOTAL                       : Rs 250.00                             |
       |-----------------------------------------------------------------------
FN-002 | Dune | Late Return | 5     | Rs 50.00    | Rs 50.00    | PAID
       | (Due: 10-Feb) |             |       |             | Paid: 20-Feb |
       | Fine Breakdown:                                                       |
       |   Days 1-5 (5 days @ Rs10)    : Rs 50.00                              |
-------------------------------------------------------------------------------

                                     Total Outstanding: Rs 250.00
                                     Total Paid YTD:    Rs 50.00
                                     Total Waived YTD:  Rs 0.00

[Pay Selected] [Pay All] [Waive Selected] [Print Statement]   [View Details]


SCREEN 5: FINE CALCULATION DETAILS VIEW

================================================================================
                      FINE CALCULATION DETAILS
================================================================================

Transaction ID: TXN-2025-02-00123                Fine ID: FN-001
Member: John Doe (STD-2025-00123)
Book: Harry Potter and the Philosopher's Stone (Copy: HP-001)
Issue Date: 01-Feb-2025
Due Date:   15-Feb-2025
Return Date: 20-Feb-2025
Days Overdue: 5 days (after 2 days grace period)

-------------------------------------------------------------------------------
                      FINE CALCULATION BREAKDOWN
-------------------------------------------------------------------------------

Fine Slab Applied: Student Late Fine (Slab ID: 1)

┌─────────┬──────────┬──────────┬──────────┬──────────┬──────────────┐
│ Day     │ Day      │ Days in  │ Rate     │ Rate     │ Fine         │
│ From    │ To       │ Slab     │ (Rs)     │ Type     │ Amount (Rs)  │
├─────────┼──────────┼──────────┼──────────┼──────────┼──────────────┤
│ 1       │ 10       │ 5        │ 10.00    │ Fixed    │ 50.00        │
├─────────┼──────────┼──────────┼──────────┼──────────┼──────────────┤
│ 11      │ 20       │ 0        │ 20.00    │ Fixed    │ 0.00         │
├─────────┼──────────┼──────────┼──────────┼──────────┼──────────────┤
│ 21      │ 30       │ 0        │ 30.00    │ Fixed    │ 0.00         │
├─────────┼──────────┼──────────┼──────────┼──────────┼──────────────┤
│ 31+     │ 999      │ 0        │ 50.00    │ Fixed    │ 0.00         │
└─────────┴──────────┴──────────┴──────────┴──────────┴──────────────┘

                           Subtotal:        Rs 50.00
                           Late Fee (25%):  Rs 12.50
                           GST (18%):       Rs 9.00
                           TOTAL FINE:       Rs 71.50

Max Cap Applied: Rs 500.00 (Not exceeded)
Final Fine Amount: Rs 71.50

[Recalculate] [Waive Fine] [Mark as Paid] [Print] [Close]


SCREEN 6: OVERDUE BOOKS MANAGEMENT

================================================================================
                      OVERDUE BOOKS MANAGEMENT
================================================================================

As of: 25-Feb-2025 10:30 AM

Filters: Membership: [All ▼]  Days Overdue: [> 0 ▼]  [Apply]

[Send Reminders] [Bulk Update] [Export CSV]

===============================================================================
Member          | Book              | Due Date | Days    | Est. Fine   | Action
                |                   |          | Overdue | (Slab Based)|
===============================================================================
John Doe        | Harry Potter      | 15-Feb   | 10      | Rs 150.00   | [View]
(STD-00123)     | (Copy: HP-001)    |          |         | Breakdown:  |
                |                   |          |         | 1-10: Rs100 |
                |                   |          |         | 11-20: Rs50 |
------------------------------------------------------------------------------
Jane Smith      | Dune              | 10-Feb   | 15      | Rs 250.00   | [View]
(STAFF-00456)   | (Copy: DN-002)    |          |         | Breakdown:  |
                |                   |          |         | 1-15: Rs75  |
                |                   |          |         | 16-30: Rs175|
------------------------------------------------------------------------------
Rahul Kumar     | Physics Textbook  | 05-Feb   | 20      | Rs 350.00   | [View]
(STD-00789)     | (Copy: PHY-003)   |          |         | Breakdown:  |
                |                   |          |         | 1-10: Rs100 |
                |                   |          |         | 11-20: Rs200|
                |                   |          |         | 21+: Rs50   |
===============================================================================

Legend: [ ] Send Reminder  [ ] Apply Waiver  [ ] Mark Lost

[<<] 1 2 3 4 5 [>>]


SCREEN 7: BOOK ISSUE SCREEN

================================================================================
                              BOOK ISSUE
================================================================================

┌─────────────────────────────────────────────────────────────────────────────┐
│ MEMBER DETAILS                                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│ Scan/Lookup: [ SCAN CARD ] or Search: [________] [Go]                       │
│                                                                              │
│ Member: John Doe                     Membership: STD-2025-00123             │
│ Type: Standard Student               Status: ACTIVE                          │
│ Books Issued: 3/5                    Outstanding Fines: Rs 250.00           │
│ Expiry: 31-Dec-2025                  Last Activity: 20-Feb-2025             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ BOOK DETAILS                                                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│ Scan: [ SCAN BOOK ] or Enter Accession No: [________] [Add]                 │
│                                                                              │
│ # | Accession | Title                | Due Date    | Condition              │
├───┼───────────┼──────────────────────┼──────────────┼───────────────────────┤
│ 1 | HP-001    | Harry Potter         | 10-Mar-2025  | [Good ▼]              │
│ 2 | DN-002    | Dune                 | 10-Mar-2025  | [Excellent ▼]         │
│ 3 |             [Add more...]                                               │
└─────────────────────────────────────────────────────────────────────────────┘

Notes: _________________________________________________________________

[Clear]                                                [Cancel] [Issue Books]


SCREEN 8: BOOK RETURN SCREEN

================================================================================
                              BOOK RETURN
================================================================================

┌─────────────────────────────────────────────────────────────────────────────┐
│ RETURN SCANNER                                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│ Scan Book: [ SCAN BOOK ] or Enter Barcode: [________] [Find]                │
│                                                                              │
│ Last Scanned: HP-001                                                         │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ RETURN DETAILS                                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│ Book: Harry Potter and the Philosopher's Stone                               │
│ Copy: HP-001                         Member: John Doe (STD-00123)           │
│ Issue Date: 01-Feb-2025              Due Date: 15-Feb-2025                  │
│                                                                              │
│ Return Date: 25-Feb-2025 (Auto)       Days Overdue: 10                       │
│                                                                              │
│ Return Condition: [Good ▼]                                                   │
│                                                                              │
│ ┌─────────────────────────────────────────────────────────────────────────┐ │
│ │ FINE CALCULATION                                                         │ │
│ ├─────────────────────────────────────────────────────────────────────────┤ │
│ │ Days 1-10 (10 days @ Rs10/day): Rs 100.00                                │ │
│ │ Days 11-20 (0 days @ Rs20/day): Rs 0.00                                  │ │
│ │ Total Fine: Rs 100.00                                                    │ │
│ │                                                                          │ │
│ │ [X] Apply fine to member account                                         │ │
│ │ [ ] Waive fine (Reason: __________________)                              │ │
│ └─────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│ Notes: __________________________________________________________________    │
└─────────────────────────────────────────────────────────────────────────────┘

[Clear]                                                [Cancel] [Process Return]


SCREEN 9: FINE REPORT

================================================================================
                        FINE COLLECTION REPORT
================================================================================

Period: [01-Jan-2025] to [28-Feb-2025]  [Generate Report]

┌─────────────────────────────────────────────────────────────────────────────┐
│ SUMMARY STATISTICS                                                            │
├─────────────────────────────────────────────────────────────────────────────┤
│ Total Fines Levied:      Rs 45,250.00   │ Number of Fines:        342       │
│ Total Fines Collected:   Rs 32,180.00   │ Collection Rate:        71.1%     │
│ Total Fines Waived:      Rs 8,070.00    │ Waiver Rate:           17.8%      │
│ Pending Fines:           Rs 5,000.00    │ Avg Fine per Transaction: Rs 132   │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ FINE BREAKDOWN BY MEMBERSHIP TYPE                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ Membership Type    │ Fines Levied │ Collected │ Waived │ Pending │ % of Total│
├────────────────────┼──────────────┼───────────┼────────┼─────────┼──────────┤
│ Standard Student   │ Rs 25,000    │ Rs 18,000 │ Rs 4,500│ Rs 2,500│ 55.2%    │
│ Premium Student    │ Rs 8,250     │ Rs 6,000  │ Rs 1,500│ Rs 750  │ 18.2%    │
│ Staff              │ Rs 7,000     │ Rs 5,000  │ Rs 1,500│ Rs 500  │ 15.5%    │
│ Research Scholar   │ Rs 3,500     │ Rs 2,500  │ Rs 570  │ Rs 430  │ 7.7%     │
│ External           │ Rs 1,500     │ Rs 680    │ Rs 0    │ Rs 820  │ 3.3%     │
└────────────────────┴──────────────┴───────────┴────────┴─────────┴──────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ TREND ANALYSIS (Last 6 Months)                                                │
├─────────────────────────────────────────────────────────────────────────────┤
│ Month     │ Sep'24 │ Oct'24 │ Nov'24 │ Dec'24 │ Jan'25 │ Feb'25 │           │
├───────────┼────────┼────────┼────────┼────────┼────────┼────────┤           │
│ Fines     │ 6,200  │ 6,800  │ 7,100  │ 7,500  │ 8,200  │ 8,450  │ ↗ Rising │
│ Collection│ 4,800  │ 5,200  │ 5,500  │ 5,800  │ 6,100  │ 6,180  │ ↗ Rising │
└───────────┴────────┴────────┴────────┴────────┴────────┴────────┴──────────┘

[Export PDF] [Export Excel] [Print]

