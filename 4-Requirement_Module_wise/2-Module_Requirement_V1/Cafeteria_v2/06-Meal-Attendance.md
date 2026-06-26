# Meal Attendance — Business Requirements

## What This Screen Does

The Meal Attendance screen tracks which students ate which meal and when. Attendance is recorded automatically when a student scans their QR code at the POS counter, or manually by staff for students without QR access.

This is used for verifying meal delivery, generating consumption reports for parents, calculating actual meal costs vs. subscription revenue, and kitchen planning.

---

## When This Screen Is Used

- A student scans their QR code at the breakfast counter — attendance is auto-recorded
- A student forgets their QR card — staff manually records their attendance
- Admin wants to see how many students ate lunch today vs. yesterday
- Parents want to check if their child had breakfast at school
- Monthly meal consumption reports need to be generated

---

## Key Fields at a Glance

**Student**
The student who was served the meal. Auto-detected from QR scan or selected manually.

**Meal Date & Category**
The date of the meal and which meal category (Breakfast, Lunch, Snacks, Dinner). A student can have records for multiple categories on the same day.

**Scanned At**
Exact timestamp when attendance was recorded. Auto-set from system clock.

**Scan Method**
QR (student scanned their QR code), Biometric (fingerprint/face scan), or Manual (staff selected student).

**Counter Name**
Optional — which POS counter the student scanned at.

**Scanned By**
For manual scans — the staff member who recorded the attendance.

---

## Business Rules and Conditions

**Idempotent Scanning (BR-CAF-001)**
UNIQUE on (student_id, meal_date, meal_category_id). Double-scan returns existing record. "Attendance already recorded for Breakfast on this date."

**Immutability**
Attendance records cannot be modified or deleted through the regular UI. Corrections require senior admin access with audit logging.

**Auto-Attendance from POS**
When a MealCard POS transaction is processed, attendance is auto-created in the same transaction.

**Manual Scan Requirement**
Staff member who performed the scan must be recorded for manual entries.

---

## Workflow Steps

**Student Scans QR Code**
Student presents QR code at POS scanner → system reads student ID → checks current meal category and date → records attendance → optionally processes meal card transaction.

**Staff Records Manual Attendance**
Staff searches student by name → selects meal category → records attendance → staff name recorded as scanner.

**Viewing Attendance Reports**
Filter by date range, meal category, class, or student. Shows counts per meal per day.

---

## Example Scenario

Breakfast service (7:30-8:30 AM): Student A scans at 7:35 → Attendance recorded. Student B scans at 7:35 → Recorded. Student A tries to scan again → "Attendance already recorded." Student C forgot QR card → Staff records manually.

End of breakfast: 156 students recorded. Kitchen compares against 150 pre-orders — 6 extra students, adjusts tomorrow's preparation.

---

## Related Screens

- **Orders** — Attendance can be linked to pre-orders
- **POS Sessions** — POS transactions can auto-create attendance records
- **Meal Cards** — Subscription usage can be verified against attendance
