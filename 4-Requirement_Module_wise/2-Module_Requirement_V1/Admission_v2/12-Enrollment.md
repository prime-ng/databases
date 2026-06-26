# Enrollment — Business Requirements

## What This Screen Does

The Enrollment screen is the final conversion step in the admission pipeline. When an applicant has been allotted a seat and has accepted the offer, the admin uses this page to atomically create the student's full enrollment record. This single action:

1. Creates a **User** account (sys_users) with login credentials
2. Creates a **Student** record (std_students) linked to the user
3. Creates a **StudentAcademicSession** (std_student_academic_sessions) with the enrolled class-section
4. Creates an **Enrollment** log record for audit
5. Optionally creates **Sibling Links** (if siblings already exist in the school)

This is a "big red button" transaction — if any part fails, the entire enrollment is rolled back.

---

## When This Screen Is Used

- After parent accepts the allotment: Admin converts the acceptance into full enrollment
- End of enrollment window: Admin batch-enrolls remaining accepted allotments
- Manual override: Admin needs to enroll a student outside the standard flow

---

## Key Fields at a Glance

**Allotment**
The accepted allotment being converted into enrollment. Read-only — shows applicant name, class, cycle, quota.

**Applicant Details**
Pre-filled from the application: full name, date of birth, gender, address, contact details.

**Student Profile Fields**
Additional fields required for the student record: blood group, medical conditions, previous school, transport requirement, etc.

**Academic Session**
Auto-selected from the cycle's target session. Admin can optionally override.

**Parent / Guardian Fields**
Fields for the parent user account: name, email, phone, relationship.

---

## Business Rules and Conditions

**Atomic Transaction**
All records are created within a single database transaction. If any step fails, the entire enrollment is rolled back.

**Duplicate Prevention**
The system checks that the applicant has not already been enrolled. An allotment can only be enrolled once.

**User Account Creation**
A unique username and initial password are generated. The parent receives login credentials via SMS/Email.

**Academic Session**
The new session record is marked as `is_current = true`. If the student has a previous session (e.g., from a different school), it is marked as `is_current = false`.

**Sibling Detection**
If the applicant's parent/guardian email or phone matches an existing student's parent contact, a sibling link is auto-created.

---

## Workflow Steps

**Opening the Enrollment Page**
Admin navigates to the accepted allotment and clicks "Enroll". The enrollment page opens with pre-filled applicant data.

**Reviewing Details**
Admin reviews the applicant details, student profile fields, and parent/guardian information. Fields can be edited before submission.

**Submitting Enrollment**
Admin clicks "Confirm Enrollment". The system:
1. Creates the User account
2. Creates the Student record
3. Creates the StudentAcademicSession
4. Creates the Enrollment log
5. Detects and creates sibling links
6. Updates the allotment status to "Enrolled"

All within a single transaction. A success message with the student's details and login credentials is displayed.

**Viewing the Result**
The admin is shown the created student's profile link and the generated login credentials.


## Example Scenario

A parent (Ravi Sharma) accepts the Class IX allotment for their child (Aadil). The admin opens the enrollment page:
- Applicant: Aadil Sharma (from allotment)
- Class: IX - A
- Cycle: 2027-28

Admin verifies the details and clicks "Confirm Enrollment". The system:
1. Creates user "Aadil Sharma" with email parent@example.com
2. Creates student record linked to the user
3. Creates academic session: Class IX - A, Roll No: 15, Session: 2027-28
4. Detects that Aadil's elder sister is already a student → creates sibling link
5. Updates allotment status to "Enrolled"

Total time: one click. All-or-nothing.

---

## Related Screens

- **Allotments** — Enrollment is the conversion of an accepted allotment
- **Withdrawals** — Post-enrollment withdrawals reverse this process
- **StudentProfile** — The target module for student records
- **Promotions** — Future promotions depend on the academic session created here
