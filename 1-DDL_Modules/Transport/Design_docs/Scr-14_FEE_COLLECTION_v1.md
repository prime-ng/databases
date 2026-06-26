# Screen Design Specification: Fee Collection
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Track transportation fee payments and collections from students. Backed by `tpt_fee_collection`.

### 1.2 User Roles & Permissions
| Role | Create | View | Update | Delete | print | Export | Import |
|------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| PG Support   |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| School Admin |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✗    |
| Principal    |   ✓   |  ✓  |   ✗    |   ✗    |  ✓   |  ✓    |  ✗    |
| Teacher      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Student      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Parents      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |

### 1.3 Data Context

Database Table: `tpt_fee_collection`
├── id (BIGINT PRIMARY KEY)
├── student_id (FK -> `std_students.id`)
├── fee_master_id (FK -> `tpt_fee_master.id`)
├── amount_due (DECIMAL(10,2))
├── amount_paid (DECIMAL(10,2), default 0)
├── due_date (DATE)
├── paid_date (DATE, nullable)
├── status (ENUM: DUE, PARTIAL, PAID, OVERDUE, CANCELLED)
├── payment_method (ENUM: CASH, CHEQUE, ONLINE, AUTO)
├── receipt_no (VARCHAR, nullable)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Fee Collection Dashboard
**Route:** `/transport/fee-collection`

#### 2.1.1 Dashboard Summary
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > FEE COLLECTION                                       │
├──────────────────────────────────────────────────────────────────┤
│ SESSION: [2025-26 ▼]  ROUTE: [All ▼]  CLASS: [All ▼]           │
│ STATUS: [All ▼]  [Search Student]  [Advanced Filter]            │
├──────────────────────────────────────────────────────────────────┤
│
│ ┌─ COLLECTION SUMMARY ─────────────────────────────┐
│ │ Total Due: ₹4,50,000    Collected: ₹3,75,000   │
│ │ Collection Rate: 83.3%  Pending: ₹75,000       │
│ └──────────────────────────────────────────────────┘
│
│ [Collect Payment] [Generate Invoice] [Send Reminder] [Export]
│
│ Roll No | Student Name      | Class | Due Amount | Paid  | Status     │ Actions
├──────────────────────────────────────────────────────────────────────────────┤
│ ST001   | Aarav Patel       | 10-A  | ₹ 2,000    | ₹2,000│ PAID       │ [Receipt]
│ ST002   | Bhavna Gupta      | 10-A  | ₹ 2,000    | ₹1,500│ PARTIAL    │ [Collect] [Details]
│ ST003   | Chetan Singh      | 10-B  | ₹ 1,800    | ₹0    │ DUE        │ [Collect] [Reminder]
│ ST004   | Diya Verma        | 10-A  | ₹ 2,000    | ₹0    │ OVERDUE    │ [Urgent!] [Collect]
│
│ [Bulk Actions] [Print Reminder Letters]
│
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Collect Payment
#### 2.2.1 Payment Collection Modal
```
┌────────────────────────────────────────────────┐
│ COLLECT PAYMENT                             [✕]│
├────────────────────────────────────────────────┤
│ Student *                [Aarav Patel]        │
│ Due Amount               [₹ 2,000]             │
│ Received Amount *        [____________]        │
│ Payment Method *         [Online ▼]            │
│                          CASH/CHEQUE/ONLINE/AUTO
│ Payment Date *           [Calendar Picker]     │
│ Cheque No (if cheque)    [____________]        │
│ Transaction ID (online)  [____________]        │
│ Notes                    [__________________]  │
│
│ CALCULATION
│ Amount Due: ₹2,000.00
│ Amount Paid: ₹500.00
│ New Status: PARTIAL (₹1,500.00 remaining)
│
├────────────────────────────────────────────────┤
│ [Cancel] [Generate Receipt] [Save & Print]    │
└────────────────────────────────────────────────┘
```

### 2.3 Payment Receipt
#### 2.3.1 Receipt View/Print
```
┌─────────────────────────────────────────────────┐
│                                                  │
│                  [SCHOOL LOGO]                  │
│         TRANSPORTATION FEE RECEIPT              │
│                                                  │
├─────────────────────────────────────────────────┤
│ Receipt No: REC-2025-12-0001
│ Date: 2025-12-01
│
│ STUDENT DETAILS
│ Name: Aarav Patel
│ Roll No: ST001
│ Class: 10-A
│ Route: Route A
│
│ PAYMENT DETAILS
│ Fee Type: Monthly
│ Month: December 2025
│ Amount Due: ₹2,000.00
│ Amount Paid: ₹2,000.00
│ Payment Method: Online
│ Payment Date: 2025-12-01
│ Transaction ID: TXN-123456
│
│ STATUS: PAID
│ [Print] [Email] [Download PDF]
│
└─────────────────────────────────────────────────┘
```

### 2.4 Fee Collection Report
#### 2.4.1 Detailed View
```
ROUTE: Route A  SESSION: 2025-26
─────────────────────────────────────────────────────
Class | Students | Due Amount | Collected | Pending | %
─────────────────────────────────────────────────────
10-A  | 42       | ₹84,000    | ₹75,600   | ₹8,400  | 90%
10-B  | 38       | ₹68,400    | ₹57,600   | ₹10,800 | 84%
9-A   | 45       | ₹90,000    | ₹72,000   | ₹18,000 | 80%
─────────────────────────────────────────────────────
Total | 125      | ₹242,400   | ₹205,200  | ₹37,200 | 85%
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Fee Collection (Invoice Generation)
```json
POST /api/v1/transport/fee-collection
{
  "student_id": 10,
  "fee_master_id": 5,
  "amount_due": 2000.00,
  "due_date": "2025-12-15",
  "status": "DUE"
}

Response:
{
  "id": 400,
  "student_id": 10,
  "student_name": "Aarav Patel",
  "fee_master_id": 5,
  "amount_due": 2000.00,
  "amount_paid": 0.00,
  "due_date": "2025-12-15",
  "status": "DUE",
  "created_at": "2025-12-01T10:00:00Z"
}
```

### 3.2 Record Payment
```json
PATCH /api/v1/transport/fee-collection/{id}
{
  "amount_paid": 2000.00,
  "paid_date": "2025-12-01",
  "payment_method": "ONLINE",
  "receipt_no": "REC-2025-12-0001",
  "status": "PAID",
  "transaction_id": "TXN-123456"
}

Response:
{
  "id": 400,
  "amount_due": 2000.00,
  "amount_paid": 2000.00,
  "status": "PAID",
  "paid_date": "2025-12-01",
  "receipt_no": "REC-2025-12-0001"
}
```

### 3.3 Get Collection Records
```json
GET /api/v1/transport/fee-collection?student_id={id}&status={status}

Response:
{
  "data": [
    {
      "id": 400,
      "student_id": 10,
      "student_name": "Aarav Patel",
      "amount_due": 2000.00,
      "amount_paid": 2000.00,
      "due_date": "2025-12-15",
      "paid_date": "2025-12-01",
      "status": "PAID",
      "payment_method": "ONLINE"
    }
  ]
}
```

### 3.4 Get Collection Dashboard
```json
GET /api/v1/transport/fee-collection/dashboard?session_id={id}&route_id={id}

Response:
{
  "summary": {
    "total_due": 450000.00,
    "total_collected": 375000.00,
    "total_pending": 75000.00,
    "collection_rate": 83.3
  },
  "status_breakdown": {
    "PAID": 95,
    "PARTIAL": 12,
    "DUE": 15,
    "OVERDUE": 3
  }
}
```

---

## 4. USER WORKFLOWS

### 4.1 Generate Fee Invoice
```
1. Admin selects session and fee master rule (monthly for Route A)
2. System identifies all students allocated to Route A
3. Creates fee_collection records (one per student, status=DUE)
4. Invoices sent to parents (email/SMS notification)
5. Due date set to 15th of month
```

### 4.2 Collect Payment
```
1. Parent makes payment (online/cheque/cash) on parent portal or via admin
2. Admin opens [Collect Payment] for student
3. Enters received amount and payment method
4. System calculates remaining balance (amount_due - amount_paid)
5. Status updated (PAID if full, PARTIAL if partial)
6. Receipt generated and emailed
```

### 4.3 Send Payment Reminders
```
1. Admin opens Fee Collection dashboard
2. Filters for OVERDUE status
3. Selects multiple students
4. Clicks [Send Reminder]
5. Email/SMS sent to parents with pending amount
```

---

## 5. VISUAL DESIGN GUIDELINES

- Color-code status: PAID (green), PARTIAL (yellow), DUE (blue), OVERDUE (red), CANCELLED (gray)
- Summary metrics in prominent cards at top
- Receipt design professional and printer-friendly
- Mobile-responsive payment form

---

## 6. ACCESSIBILITY & USABILITY

- Currency input with validation (positive decimals)
- Date pickers accessible via keyboard
- Receipt printable and emailable
- Status filters clear and intuitive

---

## 7. TESTING CHECKLIST

- [ ] Fee invoice created for all students in route
- [ ] Full payment marks status as PAID
- [ ] Partial payment marks status as PARTIAL
- [ ] Receipt generated with correct amount and date
- [ ] OVERDUE flag set when paid_date > due_date
- [ ] Collection dashboard summary calculates correctly
- [ ] Export to CSV includes all payment records
- [ ] Bulk reminder send to multiple students

---

## 8. FUTURE ENHANCEMENTS

1. Automated invoice generation (scheduled monthly)
2. Payment plan for large amounts (installment tracking)
3. Online payment gateway integration (Razorpay, Stripe)
4. Discount and waiver management
5. Refund processing for overpayments
6. Late fee surcharge calculation
7. Fee receipt SMS and email templates customization

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
