# Review & Approval — Requirements

## What It Does
Workflow for Principal/HOD to review submitted behavioural assessments. Supports two actions: **Approve** (transition to reviewed — triggers score computation) and **Send Back** (revert to draft with reviewer remarks for teacher revision).

## Business Rules

**Reviewer Scope**
- Principal can review ALL assessments across all class-sections.
- HOD/Coordinator can review assessments only for their assigned departments/classes.
- Reviewer role is determined by permission: `ba.review.approve`.

**Approve Flow**
1. Reviewer opens submitted assessment — grid displayed in read-only mode.
2. Reviewer clicks "Approve" → confirmation modal.
3. System validates no incomplete ratings (redundant check — already validated at submission).
4. Assessment transitions from `submitted` to `reviewed`.
5. `reviewed_by` and `reviewed_at` are set to the reviewer.
6. `AssessmentApproved` event fired → triggers `BehaviouralScoreService::computeAndCacheScores()` for this class-section-period.
7. Teacher receives notification that assessment was approved.

**Send Back Flow**
1. Reviewer clicks "Send Back" → modal with required remarks field.
2. `reviewer_remarks` are saved explaining what needs correction.
3. Assessment transitions from `submitted` → `draft` (or `reviewed` → `draft`).
4. `AssessmentSentBack` event fired → teacher receives notification.
5. Teacher revises ratings and re-submits.

**Locked Period Check**
- If the assessment period is `locked`, no review actions are permitted.

## CRUD Operations

**List**
- Route: `GET /behavioural-assessment/reviews` → all submitted/reviewed assessments for reviewer's scope
- Filters: period, class-section, teacher, status (submitted/reviewed)
- Shows: period name, teacher name, class-section, submission date, days pending

**Show**
- Route: `GET /behavioural-assessment/reviews/{assessment}` → read-only grid with all ratings displayed
- Shows: student name, criterion ratings, overall remarks, submit date
- Action buttons: Approve (green), Send Back (yellow, with remarks modal)

**Approve**
- Route: `POST /behavioural-assessment/reviews/{assessment}/approve`
- Validates: assessment status = `submitted`; reviewer has permission
- Side effects: triggers score computation

**Send Back**
- Route: `POST /behavioural-assessment/reviews/{assessment}/send-back`
- Validates: `remarks` required, max:1000; assessment is `submitted` or `reviewed`
- Side effects: assessment reverts to `draft`

## Permissions

| Operation | Permission Key |
|---|---|
| View reviews tab | `tenant.ba.review.viewAny` |
| View assessment for review | `tenant.ba.review.viewAny` |
| Approve assessment | `tenant.ba.review.approve` |
| Send back assessment | `tenant.ba.review.approve` |
