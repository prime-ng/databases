# Screen Design Specification: Audit Log
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Central audit trail of all entity changes in the transport module (create, update, delete, status changes) for compliance and debugging. Backed by `tpt_audit_log`.

### 1.2 User Roles & Permissions
| Role | Create | View | Update | Delete | print | Export | Import |
|------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| PG Support   |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| School Admin |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✓    |  ✗    |
| Principal    |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✗    |  ✗    |
| Teacher      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Student      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Parents      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |

### 1.3 Data Context

Database Table: `tpt_audit_log`
├── id (BIGINT PRIMARY KEY)
├── entity_type (VARCHAR)
├── entity_id (BIGINT)
├── action (ENUM: CREATE, UPDATE, DELETE, SOFT_DELETE, STATUS_CHANGE)
├── changed_by (FK -> `hrm_employees.id`)
├── changed_timestamp (DATETIME)
├── old_values (JSON)
├── new_values (JSON)
├── change_reason (VARCHAR, nullable)
├── ip_address (VARCHAR, nullable)
├── user_agent (VARCHAR, nullable)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Audit Trail Dashboard
**Route:** `/transport/audit-log`

#### 2.1.1 Layout (Change History)
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > AUDIT LOG                                            │
├──────────────────────────────────────────────────────────────────┤
│ ENTITY: [Trip ▼]  ACTION: [All ▼]  DATE: [Last 7 days ▼]       │
│ CHANGED BY: [All Users ▼]  SEARCH: [Entity ID]                 │
│ [View Entity] [Export] [Compare Versions]                      │
├──────────────────────────────────────────────────────────────────┤
│ Time       | Entity    | ID    | Action | Changed By | Details  │
├──────────────────────────────────────────────────────────────────┤
│ 07:30 AM   | Trip      | 123   | CREATE | Ravi Kumar │ [View]   │
│ 07:15 AM   | Trip      | 123   | UPDATE | Admin      │ [View]   │
│ 07:10 AM   | Incident  | 542   | CREATE | Driver     │ [View]   │
│ 07:05 AM   | Route     | A     | UPDATE | Admin      │ [View]   │
│ 06:50 AM   | Vehicle   | 101   | UPDATE | Ravi Kumar │ [View]   │
│ 06:45 AM   | Trip      | 122   | DELETE | Admin      │ [View]   │
│
│ [Load More] [Advanced Filter]
│
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Audit Detail - Change Comparison
#### 2.2.1 Before/After View
```
┌────────────────────────────────────────────────────────┐
│ AUDIT RECORD DETAIL                                 [✕]│
├────────────────────────────────────────────────────────┤
│ AUDIT ID: AUD-2025-9821
│ Entity: Trip-123
│ Action: UPDATE
│ Time: 2025-12-01 07:15:00 AM
│ Changed By: Admin User
│ IP Address: 192.168.1.100
│
│ CHANGE DETAILS
│ Reason: "Route change due to traffic"
│
│ BEFORE
│ ┌─────────────────────────────────────┐
│ │ status: SCHEDULED                   │
│ │ vehicle_id: 1 (BUS-101)            │
│ │ start_time: 06:45:00                │
│ │ trip_type: MORNING                  │
│ └─────────────────────────────────────┘
│
│ AFTER
│ ┌─────────────────────────────────────┐
│ │ status: ONGOING                     │
│ │ vehicle_id: 2 (VAN-22)             │
│ │ start_time: 06:50:00                │
│ │ trip_type: MORNING                  │
│ └─────────────────────────────────────┘
│
│ CHANGES SUMMARY
│ • status: SCHEDULED → ONGOING
│ • vehicle_id: 1 → 2
│ • start_time: 06:45 → 06:50
│
│ [View Full JSON] [Revert (if possible)] [Print]
│
└────────────────────────────────────────────────────────┘
```

### 2.3 Entity Timeline
#### 2.3.1 Complete History
```
ENTITY: Trip-123 HISTORY
────────────────────────────────────────────────────────
2025-12-01 07:30 AM
├─ CREATE
├─ Created By: Ravi Kumar
├─ Initial Status: SCHEDULED
├─ Initial Vehicle: BUS-101
└─ [View Details]

2025-12-01 07:15 AM
├─ UPDATE
├─ Changed By: Admin
├─ Modified: vehicle_id (1→2), status (SCHEDULED→ONGOING)
└─ [View Comparison]

2025-12-01 07:05 AM
├─ STATUS_CHANGE
├─ Changed By: Driver
├─ New Status: ONGOING
└─ [View Details]

[View All Versions] [Export Timeline]
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Audit Log Entry (Auto)
```json
POST /api/v1/transport/audit-log
{
  "entity_type": "TRIP",
  "entity_id": 123,
  "action": "UPDATE",
  "changed_by": 5,
  "changed_timestamp": "2025-12-01T07:15:00Z",
  "old_values": {
    "status": "SCHEDULED",
    "vehicle_id": 1,
    "start_time": "06:45:00"
  },
  "new_values": {
    "status": "ONGOING",
    "vehicle_id": 2,
    "start_time": "06:50:00"
  },
  "change_reason": "Route change due to traffic",
  "ip_address": "192.168.1.100",
  "user_agent": "Mozilla/5.0..."
}

Response:
{
  "id": 9821,
  "entity_type": "TRIP",
  "entity_id": 123,
  "action": "UPDATE",
  "changed_timestamp": "2025-12-01T07:15:00Z",
  "created_at": "2025-12-01T07:15:00Z"
}
```

### 3.2 Get Audit Records
```json
GET /api/v1/transport/audit-log?entity_type=TRIP&entity_id={id}&from_date={date}

Response:
{
  "data": [
    {
      "id": 9821,
      "entity_type": "TRIP",
      "entity_id": 123,
      "action": "UPDATE",
      "changed_by": 5,
      "changed_by_name": "Admin",
      "changed_timestamp": "2025-12-01T07:15:00Z",
      "old_values": {
        "status": "SCHEDULED",
        "vehicle_id": 1
      },
      "new_values": {
        "status": "ONGOING",
        "vehicle_id": 2
      },
      "change_reason": "Route change due to traffic"
    }
  ],
  "pagination": {"page": 1, "per_page": 20, "total": 5}
}
```

### 3.3 Get Entity Timeline
```json
GET /api/v1/transport/audit-log/entity-timeline/{entity_type}/{entity_id}

Response:
{
  "entity_type": "TRIP",
  "entity_id": 123,
  "total_changes": 3,
  "timeline": [
    {
      "event_no": 1,
      "action": "CREATE",
      "timestamp": "2025-12-01T07:30:00Z",
      "changed_by": "Ravi Kumar"
    },
    {
      "event_no": 2,
      "action": "UPDATE",
      "timestamp": "2025-12-01T07:15:00Z",
      "changed_by": "Admin",
      "changes": ["vehicle_id", "status", "start_time"]
    }
  ]
}
```

---

## 4. USER WORKFLOWS

### 4.1 Auto-Record Changes (System)
```
1. Admin updates trip status (SCHEDULED → ONGOING)
2. System captures:
   - Entity: TRIP, ID: 123
   - Action: UPDATE
   - Old values: {status: SCHEDULED}
   - New values: {status: ONGOING}
   - Changed by: Admin ID
   - Timestamp: exact UTC time
   - IP Address: source IP
3. Audit log entry created automatically
```

### 4.2 Review Entity History
```
1. Admin needs to understand trip changes
2. Clicks on trip
3. Opens [Audit Trail] tab
4. Views complete history (CREATE, UPDATE, UPDATE)
5. Clicks on specific update to see before/after
6. Understands what changed and when
```

### 4.3 Investigate Change
```
1. Principal questions why vehicle changed
2. Opens Audit Log
3. Searches for Trip-123
4. Finds UPDATE action at 07:15 AM
5. Sees old_values (BUS-101) → new_values (VAN-22)
6. Notes change reason: "Route change due to traffic"
7. Identifies changed_by: Admin user
8. Exports audit trail as PDF for records
```

---

## 5. VISUAL DESIGN GUIDELINES

- Color-code actions: CREATE (green), UPDATE (blue), DELETE (red), STATUS_CHANGE (orange)
- Timeline vertical display with chronological order
- Before/After comparison in split view
- Timestamp clearly displayed in local timezone

---

## 6. ACCESSIBILITY & USABILITY

- Date/time pickers for filtering
- Dropdown for entity type and action
- JSON viewer for complex old/new values
- Keyboard shortcuts: Next [N], Previous [P], Expand [E]

---

## 7. TESTING CHECKLIST

- [ ] Audit entry created on entity CREATE
- [ ] Audit entry created on entity UPDATE
- [ ] old_values and new_values captured correctly
- [ ] changed_by populated with correct user ID
- [ ] Timestamp in UTC format
- [ ] IP address and user agent captured
- [ ] Entity timeline shows all changes in order
- [ ] Comparison view shows before/after values correctly
- [ ] Export to CSV includes all audit fields

---

## 8. FUTURE ENHANCEMENTS

1. Change notifications (alert on critical entity changes)
2. Rollback functionality (undo changes for non-deleted records)
3. Audit report generation (compliance, SOX, etc.)
4. Advanced filtering (by user, date range, action type)
5. Change approval workflow (for high-risk changes)
6. Data retention policies (auto-archive old audit logs)

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
