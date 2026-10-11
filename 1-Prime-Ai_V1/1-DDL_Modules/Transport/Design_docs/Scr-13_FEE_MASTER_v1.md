# Screen Design Specification: Fee Master
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Define recurring transportation fees for students. Backed by `tpt_fee_master`.

### 1.2 User Roles & Permissions
| Role | Create | View | Update | Delete | print | Export | Import |
|------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| PG Support   |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| School Admin |   ✓   |  ✓  |   ✓    |   ✗    |  ✓   |  ✓    |  ✗    |
| Principal    |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✗    |  ✗    |
| Teacher      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Student      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Parents      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |

### 1.3 Data Context

Database Table: `tpt_fee_master`
├── id (BIGINT PRIMARY KEY)
├── route_id (FK -> `tpt_routes.id`, nullable)
├── stop_id (FK -> `tpt_pickup_points.id`, nullable)
├── session_id (FK -> `sch_sessions.id`)
├── fee_type (ENUM: MONTHLY, QUARTERLY, ANNUAL)
├── amount (DECIMAL(10,2))
├── applicable_from (DATE)
├── applicable_to (DATE)
├── description (TEXT, nullable)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Fee Master Dashboard
**Route:** `/transport/fee-master`

#### 2.1.1 Layout (List + Filters)
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > FEE MASTER                                           │
├──────────────────────────────────────────────────────────────────┤
│ SESSION: [2025-26 ▼]  FEE TYPE: [Monthly ▼]                    │
│ [+ Add Fee] [Import CSV] [Export]                               │
├──────────────────────────────────────────────────────────────────┤
│ Route/Stop          | Fee Type | Amount   | From Date | To Date  │
├──────────────────────────────────────────────────────────────────┤
│ Route A             | Monthly  | ₹ 1,500  | 2025-12-01| 2026-03-31
│ Route A - Stop 5    | Monthly  | ₹ 2,000  | 2025-12-01| 2026-03-31
│ Route B             | Quarterly| ₹ 4,200  | 2025-12-01| 2026-03-31
│ Route B - Stop 12   | Quarterly| ₹ 5,000  | 2025-12-01| 2026-03-31
│ School Annual Pass  | Annual   | ₹12,000  | 2025-12-01| 2026-03-31
│
│ [Edit] [Duplicate] [Deactivate]
│
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Create/Edit Fee Master
#### 2.2.1 Form Dialog
```
┌────────────────────────────────────────────────┐
│ ADD FEE RULE                                [✕]│
├────────────────────────────────────────────────┤
│ SESSION *                [2025-26 ▼]           │
│ 
│ FEE SCOPE
│ Applies To *  [Route ▼] [Specific Stop ▼]     │
│               [Route A ▼]  [Stop 5 ▼]         │
│
│ FEE DETAILS
│ Fee Type *            [Monthly ▼]              │
│                       Monthly / Quarterly / Annual
│ Amount *              [1500    ]  INR           │
│ Description           [__________________]     │
│
│ VALIDITY
│ From Date *           [Calendar]               │
│ To Date *             [Calendar]               │
│
│ PREVIEW
│ Route A, Stop 5 (Jun–Aug 2025)
│ Monthly: ₹2,000/month (6 months = ₹12,000)
│
├────────────────────────────────────────────────┤
│         [Cancel]         [Save]                │
└────────────────────────────────────────────────┘
```

### 2.3 Fee Structure Overview
#### 2.3.1 Summary Card
```
SESSION: 2025-26 (Jan–Mar 2025)
────────────────────────────────────────────
ROUTE          | MONTHLY | QUARTERLY | ANNUAL
────────────────────────────────────────────
Route A        | ₹1,500  | ₹4,200    | -
Route B        | ₹1,800  | ₹5,000    | ₹15,000
Suburban Route | ₹2,200  | ₹6,000    | ₹18,000
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Fee Rule
```json
POST /api/v1/transport/fee-master
{
  "route_id": 1,
  "stop_id": 5,
  "session_id": 1,
  "fee_type": "MONTHLY",
  "amount": 2000.00,
  "applicable_from": "2025-12-01",
  "applicable_to": "2026-03-31",
  "description": "Monthly fee for Route A - Stop 5"
}

Response:
{
  "id": 300,
  "route_id": 1,
  "route_name": "Route A",
  "stop_id": 5,
  "stop_name": "Stop 5",
  "session_id": 1,
  "fee_type": "MONTHLY",
  "amount": 2000.00,
  "applicable_from": "2025-12-01",
  "applicable_to": "2026-03-31",
  "created_at": "2025-12-01T10:00:00Z"
}
```

### 3.2 Get Fee Rules
```json
GET /api/v1/transport/fee-master?session_id={id}&route_id={id}

Response:
{
  "data": [
    {
      "id": 300,
      "route_id": 1,
      "route_name": "Route A",
      "stop_id": 5,
      "stop_name": "Stop 5",
      "session_id": 1,
      "fee_type": "MONTHLY",
      "amount": 2000.00,
      "applicable_from": "2025-12-01",
      "applicable_to": "2026-03-31"
    }
  ],
  "pagination": {"page": 1, "per_page": 50, "total": 120}
}
```

### 3.3 Update Fee Rule
```json
PATCH /api/v1/transport/fee-master/{id}
{
  "amount": 2200.00,
  "description": "Updated fee for Route A - Stop 5"
}
```

### 3.4 Bulk Fee Import
```json
POST /api/v1/transport/fee-master/bulk-upload
{
  "file": <CSV binary>,
  "session_id": 1
}

CSV Format:
route_name,stop_name,fee_type,amount,from_date,to_date
Route A,,MONTHLY,1500,2025-12-01,2026-03-31
Route A,Stop 5,MONTHLY,2000,2025-12-01,2026-03-31
```

---

## 4. USER WORKFLOWS

### 4.1 Define Fee for New Session
```
1. Admin opens Fee Master
2. Selects new session (2026-27)
3. Clicks [+ Add Fee]
4. Selects route (Route A)
5. Enters fee_type (MONTHLY) and amount (₹1,500)
6. Sets applicable_from and applicable_to dates
7. Saves fee rule
8. Notification sent to parents about new fees
```

### 4.2 Update Fees Mid-Session
```
1. School admin needs to change fee for Route A (from ₹1,500 to ₹1,600)
2. Opens Fee Master
3. Clicks [Edit] on existing rule
4. Updates amount
5. Saves
6. Fee collection uses updated amount for future invoices
```

### 4.3 Bulk Import Fees
```
1. Admin downloads CSV template
2. Fills in routes, stop-specific fees, amounts
3. Uploads via [Import CSV]
4. System validates all rows
5. Preview shown
6. Confirms import
7. All rules created/updated
```

---

## 5. VISUAL DESIGN GUIDELINES

- Color-code fee types: Monthly (blue), Quarterly (green), Annual (purple)
- Display effective date ranges clearly
- Summary table with route hierarchy (Route → Stop-specific fees)

---

## 6. ACCESSIBILITY & USABILITY

- Date pickers with keyboard support
- Clear decimal input for currency amounts
- Screen-reader friendly currency formatting

---

## 7. TESTING CHECKLIST

- [ ] Create fee rule for route-level (no stop)
- [ ] Create fee rule for stop-level (route + stop)
- [ ] Update amount on existing rule
- [ ] Bulk import CSV with 50+ rows
- [ ] Date range validation (applicable_from < applicable_to)
- [ ] Soft delete (deactivate) preserves historical data

---

## 8. FUTURE ENHANCEMENTS

1. Fee calculation wizard (auto-suggest based on distance/stops)
2. Discount rules (siblings, payment early, scholarship adjustments)
3. Fee structure templates (copy from previous session)
4. Price history and comparison view
5. Integration with fee collection for automatic invoice generation

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
