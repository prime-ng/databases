# Business Requirements Document (BRD)
## Module: Smart Timetable Ecosystem
### Feature 05: Refinement, View & Publish

---

## 1. Executive Summary
AI-generated timetables often require human finishing touches. The system provides a drag-and-drop manual refinement interface. Once perfected, the timetable is Locked and Published to Teachers and the Parent Portal.

## 2. Core Components
- `SmartTimetable` & `StandardTimetable` Modules
- Controllers: `TimetableMenuController`, `RefinementController`, `TimetablePublishController`, `StandardTimetableController`
- Tables: `tt_timetable_cells`

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Grid Views & Manual Refinement
- **Multi-Pivot Views:** Admin can view the grid by Class (Monday-Saturday), by Teacher (Where is Mr. John today?), or by Room.
- **Drag and Drop (`RefinementController` / `StandardTimetableController`):** Admin can drag a Math class from Period 1 to Period 4.
- **Live Validation:** If the admin drops a class into a slot where the Teacher is already busy, the UI instantly rejects the drop with a clash warning.

### FR-02: Lock & Publish (`TimetablePublishController`)
- **Locking:** Once the timetable is finalized, it is `LOCKED` to prevent accidental drags or AI overwrites.
- **Publishing:** The status transitions to `PUBLISHED`. Only published timetables are synchronized with:
  - Parent Portal (Daily Schedule view)
  - Teacher Portal
  - `LmsHomework` and `Attendance` modules.

---

## 4. Acceptance Criteria
- **Given** an auto-generated timetable, **When** I drag a Science class into a slot where the Science teacher is already teaching another section, **Then** the drop is rejected and a conflict error is displayed. **When** I successfully publish the timetable, **Then** parents can immediately see the schedule on the Mobile App.
