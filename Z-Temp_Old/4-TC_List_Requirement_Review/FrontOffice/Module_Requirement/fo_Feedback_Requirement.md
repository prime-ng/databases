# Feedback — Business Requirements

## What This Screen Does

The Feedback tab manages feedback forms with dynamic questions (stored as JSON), public/private submission, response collection, and reporting. Staff create forms, share public links (token-based), and view response reports.

## When This Screen Is Used

- **Parent Surveys**: Collecting feedback on school events, teaching quality
- **Staff Feedback**: Anonymous staff satisfaction surveys
- **Public Forms**: External stakeholder feedback via token URL

## Key Fields

- **title** (string 200) — Form title
- **description** (text, nullable) — Form description
- **questions_json** (json) — Array of question objects
- **token** (string, nullable) — Unique token for public submission URL
- **is_anonymous_allowed** (boolean) — Allow anonymous responses
- **responses** (HasMany → `fof_feedback_responses`)

## Business Rules

**Questions JSON:** `questions_json` cast as array. View shows count as "X Questions" badge.

**Anonymous:** `is_anonymous_allowed` badge: Yes (info-subtle with shield icon) / No.

**Response Count:** `$form->responses_count ?? 0` shows total responses (loaded via withCount).

**Public Token:** Each form has a unique `token` for public submission at `route('fof.feedback.public', $form->token)`. If token is null, falls back to `$form->id`.

**Report View:** `route('fof.feedback.report', $form)` opens a report page (chart/stats).

**Response Model:** `FeedbackResponse` stores `respondent_user_id`, `respondent_name`, `is_anonymous`, `responses_json`, `submitted_at`.

## Requirements

- MUST display in Communication tab group as paginated table
- MUST authorize via `frontoffice.feedback.*` policy gates
- MUST show question count from questions_json array
- MUST show anonymous allowed status with shield icon
- MUST show response count (loaded via withCount)
- MUST link to Report view (chart-bar icon button)
- MUST link to Public form (link icon button, opens new tab)
- MUST support status toggle via Ajax
- MUST support soft delete
