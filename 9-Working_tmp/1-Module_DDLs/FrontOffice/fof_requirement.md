# Front Office Module — Requirements Overview

**Module:** FrontOffice | **Laravel Module:** `Modules\FrontOffice` | **Prefix:** `fof_`
**Route:** `front-office/*` | **Route Name:** `fof.*` | **Database:** tenant_db
**Controllers:** 18 | **Models:** 22 | **Tables:** 22 | **Services:** 5 | **Views:** ~60

## Module Overview

The Front Office module digitizes all front-desk operations of a K-12 school — visitor management, gate passes, early departures, phone diary, postal/dispatch registers, circulars, notices, appointments, lost & found, key register, emergency contacts, certificate requests, complaints, feedback forms, and bulk communication.

**Key Distinction vs VSM:** FOF handles operational front-desk tasks (receptionists). VSM (Visitor Security Module, pending) handles gate-level security (biometric, vehicle logs). FOF receives pre-registered visitor handoffs from VSM.

## Requirements by Feature

| # | File | Feature Group | Tables |
|---|------|--------------|--------|
| 1 | `Requirements/visitor-management.md` | Visitor Management | Visitor Purposes, Visitors |
| 2 | `Requirements/gate-passes.md` | Gate Pass (Early Exit) | Gate Passes |
| 3 | `Requirements/early-departures.md` | Student Early Departure | Early Departures |
| 4 | `Requirements/phone-diary.md` | Phone Call Log | Phone Diary |
| 5 | `Requirements/postal-dispatch.md` | Postal & Dispatch Registers | Postal Register, Dispatch Register |
| 6 | `Requirements/circulars.md` | Circular Management | Circulars, Circular Distributions |
| 7 | `Requirements/notices-events.md` | Notice Board & Events | Notices, School Events |
| 8 | `Requirements/appointments.md` | Appointment Scheduling | Appointments |
| 9 | `Requirements/lost-found.md` | Lost & Found Register | Lost Found |
| 10 | `Requirements/key-register.md` | Key Management | Key Register |
| 11 | `Requirements/emergency-contacts.md` | Emergency Contact Directory | Emergency Contacts |
| 12 | `Requirements/certificate-requests.md` | Certificate Request & Issuance | Certificate Requests |
| 13 | `Requirements/complaints.md` | Complaint Handling (FOF Level) | Complaints |
| 14 | `Requirements/feedback.md` | Feedback Collection | Feedback Forms, Feedback Responses |
| 15 | `Requirements/communication.md` | Email & SMS Communication | Email Templates, Communication Logs, SMS Logs |
| 16 | `Requirements/reports-dashboard.md` | Dashboard & Reports | — (computed) |

## Implementation Phases

| Phase | Feature Group | FR IDs |
|-------|--------------|--------|
| Phase 1 | Visitor Management, Gate Pass, Early Departure, Phone Diary, Postal, Dispatch | FOF-01 to FOF-06 |
| Phase 2 | Circulars, Notice Board, School Events | FOF-07, FOF-08, FOF-17 |
| Phase 3 | Certificate Requests, Complaints | FOF-13, FOF-14 |
| Phase 4 | Appointments, Lost & Found, Key Register, Emergency Contacts | FOF-09 to FOF-12 |
| Phase 5 | Feedback, Email & SMS Communication | FOF-15, FOF-16 |

## FOF vs VSM Distinction

| Aspect | FOF (Front Office) | VSM (Visitor Security - Pending) |
|--------|--------------------|----------------------|
| Actor | Receptionist (inside campus) | Security guard (main gate) |
| Visitor record | Pass number, purpose, person to meet | Gate entry, ID scan, vehicle log |
| Integration | Operational detail | Gate timestamps |
| Key feature | Visitor register, circulars, certificates | Biometric scan, vehicle entry |

## Related Files

- Full feature specification: `Claude_Plan/FOF_FeatureSpec.md`
- Development plan: `Claude_Plan/FOF_Dev_Plan.md`
- Table summary: `Claude_Plan/FOF_TableSummary.md`
- DDL: `DDL/FOF_DDL_v1.sql`
- Seeders: `Seeders/FofVisitorPurposeSeeder.php`, `Seeders/FofSeederRunner.php`
