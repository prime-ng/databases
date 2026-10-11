# Screen Design Specification: Class-Section Timetable View
## Document Version: 1.0
**Last Updated:** December 14, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Class-Section Timetable View** screen, enabling users to view weekly timetable schedules for specific classes and sections with comprehensive filtering, navigation, and export capabilities.

### 1.2 User Roles & Permissions
| Role         | Create | View | Update | Delete | Print | Export | Import |
|--------------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| PG Support   |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| School Admin |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✗    |
| Principal    |   ✓    |   ✓  |   ✗    |   ✗    |   ✓   |   ✓    |   ✗    |
| Teacher      |   ✗    |   ✓  |   ✗    |   ✗    |   ✓   |   ✓    |   ✗    |
| Student      |   ✗    |   ✓  |   ✗    |   ✗    |   ✓   |   ✗    |   ✗    |
| Parents      |   ✗    |   ✓  |   ✗    |   ✗    |   ✓   |   ✗    |   ✗    |

### 1.3 Data Context

**Core Tables:**
- `tt_timetable_cell` - Individual period assignments
- `tim_timetable_cell_teacher` - Teacher assignments
- `tim_generation_run` - Timetable generation metadata
- `sch_class_groups_jnt` - Class and section groupings
- `tim_period_set_period` - Period definitions and timing

**Key Relationships:**
- Timetable Cells → Class Groups (many-to-one)
- Timetable Cells → Teachers (many-to-many via junction)
- Timetable Cells → Rooms (many-to-one)
- Generation Runs → Timetable Cells (one-to-many)

---

## 2. SCREEN LAYOUTS

### 2.1 Class Timetable List Screen
**Route:** `/timetable/class` or `/timetable/classes`

#### 2.1.1 Page Layout

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│ TIMETABLE MANAGEMENT > CLASS TIMETABLES                                            │
├────────────────────────────────────────────────────────────────────────────────────┤
│   [New Timetable] [Settings]    Current: Regular Term 1 2025                       │
├────────────────────────────────────────────────────────────────────────────────────┤
│ CLASS: [Dropdown ▼]    SECTION: [Dropdown ▼]    STATUS: [Dropdown ▼]      [Filter] │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Class     | Section  | Status     | Periods  | Teachers | Conflicts | Action   │
│────────────────────────────────────────────────────────────────────────────────────│
│ ☐ │ Class 9   | A        | ✓ Complete | 40/40    | 8/8      | 0         │ 👁️ ✏️ 📊 │
│ ☐ │ Class 9   | B        | ⚠ Partial  | 38/40    | 7/8      | 2         │ 👁️ ✏️ 📊 │
│ ☐ │ Class 10  | A        | ✓ Complete | 40/40    | 8/8      | 0         │ 👁️ ✏️ 📊 │
│   │ Class 10  | B        | ✗ Empty    | 0/40     | 0/8      | -         │ 👁️ ✏️ 📊 │
│────────────────────────────────────────────────────────────────────────────────────│
│ Showing 1-10 of 24 classes                                           [< 1 2 3 >]   │
└────────────────────────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Components & Interactions

**Filter Bar:**
- **Class Dropdown** – Multi-select with search
  - Options: All classes (6th, 7th, 8th, 9th, 10th, 11th, 12th)
  - Default: All classes
- **Section Dropdown** – Multi-select (A, B, C, D, etc.)
  - Filtered by selected classes
  - Default: All sections
- **Status Dropdown**
  - Options: Complete, Partial, Empty, Conflicts
  - Default: All

**Action Buttons:**
- **[New Timetable]** – Opens timetable generation wizard
- **[Settings]** – Opens timetable configuration

**Table Columns:**
- **Class** – Class name (e.g., "Class 9")
- **Section** – Section identifier (e.g., "A", "B")
- **Status** – Completion status with icons
- **Periods** – Completed periods (e.g., "40/40")
- **Teachers** – Assigned teachers (e.g., "8/8")
- **Conflicts** – Number of constraint violations
- **Actions** – View 👁️, Edit ✏️, Analytics 📊

---

### 2.2 Weekly Timetable Grid Screen
**Route:** `/timetable/class/{classId}/section/{sectionId}` or `/timetable/class/9A`

#### 2.2.1 Layout (Weekly Grid View)

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│ CLASS TIMETABLE > Class 9A Science                                                  │
├────────────────────────────────────────────────────────────────────────────────────┤
│ [← Prev Class] [9A Science] [9B Science] [9C Science] [Next Class →]   [Week ▼]    │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ┌──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┐                        │
│ │      │ MON  │ TUE  │ WED  │ THU  │ FRI  │ SAT  │ SUN  │                        │
│ │Period│ Dec9 │ Dec10│ Dec11│ Dec12│ Dec13│ Dec14│ Dec15│                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┤      │                        │
│ │1     │Maths │Science│English│Hindi │Science│Maths │      │                        │
│ │08:00 │Mr.S  │Ms.J   │Mr.D   │Ms.K   │Ms.J   │Mr.S  │      │                        │
│ │08:45 │Rm101 │Lab1   │Rm102  │Rm103  │Lab1   │Rm101 │      │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │2     │English│Maths │Science│English│Hindi │English│      │                        │
│ │08:50 │Mr.D   │Mr.S   │Ms.J   │Mr.D   │Ms.K   │Mr.D  │      │                        │
│ │09:35 │Rm102  │Rm101  │Lab1   │Rm102  │Rm103  │Rm102  │      │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │BREAK │      │      │      │      │      │      │     │                        │
│ │09:35 │      │      │      │      │      │      │     │                        │
│ │09:45 │      │      │      │      │      │      │     │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │3     │Hindi │English│Maths │Science│Maths │Science│     │                        │
│ │09:45 │Ms.K   │Mr.D   │Mr.S   │Ms.J   │Mr.S   │Ms.J   │     │                        │
│ │10:30 │Rm103  │Rm102  │Rm101  │Lab1   │Rm101  │Lab1   │     │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │4     │Science│Hindi │English│Maths │English│Hindi │     │                        │
│ │10:35 │Ms.J   │Ms.K   │Mr.D   │Mr.S   │Mr.D   │Ms.K   │     │                        │
│ │11:20 │Lab1   │Rm103  │Rm102  │Rm101  │Rm102  │Rm103  │     │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │LUNCH │      │      │      │      │      │      │     │                        │
│ │11:20 │      │      │      │      │      │      │     │                        │
│ │12:00 │      │      │      │      │      │      │     │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │5     │Maths │Science│Hindi │English│Science│Maths │     │                        │
│ │12:00 │Mr.S   │Ms.J   │Ms.K   │Mr.D   │Ms.J   │Mr.S   │     │                        │
│ │12:45 │Rm101  │Lab1   │Rm103  │Rm102  │Lab1   │Rm101  │     │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │6     │English│Maths │Science│Hindi │Maths │English│     │                        │
│ │12:50 │Mr.D   │Mr.S   │Ms.J   │Ms.K   │Mr.S   │Mr.D   │     │                        │
│ │13:35 │Rm101  │Rm101  │Lab1   │Rm103  │Rm101  │Rm102  │     │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │BREAK │      │      │      │      │      │      │     │                        │
│ │13:35 │      │      │      │      │      │      │     │                        │
│ │13:45 │      │      │      │      │      │      │     │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │7     │Hindi │English│Maths │Science│English│Hindi │     │                        │
│ │13:45 │Ms.K   │Mr.D   │Mr.S   │Ms.J   │Mr.D   │Ms.K   │     │                        │
│ │14:30 │Rm103  │Rm102  │Rm101  │Lab1   │Rm102  │Rm103  │     │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │8     │Science│Hindi │English│Maths │Hindi │Science│     │                        │
│ │14:35 │Ms.J   │Ms.K   │Mr.D   │Mr.S   │Ms.K   │Ms.J   │     │                        │
│ │15:20 │Lab1   │Rm103  │Rm102  │Rm101  │Rm103  │Lab1   │     │                        │
│ └──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┘                        │
├────────────────────────────────────────────────────────────────────────────────────┤
│ [Print] [Export] [Edit Mode] [View Conflicts] [Teacher View] [Room View]          │
└────────────────────────────────────────────────────────────────────────────────────┘
```

#### 2.2.2 Components & Interactions

**Navigation:**
- **Class/Section Selector** – Quick navigation between classes
- **Week Selector** – Dropdown for different weeks
- **Period Information** – Hover shows detailed timing

**Grid Features:**
- **Subject Display** – Primary subject name
- **Teacher Display** – Teacher abbreviation (hover for full name)
- **Room Display** – Room code (hover for full details)
- **Color Coding** – Different colors per subject
- **Conflict Indicators** – Red borders for violations

**Action Buttons:**
- **[Print]** – Print current timetable
- **[Export]** – Export options (PDF, Excel, CSV)
- **[Edit Mode]** – Switch to manual editing
- **[View Conflicts]** – Highlight constraint violations
- **[Teacher View]** – Switch to teacher-centric view
- **[Room View]** – Switch to room utilization view

---

### 2.3 Timetable Detail Modal
**Route:** Modal overlay on timetable grid

#### 2.3.1 Layout
```
┌──────────────────────────────────────────────────┐
│ PERIOD DETAILS                                  │
├──────────────────────────────────────────────────┤
│ Class:          Class 9A                         │
│ Section:        Science                          │
│ Date:           Monday, December 9, 2025        │
│ Period:         3 (09:45 - 10:30)               │
│                                                  │
│ Subject:        Mathematics                      │
│ Teacher:        Mr. Smith (Primary)              │
│ Room:           Room 101 (Classroom)             │
│                                                  │
│ Status:         ✓ Scheduled                      │
│ Source:         Auto-generated                   │
│ Last Modified:  Dec 8, 2025 by System           │
│                                                  │
│ Constraints:                                     │
│ ✓ Teacher available                              │
│ ✓ Room available                                 │
│ ✓ No double-booking                             │
│                                                  │
│ [Edit] [Substitute] [Lock] [Close]               │
└──────────────────────────────────────────────────┘
```

#### 2.3.2 Field Specifications

| Field | Type | Validation | Display Format |
|----------------|--------------|--------------------------------|---------------|
| Class | Read-only | FK to sch_classes | "Class 9A" |
| Section | Read-only | FK to sch_sections | "Science" |
| Date | Read-only | Date | "Monday, December 9, 2025" |
| Period | Read-only | FK to tim_period_set_period | "3 (09:45 - 10:30)" |
| Subject | Read-only | FK to sch_subjects | "Mathematics" |
| Teacher | Read-only | FK to sch_users | "Mr. Smith (Primary)" |
| Room | Read-only | FK to sch_rooms | "Room 101 (Classroom)" |
| Status | Status Badge | ENUM | ✓ Scheduled / ⚠ Conflict / 🔒 Locked |
| Source | Read-only | ENUM | Auto-generated / Manual / Substitute |
| Constraints | Status List | Dynamic | List of passed/failed constraints |

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Get Class Timetable Request
```
GET /api/v1/timetable/classes/{classId}/sections/{sectionId}?week_start=2025-12-09&include_conflicts=true
```

### 3.2 Get Class Timetable Response
```json
{
  "success": true,
  "data": {
    "class": {
      "id": 9,
      "name": "Class 9",
      "section": "A"
    },
    "week": {
      "start_date": "2025-12-09",
      "end_date": "2025-12-15"
    },
    "periods": [
      {
        "period_ord": 1,
        "start_time": "08:00",
        "end_time": "08:45",
        "type": "TEACHING",
        "days": {
          "2025-12-09": {
            "subject": "Mathematics",
            "teacher": "Mr. Smith",
            "room": "Room 101",
            "status": "SCHEDULED",
            "source": "AUTO",
            "locked": false,
            "conflicts": []
          },
          "2025-12-10": {
            "subject": "Science",
            "teacher": "Ms. Johnson",
            "room": "Lab 1",
            "status": "SCHEDULED",
            "source": "AUTO",
            "locked": false,
            "conflicts": []
          }
        }
      }
    ],
    "summary": {
      "total_periods": 40,
      "scheduled_periods": 40,
      "conflicts": 0,
      "locked_periods": 5
    }
  }
}
```

### 3.3 Get Period Detail Request
```
GET /api/v1/timetable/cells/{cellId}?include_constraints=true
```

### 3.4 Get Period Detail Response
```json
{
  "success": true,
  "data": {
    "id": 1001,
    "class_group_id": 45,
    "date": "2025-12-09",
    "period_ord": 3,
    "subject": {
      "id": 5,
      "name": "Mathematics",
      "code": "MATH"
    },
    "teachers": [
      {
        "id": 12,
        "name": "Mr. Smith",
        "assignment_role": "PRIMARY_INSTRUCTOR"
      }
    ],
    "room": {
      "id": 8,
      "name": "Room 101",
      "type": "CLASSROOM"
    },
    "status": "SCHEDULED",
    "source": "AUTO",
    "locked": false,
    "constraints_status": [
      {
        "constraint_id": 23,
        "type": "MAX_PERIODS_PER_DAY",
        "status": "PASSED",
        "message": "Teacher has 5 periods today (max 6)"
      },
      {
        "constraint_id": 45,
        "type": "ROOM_AVAILABLE",
        "status": "PASSED",
        "message": "Room is available for this period"
      }
    ],
    "created_at": "2025-12-08T10:30:00Z",
    "updated_at": "2025-12-08T10:30:00Z"
  }
}
```

---

## 4. USER WORKFLOWS

### 4.1 View Class Timetable Workflow
```
1. User navigates to Class Timetables section
2. System loads list of all classes and sections
3. User selects specific class/section (e.g., Class 9A)
4. System fetches timetable data for current week
5. Grid displays with subjects, teachers, rooms
6. User can navigate between weeks using week selector
7. User can switch between different classes/sections
8. User can click on any cell to view period details
9. User can export/print the current view
10. User can switch to edit mode if permissions allow
```

### 4.2 Navigate Between Classes Workflow
```
1. User is viewing Class 9A timetable
2. User clicks [Next Class →] button
3. System loads Class 9B timetable data
4. Grid updates with new class data
5. URL updates to reflect new class/section
6. Breadcrumb navigation updates
7. User can continue navigating or perform other actions
```

### 4.3 View Period Details Workflow
```
1. User clicks on a timetable cell (e.g., Monday Period 3)
2. Modal opens with period details
3. System loads full period information including constraints
4. User can see subject, teacher, room, status
5. User can view constraint validation results
6. User can access edit/substitute/lock actions if permitted
7. User closes modal or performs actions
```

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Colors & Typography
| Element | Color | Font | Size | Weight |
|---------|-------|------|------|--------|
| Page Title | #1F2937 (Dark Gray) | Inter/Roboto | 28px | Bold (700) |
| Section Title | #374151 | Inter/Roboto | 18px | Bold (600) |
| Subject Text | Dynamic (per subject) | Inter/Roboto | 12px | Medium (500) |
| Teacher Text | #6B7280 | Inter/Roboto | 10px | Regular (400) |
| Room Text | #9CA3AF | Inter/Roboto | 10px | Regular (400) |
| Grid Borders | #E5E7EB | - | - | - |
| Conflict Highlight | #EF4444 (Red) | - | - | - |
| Locked Indicator | #F59E0B (Amber) | - | - | - |

### 5.2 Timetable Grid Colors
| Subject Type | Background Color | Text Color |
|-------------|------------------|------------|
| Mathematics | #DBEAFE (Light Blue) | #1E40AF (Dark Blue) |
| Science | #DCFCE7 (Light Green) | #166534 (Dark Green) |
| English | #FEF3C7 (Light Yellow) | #92400E (Dark Yellow) |
| Hindi | #FCE7F3 (Light Pink) | #9D174D (Dark Pink) |
| Break | #F9FAFB (Light Gray) | #6B7280 (Gray) |
| Lunch | #F3F4F6 (Medium Gray) | #374151 (Dark Gray) |

### 5.3 Icons
- **View Details:** 👁️ Eye Icon
- **Edit:** ✏️ Pencil Icon
- **Analytics:** 📊 Chart Icon
- **Conflict:** ⚠️ Warning Triangle
- **Locked:** 🔒 Padlock
- **Navigation:** ← → Arrow Icons

---

## 6. ACCESSIBILITY & USABILITY

### 6.1 Keyboard Navigation
- **Tab/Shift+Tab:** Navigate between grid cells
- **Enter/Space:** Open period detail modal
- **Arrow Keys:** Navigate within grid
- **Page Up/Down:** Navigate between weeks
- **Home/End:** Jump to first/last period

### 6.2 Screen Reader Support
```html
<!-- Timetable Grid -->
<table role="grid" aria-label="Class 9A Timetable for week of December 9, 2025">
  <thead>
    <tr>
      <th scope="col">Period</th>
      <th scope="col">Monday December 9</th>
      <th scope="col">Tuesday December 10</th>
      <!-- ... -->
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">Period 1 (08:00-08:45)</th>
      <td aria-label="Mathematics with Mr. Smith in Room 101, status scheduled">
        Maths<br><small>Mr.S<br>Rm101</small>
      </td>
      <!-- ... -->
    </tr>
  </tbody>
</table>
```

### 6.3 Responsive Design
| Breakpoint | Layout |
|------------|--------|
| Desktop (>1024px) | Full grid with all columns |
| Tablet (640px-1024px) | Condensed grid, hide room details |
| Mobile (<640px) | Card-based layout, one day per card |

---

## 7. EDGE CASES & ERROR SCENARIOS

| Scenario | Behavior |
|----------|----------|
| No Timetable Generated | Show empty grid with "No timetable generated" message |
| Partial Timetable | Show completed periods, empty cells for missing ones |
| Network Error | Show error toast, retry button for data reload |
| Permission Denied | Hide edit actions, show read-only view |
| Invalid Date Range | Show warning, default to current week |
| Concurrent Edits | Show notification of external changes |

---

## 8. PERFORMANCE CONSIDERATIONS

### 8.1 Data Optimization
- **Lazy Loading:** Load one week at a time
- **Caching:** Cache timetable data for 15 minutes
- **Pagination:** Limit to 50 cells per API call
- **Compression:** Gzip timetable responses

### 8.2 Rendering Optimization
- **Virtual Scrolling:** For large grids
- **Cell Memoization:** Avoid re-rendering unchanged cells
- **Image Lazy Loading:** For teacher photos (if applicable)

---

## 9. TESTING CHECKLIST

### 9.1 Functional Testing
- [ ] Load timetable for different classes/sections
- [ ] Navigate between weeks
- [ ] View period details modal
- [ ] Export/print functionality
- [ ] Responsive layout on different screen sizes
- [ ] Keyboard navigation
- [ ] Screen reader compatibility

### 9.2 UI/UX Testing
- [ ] Color coding is consistent
- [ ] Conflict indicators are visible
- [ ] Loading states are smooth
- [ ] Error handling is user-friendly
- [ ] Navigation is intuitive

### 9.3 Integration Testing
- [ ] API responses match expected format
- [ ] Real-time updates work
- [ ] Permission checks are enforced
- [ ] Data consistency across views

---

## 10. FUTURE ENHANCEMENTS

1. **Interactive Timetable:** Click-to-edit functionality
2. **Mobile App:** Native timetable viewer
3. **Calendar Integration:** Sync with Google/Outlook calendars
4. **Notifications:** Timetable change alerts
5. **Analytics:** Usage patterns and optimization suggestions
6. **Templates:** Save/load timetable templates
7. **Bulk Operations:** Multi-class editing
8. **Time Zone Support:** Handle different time zones
9. **Offline Mode:** Cache timetable for offline viewing
10. **Voice Commands:** Voice-activated navigation

---

**Document Created By:** ERP Architect GPT  
**Last Reviewed:** December 14, 2025  
**Next Review Date:** March 14, 2026  
**Version Control:** Initial creation