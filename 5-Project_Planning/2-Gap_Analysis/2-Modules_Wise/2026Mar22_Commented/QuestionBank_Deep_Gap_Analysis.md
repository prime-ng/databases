# QuestionBank Module - Deep Gap Analysis Report
**Date:** 2026-03-22 | **Branch:** Brijesh_SmartTimetable | **Auditor:** Senior Laravel Architect (AI)

---

## EXECUTIVE SUMMARY

| Metric | Value |
|---|---|
| **Overall Readiness** | 45% |
| **Critical Issues** | 6 |
| **High Issues** | 10 |
| **Medium Issues** | 12 |
| **Low Issues** | 7 |
| **Estimated Fix Effort** | 10-12 developer days |

The QuestionBank module has a **CRITICAL security vulnerability**: OpenAI and Gemini API keys are hardcoded in the AIQuestionGeneratorController source code (lines 55-57). The AI generator controller has ZERO authorization. The `generateQuestions()` method immediately returns demo data (line 224), bypassing all AI logic. No Service layer exists. No `EnsureTenantHasModule` middleware. No tests.

---

## SECTION 1: DATABASE INTEGRITY

### 1.1 DDL Tables (tenant_db_v2.sql)
Tables with `qns_` prefix:
- `qns_questions_bank` (line 5209)
- `qns_question_options` (line 5297)
- `qns_question_media_jnt` (line 5313)
- `qns_question_tags` (line 5333)
- `qns_question_questiontag_jnt` (line 5346)
- `qns_question_versions` (line 5360)
- `qns_media_store` (line 5376)
- `qns_question_topic_jnt` (line 5397)
- `qns_question_statistics` (line 5413)
- `qns_question_performance_category_jnt` (line 5432)
- `qns_question_usage_log` (line 5452)
- `qns_question_review_log` (line 5468)
- `qns_question_usage_type` (line 5487)

### 1.2 Model Coverage
All 13 DDL tables have corresponding models. No missing models detected.

---

## SECTION 2: ROUTE INTEGRITY

### 2.1 Route Group
- **File:** `/routes/tenant.php` line 962
- **Prefix:** `question-bank`
- **Name prefix:** `question-bank.`
- **Middleware:** `['auth', 'verified']`

### 2.2 Missing Middleware
| Issue | Severity | File | Line |
|---|---|---|---|
| **No `EnsureTenantHasModule` middleware** | CRITICAL | `/routes/tenant.php` | 962 |

---

## SECTION 3: CONTROLLER AUDIT

### 3.1 AIQuestionGeneratorController
**File:** `/Modules/QuestionBank/app/Http/Controllers/AIQuestionGeneratorController.php`

| Issue | Severity | Line | Description |
|---|---|---|---|
| **HARDCODED API KEYS** | CRITICAL | 55-57 | OpenAI key: `sk-proj-KimXs0Dn-vomC2K6kc3ooP9K...` and Gemini key: `AIzaSyD-UVS7sEjn79TuvA3sxeFlGTjD_xaUhKY` are hardcoded as class properties. These MUST be moved to `.env` immediately. |
| **ZERO authorization on ALL methods** | CRITICAL | All | No `Gate::authorize()` on index(), getSections(), getSubjectGroups(), getSubjects(), getLessons(), getTopics(), generateQuestions() |
| **generateQuestions() returns demo data** | HIGH | 224 | `return $this->getDemoResponse($request);` is called before any real AI logic. Dead code from line 226 onward. |
| **Inline Validator instead of FormRequest** | MEDIUM | 206 | Uses `Validator::make($request->all(), ...)` instead of FormRequest class |
| **Demo data hardcoded** | MEDIUM | 302-393 | `getDemoResponse()` returns hardcoded question data - should not exist in production |
| **No activity logging** | HIGH | All | No `activityLog()` calls |
| **No rate limiting** | HIGH | 202 | AI generation endpoint has no rate limiting, could cause excessive API costs |

### 3.2 QuestionBankController
**File:** `/Modules/QuestionBank/app/Http/Controllers/QuestionBankController.php`

| Issue | Severity | Line | Description |
|---|---|---|---|
| **index() has NO authorization** | HIGH | 55-66 | No `Gate::authorize()` call. The main listing page is unprotected. |
| **print() has NO authorization** | HIGH | 71-80 | Print endpoint unprotected |
| **validateFile() has NO authorization** | HIGH | 82-191 | File upload endpoint unprotected |
| **startImport() has NO authorization** | HIGH | 193-221 | Import endpoint unprotected |
| **getQuestionBank() has NO authorization** | HIGH | 279 | Public method returns all questions without auth |
| **Session-based import flow** | MEDIUM | 193-221 | Same session-state vulnerability as Syllabus module |
| **Fat controller** | MEDIUM | All | 1400+ lines, no Service layer |

### 3.3 Other Controllers (QuestionTagController, QuestionStatisticController, etc.)
These controllers properly use `Gate::authorize()` on all CRUD methods. They follow the standard pattern.

### 3.4 QuestionMediaStoreController
**File:** `/Modules/QuestionBank/app/Http/Controllers/QuestionMediaStoreController.php`

| Issue | Severity | Line | Description |
|---|---|---|---|
| **Wrong policy references** | HIGH | 25, 42, 54, etc. | Uses `Gate::authorize('tenant.competency.*')` instead of `tenant.question-media.*`. Copy-paste error from Syllabus module. |

---

## SECTION 4: MODEL AUDIT

| Model | SoftDeletes | created_by | is_active | Table Match | Issues |
|---|---|---|---|---|---|
| QuestionBank | YES | YES (fillable) | YES | qns_questions_bank | OK |
| QuestionOption | YES | NO | YES | qns_question_options | Missing created_by |
| QuestionMediaStore | YES | YES | YES | qns_media_store | OK |
| QuestionTag | YES | YES | YES | qns_question_tags | OK |
| QuestionStatistic | YES | NO | NO | qns_question_statistics | Missing audit fields |
| QuestionVersion | YES | YES | YES | qns_question_versions | OK |
| QuestionUsageType | YES | YES | YES | qns_question_usage_type | OK |
| QuestionReviewLog | YES | YES | YES | qns_question_review_log | OK |
| QuestionUsageLog | YES | NO | YES | qns_question_usage_log | Missing created_by |

---

## SECTION 5: SERVICE LAYER AUDIT

| Issue | Severity | Description |
|---|---|---|
| **No Service classes exist** | HIGH | Zero Services directory. QuestionBankController is 1400+ lines. |
| **No AIService abstraction** | HIGH | AI provider logic is embedded directly in controller |

---

## SECTION 6: FORM REQUEST AUDIT

| FormRequest | Used By | Issues |
|---|---|---|
| QuestionBankRequest | QuestionBankController::store() | OK, used correctly |
| QuestionMediaStoreRequest | QuestionMediaStoreController | OK |
| QuestionStatisticRequest | QuestionStatisticController | OK |
| QuestionTagRequest | QuestionTagController | OK |
| QuestionUsageTypeRequest | QuestionUsageTypeController | OK |
| QuestionVersionRequest | QuestionVersionController | OK |

**Missing:** No FormRequest for AIQuestionGeneratorController (uses inline Validator).

---

## SECTION 7: POLICY AUDIT

| Policy | Registered | Enforced | Issues |
|---|---|---|---|
| QuestionBankPolicy | Unknown | Partially | index(), print(), validateFile(), startImport() bypass auth |
| AiQuestionGeneratorPolicy | Exists | NOT enforced | AIQuestionGeneratorController has zero Gate calls |
| AIQuestionPolicy | Exists | NOT enforced | Duplicate policy file, likely dead code |
| QuestionMediaStorePolicy | Exists | WRONG refs | Controller uses `tenant.competency.*` instead of correct policy |
| QuestionTagPolicy | Exists | Enforced | OK |
| QuestionStatisticPolicy | Exists | Enforced | OK |
| QuestionVersionPolicy | Exists | Enforced | OK |
| QuestionUsageTypePolicy | Exists | Enforced | OK |

---

## SECTION 8: SECURITY AUDIT

| SEC-ID | Issue | Severity | File | Line |
|---|---|---|---|---|
| SEC-01 | **HARDCODED OpenAI API KEY** | CRITICAL | AIQuestionGeneratorController.php | 55 |
| SEC-02 | **HARDCODED Gemini API KEY** | CRITICAL | AIQuestionGeneratorController.php | 56-57 |
| SEC-03 | Zero auth on AI generator | CRITICAL | AIQuestionGeneratorController.php | All |
| SEC-04 | Zero auth on QuestionBank index/print/import | CRITICAL | QuestionBankController.php | 55, 71, 82, 193 |
| SEC-05 | Wrong policy references (competency) | HIGH | QuestionMediaStoreController.php | 25+ |
| SEC-06 | No EnsureTenantHasModule | CRITICAL | tenant.php | 962 |
| SEC-07 | No rate limiting on AI endpoint | HIGH | AIQuestionGeneratorController.php | 202 |
| SEC-08 | Demo data in production code | MEDIUM | AIQuestionGeneratorController.php | 302-393 |
| SEC-09 | File upload without virus scan | LOW | QuestionBankController.php | 82 |

---

## SECTION 9: PERFORMANCE AUDIT

| PERF-ID | Issue | Severity | File | Line |
|---|---|---|---|---|
| PERF-01 | Fat controller 1400+ lines | HIGH | QuestionBankController.php | All |
| PERF-02 | `QuestionBank::get()` loads all in index | MEDIUM | LmsExamController uses `QuestionBank::where('is_active', '1')->get()` | 61 |
| PERF-03 | No caching for filter dropdowns | MEDIUM | QuestionBankController::getFilterData() | 247-277 |
| PERF-04 | Duplicate check uses LOWER() preventing index use | MEDIUM | QuestionBankController::validateFile() | 132 |
| PERF-05 | No query optimization on getQuestionBank() | MEDIUM | QuestionBankController | 279-400 |

---

## SECTION 10: TEST COVERAGE

| Metric | Value |
|---|---|
| Unit Tests | 0 |
| Feature Tests | 0 |
| **Total Coverage** | **0%** |

---

## SECTION 11: BUSINESS LOGIC COMPLETENESS

| Feature | Status | Notes |
|---|---|---|
| Question CRUD | 85% | Works but auth gaps on some endpoints |
| Question Options | 85% | Managed within QuestionBank store |
| Question Media | 70% | Wrong policy references |
| Question Tags | 95% | Fully implemented with auth |
| Question Statistics | 90% | Auth present |
| Question Versions | 90% | Auth present |
| Question Usage Types | 90% | Auth present |
| Question Import (Excel) | 80% | Works but no auth on import endpoints |
| AI Question Generation | 10% | Returns demo data only, hardcoded keys, zero auth |
| Question Review Workflow | 60% | Review log model exists but limited controller support |

---

## PRIORITY FIX PLAN

### P0 - CRITICAL (Fix Immediately - Security Emergency)
1. **REMOVE HARDCODED API KEYS** from AIQuestionGeneratorController lines 55-57. Move to `.env` file as `OPENAI_API_KEY` and `GEMINI_API_KEY`. Use `config('services.openai.key')`.
2. **Rotate compromised API keys** - The OpenAI and Gemini keys in source code MUST be considered compromised and regenerated.
3. **Add Gate::authorize() to AIQuestionGeneratorController** - ALL methods need authorization
4. **Add Gate::authorize() to QuestionBankController** - index(), print(), validateFile(), startImport()
5. **Add `EnsureTenantHasModule` middleware** to question-bank route group

### P1 - HIGH (Fix Before Release)
6. **Fix QuestionMediaStoreController policy references** - Replace `tenant.competency.*` with `tenant.question-media.*`
7. **Remove demo data** from AIQuestionGeneratorController::getDemoResponse()
8. **Remove dead code** after `return $this->getDemoResponse()` in generateQuestions()
9. **Add rate limiting** to AI generation endpoint
10. **Add activity logging** to AIQuestionGeneratorController and QuestionBankController
11. **Create Service layer** - QuestionBankService, AIQuestionService

### P2 - MEDIUM
12. Replace inline Validator with FormRequest in AIQuestionGeneratorController
13. Add virus scanning for file uploads
14. Optimize duplicate check query (use hash index)
15. Add caching for filter dropdowns

### P3 - LOW
16. Write comprehensive tests (minimum 50 test cases)
17. Refactor QuestionBankController (1400+ lines) into smaller focused controllers
18. Remove duplicate AIQuestionPolicy / AiQuestionGeneratorPolicy

---

## EFFORT ESTIMATION

| Priority | Items | Estimated Hours |
|---|---|---|
| P0 - Critical | 5 items | 6-8 hours |
| P1 - High | 6 items | 20-28 hours |
| P2 - Medium | 4 items | 8-12 hours |
| P3 - Low | 3 items | 24-32 hours |
| **Total** | **18 items** | **58-80 hours (10-12 dev days)** |
