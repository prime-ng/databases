# Screen Design Specification: Room/Resource Timetable View
## Document Version: 1.0
**Last Updated:** December 14, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Room/Resource Timetable View** screen, enabling administrators to monitor room utilization, identify conflicts, and optimize resource allocation across the school facility.

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
- `tt_timetable_cell` - Room assignments in periods
- `sch_rooms` - Room/building information
- `sch_buildings` - Building hierarchy
- `tim_constraint` - Room-specific constraints

**Key Relationships:**
- Rooms → Timetable Cells (one-to-many)
- Buildings → Rooms (one-to-many)
- Room Constraints → Timetable Validation

---

## 2. SCREEN LAYOUTS

### 2.1 Room Utilization Dashboard
**Route:** `/timetable/rooms` or `/timetable/room-utilization`

#### 2.1.1 Page Layout

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│ TIMETABLE MANAGEMENT > ROOM UTILIZATION                                            │
├────────────────────────────────────────────────────────────────────────────────────┤
│   [Add Room] [Bulk Edit] [Settings]    Current: Regular Term 1 2025               │
├────────────────────────────────────────────────────────────────────────────────────┤
│ BUILDING: [Dropdown ▼]    ROOM TYPE: [Dropdown ▼]    UTILIZATION: [Dropdown ▼]   │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Room Name | Building | Type     | Capacity | Util% | Conflicts | Status   │ Action │
│────────────────────────────────────────────────────────────────────────────────────│
│ ☐ │ Room 101  | Main     | Classroom│ 45       │ 92%   │ 0         │ ✓ Active │ 👁️ ✏️ 📊 │
│ ☐ │ Lab 1     | Science  | Lab      │ 30       │ 87%   │ 1         │ ✓ Active │ 👁️ ✏️ 📊 │
│ ☐ │ Gym       | Sports   | Gym      │ 100      │ 65%   │ 0         │ ✓ Active │ 👁️ ✏️ 📊 │
│   │ Auditorium| Main     | Hall     │ 200      │ 45%   │ 2         │ ⚠ Conflicts│ 👁️ ✏️ 📊 │
│────────────────────────────────────────────────────────────────────────────────────│
│ Showing 1-10 of 25 rooms                                             [< 1 2 3 >]   │
└────────────────────────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Components & Interactions

**Filter Options:**
- **Building Dropdown** – Filter by building
- **Room Type Dropdown** – Classroom, Lab, Gym, Hall, etc.
- **Utilization Dropdown** – High (80%+), Medium (50-80%), Low (<50%)

**Utilization Metrics:**
- **Utilization %** – Periods used vs available
- **Conflicts** – Double-booking incidents
- **Status** – Active/Inactive/Maintenance

---

### 2.2 Individual Room Timetable Screen
**Route:** `/timetable/room/{roomId}` or `/timetable/room/room-101`

#### 2.2.1 Layout (Weekly Room Schedule)

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│ ROOM TIMETABLE > Room 101 (Classroom - Main Building)                              │
├────────────────────────────────────────────────────────────────────────────────────┤
│ [← Prev Room] [Room 101] [Lab 1] [Gym] [Auditorium] [Next Room →]   [Week ▼]       │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ┌─ ROOM INFO ─────────────────────────────────────────────────────────────────────┐ │
│ │ Name: Room 101                           Building: Main Building                │ │
│ │ Type: Classroom                          Capacity: 45 students                  │ │
│ │ Facilities: Projector, Whiteboard        Utilization: 92% (37/40 periods)       │ │
│ │ Status: ✓ Active                         Conflicts: 0                            │ │
│ └─────────────────────────────────────────────────────────────────────────────────┘ │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ┌──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┐                        │
│ │      │ MON  │ TUE  │ WED  │ THU  │ FRI  │ SAT  │ SUN  │                        │
│ │Period│ Dec9 │ Dec10│ Dec11│ Dec12│ Dec13│ Dec14│ Dec15│                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │1     │9A Math│10B Math│11C Math│9A Math│10B Math│      │      │                        │
│ │08:00 │Mr.S   │Mr.S    │Mr.S    │Mr.S   │Mr.S    │      │      │                        │
│ │08:45 │45/45  │45/45   │45/45   │45/45  │45/45   │      │      │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │2     │10B Math│9A Math│      │11C Math│9A Math│      │      │                        │
│ │08:50 │Mr.S    │Mr.S   │      │Mr.S    │Mr.S   │      │      │                        │
│ │09:35 │45/45   │45/45  │      │45/45   │45/45  │      │      │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │BREAK │      │      │      │      │      │      │     │                        │
│ │09:35 │      │      │      │      │      │      │     │                        │
│ │09:45 │      │      │      │      │      │      │     │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │3     │11C Math│      │9A Math│10B Math│11C Math│      │      │                        │
│ │09:45 │Mr.S    │      │Mr.S    │Mr.S    │Mr.S    │      │      │                        │
│ │10:30 │45/45   │      │45/45   │45/45   │45/45   │      │      │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │4     │9A Math│11C Math│10B Math│      │9A Math│      │      │                        │
│ │10:35 │Mr.S    │Mr.S    │Mr.S    │      │Mr.S   │      │      │                        │
│ │11:20 │45/45   │45/45   │45/45   │      │45/45  │      │      │      │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │LUNCH │      │      │      │      │      │      │     │                        │
│ │11:20 │      │      │      │      │      │      │     │                        │
│ │12:00 │      │      │      │      │      │      │     │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │5     │10B Math│9A Math│11C Math│9A Math│      │      │      │                        │
│ │12:00 │Mr.S    │Mr.S    │Mr.S    │Mr.S   │      │      │      │                        │
│ │12:45 │45/45   │45/45   │45/45   │45/45  │      │      │      │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │6     │      │10B Math│9A Math│11C Math│10B Math│      │      │                        │
│ │12:50 │      │Mr.S    │Mr.S   │Mr.S    │Mr.S    │      │      │      │                        │
│ │13:35 │      │45/45   │45/45  │45/45   │45/45   │      │      │      │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │BREAK │      │      │      │      │      │      │     │                        │
│ │13:35 │      │      │      │      │      │      │     │                        │
│ │13:45 │      │      │      │      │      │      │     │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │7     │9A Math│11C Math│      │10B Math│9A Math│      │      │                        │
│ │13:45 │Mr.S    │Mr.S    │      │Mr.S    │Mr.S   │      │      │                        │
│ │14:30 │45/45   │45/45   │      │45/45   │45/45  │      │      │      │                        │
│ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │
│ │8     │11C Math│      │10B Math│9A Math│11C Math│      │      │                        │
│ │14:35 │Mr.S     │      │Mr.S    │Mr.S   │Mr.S    │      │      │                        │
│ │15:20 │45/45    │      │45/45   │45/45  │45/45   │      │      │      │                        │
│ └──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┘                        │
├────────────────────────────────────────────────────────────────────────────────────┤
│ [Print] [Export] [Edit Constraints] [View Conflicts] [Utilization Report]          │
└────────────────────────────────────────────────────────────────────────────────────┘
```

#### 2.2.2 Components & Interactions

**Room Navigation:**
- **Room Selector** – Quick navigation between rooms
- **Week Selector** – View different weeks
- **Capacity Display** – Current occupancy vs capacity

**Utilization Display:**
- **Class/Teacher Info** – Which class and teacher is using the room
- **Occupancy Ratio** – Students present vs room capacity
- **Conflict Indicators** – Highlight double-bookings

---

### 2.3 Room Conflict Resolution Modal
**Route:** Modal overlay

#### 2.3.1 Layout
```
┌──────────────────────────────────────────────────┐
│ ROOM CONFLICT RESOLUTION                         │
├──────────────────────────────────────────────────┤
│ Room: Lab 1 (Science Building)                   │
│ Date: Monday, December 9, 2025                  │
│ Period: 3 (09:45-10:30)                         │
│                                                  │
│ ┌─ CONFLICTING ASSIGNMENTS ────────────────────┐ │
│ │ 1. 9A Science - Ms. Johnson (Lab 1)          │ │
│ │    Students: 30/30                           │ │
│ │                                              │ │
│ │ 2. 10B Physics - Mr. Davis (Lab 1)           │ │
│ │    Students: 28/30                           │ │
│ └─────────────────────────────────────────────┘ │
│                                                  │
│ Suggested Resolutions:                           │
│ □ Move 10B Physics to Room 102 (available)      │
│ □ Combine classes (if same subject)             │
│ □ Split into two sessions                       │
│ □ Cancel one assignment                         │
│                                                  │
│ [Apply Resolution] [Manual Edit] [Cancel]       │
└──────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Get Room Timetable Request
```
GET /api/v1/timetable/rooms/{roomId}?week_start=2025-12-09&include_utilization=true
```

### 3.2 Get Room Timetable Response
```json
{
  "success": true,
  "data": {
    "room": {
      "id": 8,
      "name": "Room 101",
      "building": "Main Building",
      "type": "Classroom",
      "capacity": 45,
      "facilities": ["Projector", "Whiteboard"]
    },
    "utilization": {
      "total_periods": 40,
      "used_periods": 37,
      "percentage": 92,
      "conflicts": 0,
      "avg_occupancy": 42
    },
    "schedule": {
      "2025-12-09": {
        "P1": {
          "class": "9A",
          "subject": "Mathematics",
          "teacher": "Mr. Smith",
          "students": 45,
          "occupancy_rate": 100
        }
      }
    }
  }
}
```

---

## 4. USER WORKFLOWS

### 4.1 Monitor Room Utilization Workflow
```
1. User navigates to Room Utilization dashboard
2. System loads all rooms with utilization metrics
3. User filters by building, type, or utilization level
4. User identifies under/over-utilized rooms
5. User selects specific room for detailed view
6. System shows weekly schedule with occupancy details
7. User can identify conflicts and optimization opportunities
8. User can export utilization reports
```

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Colors & Typography
| Element | Color | Font | Size | Weight |
|---------|-------|------|------|--------|
| Room Name | #1F2937 | Inter/Roboto | 24px | Bold (700) |
| Building Info | #374151 | Inter/Roboto | 16px | Medium (500) |
| Class Labels | Dynamic | Inter/Roboto | 11px | Medium (500) |
| Teacher Labels | #6B7280 | Inter/Roboto | 10px | Regular (400) |
| Occupancy | #10B981 | Inter/Roboto | 9px | Medium (500) |

### 5.2 Utilization Status Colors
| Utilization | Background | Text | Indicator |
|-------------|------------|------|-----------|
| High (80%+) | #DCFCE7 | #166534 | ✓ |
| Medium (50-80%) | #FEF3C7 | #92400E | ⚠ |
| Low (<50%) | #FEE2E2 | #DC2626 | ✗ |
| Conflict | #EF4444 | #FFFFFF | ⚠ |

---

## 6. ACCESSIBILITY & USABILITY

### 6.1 Keyboard Navigation
- **Tab:** Navigate between periods
- **Enter:** View period details
- **Arrow Keys:** Navigate grid

### 6.2 Screen Reader Support
```html
<table role="grid" aria-label="Room 101 utilization schedule">
  <caption>Classroom schedule for Room 101, week of December 9, 2025</caption>
  <!-- table content -->
</table>
```

---

## 7. EDGE CASES & ERROR SCENARIOS

| Scenario | Behavior |
|----------|----------|
| Room Unavailable | Show maintenance indicator |
| Capacity Exceeded | Highlight in red |
| Double Booking | Show conflict modal |

---

## 8. PERFORMANCE CONSIDERATIONS

### 8.1 Data Optimization
- **Lazy Loading:** Load one room at a time
- **Caching:** Cache room schedules for 15 minutes

---

## 9. TESTING CHECKLIST

### 9.1 Functional Testing
- [ ] Load room timetables
- [ ] View utilization metrics
- [ ] Identify conflicts
- [ ] Export reports

### 9.2 UI/UX Testing
- [ ] Utilization indicators accurate
- [ ] Conflict highlighting visible

---

## 10. FUTURE ENHANCEMENTS

1. **Real-time Monitoring:** Live occupancy tracking
2. **IoT Integration:** Sensor-based utilization
3. **Predictive Analytics:** Usage forecasting
4. **Maintenance Scheduling:** Automated booking blocks

---

**Document Created By:** ERP Architect GPT  
**Last Reviewed:** December 14, 2025  
**Next Review Date:** March 14, 2026  
**Version Control:** Initial creation