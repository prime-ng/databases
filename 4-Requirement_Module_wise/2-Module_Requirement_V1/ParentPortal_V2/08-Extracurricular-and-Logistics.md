# Business Requirements Document (BRD)
## Module: Parent Portal
### Feature 08: Extracurricular & Logistics

---

## 1. Executive Summary
Beyond academics, the portal provides visibility into school logistics (Transport, Hostel) and the child's physical well-being (Health records).

## 2. Core Components
- `ParentTransportController.php`
- `ParentHostelController.php`
- `ParentHealthController.php`
- `ParentEventController.php`

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Transport Management (`ParentTransportController`)
- Displays the assigned Bus Route, Bus Number, Pick-up, and Drop-off stop details.
- Displays the driver/conductor contact details for emergencies.

### FR-02: Hostel Management (`ParentHostelController`)
- For boarding students, displays Hostel Block, Room Number, and Room Type.
- **Out-Pass Requests:** Parents can request an out-pass (Gate Pass) for weekend leaves. Approval workflow similar to standard leaves.

### FR-03: Health & Medical Records (`ParentHealthController`)
- Read-only access to the child's recorded medical profile:
  - Blood Group, Height, Weight, BMI.
  - Known Allergies, Chronic Conditions.
  - Vision/Dental checkup records conducted by the school infirmary.

### FR-04: Events Calendar (`ParentEventController`)
- Displays upcoming school-wide and class-specific events.
- (Pending Future Enhancements: Brijesh noted that the `ppt_event_rsvps` table is currently on hold pending the creation of a full Event registration module).

---

## 4. Acceptance Criteria
- **Given** my child is a boarding student, **When** I log into the portal, **Then** I can view their Hostel Room details and apply for a weekend out-pass.
