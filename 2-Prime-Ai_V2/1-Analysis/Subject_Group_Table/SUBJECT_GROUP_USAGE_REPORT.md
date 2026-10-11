# Subject Group & Subject Group Subject Module Usage Matrix

This document provides a comprehensive, module-by-module and screen-by-screen breakdown of all features across the system that consume:
1. **`SubjectGroup`** (Database Table: `sch_subject_groups`) — `Modules/SchoolSetup/app/Models/SubjectGroup.php`
2. **`SubjectGroupSubject`** (Database Table: `sch_subject_group_subject_jnt`) — `Modules/SchoolSetup/app/Models/SubjectGroupSubject.php`

*(Note: Standard CRUD screens in SchoolSetup for Subject Group and Subject Group Subject are excluded per request to focus strictly on consuming workflows and screens).*

---

## 1. Quick Reference Summary Table

| # | Module Name | Uses `SubjectGroup` | Uses `SubjectGroupSubject` | Consuming Screens & Features |
|---|---|:---:|:---:|---|
| 1 | **StudentProfile** | Yes | Yes | Student Directory List, Admission/Edit Session Tab, Missing Optional Subjects Chooser, Excel Export |
| 2 | **QuestionBank** | Yes | Yes | AI Question Generator, Question Media Store, Question Bank Reports |
| 3 | **LmsQuiz** | Yes | Yes | Quiz Question Creator, Quiz Management, Student Performance Reports |
| 4 | **LmsQuests** | Yes | Yes | Quest Question Creator, Gamified Quest Class Performance Reports |
| 5 | **LmsExam** | Yes | Yes | Question Paper Set Generator, LMS Exam Management |
| 6 | **LmsHomework** | Yes | Yes | Homework Assignment, Student Homework List, Homework Analytics Reports |
| 7 | **Admission** | Yes | Yes | Admission Screening Question Bank Filter |
| 8 | **Syllabus** | Yes | Yes | Lesson & Topic Planning, Syllabus Tracker, Extra Period Rules Configuration |
| 9 | **SyllabusBooks** | Yes | Yes | Textbook Allocation & Book Mapping Matrix |
| 10 | **SchoolSetup** *(Non-CRUD)* | Yes | Yes | Subject-Class Mapping Matrix, Employee Subject Group Allocation |
| 11 | **Ptm** | Yes | No (via relations) | Parent-Teacher Meeting Appointment & Subject Teacher Slot Generator |
| 12 | **ParentPortal & StudentPortal** | Yes | Yes | Parent Dashboard & Mobile Student Academic Schedule/Subject List |
| 13 | **SmartTimetable & TimetableFoundation** | Yes | No (Timetable Grouping) | Requirement Consolidation & Parallel Subject Group Activity Generator |
| 14 | **Dashboard** | Yes | No (Stats Query) | Admin Setup Statistics Dashboard Widget |

---

## 2. Detailed Breakdown by Module and Screen

### 1. StudentProfile Module
* **Screen 1: Student Management List / Directory**
  * **Blade View:** `Modules/StudentProfile/resources/views/student/student_list.blade.php`
  * **Controller:** `StudentController@index` (`Modules/StudentProfile/app/Http/Controllers/StudentController.php`)
  * **Description:** Provides a filter dropdown for `subject_group_id` allowing administrators to filter students belonging to specific subject streams/bundles.
* **Screen 2: Student Admission & Edit (Academic Session Tab)**
  * **Blade View:** `Modules/StudentProfile/resources/views/student/partials/create/student-details-tabs/_student-session.blade.php`
  * **Controller:** `StudentController@create`, `edit`, `store`, `update` (`Modules/StudentProfile/app/Http/Controllers/StudentController.php`)
  * **Description:** Allows assigning a `subject_group_id` to the student's academic session and storing opted subjects mapped in `sch_subject_group_subject_jnt`.
* **Screen 3: Missing Optional Subjects Management**
  * **Blade View:** `Modules/StudentProfile/resources/views/student/missing_optional_subjects_list.blade.php`
  * **Controller:** `StudentController@missingOptionalSubjects` (`Modules/StudentProfile/app/Http/Controllers/StudentController.php`)
  * **Description:** Cross-checks student enrollments against `SubjectGroupSubject` records to pinpoint students who have not finalized their optional subject choices.
* **Screen 4: Student Data Excel Export**
  * **Export Class:** `Modules/StudentProfile/app/Exports/StudentsExport.php`
  * **Description:** Filters exportable student datasets by selected `subject_group_id`.

---

### 2. QuestionBank Module
* **Screen 1: AI Question Generator**
  * **Blade View:** `Modules/QuestionBank/resources/views/ai-question-generator/index.blade.php` & `js.blade.php`
  * **Controller:** `AIQuestionGeneratorController` (`Modules/QuestionBank/app/Http/Controllers/AIQuestionGeneratorController.php`)
  * **Description:** Dynamically populates Subject Groups for selected Class/Section and loads subjects through `sch_subject_group_subject_jnt` to generate curriculum-aligned questions.
* **Screen 2: Question Media Store & Question Bank Reports**
  * **Controller:** `QuestionMediaStoreController` & `QuestionBankReportController` (`Modules/QuestionBank/app/Http/Controllers/`)
  * **Description:** Fetches active class subjects via `SubjectGroup::subjectsForClass()`.

---

### 3. LmsQuiz Module
* **Screen 1: Quiz Question Creation & Selection**
  * **Blade View:** `Modules/LmsQuiz/resources/views/quiz-question/create.blade.php`
  * **Controller:** `QuizQuestionController@getSubjectGroups` (`Modules/LmsQuiz/app/Http/Controllers/QuizQuestionController.php`)
  * **Description:** Loads active Subject Groups and subjects from `sch_subject_group_subject_jnt` during question authoring.
* **Screen 2: Quiz Management & Configuration**
  * **Controller:** `LmsQuizController` (`Modules/LmsQuiz/app/Http/Controllers/LmsQuizController.php`)
  * **Description:** Retrieves subject structure linked through `SubjectGroup`.
* **Screen 3: Quiz Student Performance Reports**
  * **Controller:** `LmsQuizReportController` (`Modules/LmsQuiz/app/Http/Controllers/LmsQuizReportController.php`)
  * **Description:** Filters student quiz performance and score distributions by Subject Group.

---

### 4. LmsQuests Module
* **Screen 1: Quest Question Creation**
  * **Blade View:** `Modules/LmsQuests/resources/views/quest-question/create.blade.php`
  * **Controller:** `QuestQuestionController@getSubjectGroups` (`Modules/LmsQuests/app/Http/Controllers/QuestQuestionController.php`)
  * **Description:** Resolves subject options by querying `sch_subject_group_subject_jnt` for gamified student quests.
* **Screen 2: Quest Class Performance & Analytics Reports**
  * **Blade View:** `Modules/LmsQuests/resources/views/reports/partials/class-performance.blade.php`
  * **Controller:** `QuestReportController` (`Modules/LmsQuests/app/Http/Controllers/QuestReportController.php`)
  * **Description:** Multi-level cascading filter by Subject Group for quest attempts and mastery level.

---

### 5. LmsExam Module
* **Screen: Question Paper Set Generator & Exam Management**
  * **Blade View:** `Modules/LmsExam/resources/views/paper-set-question/create.blade.php`
  * **Controller:** `PaperSetQuestionController@getSubjectGroups` & `LmsExamController` (`Modules/LmsExam/app/Http/Controllers/`)
  * **Description:** Employs AJAX selector `loadSubjectGroupsBySection` to filter exam questions and map test papers to subject groups.

---

### 6. LmsHomework Module
* **Screen: Homework Assignment, Submission & Homework Reports**
  * **Controller:** `LmsHomeworkController` & `HomeworkReportController` (`Modules/LmsHomework/app/Http/Controllers/`)
  * **Description:** Calls `SubjectGroup::subjectsForClass()` and joins `sch_subject_groups` to validate eligible subjects for assigned homework.

---

### 7. Admission Module
* **Screen: Admission Screening Question Bank**
  * **Blade View:** `Modules/Admission/resources/views/admission-questions/create.blade.php`
  * **Controller:** `AdmissionQuestionController@getSubjectGroups` (`Modules/Admission/app/Http/Controllers/AdmissionQuestionController.php`)
  * **Description:** Filters entrance assessment questions by Subject Group through `sch_subject_group_subject_jnt`.

---

### 8. Syllabus Module
* **Screen 1: Lesson & Topic Planning Screen**
  * **Controller:** `LessonController` & `SyllabusController` (`Modules/Syllabus/app/Http/Controllers/`)
  * **Description:** Uses `SubjectGroup::subjectsForClass()` to load subjects mapped to classes for curriculum authoring.
* **Screen 2: Syllabus Extra Period Rules Screen**
  * **Controller:** `SyllabusExtraPeriodRuleController` & `SyllabusPlanningService` (`Modules/Syllabus/app/Http/Controllers/`)
  * **Description:** Sets extra period allocation rules for subjects mapped to class subject groups.

---

### 9. SyllabusBooks Module
* **Screen: Textbook / Book Allocation Matrix**
  * **Blade View:** `Modules/SyllabusBooks/resources/views/book/index.blade.php`
  * **Controller:** `BookController` (`Modules/SyllabusBooks/app/Http/Controllers/BookController.php`)
  * **Description:** Resolves subject lists via `sch_subject_groups` and `sch_subject_group_subject_jnt` when mapping textbooks to curriculum subjects.

---

### 10. SchoolSetup Module *(Non-CRUD Consumption)*
* **Screen 1: Subject-Class Mapping Matrix**
  * **Controller:** `SubjectClassMappingController` (`Modules/SchoolSetup/app/Http/Controllers/SubjectClassMappingController.php`)
  * **Description:** Manages multi-subject mapping matrices and auto-synchronizes `sch_subject_group_subject_jnt` records.
* **Screen 2: Employee Profile & Subject Allocation**
  * **Blade View:** `Modules/SchoolSetup/resources/views/employee/js.blade.php`
  * **Controller:** `EmployeeProfileController` (`Modules/SchoolSetup/app/Http/Controllers/EmployeeProfileController.php`)
  * **Description:** Allocates teaching staff to designated Subject Groups.

---

### 11. Ptm Module
* **Screen: PTM Slot Generation & Teacher Booking**
  * **Controller:** `PtmManagementController` (`Modules/Ptm/app/Http/Controllers/PtmManagementController.php`)
  * **Description:** Traverses `SubjectGroup` relations to find all subject teachers associated with a student's class for booking slots.

---

### 12. ParentPortal & StudentPortal Modules
* **Screen: Parent Dashboard & Mobile Student Academic Schedule**
  * **Controllers:** `ParentDashboardController`, `MobileParentController`, `MobileStudentController`
  * **Description:** Queries `sch_subject_groups` and `sch_subject_group_subject_jnt` to display enrolled subjects and timetable schedules on parent and student mobile applications.
