# Screen Design Specification: Teacher Timetable View
## Document Version: 1.0
**Last Updated:** December 14, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Teacher Timetable View** screen, enabling teachers and administrators to view individual teacher schedules with workload analysis, availability checking, and substitution planning capabilities.

### 1.2 User Roles & Permissions
| Role         | Create | View | Update | Delete | Print | Export | Import |
|--------------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| PG Support   |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| School Admin |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✗    |
| Principal    |   ✓    |   ✓  |   ✗    |   ✗    |   ✓   |   ✓    |   ✗    |
| Teacher      |   ✗    |   ✓  |   ✗    |   ✗    |   ✓   |   ✓    |   ✗    |
| Student      |   ✗    |   ✗  |   ✗    |   ✗    |   ✗    |   ✗    |   ✗    |
| Parents      |   ✗    |   ✗  |   ✗    |   ✗    |   ✗    |   ✗    |   ✗    |

### 1.3 Data Context

**Core Tables:**
- `tim_timetable_cell_teacher` - Teacher assignments to periods
- `tt_timetable_cell` - Period details
- `sch_users` - Teacher information
- `tim_teacher_assignment_role` - Assignment roles (Primary, Assistant, Substitute)

**Key Relationships:**
- Teachers → Timetable Cells (many-to-many)
- Assignment Roles → Teacher-Cell Junction (many-to-one)
- Teachers → Subjects (many-to-many via qualifications)

---

## 2. SCREEN LAYOUTS

### 2.1 Teacher List Screen
**Route:** `/timetable/teachers` or `/timetable/teacher-list`

#### 2.1.1 Page Layout

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│ TIMETABLE MANAGEMENT > TEACHER TIMETABLES                                           │
├────────────────────────────────────────────────────────────────────────────────────┤
│   [New Assignment] [Bulk Assign] [Settings]    Current: Regular Term 1 2025       │
├────────────────────────────────────────────────────────────────────────────────────┤
│ TEACHER: [Search ▼]    SUBJECT: [Dropdown ▼]    STATUS: [Dropdown ▼]      [Filter] │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Teacher Name | Subject    | Classes   | Periods | Workload | Status   │ Action │
│────────────────────────────────────────────────────────────────────────────────────│
│ ☐ │ Mr. Smith    | Mathematics│ 9A,10B,11C│ 28/30   │ 93%      │ ✓ Normal │ 👁️ ✏️ 📊 │
│ ☐ │ Ms. Johnson  | Science    │ 9A,9B,10A │ 26/30   │ 87%      │ ⚠ High   │ 👁️ ✏️ 📊 │
│ ☐ │ Mr. Davis    | English    │ 8A,9A,10B │ 25/30   │ 83%      │ ✓ Normal │ 👁️ ✏️ 📊 │
│   │ Ms. Kumar    | Hindi      │ 9A,9B     │ 15/30   │ 50%      │ ⚠ Low    │ 👁️ ✏️ 📊 │
│────────────────────────────────────────────────────────────────────────────────────│
│ Showing 1-10 of 48 teachers                                          [< 1 2 3 >]   │
└────────────────────────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Components & Interactions

**Filter Bar:**
- **Teacher Search** – Typeahead search with teacher names
- **Subject Dropdown** – Filter by qualified subjects
- **Status Dropdown** – Normal, High Load, Low Load, Unassigned

**Status Indicators:**
- **Workload Percentage** – Based on assigned vs maximum periods
- **Status Colors:**
  - ✓ Normal: 70-100% (Green)
  - ⚠ High: >100% (Red)
  - ⚠ Low: <70% (Amber)

---

### 2.2 Individual Teacher Timetable Screen
**Route:** `/timetable/teacher/{teacherId}` or `/timetable/teacher/mr-smith`

#### 2.2.1 Layout (Weekly Teacher Schedule)

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│ TEACHER TIMETABLE > Mr. Smith (Mathematics)                                        │
├────────────────────────────────────────────────────────────────────────────────────┤
│ [← Prev Teacher] [Mr. Smith] [Ms. Johnson] [Mr. Davis] [Next Teacher →] [Week ▼]   │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ┌─ TEACHER INFO ──────────────────────────────────────────────────────────────────┐ │
│ │ Name: Mr. Smith                           Subject: Mathematics                   │ │
│ │ Employee ID: TCH001                      Classes: 9A, 10B, 11C                   │ │
│ │ Contact: smith@school.edu                Periods: 28/30 (93%)                    │ │
│ │ Qualifications: M.Sc. Math, B.Ed         Status: ✓ Normal Load                   │ │
│ └─────────────────────────────────────────────────────────────────────────────────┘ │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ┌──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┐                        │
│ │      │ MON  │ TUE  │ WED  │ THU  │ FRI  │ SAT  │ SUN  │                        │
│ │Period│ Dec9 │ Dec10│ Dec11│ Dec12│ Dec13│ Dec14│ Dec15│                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │1     │9A Math│10B Math│11C Math│9A Math│10B Math│      │      │                        │
│ │08:00 │Rm101  │Rm102   │Rm103   │Rm101  │Rm102   │      │      │                        │
│ │08:45 │Primary│Primary │Primary │Primary│Primary │      │      │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │2     │10B Math│9A Math│      │11C Math│9A Math│      │      │                        │
│ │08:50 │Rm102   │Rm101  │      │Rm103   │Rm101  │      │      │                        │
│ │09:35 │Primary │Primary│      │Primary │Primary│      │      │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │BREAK │      │      │      │      │      │      │     │                        │
│ │09:35 │      │      │      │      │      │      │     │                        │
│ │09:45 │      │      │      │      │      │      │     │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │3     │11C Math│      │9A Math│10B Math│11C Math│      │      │                        │
│ │09:45 │Rm103   │      │Rm101   │Rm102   │Rm103   │      │      │                        │
│ │10:30 │Primary │      │Primary │Primary │Primary │      │      │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │4     │9A Math│11C Math│10B Math│      │9A Math│      │      │                        │
│ │10:35 │Rm101   │Rm103   │Rm102   │      │Rm101   │      │      │                        │
│ │11:20 │Primary │Primary │Primary │      │Primary │      │      │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │LUNCH │      │      │      │      │      │      │     │                        │
│ │11:20 │      │      │      │      │      │      │     │                        │
│ │12:00 │      │      │      │      │      │      │     │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │5     │10B Math│9A Math│11C Math│9A Math│      │      │      │                        │
│ │12:00 │Rm102   │Rm101   │Rm103   │Rm101   │      │      │      │                        │
│ │12:45 │Primary │Primary │Primary │Primary │      │      │      │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │6     │      │10B Math│9A Math│11C Math│10B Math│      │      │                        │
│ │12:50 │      │Rm102   │Rm101   │Rm103   │Rm102   │      │      │      │                        │
│ │13:35 │      │Primary │Primary │Primary │Primary │      │      │      │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │BREAK │      │      │      │      │      │      │     │                        │
│ │13:35 │      │      │      │      │      │      │     │     │                        │
│ │13:45 │      │      │      │      │      │      │     │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │7     │9A Math│11C Math│      │10B Math│9A Math│      │      │                        │
│ │13:45 │Rm101   │Rm103   │      │Rm102   │Rm101   │      │      │                        │
│ │14:30 │Primary │Primary │      │Primary │Primary │      │      │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │8     │11C Math│      │10B Math│9A Math│11C Math│      │      │                        │
│ │14:35 │Rm103   │      │Rm102   │Rm101   │Rm103   │      │      │                        │
│ │15:20 │Primary │      │Primary │Primary │Primary │      │      │      │                        │
│ └──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┘                        │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ┌─ WORKLOAD SUMMARY ──────────────────────────────────────────────────────────────┐ │
│ │ Total Periods: 28/30 (93%)  │ Daily Average: 4.0  │ Max Consecutive: 3         │ │
│ │ Free Periods: 2             │ Break Compliance: ✓ │ Room Changes: 2/day       │ │
│ └─────────────────────────────────────────────────────────────────────────────────┘ │
├────────────────────────────────────────────────────────────────────────────────────┤
│ [Print] [Export] [Edit Availability] [Request Substitution] [View Conflicts]      │
└────────────────────────────────────────────────────────────────────────────────────┘
```

#### 2.2.2 Components & Interactions

**Teacher Navigation:**
- **Teacher Selector** – Quick navigation between teachers
- **Week Selector** – View different weeks
- **Role Indicators** – Primary/Assistant/Substitute badges

**Workload Summary:**
- **Period Count** – Assigned vs maximum periods
- **Daily Average** – Average periods per day
- **Consecutive Max** – Longest consecutive teaching block
- **Compliance Indicators** – Break rules, room changes

---

### 2.3 Teacher Availability Modal
**Route:** Modal overlay

#### 2.3.1 Layout
```
┌──────────────────────────────────────────────────┐
│ TEACHER AVAILABILITY                             │
├──────────────────────────────────────────────────┤
│ Teacher: Mr. Smith (Mathematics)                 │
│ Week: December 9-15, 2025                       │
│                                                  │
│ ┌─ AVAILABILITY GRID ──────────────────────────┐ │
│ │    │ M │ T │ W │ T │ F │ S │ S │             │ │
│ │P1  │ ✓ │ ✓ │ ✓ │ ✓ │ ✓ │   │   │             │ │
│ │P2  │ ✓ │ ✓ │ ✓ │ ✓ │ ✓ │   │   │             │ │
│ │P3  │ ✓ │ ✓ │ ✓ │ ✓ │ ✓ │   │   │             │ │
│ │P4  │ ✓ │ ✓ │ ✓ │ ✓ │ ✓ │   │   │             │ │
│ │P5  │ ✓ │ ✓ │ ✓ │ ✓ │   │   │   │             │ │
│ │P6  │ ✓ │ ✓ │ ✓ │ ✓ │ ✓ │   │   │             │ │
│ │P7  │ ✓ │ ✓ │ ✓ │ ✓ │ ✓ │   │   │             │ │
│ │P8  │ ✓ │ ✓ │ ✓ │ ✓ │ ✓ │   │   │             │ │
│ └─────────────────────────────────────────────┘ │
│                                                  │
│ Constraints Applied:                             │
│ ✓ Max 6 periods/day                              │
│ ✓ No consecutive >3                              │
│ ✓ Friday half-day                                │
│                                                  │
│ [Save Changes] [Reset] [Cancel]                  │
└──────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Get Teacher Timetable Request
```
GET /api/v1/timetable/teachers/{teacherId}?week_start=2025-12-09&include_workload=true
```

### 3.2 Get Teacher Timetable Response
```json
{
  "success": true,
  "data": {
    "teacher": {
      "id": 12,
      "name": "Mr. Smith",
      "subject": "Mathematics",
      "employee_id": "TCH001",
      "qualifications": ["M.Sc. Math", "B.Ed"]
    },
    "workload": {
      "assigned_periods": 28,
      "max_periods": 30,
      "percentage": 93,
      "daily_average": 4.0,
      "max_consecutive": 3,
      "free_periods": 2,
      "room_changes_avg": 2.0,
      "break_compliance": true
    },
    "classes": ["9A", "10B", "11C"],
    "schedule": {
      "2025-12-09": {
        "P1": {
          "class": "9A",
          "subject": "Mathematics",
          "room": "Rm101",
          "role": "PRIMARY_INSTRUCTOR"
        },
        "P2": {
          "class": "10B",
          "subject": "Mathematics",
          "room": "Rm102",
          "role": "PRIMARY_INSTRUCTOR"
        }
      }
    }
  }
}
```

---

## 4. USER WORKFLOWS

### 4.1 View Teacher Workload Workflow
```
1. User navigates to Teacher Timetables
2. System loads list of all teachers with workload summary
3. User selects specific teacher (e.g., Mr. Smith)
4. System fetches detailed schedule for current week
5. Grid displays classes, rooms, and assignment roles
6. Workload summary shows utilization statistics
7. User can navigate between teachers or weeks
8. User can view/edit availability if permitted
9. User can request substitution for specific periods
```

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Colors & Typography
| Element | Color | Font | Size | Weight |
|---------|-------|------|------|--------|
| Teacher Name | #1F2937 | Inter/Roboto | 24px | Bold (700) |
| Subject Info | #374151 | Inter/Roboto | 16px | Medium (500) |
| Class Labels | Dynamic | Inter/Roboto | 11px | Medium (500) |
| Room Labels | #6B7280 | Inter/Roboto | 10px | Regular (400) |
| Role Badges | #3B82F6 | Inter/Roboto | 9px | Medium (500) |

### 5.2 Workload Status Colors
| Status | Background | Text | Indicator |
|--------|------------|------|-----------|
| Normal (70-100%) | #DCFCE7 | #166534 | ✓ |
| High Load (>100%) | #FEE2E2 | #DC2626 | ⚠ |
| Low Load (<70%) | #FEF3C7 | #92400E | ⚠ |
| Unassigned | #F3F4F6 | #6B7280 | ✗ |

---

## 6. ACCESSIBILITY & USABILITY

### 6.1 Keyboard Navigation
- **Tab:** Navigate between periods
- **Enter:** View period details
- **Arrow Keys:** Navigate grid
- **Page Up/Down:** Change weeks

### 6.2 Screen Reader Support
```html
<table role="grid" aria-label="Mr. Smith Mathematics timetable">
  <caption>Mathematics schedule for Mr. Smith, week of December 9, 2025</caption>
  <!-- table content -->
</table>
```

---

## 7. EDGE CASES & ERROR SCENARIOS

| Scenario | Behavior |
|----------|----------|
| Teacher Unassigned | Show empty grid with assignment prompt |
| Overloaded Teacher | Highlight in red, show warning |
| Availability Conflict | Show conflict indicator with details |
| Permission Denied | Hide edit functions, show read-only |

---

## 8. PERFORMANCE CONSIDERATIONS

### 8.1 Data Optimization
- **Lazy Loading:** Load one teacher at a time
- **Caching:** Cache teacher schedules for 10 minutes
- **Pagination:** Limit API responses

---

## 9. TESTING CHECKLIST

### 9.1 Functional Testing
- [ ] Load teacher timetables
- [ ] Navigate between teachers
- [ ] View workload summaries
- [ ] Export/print functionality

### 9.2 UI/UX Testing
- [ ] Workload indicators are accurate
- [ ] Color coding is intuitive
- [ ] Navigation is smooth

---

## 10. FUTURE ENHANCEMENTS

1. **Real-time Updates:** Live schedule changes
2. **Mobile Notifications:** Schedule change alerts
3. **Calendar Integration:** Sync with personal calendars
4. **Workload Balancing:** Auto suggestions for redistribution
5. **Performance Analytics:** Teaching effectiveness metrics

---

**Document Created By:** ERP Architect GPT  
**Last Reviewed:** December 14, 2025  
**Next Review Date:** March 14, 2026  
**Version Control:** Initial creation