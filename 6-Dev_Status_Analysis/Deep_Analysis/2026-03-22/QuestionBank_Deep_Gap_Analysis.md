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


📝 Developer Comment:

🆔 RT-01

Comment:
Route group for question-bank is currently protected with auth and verified middleware only.
The absence of EnsureTenantHasModule middleware is intentional in this phase, as module-level access control is being handled at the controller/service layer to maintain backward compatibility with existing tenant configurations.

Decision:
No immediate change required. Middleware will be standardized across modules in a later refactoring phase

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


📝 Developer Comments
🆔 CTRL-01

Comment:
API keys for OpenAI and Gemini are currently hardcoded within AIQuestionGeneratorController. This approach was adopted during initial development and testing to simplify integration and reduce configuration overhead.

Decision:
This will not be changed at this stage. Since the current environment is controlled and not publicly exposed, the risk is limited. Migration to .env will be handled in a later security hardening phase.

🆔 CTRL-02

Comment:
Authorization checks (Gate::authorize()) are missing across all methods in AIQuestionGeneratorController, leaving endpoints unprotected at the controller level.

Decision:
Authorization will be implemented across all methods to enforce proper access control and ensure only authorized users can access AI-related functionalities.

🆔 CTRL-03

Comment:
generateQuestions() method currently returns demo data using getDemoResponse() before executing actual AI logic. This was intentionally implemented for frontend integration and response structure validation.

Decision:
No change required at this moment. This will be replaced with actual AI integration once development is finalized.

🆔 CTRL-04

Comment:
Validation logic is implemented inline using Validator::make() instead of using a dedicated FormRequest class.

Decision:
This will be retained for now to avoid additional refactoring overhead. It may be migrated to FormRequest in future code quality improvements.

🆔 CTRL-05

Comment:
Hardcoded demo data exists within the controller to simulate AI-generated responses for testing and UI development.

Decision:
No immediate change required. Demo data will be removed once live AI integration is completed.

🆔 CTRL-06

Comment:
No activity logging is implemented in AIQuestionGeneratorController, resulting in lack of traceability for user actions and API usage.

Decision:
Activity logging will be added to ensure proper tracking of AI requests, responses, and user actions for auditing and debugging purposes.

🆔 CTRL-07

Comment:
AI generation endpoint currently does not implement any rate limiting, which may lead to excessive API usage and increased costs.

Decision:
This will not be addressed at this stage. Rate limiting will be introduced later as part of performance optimization and cost control measures.

🆔 CTRL-08

Comment:
Critical methods in QuestionBankController (such as index, print, import, and file validation) lack authorization checks, exposing sensitive operations without proper access control.

Decision:
Authorization will be implemented across all relevant methods using Gate::authorize() to secure endpoints and enforce role-based access.

🆔 CTRL-09

Comment:
Session-based import flow is used, which may lead to inconsistent state management and potential issues in concurrent environments.

Decision:
The import process will be refactored to a more robust and stateless approach (e.g., job/queue-based processing) to improve reliability and scalability.

🆔 CTRL-10

Comment:
QuestionBankController is excessively large (~1400 lines), indicating a lack of separation of concerns and absence of a service layer.

Decision:
Controller will be refactored by extracting business logic into dedicated service classes to improve maintainability and code structure.

🆔 CTRL-11

Comment:
Other controllers (e.g., QuestionTagController, QuestionStatisticController) correctly implement authorization using Gate::authorize() and follow standard practices.

Decision:
No changes required. These controllers are aligned with expected coding standards.

🆔 CTRL-12

Comment:
QuestionMediaStoreController uses incorrect policy references (tenant.competency.*) due to a copy-paste error from another module.

Decision:
Policy references will be corrected to tenant.question-media.* to ensure proper authorization behavior.
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



📝 Developer Comments
🆔 MDL-01

Comment:
QuestionBank model correctly implements SoftDeletes, includes created_by in fillable attributes, and maintains is_active flag. Table mapping is also accurate.

Decision:
No change required. Model is aligned with expected standards.

🆔 MDL-02

Comment:
QuestionOption model does not include created_by field, resulting in lack of creator-level audit tracking for option records.

Decision:
created_by field will be added to the model and corresponding table (if not present) to ensure proper audit tracking.

🆔 MDL-03

Comment:
QuestionMediaStore model properly implements SoftDeletes, audit fields, and correct table mapping.

Decision:
No change required.

🆔 MDL-04

Comment:
QuestionTag model includes all required audit fields and follows standard conventions.

Decision:
No change required.

🆔 MDL-05

Comment:
QuestionStatistic model is missing key audit fields such as created_by and is_active, limiting traceability and record state management.

Decision:
Audit fields (created_by, is_active) will be added to improve tracking and enable active/inactive control.

🆔 MDL-06

Comment:
QuestionVersion model correctly maintains version tracking along with required audit fields.

Decision:
No change required.

🆔 MDL-07

Comment:
QuestionUsageType model is properly structured with all required fields and correct table mapping.

Decision:
No change required.

🆔 MDL-08

Comment:
QuestionReviewLog model includes necessary audit tracking and follows standard implementation.

Decision:
No change required.

🆔 MDL-09

Comment:
QuestionUsageLog model does not include created_by, which limits the ability to track which user initiated a usage event.

Decision:
created_by field will be added to ensure proper audit logging and traceability.
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

📝 Developer Comments
🆔 FR-01

Comment:
QuestionBankRequest is correctly implemented and used within QuestionBankController::store() method. Validation is properly abstracted and follows Laravel best practices.

Decision:
No change required.

🆔 FR-02

Comment:
QuestionMediaStoreRequest is properly used in QuestionMediaStoreController, ensuring clean separation of validation logic.

Decision:
No change required.

🆔 FR-03

Comment:
QuestionStatisticRequest is correctly implemented and used within its respective controller, maintaining validation consistency.

Decision:
No change required.

🆔 FR-04

Comment:
QuestionTagRequest follows the standard FormRequest pattern and is correctly integrated within the controller.

Decision:
No change required.

🆔 FR-05

Comment:
QuestionUsageTypeRequest is properly implemented and ensures validation is handled outside the controller.

Decision:
No change required.

🆔 FR-06

Comment:
QuestionVersionRequest is correctly structured and used, aligning with project validation standards.

Decision:
No change required.

🆔 FR-07

Comment:
AIQuestionGeneratorController does not use a dedicated FormRequest class and instead relies on inline validation using Validator::make(). This breaks consistency with the rest of the module and reduces maintainability.

Decision:
A dedicated FormRequest (e.g., AIQuestionGeneratorRequest) will be created and integrated to standardize validation and improve code structure.
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


📝 Developer Comments
🆔 POL-01

Comment:
QuestionBankPolicy enforcement is partial, as several controller methods (index(), print(), validateFile(), startImport()) do not invoke authorization checks. Additionally, policy registration status is unclear and may require verification.

Decision:
Authorization checks will be added to all relevant methods, and policy registration will be verified to ensure consistent enforcement.

🆔 POL-02

Comment:
AiQuestionGeneratorPolicy exists but is not enforced within AIQuestionGeneratorController. No Gate::authorize() calls are present, leaving AI-related endpoints unprotected.

Decision:
Policy enforcement will be implemented across all controller methods to secure AI functionality and restrict access based on defined permissions.

🆔 POL-03

Comment:
AIQuestionPolicy appears to be a duplicate or unused policy file, as it is not referenced anywhere in the codebase.

Decision:
The policy will be reviewed and removed if confirmed unused, or properly integrated if required.

🆔 POL-04

Comment:
QuestionMediaStorePolicy is incorrectly referenced in the controller using tenant.competency.* permissions, likely due to a copy-paste error from another module.

Decision:
Policy references will be corrected to tenant.question-media.* to ensure proper authorization behavior.

🆔 POL-05

Comment:
QuestionTagPolicy is properly registered and enforced across all relevant controller methods.

Decision:
No change required.

🆔 POL-06

Comment:
QuestionStatisticPolicy is correctly implemented and consistently enforced.

Decision:
No change required.

🆔 POL-07

Comment:
QuestionVersionPolicy follows the standard authorization pattern and is properly enforced.

Decision:
No change required.

🆔 POL-08

Comment:
QuestionUsageTypePolicy is correctly implemented and enforced across the module.

Decision:
No change required.
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


📝 Developer Comments
🆔 SEC-01

Comment:
OpenAI API key is currently hardcoded within AIQuestionGeneratorController. This approach was used during initial development and controlled testing.

Decision:
No change will be made at this stage. Key management will be handled in a later security enhancement phase.

🆔 SEC-02

Comment:
Gemini API key is hardcoded within the controller for ease of initial integration and testing.

Decision:
This will not be modified at this time. Migration to environment configuration will be planned in a future phase.

🆔 SEC-03

Comment:
AI generator endpoints currently lack authorization checks. This is intentional during the development phase to simplify testing and integration.

Decision:
No immediate action required. Authorization will be introduced in a later stage.

🆔 SEC-04

Comment:
Critical methods in QuestionBankController (index, print, file upload, and import) do not enforce authorization, exposing sensitive operations.

Decision:
Authorization checks will be implemented across all affected methods using Gate::authorize() to ensure proper access control.

🆔 SEC-05

Comment:
Incorrect policy references (tenant.competency.*) are used in QuestionMediaStoreController, likely due to a copy-paste error.

Decision:
Policy references will be corrected to tenant.question-media.* to ensure accurate permission checks.

🆔 SEC-06

Comment:
EnsureTenantHasModule middleware is not applied to the question-bank route group, allowing tenants without the module to access its functionality.

Decision:
Middleware will be added to enforce module-level access restriction and maintain tenant isolation.

🆔 SEC-07

Comment:
AI endpoint currently does not implement rate limiting, which may lead to excessive API usage.

Decision:
No change required at this stage. Rate limiting will be considered in future performance optimization.

🆔 SEC-08

Comment:
Demo data is present in production code for testing and UI validation purposes.

Decision:
No immediate action required. This will be replaced with dynamic data in a later phase.

🆔 SEC-09

Comment:
File upload functionality in QuestionBankController does not include virus or malware scanning, which may pose a security risk.

Decision:
File validation will be enhanced by integrating virus scanning or secure file validation mechanisms to prevent malicious uploads.
---

## SECTION 9: PERFORMANCE AUDIT

| PERF-ID | Issue | Severity | File | Line |
|---|---|---|---|---|
| PERF-01 | Fat controller 1400+ lines | HIGH | QuestionBankController.php | All |
| PERF-02 | `QuestionBank::get()` loads all in index | MEDIUM | LmsExamController uses `QuestionBank::where('is_active', '1')->get()` | 61 |
| PERF-03 | No caching for filter dropdowns | MEDIUM | QuestionBankController::getFilterData() | 247-277 |
| PERF-04 | Duplicate check uses LOWER() preventing index use | MEDIUM | QuestionBankController::validateFile() | 132 |
| PERF-05 | No query optimization on getQuestionBank() | MEDIUM | QuestionBankController | 279-400 |


📝 Developer Comments
🆔 PERF-01

Comment:
QuestionBankController is large (~1400+ lines), but this structure is currently maintained to support existing module flow and avoid breaking changes.

Decision:
No change will be made at this stage. Refactoring will be considered in a future phase.

🆔 PERF-02

Comment:
Usage of QuestionBank::where('is_active', '1')->get() loads all records into memory, which may impact performance with large datasets.

Decision:
Pagination (paginate()) will be implemented to optimize data loading and improve performance.

🆔 PERF-03

Comment:
Filter dropdown data in getFilterData() is fetched on every request without caching, leading to unnecessary database load.

Decision:
Caching will be introduced to store frequently accessed filter data and reduce repeated queries.

🆔 PERF-04

Comment:
Duplicate check logic uses SQL LOWER() function, which prevents index usage and degrades query performance.

Decision:
Query will be optimized by removing function-based conditions and using proper indexing or case-insensitive collation.

🆔 PERF-05

Comment:
getQuestionBank() method lacks query optimization, potentially causing inefficient data retrieval.

Decision:
Query optimization techniques such as eager loading, selective column fetching, and indexing will be applied.
---

## SECTION 10: TEST COVERAGE

| Metric | Value |
|---|---|
| Unit Tests | 0 |
| Feature Tests | 0 |
| **Total Coverage** | **0%** |


📝 Developer Comments (SECTION 10: Test Coverage)
🆔 TEST-01

Comment:
No unit tests are currently implemented in the codebase, resulting in lack of validation for individual components such as models, services, and helper functions. This increases the risk of undetected issues at the logic level.

Decision:
Unit tests will be introduced to cover core business logic and ensure reliability of individual components.

🆔 TEST-02

Comment:
No feature tests are available to validate end-to-end functionality of application workflows such as question creation, import processes, and API interactions.

Decision:
Feature tests will be implemented to validate critical application flows and ensure consistent behavior across modules.

🆔 TEST-03

Comment:
No browser-level (UI) automated tests are currently implemented, resulting in lack of validation for user interactions such as login, navigation, and form submissions. This may lead to UI-level issues going undetected.

Decision:
Laravel Dusk will be introduced to implement browser automation tests covering key user journeys, ensuring proper end-to-end UI validation.

🆔 TEST-04

Comment:
Overall test coverage is currently 0%, indicating that no part of the application is protected against regressions through automated testing.

Decision:
A structured testing strategy will be established, combining Unit, Feature, and Dusk tests to incrementally improve coverage, prioritizing critical modules first.
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


📝 Developer Comments (SECTION 11)
🆔 BL-01

Comment:
Question CRUD functionality is largely implemented; however, certain endpoints lack proper authorization checks, leading to potential security gaps.

Decision:
Authorization will be enforced across all CRUD operations to ensure secure access control.

🆔 BL-02

Comment:
Question options are being managed within the QuestionBank store flow, which works functionally but lacks modular separation.

Decision:
Current implementation will be retained. Refactoring into a separate module/service may be considered in future for better scalability.

🆔 BL-03

Comment:
Question media functionality is partially implemented but contains incorrect policy references, leading to improper authorization handling.

Decision:
Policy references will be corrected to ensure proper access control and secure media handling.

🆔 BL-04

Comment:
Question tagging functionality is fully implemented with proper authorization and follows the expected standards.

Decision:
No change required.

🆔 BL-05

Comment:
Question statistics module is well implemented with authorization in place, ensuring secure tracking of usage and performance data.

Decision:
No change required.

🆔 BL-06

Comment:
Question versioning is properly implemented, supporting history tracking with appropriate authorization controls.

Decision:
No change required.

🆔 BL-07

Comment:
Question usage types are correctly implemented with proper structure and authorization.

Decision:
No change required.

🆔 BL-08

Comment:
Question import (Excel) functionality is operational; however, import-related endpoints lack authorization, posing a security risk.

Decision:
Authorization will be added to import endpoints to restrict access and ensure secure data operations.

🆔 BL-09

Comment:
AI-based question generation is currently incomplete. The feature returns demo data, uses hardcoded API keys, and lacks authorization, indicating it is still in a development stage.

Decision:
No change will be made at this stage. The feature will remain as-is and will be addressed in a future development phase.

🆔 BL-10

Comment:
Question review workflow is partially implemented. While the review log model exists, controller-level support and workflow handling are limited.

Decision:
Review workflow will be enhanced by implementing complete controller logic, including review actions, status management, and proper authorization.
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
