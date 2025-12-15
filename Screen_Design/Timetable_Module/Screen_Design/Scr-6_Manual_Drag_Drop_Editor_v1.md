# Screen Design Specification: Manual Drag-Drop Editor
## Document Version: 1.0
**Last Updated:** December 14, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Manual Drag-Drop Editor** screen, enabling administrators and teachers to interactively modify timetables through intuitive drag-and-drop operations, with real-time validation and conflict detection.

### 1.2 User Roles & Permissions
| Role         | Create | View | Update | Delete | Print | Export | Import |
|--------------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| PG Support   |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| School Admin |   ✓    |   ✓  |   ✓    |   ✓    |   ✓   |   ✓    |   ✓    |
| Principal    |   ✓    |   ✓  |   ✗    |   ✗    |   ✓   |   ✓    |   ✗    |
| Teacher      |   ✓    |   ✓  |   ✓    |   ✗    |   ✓   |   ✓    |   ✗    |
| Student      |   ✗    |   ✗  |   ✗    |   ✗    |   ✗    |   ✗    |   ✗    |
| Parents      |   ✗    |   ✗  |   ✗    |   ✗    |   ✗    |   ✗    |   ✗    |

### 1.3 Data Context

**Core Tables:**
- `tt_timetable_cell` - Individual period assignments
- `tim_constraint` - Active constraints for validation
- `sch_class` - Class information
- `sch_teacher` - Teacher details

**Key Relationships:**
- Timetable Cells → Classes (many-to-one)
- Timetable Cells → Teachers (many-to-one)
- Constraints → Timetable Cells (validation)

---

## 2. SCREEN LAYOUTS

### 2.1 Interactive Timetable Editor
**Route:** `/timetable/editor` or `/timetable/manual-editor`

#### 2.1.1 Page Layout

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│ TIMETABLE MANAGEMENT > MANUAL EDITOR                                               │
├──────────────────────────────────────────────────────────────────────────────────────┤
│   [Save Changes] [Undo] [Redo] [Auto-Fix] [Settings]    Current: Regular Term 1 2025│
├──────────────────────────────────────────────────────────────────────────────────────┤
│ ┌─ EDITOR CONTROLS ────────────────────────────────────────────────────────────────┐ │
│ │ View: [Weekly ▼]    Class: [9A ▼]    Week: [Dec 9-15 ▼]    Mode: [Edit ▼]        │ │
│ │                                                                                  │ │
│ │ [🔍 Zoom In] [🔍 Zoom Out] [📋 Copy Period] [📝 Paste] [🗑️ Clear Selection]      │ │
│ └──────────────────────────────────────────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────────────────────────────────────────┤
│ ┌─ TIMETABLE GRID ─────────────────────────────────────────────────────────────────┐ │
│ │ ┌──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┐                        │ │
│ │ │      │ MON  │ TUE  │ WED  │ THU  │ FRI  │ SAT  │ SUN  │                        │ │
│ │ │Period│ Dec9 │ Dec10│ Dec11│ Dec12│ Dec13│ Dec14│ Dec15│                        │ │
│ │ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │ │
│ │ │1     │┌─Math─┐│┌─Sci──┐│┌─Eng──┐│┌─Math─┐│┌─Sci──┐│      │      │                        │ │
│ │ │08:00 ││Mr.S  │││Ms.J  │││Mr.D  │││Mr.S  │││Ms.J  ││      │      │                        │ │
│ │ │08:45 ││45/45 │││45/45 │││45/45 │││45/45 │││45/45 ││      │      │                        │ │
│ │ │      │└─────┘│└─────┘│└─────┘│└─────┘│└─────┘│      │      │                        │ │
│ │ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │ │
│ │ │2     │┌─Sci──┐│┌─Math─┐│      │┌─Eng──┐│┌─Math─┐│      │      │                        │ │
│ │ │08:50 ││Ms.J  │││Mr.S  ││      ││Mr.D  │││Mr.S  ││      │      │                        │ │
│ │ │09:35 ││45/45 │││45/45 ││      ││45/45 │││45/45 ││      │      │                        │ │
│ │ │      │└─────┘│└─────┘│      │└─────┘│└─────┘│      │      │                        │ │
│ │ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │ │
│ │ │BREAK │      │      │      │      │      │      │     │                        │ │
│ │ │09:35 │      │      │      │      │      │      │     │                        │ │
│ │ │09:45 │      │      │      │      │      │      │     │                        │ │
│ │ ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤                        │ │
│ │ │3     │┌─Eng──┐│      │┌─Math─┐│┌─Sci──┐│┌─Eng──┐│      │      │                        │ │
│ │ │09:45 ││Mr.D  ││      ││Mr.S  │││Ms.J  │││Mr.D  ││      │      │                        │ │
│ │ │10:30 ││45/45 ││      ││45/45 │││45/45 │││45/45 ││      │      │                        │ │
│ │ │      │└─────┘│      │└─────┘│└─────┘│└─────┘│      │      │                        │ │
│ │ └──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┘                        │ │
│ └─────────────────────────────────────────────────────────────────────────────────┘ │
├────────────────────────────────────────────────────────────────────────────────────┤
│ ┌─ VALIDATION PANEL ──────────────────────────────────────────────────────────────┐ │
│ │ ⚠ 2 Warnings                           🔴 0 Errors                             │ │
│ │                                                                              │ │
│ │ ⚠ Teacher Overload: Mr. Smith has 6 periods on Monday                       │ │
│ │ ⚠ Room Conflict: Lab 1 double-booked Period 3 Wednesday                      │ │
│ └─────────────────────────────────────────────────────────────────────────────────┘ │
├────────────────────────────────────────────────────────────────────────────────────┤
│ [Save Changes] [Discard Changes] [Preview Impact] [Bulk Operations]              │
└────────────────────────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Components & Interactions

**Editor Controls:**
- **View Modes** – Weekly, Daily, Teacher, Room views
- **Selection Tools** – Single cell, row, column, rectangle selection
- **Edit Operations** – Copy, paste, clear, swap

**Drag & Drop:**
- **Period Cards** – Draggable subject-teacher assignments
- **Visual Feedback** – Highlight valid/invalid drop zones
- **Snap-to-Grid** – Automatic alignment to periods

---

### 2.2 Assignment Palette Sidebar
**Route:** Right sidebar panel

#### 2.2.1 Layout
```
┌─ ASSIGNMENT PALETTE ──────────────────────┐
│ Search: [_________________________] [🔍] │
│                                          │
│ ┌─ AVAILABLE SUBJECTS ──────────────────┐ │
│ │ 📚 Mathematics                        │ │
│ │   • Mr. Smith (Available)             │ │
│ │   • Ms. Davis (Busy)                  │ │
│ │                                        │ │
│ │ 🔬 Science                            │ │
│ │   • Ms. Johnson (Available)           │ │
│ │   • Mr. Wilson (Busy)                 │ │
│ │                                        │ │
│ │ 📖 English                            │ │
│ │   • Mr. Davis (Available)             │ │
│ │   • Ms. Brown (Busy)                  │ │
│ └──────────────────────────────────────┘ │
│                                          │
│ ┌─ QUICK ACTIONS ───────────────────────┐ │
│ │ [Auto-Assign Empty]                   │ │
│ │ [Clear Day]                           │ │
│ │ [Copy from Template]                  │ │
│ │ [Swap Teachers]                       │ │
│ └──────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

### 2.3 Conflict Resolution Modal
**Route:** Modal overlay

#### 2.3.1 Layout
```
┌──────────────────────────────────────────────────┐
│ RESOLVE CONFLICT                                 │
├──────────────────────────────────────────────────┤
│ Conflict Type: Teacher Double-Booking            │
│                                                  │
│ ┌─ CONFLICT DETAILS ───────────────────────────┐ │
│ │ Period: Monday Period 3 (09:45-10:30)        │ │
│ │ Current: 9A Math - Mr. Smith                  │ │
│ │ Conflict: 10B Science - Mr. Smith             │ │
│ └─────────────────────────────────────────────┘ │
│                                                  │
│ Suggested Resolutions:                           │
│ □ Move 10B Science to Period 4                   │
│ □ Swap with substitute teacher                  │
│ □ Change room for 10B Science                   │
│ □ Cancel one assignment                         │
│                                                  │
│ [Apply Resolution] [Manual Edit] [Ignore]       │
└──────────────────────────────────────────────────┘
```

---

### 2.4 Bulk Operations Modal
**Route:** Modal overlay

#### 2.4.1 Layout
```
┌──────────────────────────────────────────────────┐
│ BULK OPERATIONS                                  │
├──────────────────────────────────────────────────┤
│ Operation Type: [Replace Teacher ▼]             │
│                                                  │
│ ┌─ SELECTION ──────────────────────────────────┐ │
│ │ □ All periods for Mr. Smith                   │ │
│ │ □ Selected cells only                         │ │
│ │ □ Current week only                           │ │
│ └─────────────────────────────────────────────┘ │
│                                                  │
│ ┌─ PARAMETERS ─────────────────────────────────┐ │
│ │ Replace with: [Ms. Davis ▼]                   │ │
│ │ Apply to: [All subjects ▼]                    │ │
│ │ Conflict handling: [Skip ▼]                   │ │
│ └─────────────────────────────────────────────┘ │
│                                                  │
│ [Preview Changes] [Apply] [Cancel]              │
└──────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Update Timetable Cell Request
```
PUT /api/v1/timetable/cells/{cellId}
Content-Type: application/json

{
  "subject_id": 5,
  "teacher_id": 12,
  "room_id": 8,
  "class_id": 9
}
```

### 3.2 Bulk Update Request
```
POST /api/v1/timetable/cells/bulk-update
Content-Type: application/json

{
  "operation": "replace_teacher",
  "selection": {
    "teacher_id": 12,
    "scope": "all_periods"
  },
  "parameters": {
    "new_teacher_id": 15,
    "conflict_handling": "skip"
  }
}
```

### 3.3 Validation Response
```json
{
  "success": true,
  "data": {
    "valid": false,
    "errors": [
      {
        "type": "teacher_double_booking",
        "severity": "error",
        "message": "Mr. Smith is double-booked in Period 3",
        "suggestions": [
          {
            "action": "move_period",
            "description": "Move 10B Science to Period 4",
            "target_cell_id": 456
          }
        ]
      }
    ],
    "warnings": [
      {
        "type": "teacher_overload",
        "severity": "warning",
        "message": "Mr. Smith has 6 periods today"
      }
    ]
  }
}
```

---

## 4. USER WORKFLOWS

### 4.1 Manual Editing Workflow
```
1. User navigates to Manual Editor
2. User selects class/week to edit
3. User identifies period needing change
4. User drags subject-teacher from palette
5. System validates assignment in real-time
6. If valid, assignment is placed
7. If conflict, system shows resolution modal
8. User selects resolution or makes manual adjustment
9. User continues editing other periods
10. User saves all changes
```

---

## 5. VISUAL DESIGN GUIDELINES

### 5.1 Colors & Typography
| Element | Color | Font | Size | Weight |
|---------|-------|------|------|--------|
| Period Cards | #FFFFFF | Inter/Roboto | 11px | Medium (500) |
| Subject Labels | #1F2937 | Inter/Roboto | 10px | Bold (700) |
| Teacher Labels | #6B7280 | Inter/Roboto | 9px | Regular (400) |
| Occupancy | #10B981 | Inter/Roboto | 8px | Medium (500) |

### 5.2 Drag & Drop States
| State | Background | Border | Cursor |
|-------|------------|--------|--------|
| Normal | #FFFFFF | #E5E7EB | default |
| Hover | #F9FAFB | #D1D5DB | pointer |
| Dragging | #EBF4FF | #3B82F6 | grabbing |
| Valid Drop | #DCFCE7 | #10B981 | pointer |
| Invalid Drop | #FEE2E2 | #EF4444 | not-allowed |

### 5.3 Validation Colors
| Severity | Background | Text | Icon |
|----------|------------|------|------|
| Error | #FEE2E2 | #DC2626 | 🔴 |
| Warning | #FEF3C7 | #92400E | ⚠️ |
| Info | #DBEAFE | #1E40AF | ℹ️ |

---

## 6. ACCESSIBILITY & USABILITY

### 6.1 Keyboard Navigation
- **Tab/Shift+Tab:** Navigate between cells
- **Enter:** Edit selected cell
- **Arrow Keys:** Move selection
- **Ctrl+C/Ctrl+V:** Copy/paste assignments

### 6.2 Screen Reader Support
```html
<table role="grid" aria-label="Timetable editor for 9A class">
  <caption>Interactive timetable editor showing assignments for 9A class</caption>
  <!-- table content with proper ARIA labels -->
</table>
```

---

## 7. EDGE CASES & ERROR SCENARIOS

| Scenario | Behavior |
|----------|----------|
| Invalid Drop | Show red highlight, prevent drop |
| Network Error | Show offline indicator, queue changes |
| Concurrent Edit | Show conflict modal with merge options |
| Permission Denied | Disable editing, show read-only view |

---

## 8. PERFORMANCE CONSIDERATIONS

### 8.1 Optimization
- **Virtual Scrolling:** Render only visible cells
- **Lazy Validation:** Validate on drop, not hover
- **Change Batching:** Group updates for efficiency

---

## 9. TESTING CHECKLIST

### 9.1 Functional Testing
- [ ] Drag and drop assignments
- [ ] Real-time validation
- [ ] Conflict resolution
- [ ] Bulk operations

### 9.2 UI/UX Testing
- [ ] Visual feedback clear
- [ ] Keyboard navigation works
- [ ] Touch/mobile support

---

## 10. FUTURE ENHANCEMENTS

1. **Multi-Touch Support:** Pinch-to-zoom, multi-finger drag
2. **Undo/Redo Stack:** Full edit history with branching
3. **Collaborative Editing:** Real-time multi-user editing
4. **AI Suggestions:** Smart assignment recommendations

---

**Document Created By:** ERP Architect GPT  
**Last Reviewed:** December 14, 2025  
**Next Review Date:** March 14, 2026  
**Version Control:** Initial creation