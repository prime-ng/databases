# STP — Hostel Information Requirement Document

---

## 1. Module / Sub-Module
- **Module:** StudentPortal (STP)
- **Sub-Module:** Services — Hostel Information
- **Table Prefix:** stp_ (read-only from hst_* tables)

---

## 2. FRD Reference
| ID | Description | Priority |
|----|------------|----------|
| REQ-STP-026 | Hostel Information | P2 (Blocked on Hostel module) |
| BR-STP-001 | Data must belong to authenticated student | P0 |

---

## 3. Feature Description
Read-only dashboard for hostel boarders showing allocated room details, mess menus, mess bills, fee demands, attendance entries, leave passes, laundry tickets, and room change requests. Blocked on Hostel (HST) module readiness.

---

## 4. User Stories / Use Cases
- **As a** hostel-resident student, **I want to** see my allocated room, floor, building, and bed number **so that** I know my accommodation details.
- **As a** hostel-resident student, **I want to** view the weekly mess menu, attendance records, leave passes, laundry tickets, and fee demands **so that** I can manage my hostel life.

---

## 5. Business Rules (BR)
| BR ID | Rule | Type | Enforcement |
|-------|------|------|-------------|
| BR-STP-001 | All hostel data must belong to the authenticated student | Permission | All queries scoped to `auth()->user()->student->id` |
| — | Allotment must be active and confirmed (`is_active = true`, `is_alloted = true`) | Validation | Controller filter on Allotment query |
| — | Mess menus shown only for the allotted hostel | Display | Scoped by `allotment->bed->room->hostel_id` |
| — | Mess menus must be published (`is_published = true`) | Validation | Controller filter |
| — | Allotment may be null (non-boarder) | Display | Variables set to null/empty; view handles empty state |

---

## 6. Validations & Edge Cases
| Scenario | Expected Behaviour |
|----------|-------------------|
| Student has no hostel allotment | `$allotment` is null; all dependent sections (mess, fee, etc.) return empty collections |
| Student not found | All variables return empty; view renders empty state |
| Allotment exists but no mess menus published | `$messMenus` is empty collection; mess section shows "No menus published" |
| No attendance entries | `$attendanceEntries` is empty collection |
| No leave passes, bills, tickets, or requests | Each collection returns empty; section hidden or shows "None" |
| Hostel module tables do not exist (module not installed) | Controller will throw SQL exception — no graceful degradation |

---

## 7. Route Details
| Method | Route | Name | Controller Method |
|--------|-------|------|-------------------|
| GET | /hostel | student-portal.hostel | StudentPortalController@hostel |

---

## 8. Data / Entity Reference

### A. Allotment
- **Model:** `Modules\Hostel\Models\Allotment`
- **Table:** `hst_allotments`
- **Eager loads:** `bed.room.hostel`, `bed.room.floor`, `bed.bedType`
- **Scope:** `where('student_id', $student->id)->where('is_active', true)->where('is_alloted', true)`

### B. Attendance Entries
- **Model:** `Modules\Hostel\Models\HstAttendanceEntry`
- **Table:** `hst_attendance_entries`
- **Eager loads:** `session`, `statusMaster`

### C. Leave Passes
- **Model:** `Modules\Hostel\Models\LeavePass`
- **Table:** `hst_leave_passes`
- **Eager loads:** `statusMaster`

### D. Mess Weekly Menu
- **Model:** `Modules\Hostel\Models\MessWeeklyMenu`
- **Table:** `hst_mess_weekly_menus`
- **Scope:** Scoped by hostel_id of allotment; filtered to `is_active = true` AND `is_published = true`

### E. Mess Bills
- **Model:** `Modules\Hostel\Models\MessBill`
- **Table:** `hst_mess_bills`
- **Eager loads:** `statusMaster`

### F. Fee Demands
- **Model:** `Modules\Hostel\Models\FeeDemand`
- **Table:** `hst_fee_demands`
- **Eager loads:** `statusMaster`

### G. Laundry Tickets
- **Model:** `Modules\Hostel\Models\LaundryTicket`
- **Table:** `hst_laundry_tickets`
- **Eager loads:** `statusMaster`

### H. Room Change Requests
- **Model:** `Modules\Hostel\Models\RoomChangeRequest`
- **Table:** `hst_room_change_requests`
- **Eager loads:** `statusMaster`, `requestedRoom.hostel`, `fromAllotment.bed.room`

---

## 9. Dependencies (Cross-Module)
| Module | Dependency | Type |
|--------|-----------|------|
| Hostel (HST) | Allotment, HstAttendanceEntry, LeavePass, MessWeeklyMenu, MessBill, FeeDemand, LaundryTicket, RoomChangeRequest | Read-only |

---

## 10. Integration / API
- Purely read-only view; no write operations
- No AJAX endpoints

---

## 11. Security & Permissions
| Check | Implementation |
|-------|---------------|
| Authentication | Standard `auth` + `verified` middleware |
| Data ownership | All queries scoped to `auth()->user()->student` |
| Cross-student access | Impossible — no user-supplied IDs accepted |

---

## 12. Assumptions & Constraints
- **BLOCKED** on Hostel (HST) module being installed and seeded
- Student must be a hostel boarder (have an active allotment) for most sections to render data
- If HST module tables are absent, controller will throw an SQL exception

---

## 13. Known Issues / Gaps
| ID | Issue | Severity | Status |
|----|-------|----------|--------|
| GAP-STP-26-01 | REQ-STP-026 is P2 — no test cases exist yet | Low | Open |
| GAP-STP-26-02 | Blocked on Hostel module readiness; V2 requirement marked as placeholder | Medium | Open |
| GAP-STP-26-03 | No graceful degradation if HST module is not installed (SQL exception) | Medium | Open |

---

## 14. Future Enhancements
| ID | Suggestion | Priority |
|----|-----------|----------|
| ENH-STP-HST-01 | Integrate warden contact details from Hostel module | P2 |
| ENH-STP-HST-02 | Add hostel rules and emergency contact display | P2 |
| ENH-STP-HST-03 | Allow room change requests submission from portal | P3 |

---

## 15. V1/V2 Status
- **V1:** —
- **V2:** —
- **Status:** ❌ Blocked (P2)
- **CR:** ◌

---

## 16. Revision History
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 23-07-2026 | OpenCode | Initial requirement document |
