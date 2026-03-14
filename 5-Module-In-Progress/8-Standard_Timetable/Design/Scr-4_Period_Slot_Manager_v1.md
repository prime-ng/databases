# Screen Design Specification: Period/Slot Manager
## Document Version: 1.0
**Last Updated:** December 14, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Period/Slot Manager** screen, enabling administrators to configure period sets, manage slot timings, and define break schedules for the school's timetable system.

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
- `tim_period_set` - Period set definitions
- `tim_period_slot` - Individual period slots
- `tim_break_slot` - Break periods
- `tim_timetable_mode` - Mode configurations

**Key Relationships:**
- Period Sets → Period Slots (one-to-many)
- Period Sets → Break Slots (one-to-many)
- Timetable Modes → Period Sets (many-to-many)

---

## 2. SCREEN LAYOUTS

### 2.1 Period Set Management Dashboard
**Route:** `/timetable/periods` or `/timetable/period-management`

#### 2.1.1 Page Layout

```
┌────────────────────────────────────────────────────────────────────────────────────────────────┐
│ TIMETABLE MANAGEMENT > PERIOD MANAGEMENT                                                       │
├────────────────────────────────────────────────────────────────────────────────────────────────┤
│   [Create Period Set] [Import Template] [Settings]    Current: Regular Term 1 2025             │
├────────────────────────────────────────────────────────────────────────────────────────────────┤
│ GRADE LEVEL: [Dropdown ▼]        TIMETABLE MODE: [Dropdown  ▼]          STATUS: [Dropdown  ▼]  │
├────────────────────────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Period Set Name | Grade Level | Mode     | Periods | Breaks | Duration | Status │ Action   │
│────────────────────────────────────────────────────────────────────────────────────────────────│
│ ☐ │ Primary Morning │ Grades 1-5  │ Regular │ 8       │ 3      │ 6h 30m   │ ✓ Active│ 👁️ ✏️ 📋 │
│ ☐ │ Secondary Full  │ Grades 6-12 │ Regular │ 10      │ 4      │ 7h 45m   │ ✓ Active│ 👁️ ✏️ 📋 │
│ ☐ │ Exam Schedule   │ All Grades  │ Exam    │ 6       │ 2      │ 5h 15m   │ ✓ Active│ 👁️ ✏️ 📋 │
│ ☐ │ Weekend Classes │ Grades 9-12 │ Weekend │ 4       │ 1      │ 3h 20m   │ ⚠ Draft │ 👁️ ✏️ 📋 │
│────────────────────────────────────────────────────────────────────────────────────────────────│
│ Showing 1-10 of 15 period sets                                                   [< 1 2 >]     │
└────────────────────────────────────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Components & Interactions

**Filter Options:**
- **Grade Level Dropdown** – Primary, Secondary, All Grades
- **Timetable Mode Dropdown** – Regular, Exam, Weekend, Holiday
- **Status Dropdown** – Active, Draft, Inactive

**Period Set Metrics:**
- **Periods** – Number of teaching periods
- **Breaks** – Number of break periods
- **Duration** – Total schedule duration

---

### 2.2 Period Set Editor Screen
**Route:** `/timetable/periods/{periodSetId}/edit` or `/timetable/periods/primary-morning/edit`

#### 2.2.1 Layout (Period Configuration)

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│ PERIOD SET EDITOR > Primary Morning (Grades 1-5)                                   │
├────────────────────────────────────────────────────────────────────────────────────┤
│ [← Back to List] [Save] [Save as New] [Preview] [Delete]                           │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ┌─ PERIOD SET DETAILS ─────────────────────────────────────────────────────────────┐ │
│ │ Name: Primary Morning                           Grade Level: Grades 1-5          │ │
│ │ Mode: Regular                                   Status: ✓ Active                 │ │
│ │ Description: Standard morning schedule for primary students                     │ │
│ └─────────────────────────────────────────────────────────────────────────────────┘ │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ┌─ PERIOD CONFIGURATION ───────────────────────────────────────────────────────────┐ │
│ │ ┌──────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┐ │ │
│ │ │Slot  │ Type    │ Start   │ End     │ Duration│ Subject │ Teacher │ Room   │ │ │
│ │ │      │         │ Time    │ Time    │         │ Limit   │ Limit  │ Limit  │ │ │
│ │ ├──────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤ │ │
│ │ │1     │Period  │08:00    │08:45    │45m      │✓        │✓        │✓        │ │ │
│ │ │2     │Period  │08:50    │09:35    │45m      │✓        │✓        │✓        │ │ │
│ │ │3     │Break   │09:35    │09:45    │10m      │✗        │✗        │✗        │ │ │
│ │ │4     │Period  │09:45    │10:30    │45m      │✓        │✓        │✓        │ │ │
│ │ │5     │Period  │10:35    │11:20    │45m      │✓        │✓        │✓        │ │ │
│ │ │6     │Break   │11:20    │12:00    │40m      │✗        │✗        │✗        │ │ │
│ │ │7     │Period  │12:00    │12:45    │45m      │✓        │✓        │✓        │ │ │
│ │ │8     │Period  │12:50    │13:35    │45m      │✓        │✓        │✓        │ │ │
│ │ │9     │Break   │13:35    │13:45    │10m      │✗        │✗        │✗        │ │ │
│ │ │10    │Period  │13:45    │14:30    │45m      │✓        │✓        │✓        │ │ │
│ │ │11    │Period  │14:35    │15:20    │45m      │✓        │✓        │✓        │ │ │
│ │ └──────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┘ │ │
│ └─────────────────────────────────────────────────────────────────────────────────┘ │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ┌─ BULK OPERATIONS ───────────────────────────────────────────────────────────────┐ │
│ │ [Add Period] [Add Break] [Remove Selected] [Copy from Template]                 │ │
│ │                                                                                  │ │
│ │ [Adjust All Periods] Duration: [45] minutes    [Apply to Selected]              │ │
│ │ [Shift Schedule] Start Time: [08:00]    [Apply Shift]                           │ │
│ └─────────────────────────────────────────────────────────────────────────────────┘ │
├────────────────────────────────────────────────────────────────────────────────────┤
│ [Save Changes] [Cancel] [Preview Schedule] [Export Configuration]                 │
└────────────────────────────────────────────────────────────────────────────────────┘
```

#### 2.2.2 Components & Interactions

**Period Configuration:**
- **Slot Type** – Period, Break, Lunch, Assembly
- **Time Fields** – Start/End time with validation
- **Duration** – Auto-calculated from start/end times
- **Limits** – Subject/Teacher/Room assignment restrictions

**Bulk Operations:**
- **Add/Remove Slots** – Dynamic schedule modification
- **Adjust Duration** – Change all periods at once
- **Shift Schedule** – Move entire schedule time

---

### 2.3 Period Template Library Modal
**Route:** Modal overlay

#### 2.3.1 Layout
```
┌──────────────────────────────────────────────────┐
│ PERIOD SET TEMPLATES                             │
├──────────────────────────────────────────────────┤
│ Search: [_________________________] [🔍]        │
│                                                  │
│ ┌─ RECOMMENDED TEMPLATES ──────────────────────┐ │
│ │ □ Primary Standard (8 periods, 3 breaks)     │ │
│ │ □ Secondary Extended (10 periods, 4 breaks) │ │
│ │ □ Exam Schedule (6 periods, 2 breaks)        │ │
│ │ □ Weekend Intensive (4 periods, 1 break)     │ │
│ └─────────────────────────────────────────────┘ │
│                                                  │
│ ┌─ CUSTOM TEMPLATES ───────────────────────────┐ │
│ │ □ My Primary Schedule                        │ │
│ │ □ Summer Camp Schedule                       │ │
│ └─────────────────────────────────────────────┘ │
│                                                  │
│ [Load Template] [Create from Scratch] [Cancel]  │
└──────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Get Period Sets Request
```
GET /api/v1/timetable/period-sets?grade_level=primary&mode=regular&status=active
```

### 3.2 Get Period Sets Response
```json
{
  "success": true,
  "data": {
    "period_sets": [
      {
        "id": 1,
        "name": "Primary Morning",
        "grade_level": "Grades 1-5",
        "mode": "Regular",
        "period_count": 8,
        "break_count": 3,
        "total_duration": "6h 30m",
        "status": "active",
        "slots": [
          {
            "slot_number": 1,
            "type": "period",
            "start_time": "08:00",
            "end_time": "08:45",
            "duration_minutes": 45,
            "subject_limit": true,
            "teacher_limit": true,
            "room_limit": true
          }
        ]
      }
    ]
  }
}
```

---

## 4. USER WORKFLOWS

### 4.1 Create New Period Set Workflow
```
1. User navigates to Period Management dashboard
2. User clicks "Create Period Set"
3. System shows template selection modal
4. User selects template or creates from scratch
5. User configures period details (name, grade, mode)
6. User defines period slots with timings
7. User adds break periods as needed
8. User sets assignment limits for each slot
9. User previews the schedule
10. User saves the period set
```

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Colors & Typography
| Element | Color | Font | Size | Weight |
|---------|-------|------|------|--------|
| Period Set Name | #1F2937 | Inter/Roboto | 24px | Bold (700) |
| Slot Labels | #374151 | Inter/Roboto | 14px | Medium (500) |
| Time Fields | #6B7280 | Inter/Roboto | 13px | Regular (400) |
| Duration | #10B981 | Inter/Roboto | 12px | Medium (500) |

### 5.2 Slot Type Colors
| Slot Type | Background | Text | Icon |
|-----------|------------|------|------|
| Period | #E0F2FE | #0277BD | 📚 |
| Break | #F3E5F5 | #7B1FA2 | ☕ |
| Lunch | #FFF3E0 | #EF6C00 | 🍽️ |
| Assembly | #E8F5E8 | #2E7D32 | 👥 |

---

## 6. ACCESSIBILITY & USABILITY

### 6.1 Keyboard Navigation
- **Tab:** Navigate between time fields
- **Enter:** Confirm time entry
- **Arrow Keys:** Adjust time values

### 6.2 Screen Reader Support
```html
<table role="grid" aria-label="Period configuration for Primary Morning schedule">
  <caption>Configure periods and breaks for Primary Morning schedule</caption>
  <!-- table content -->
</table>
```

---

## 7. EDGE CASES & ERROR SCENARIOS

| Scenario | Behavior |
|----------|----------|
| Overlapping Times | Show validation error |
| Invalid Duration | Highlight in red |
| Missing Breaks | Show warning |

---

## 8. PERFORMANCE CONSIDERATIONS

### 8.1 Data Optimization
- **Template Caching:** Cache common templates
- **Validation:** Client-side time validation

---

## 9. TESTING CHECKLIST

### 9.1 Functional Testing
- [ ] Create period sets
- [ ] Configure slot timings
- [ ] Add/remove breaks
- [ ] Validate schedules

### 9.2 UI/UX Testing
- [ ] Time input validation
- [ ] Bulk operations work
- [ ] Template loading

---

## 10. FUTURE ENHANCEMENTS

1. **Dynamic Scheduling:** AI-optimized break placement
2. **Flexible Periods:** Variable duration periods
3. **Calendar Integration:** Holiday-aware scheduling
4. **Mobile Editing:** Touch-friendly period editor

---

**Document Created By:** ERP Architect GPT  
**Last Reviewed:** December 14, 2025  
**Next Review Date:** March 14, 2026  
**Version Control:** Initial creation