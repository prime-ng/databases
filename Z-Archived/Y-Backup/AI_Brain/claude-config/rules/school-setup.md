---
globs: ["Modules/SchoolSetup/**", "database/migrations/tenant/*school*", "database/migrations/tenant/*class*", "database/migrations/tenant/*section*", "database/migrations/tenant/*subject*", "database/migrations/tenant/*teacher*", "database/migrations/tenant/*room*"]
---

# SchoolSetup Module Rules

## Module Context
- 40 controllers, 42 models, 0 services
- Table prefix: `sch_*` (~25 tables)
- Route prefix: `/school-setup/*`
- Core infrastructure module — most other tenant modules depend on it

## Key Entities
- Organization, Department, Designation
- SchoolClass, Section, ClassSection (junction)
- Subject, SubjectGroup, SubjectType, StudyFormat
- Teacher, TeacherProfile, TeacherCapability
- Room, RoomType, Building
- Employee, EmployeeProfile

## Dependencies (other modules depend on this)
- SmartTimetable → classes, teachers, rooms
- StudentProfile → class-sections
- Transport → SchoolSetup
- Syllabus → class, subject

## Known Issues
- SchoolClassController::index() has 15+ queries per request (PERF-001) — needs AJAX tabs
- SchoolSetup ↔ SmartTimetable circular dependency exists (ARCH-003)

## Academic Context
- Academic year MUST be resolved before creating term-related data
- `OrganizationAcademicSession::where('is_current', true)->firstOrFail()`
