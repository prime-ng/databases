# School Domain Rules — MANDATORY

## Data Isolation

1. **Students, Teachers, Staff are ALWAYS tenant-scoped.** They must never be accessible across tenants. Every query involving these entities must run within an initialized tenant context.

2. **Parent accounts must be linked to their children (students) within the same tenant only.** A parent in School A cannot see students in School B.

3. **SuperAdmin is central-scoped** — can manage tenants but cannot directly access tenant data without explicitly initializing tenancy.

4. **SchoolAdmin is tenant-scoped** — manages their own school only. Cannot see or modify other schools.

## Academic Year & Term

5. **Academic Year must ALWAYS be resolved before creating term-related data.** This includes:
   - Attendance records
   - Exam results
   - Timetables
   - Fee invoices
   - Syllabus schedules
   ```php
   // Always validate academic context
   $academicSession = OrganizationAcademicSession::where('is_current', true)->firstOrFail();
   ```

6. **Academic term changes affect active timetables, attendance, and assessments.** Always check for cascading impacts.

## Student Management

7. **Student enrollment must verify:**
   - Academic session exists and is active
   - Class and section exist and have capacity
   - Required documents are provided
   - Guardian information is linked

8. **Attendance must always be tied to:** Student + Class/Section + Subject + Date + Academic Year
   ```php
   // Required fields for attendance
   'student_id', 'class_section_id', 'subject_id', 'attendance_date', 'academic_session_id'
   ```

9. **Student transfers between sections/classes** must update all related records (attendance, fee assignments, timetable associations).

## Assessment & Exams

10. **Exam results must always be tied to:** Student + Exam + Subject + Academic Year
    - Never store results without academic context.
    - Validate that student is enrolled in the subject before recording results.

11. **Question bank questions are tenant-scoped.** Each school maintains its own question repository.

## Fee Management

12. **Fee structures are school-specific.** Never share fee configs across tenants.
    - Fee heads are defined per school
    - Concession types are per school
    - Fine rules are per school

13. **Fee invoices must track:**
    - Student, academic session, installment
    - Amount, discount, fine, net payable
    - Payment status and receipt reference

## Timetable

14. **Timetable conflicts must be validated:**
    - Same Teacher cannot have two classes at the same time slot
    - Same Class+Section cannot have two activities at the same time slot
    - Same Room cannot host two activities at the same time slot

15. **Timetable generation requires:**
    - Active academic term
    - Period set configured
    - Working days defined
    - Activities created with teacher assignments
    - Constraints configured

## RBAC (Roles & Permissions)

16. **Roles and permissions are tenant-scoped.** A Teacher role in one school does not grant access to another school.

17. **Permission checks must be performed at both:**
    - Route level (middleware): `->middleware('permission:manage-students')`
    - Controller level (policy): `$this->authorize('update', $student)`

18. **Never expose internal IDs in URLs without proper authorization.** Use route model binding with policy checks.

## Data Integrity

19. **Soft deletes on all critical records:** Students, teachers, staff, fee transactions, exam results, attendance.

20. **Audit trail via `sys_activity_logs`** for all create, update, delete operations on sensitive data.

21. **Multi-currency support** with INR as default. 4 tax types supported.
