# Feedback Collection — Requirements

## What It Does
Allows schools to create feedback forms (MCQ, rating, text questions) with public token URLs. Forms can be shared via link for anonymous or authenticated responses. Supports reporting aggregation per form.

## Database Fields

### fof_feedback_forms

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `title` | VARCHAR(200) | Required. |
| `description` | TEXT | Nullable. |
| `questions_json` | JSON | Required. Array: `[{type, question, options}]`. |
| `token` | VARCHAR(64) | Required. Unique. Public access token. |
| `is_anonymous_allowed` | TINYINT(1) | Default 0. |
| `is_active` | BOOLEAN | Default true. Inactive forms show "closed" page. |

### fof_feedback_responses

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `feedback_form_id` | BIGINT UNSIGNED FK → `fof_feedback_forms` | Required. |
| `respondent_user_id` | INT UNSIGNED FK → `sys_users` | Nullable. NULL = anonymous. |
| `respondent_name` | VARCHAR(100) | Nullable. Optional for anonymous. |
| `is_anonymous` | TINYINT(1) | Default 0. |
| `responses_json` | JSON | Required. Array: `[{question_id, answer}]`. |
| `submitted_at` | TIMESTAMP | Default CURRENT_TIMESTAMP. |

## Business Rules

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-FOF-010 | If `is_anonymous = 1`, `respondent_user_id` MUST be NULL | Service layer validation on submission |

**Question Types (in questions_json)**
- `text` — Free text input
- `rating` — 1–5 star rating
- `mcq_single` — Multiple choice, single select
- `mcq_multiple` — Multiple choice, multi-select
- `boolean` — Yes/No

**Anonymous vs Authenticated**
- When `is_anonymous_allowed = 1`: form shows anonymous checkbox
- Anonymous submission: `respondent_user_id = NULL`, `is_anonymous = 1`, `created_by = 0`
- Authenticated submission: `respondent_user_id` set from auth, `is_anonymous = 0`

**Public Access**
- Anyone with the token URL can access the form (no auth middleware on public routes)
- `GET /feedback/{token}` — renders the form
- `POST /feedback/{token}` — submits the response
- Inactive forms (is_active = 0) show "This form is closed" page

## CRUD Operations

**Create Form**
- `POST /front-office/feedback` — validates title, questions_json (must be valid question array), generates unique token

**Report**
- `GET /front-office/feedback/{form}/report` — aggregation of responses per question
- Shows response count, average rating (for rating types), text response list

**List**
- Form list with token URL display, response count, report link

**Public Submit**
- No auth; rate-limited per IP; form must be active

## Permissions

| Operation | Permission Key |
|---|---|
| View forms & reports | `frontoffice.feedback.view` |
| Create forms | `frontoffice.feedback.create` |
| Public submit | No permission required |
