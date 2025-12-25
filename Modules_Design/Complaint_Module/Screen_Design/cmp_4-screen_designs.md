# Complaint Management Module - Screen Designs (Deliverable D)

**Route:** `/operations/complaints`
**Version:** 2.0

---

## 2.1 Complaint List Screen (The Cockpit)
**Route:** `/operations/complaints/list`

### 2.1.1 Layout
```ascii
┌────────────────────────────────────────────────────────────────────────────────────┐
│ COMPLAINT MANAGEMENT > LIST                                                        │
├────────────────────────────────────────────────────────────────────────────────────┤
│ [Search Ticket/Name...]   [+ Lodge New Complaint]   [Export]                       │
├────────────────────────────────────────────────────────────────────────────────────┤
│ FILTER: [Status: Open ▼]  [Dept: Transport ▼]  [Priority: High ▼]  [Time: All ▼]   │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Ticket #      | Subject             │ Category    │ Priority │ SLA Remaining   │
│────────────────────────────────────────────────────────────────────────────────────│
│ ☐ │ CMP-1001      | Rash Driving bus 4  | Transport   | [HIGH]   | ⚠️ 2 Hours      │
│ ☐ │ CMP-1002      | Canteen Food Cold   | Food        | [MED]    | 24 Hours        │
│ ☐ │ CMP-1003      | Staff Rude Behavior | HR          | [CRIT]   | ⛔ BREACHED (-4h)|
│   │ ...           | ...                 | ...         | ...      |                 │
│────────────────────────────────────────────────────────────────────────────────────│
│ Showing 1-10 of 45 Tickets                                           [< 1 2 3 >]   │
└────────────────────────────────────────────────────────────────────────────────────┘
```

### 2.1.2 Interactions
- **SLA Badge**:
  - Green: > 24 hours left.
  - Orange: < 4 hours left.
  - Red: Breached (Negative time).
- **Row Click**: Opens **Ticket Detail View**.

---

## 2.2 Lodge New Complaint (Wizard)
**Route:** `/operations/complaints/create`

### 2.2.1 Layout
```ascii
┌──────────────────────────────────────────────────┐
│ LODGE NEW COMPLAINT                          [✕] │
├──────────────────────────────────────────────────┤
│ STEP 1: CATEGORY SELECTION                       │
│ Department *        [Transport ▼]                │
│ Issue Type *        [Rash Driving ▼]             │
│ (Severity: High, SLA: 24h - Auto-detected)       │
│                                                  │
│ STEP 2: DETAILS                                  │
│ Title *             [__________________________] │
│ Description *       [__________________________] │
│                     [__________________________] │
│                                                  │
│ Associated Asset?   [Bus No. KA-51-AA-9999 ▼]    │
│ (Optional)                                       │
│                                                  │
│ Attach Proof        [Browse... (Image/Video) ]   │
│                                                  │
│ STEP 3: COMPLAINANT (If Admin Raising)           │
│ Raise On Behalf Of: [Parent: Mr. Sharma ▼]       │
│                                                  │
│ [Cancel]                         [Submit Ticket] │
└──────────────────────────────────────────────────┘
```

---

## 2.3 Ticket Detail View (Resolution Center)
**Route:** `/operations/complaints/{id}/view`

### 2.3.1 Layout
```ascii
┌────────────────────────────────────────────────────────────────────────────────────┐
│ < Back  |  CMP-1001: Rash Driving on Route 5                     [Esclate] [Close] │
│ Status: [OPEN] | Assigned: [Transport Mgr] | Priority: [HIGH]                      │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ┌──────────────────────────────────────┐  ┌──────────────────────────────────────┐ │
│ │ TICKET DETAILS                       │  │ METADATA & SLA                       │ │
│ │ Description: Parent reported bus was │  │ Complainant: Mr. Sharma (F/O Student)│ │
│ │ speeding >80kmph near Main Road.     │  │ Phone: 9876543210                    │ │
│ │                                      │  │                                      │ │
│ │ Evidence: [Video.mp4 (View)]         │  │ ------------------------------------ │ │
│ │ Location: Main Road                  │  │ Category: Transport > Safety         │ │
│ │ Incident Time: 10 Dec, 08:30 AM      │  │ Target: Vehicle KA-51-AA-9999        │ │
│ │                                      │  │                                      │ │
│ └──────────────────────────────────────┘  │ Risk Score (AI): 85% (Critical) ⚠️   │ │
│                                           │ SLA Target: 12 Dec, 10:00 AM         │ │
│ ┌──────────────────────────────────────┐  │                                      │ │
│ │ TIMELINE & ACTIONS                   │  └──────────────────────────────────────┘ │
│ │ [Write internal note or reply...]    │                                           │
│ │ [Send]                               │                                           │
│ │                                      │                                           │
│ │ • Today 10:00 AM - System            │                                           │
│ │   Assigned to Transport Manager      │                                           │
│ │                                      │                                           │
│ │ • Today 09:30 AM - Mr. Sharma        │                                           │
│ │   Ticket Created via App             │                                           │
│ └──────────────────────────────────────┘                                           │
└────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2.4 SLA Master Configuration
**Route:** `/settings/complaints/sla`

### 2.4.1 Layout
```ascii
┌────────────────────────────────────────────────────────────────────────────────────┐
│ CONFIGURATION > SLA & ESCALATION MATRIX                                            │
├────────────────────────────────────────────────────────────────────────────────────┤
│ Category: [Transport ▼]                                                            │
│                                                                                    │
│ LEVEL 1: FIRST RESPONSE                                                            │
│ Assign To:         [Transport Manager ▼]                                           │
│ Resolution Time:   [ 24 ] Hours                                                    │
│                                                                                    │
│ LEVEL 2: ESCALATION (If L1 Breaches)                                               │
│ Escalate To:       [Admin Head ▼]                                                  │
│ Trigger After:     [ +4 ] Hours of Breach                                          │
│                                                                                    │
│ LEVEL 3: CRITICAL (If L2 Breaches)                                                 │
│ Escalate To:       [Principal ▼]                                                   │
│ Trigger After:     [ +2 ] Hours of Breach                                          │
│                                                                                    │
│ [Save Matrix]                                                                      │
└────────────────────────────────────────────────────────────────────────────────────┘
```
