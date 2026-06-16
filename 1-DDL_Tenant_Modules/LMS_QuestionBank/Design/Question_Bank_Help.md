## 4. Question Bank Management

### `sch_questions`
**Purpose:** The central repository for all assessment items.
- **Key Fields:**
  - `stem`: The actual question text.
  - `is_school_specific`: If true, only visible to this school. *Usage: Privacy for custom questions.*
  - `visibility`: 'GLOBAL', 'SCHOOL_ONLY', 'PRIVATE'.
  - `book_page_ref`: Links question to a textbook page. *Usage: "Read page 45 to answer this".*
- **Application Workflow:**
  - **Question Bank:** Teachers search/filter these to build quizzes.

### `sch_question_options`
**Purpose:** Choices for MCQ-style questions.
- **Key Fields:**
  - `is_correct`: Boolean.
  - `feedback`: Explanation shown if chosen.
- **Application Workflow:** Displayed as selectable options in the exam interface.

### `sch_question_media`
**Purpose:** Images/Audio/Video attached to questions.
- **Application Workflow:** Displaying a diagram for a Geometry question.

### `sch_question_tags` & `sch_question_tag_jnt`
**Purpose:** Flexible tagging (e.g., "Competitive Exam", "Olympiad").
- **Application Workflow:** Advanced search filters in Question Bank.

### `sch_question_versions`
**Purpose:** Tracks history of changes to a question.
- **Key Fields:**
  - `data`: JSON snapshot.
- **Application Workflow:** If a question had an error during an exam, admins can see exactly what the text was at that time.

### `sch_question_ownership`
**Purpose:** Manages sharing permissions for custom questions.
- **Application Workflow:** A teacher creates a question -> Principal approves it -> It becomes available to the whole school.

### `sch_question_pools` & `sch_question_pool_questions`
**Purpose:** Dynamic groups of questions (e.g., "Grade 10 Algebra Hard Pool").
- **Application Workflow:** An exam can pinpoint a "Pool" instead of specific questions, so every student gets a different random set from that pool.
