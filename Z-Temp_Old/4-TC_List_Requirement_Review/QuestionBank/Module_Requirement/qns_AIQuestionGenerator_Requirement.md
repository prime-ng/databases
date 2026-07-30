# AI Question Generator — Business Requirements

## What This Screen Does

The AI Question Generator screen lets teachers create questions automatically using artificial intelligence. Instead of typing each question manually, the teacher selects the topic, Bloom level, question type, and other parameters, and the AI generates multiple questions at once.

Think of it as having a teaching assistant who can draft questions based on your specifications — you tell it the subject, topic, difficulty, and how many questions you need, and it creates them for you. You can then review, edit, and save the questions to the question bank.

---

## When This Screen Is Used

- **Quick Question Creation** — When a teacher needs to quickly build a set of questions for an upcoming assessment
- **Growing the Question Bank** — To rapidly expand the question library with AI-drafted questions
- **Generating Practice Material** — To create extra practice questions for students
- **Idea Generation** — To get inspiration for question formats and difficulty levels

---

## Who Can Access This Screen

- **Teacher** — Can generate questions using AI
- **Head of Department** — Full access
- **School Admin** — Full access

All access is controlled by the permission `tenant.question-bank.create`.

**Note:** All AI Question Generator controller methods have `Gate::authorize('tenant.question-bank.create')` (see Rule 6). The FRD initially reported this as a P0 security gap, but the current code resolves it.

---

## How This Screen Works — Logic Flow (Non-Technical)

### The AI Generator Page

When a teacher opens the AI Question Generator, they see a form with these fields:

**Curriculum Selection:**
- **AI Provider** — OpenAI (ChatGPT) or Google (Gemini)
- **Class** — Select the target class
- **Section** — Optional section filter
- **Subject Group** — Select the subject group
- **Subject** — Automatically loaded based on subject group
- **Lesson** — Automatically loaded based on subject
- **Topic** — Automatically loaded based on lesson
- **Topic Level** — The depth level of the topic

**Question Specifications:**
- **Bloom's Taxonomy** — The cognitive level (Remember, Understand, Apply, Analyse, Evaluate, Create)
- **Complexity Level** — Easy, Medium, Hard, Very Hard
- **Cognitive Skill** — The specific mental process
- **Question Type Specificity** — Sub-classification within the question type
- **Question Type** — MCQ Single, MCQ Multi, etc.
- **Number of Questions** — How many questions to generate (1 to 20)
- **Additional Instructions** — Free text to guide the AI (e.g., "Focus on real-life applications")

### Generating Questions

When the teacher clicks "Generate," the system:
1. Validates all required fields (class, subject group, subject, lesson, topic, AI provider)
2. Builds a detailed prompt incorporating the curriculum context, taxonomy, and question specifications
3. Calls the selected AI provider's API (OpenAI or Gemini) with a 120-second timeout
4. Parses the AI response (CSV format with pipe-delimited columns) into individual questions
5. Returns the generated questions to the teacher for review

The generated questions appear in a preview section where the teacher can see each question with its options, correct answer, and suggested taxonomy tags.

### Saving Generated Questions

The teacher reviews each generated question and can:
- Edit the question content, options, correct answer, and taxonomy before saving
- Remove unwanted questions
- Click "Save Selected" to save the approved questions to the question bank

When saving, the system:
1. Validates each question (content, options, correct answer, curriculum fields)
2. Creates the question with status = DRAFT and created_by_AI = 1
3. Finds the appropriate competency for the class/subject
4. Creates all 4 answer options (A, B, C, D)
5. Returns the list of created question IDs

### Provider Status Check

Teachers can check whether an AI provider is available and configured before attempting to generate questions. The `checkProviderStatus` endpoint verifies the provider's active status and configuration.

### CSV Download

Generated questions can be downloaded as a CSV file for offline review or batch processing.

### AI Provider Listing

The `getAIProviders` endpoint returns the list of active AI providers (OpenAI / Gemini) with their display name and default model. This powers the AI Provider dropdown on the generator form.

---

## Business Rules and Conditions

### Rule 1: Question Count (No Server Validation — Known Gap)
The `number_of_question_id` field is accepted by `generateQuestions()` but has **no server-side range validation** (1–20). It defaults to 10 in `buildAIPrompt()`. Any 1–20 enforcement exists client-side only.

### Rule 2: AI-Generated Flag
All questions created through the AI generator are marked with `created_by_AI = 1`. This flag triggers the mandatory review gate (see Question Review requirements).

### Rule 3: Provider Configuration
The AI provider's API key is read from the server configuration (config/services.php). If the key is not configured, the generation fails with an appropriate error message. The current implementation reads keys directly from `env()` which is a known security gap.

### Rule 4: API Timeout
The AI provider API call has a 120-second timeout. If the provider does not respond within this time, the generation fails.

### Rule 5: Demo Data Stub (Known Gap — All Downstream AI Code Is Dead)
The `generateQuestions()` method has `return $this->getDemoResponse($request);` at line 232 as the first executable statement, causing an immediate return of 4 hardcoded demo questions. **All real AI code after this line** — provider selection, prompt building, API calls (`callChatGPT`, `callGemini`), response parsing, and prompt logging — **is dead code** and never executes. This is a known P0 gap.

### Rule 6: Gate Coverage — All Methods Authorized
All 11 public methods in the AIQuestionGeneratorController (`index`, `getSections`, `getSubjectGroups`, `getSubjects`, `getLessons`, `getTopics`, `generateQuestions`, `saveQuestions`, `getAIProviders`, `checkProviderStatus`, `downloadCSV`) have `Gate::authorize('tenant.question-bank.create')`. Note that the FRD reported this as a P0 gap (zero authorization), but the current code shows all methods are gated.

### Rule 7: MCQ Single Default
When saving AI-generated questions, if no question_type_id is provided, the system defaults to MCQ_SINGLE as the question type.

### Rule 8: Curriculum Competency Resolution
When saving, the system automatically finds the first competency matching the question's class_id and subject_id and assigns it to the question.

### Rule 9: `correct_answer` Not Persisted as DB Column
The `correct_answer` field is validated during save but is **not in the `qns_questions_bank` table's schema** and is **not in the `$fillable` array of the `QuestionBank` model**. The correct/incorrect state is stored only via each option's `is_correct` flag. The `correct_answer` value passed to `QuestionBank::create()` is silently dropped during mass assignment.

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| Count Limit | No server validation; client-side only (known gap) |
| AI Flag | All AI-generated questions marked with created_by_AI = 1 |
| API Key | Provider key read from server config |
| 120s Timeout | API call times out after 120 seconds |
| Demo Data Stub | Returns demo data; all real AI code is dead (P0 gap) |
| Gate Coverage | All 11 methods have Gate::authorize() (FRD-reported gap now resolved in code) |
| MCQ Default | Questions default to MCQ_SINGLE type |
| Auto-Competency | Competency auto-assigned from class/subject |
| correct_answer | Not a DB column; stored via option is_correct flag (known gap) |
| AI Provider Listing | getAIProviders endpoint populates the provider dropdown |

---

## Validate Before Save — Error Messages

| Scenario | Error Message |
|----------|--------------|
| Missing class | "The class id field is required." |
| Missing subject group | "The subject group id field is required." |
| Missing subject | "The subject id field is required." |
| Missing lesson | "The lesson id field is required." |
| Missing topic | "The topic id field is required." |
| Invalid AI provider | "The selected ai provider is invalid." |
| AI provider not available | "Selected AI provider is not available." |
| Question content missing (save) | "The questions.0.question field is required." |
| Correct answer invalid (save) | "The questions.0.correct answer must be one of A, B, C, D." |
| Option content empty for correct answer (save) | "Option X is marked as correct but has no content." |
| Invalid correct answer letter (save) | "Invalid correct answer: X" |

---

## Success Scenarios

- A teacher selects Class 9, Subject = Biology, Topic = Photosynthesis, Bloom Level = Understand, Complexity = Medium, Question Type = MCQ Single, Count = 10. The system calls the AI provider (once the demo data stub is removed), generates 10 MCQ questions about photosynthesis, and displays them for the teacher to review and save.

---

## Failure Scenarios

- A teacher tries to use the AI generator without the "Use AI Generator" permission. The system returns 403 Forbidden.

---

## Example Scenario

Ms. Sharma wants to create 5 MCQ questions about the Indian Constitution for her Class 10 Civics class.

She opens the AI Question Generator, selects:
- Provider: ChatGPT
- Class: 10, Section: A
- Subject Group: Social Studies
- Subject: Civics
- Lesson: The Indian Constitution
- Topic: Fundamental Rights
- Bloom Level: Understand (Level 2)
- Complexity: Medium
- Question Type: MCQ Single
- Count: 5

She clicks "Generate." The system (once fixed) sends the request to OpenAI, receives 5 questions, and displays them in the preview. She reviews each question:
- Question 1: "Which of the following is a Fundamental Right?" — Correct
- Question 2: "What does Article 21 guarantee?" — Correct
- Question 3: "Who can amend the Constitution?" — Needs editing, options too similar
- Question 4: "How many Fundamental Rights were originally in the Constitution?" — Has a wrong answer marked as correct
- Question 5: "Which article abolishes untouchability?" — Correct

She edits Question 3 and 4, removes the wrong correct answer from Question 4, and clicks "Save Selected" for all 5 questions. The system creates 5 questions with status = DRAFT and created_by_AI = 1. She then goes to the Question Bank to review and submit them for the standard review workflow.

---

## Related Screens

- **Question Bank** — Where AI-generated questions appear for review and editing
- **Question Review** — Where AI-generated questions must go through the mandatory review process
- **Question Statistics** — Where AI-generated question performance can be tracked later

---

## Dependencies module and tables

| Module | Tables |
|--------|--------|
| QuestionBank Core | `qns_questions_bank` (created questions), `qns_question_options` (AI-generated options) |
| Syllabus | `slb_bloom_taxonomy`, `slb_cognitive_skill`, `slb_complexity_level`, `slb_question_types`, `slb_ques_type_specificity`, `slb_lessons`, `slb_topics`, `slb_competencies` |
| School Setup | `sch_classes`, `sch_subjects`, `sch_sections`, `sch_subject_groups`, `sch_subject_group_subject_jnt` |
| External | OpenAI (GPT-4o-mini), Google Gemini (2.0 Flash) |
