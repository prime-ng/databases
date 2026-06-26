# Entrance Tests — Business Requirements

## What This Screen Does

The Entrance Tests screen manages the setup, execution, and scoring of entrance examinations for admission. Admin creates a test (name, date, maximum marks, passing marks), imports candidates from eligible applications, and records marks for each candidate.

This is a standalone page with a list view (within the Assessment tab group) and a detail/show page where marks entry and candidate management happen.

---

## When This Screen Is Used

- Mid-cycle: Admin creates entrance tests for classes that require them
- Before test day: Admin imports the list of eligible candidates
- After the test: Admin enters marks for each candidate
- Review: Admin views test results and candidate rankings

---

## Key Fields at a Glance

**Test Name**
A label for the test (e.g., "Class IX Entrance — Mathematics & Science").

**Cycle**
The admission cycle this test belongs to.

**Date & Time**
Scheduled date and time of the test.

**Max Marks / Passing Marks**
The total marks for the test and the minimum required to pass.

**Candidates**
The list of applicants imported/added to the test. Each candidate has marks_obtained and rank fields.

**Status**
Draft / Scheduled / Completed — tracks the test lifecycle.

---

## Business Rules and Conditions

**Cycle-Scoped**
Tests belong to a specific admission cycle and class.

**Candidate Import**
Candidates are imported from Shortlisted applications for the same cycle and class.

**Marks Validation**
Entered marks cannot exceed max_marks. The system warns if a candidate's marks are below passing_marks.

**Rank Computation**
After marks are entered, the system can compute candidate ranks within the test.

**Soft Delete**
Tests can be soft-deleted. Candidate records are preserved for audit.

---

## Workflow Steps

**Creating a Test**
Admin navigates to the Entrance Tests tab, clicks "Add Test", fills in the details (name, cycle, class, date, max marks, passing marks), and submits.

**Importing Candidates**
On the test show page, admin clicks "Import Candidates". The system fetches all Shortlisted applications for the same cycle and class and adds them as candidates.

**Entering Marks**
On the test show page, admin edits each candidate's marks_obtained field. Marks are saved individually or in bulk via AJAX.

**Viewing Test Details**
The show page displays test metadata, candidate list with marks and ranks, and pass/fail status per candidate.

**Deleting a Test**
Admin clicks Delete. A confirmation dialog appears. The test is soft-deleted.

---

## Example Scenario

For Class IX admissions, the school conducts an entrance test. Admin creates:
- Name: "Class IX Entrance 2027"
- Date: 15-Feb-2027
- Max Marks: 100, Passing Marks: 35

Admin imports 45 Shortlisted candidates. After the test, admin enters each candidate's marks. The system computes ranks. Candidates scoring 35+ are marked as Pass.

---

## Related Screens

- **Admission Cycles** — Tests are scoped to a cycle
- **Merit Lists** — Test scores feed into composite merit score computation
- **Enquiry Pipeline** — Candidates are imported from Shortlisted applications
- **Assessment Tab** — Entrance Tests is one of two tabs in the Assessment page
