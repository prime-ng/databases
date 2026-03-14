
# LMS – Detailed Functional Requirement Specification
## Deliverable 1

**Role:** Business Analyst GPT – School ERP & LMS Specialist  
**Scope:** LMS Core Module  
**Sub-Modules Covered:**  
1. Homework & Assignment  
2. Question Creation & Question Bank  
3. Quiz Creation  
4. Quest (Learning Quest)  
5. Online Exam  
6. Student Attempt & Dashboard  

**Compliance:** NEP 2020, Competency-Based Learning, Holistic Progress Card  

---

## 1. HOMEWORK & ASSIGNMENT MANAGEMENT

### 1.1 Advance Homework Creation
**Purpose:**  
Enable teachers to plan and schedule homework aligned with syllabus progression.

**Actors:** Teacher, System  

**Details:**  
- Homework created class + section wise  
- Can be drafted or auto-released  
- Linked with Topic → Micro Topic hierarchy  

**Example:**  
Homework for Class 6 Science auto-released after “Solar Energy” topic completion.

---

### 1.2 Topic-Driven Auto Assignment
**Purpose:**  
Automate homework assignment to avoid manual dependency.

**How it Works:**  
- Teacher marks topic as `COMPLETED`  
- System auto-assigns linked homework  
- Students & parents notified  

**NEP Mapping:** Continuous formative assessment  

---

### 1.3 Homework Content & Submission
**Supported Content:**  
- Text (TEXT / HTML / MARKDOWN)  
- Scanned handwritten homework  
- Reference attachments  

**Student Capabilities:**  
- Upload scanned copy  
- Late submission tracking  

---

### 1.4 Review, Feedback & Reassignment
**Teacher Capabilities:**  
- View submission status  
- Add remarks  
- Reassign homework if improvement needed  

**Learning Principle:** Mastery-based improvement  

---

### 1.5 Marks & Configuration
Homework may carry marks based on configuration:
```
homework_has_marks = true / false
```

---

### 1.6 Communication & Escalation
- Auto-detect overdue homework  
- Teacher can notify students & parents  
- AI predicts chronic non-compliance  

---

## 2. QUESTION CREATION & QUESTION BANK

### 2.1 Multi-Dimensional Question Authoring
Questions categorized by:
- Class, Subject  
- Topic → Ultra Topic  
- Bloom taxonomy  
- Competency  
- Complexity  

---

### 2.2 Question Formats
- TEXT  
- HTML  
- MARKDOWN  
- LATEX  
- JSON  
- Image-based  

---

### 2.3 MCQ Options & Explanation
Each option stores:
- Correct / Incorrect flag  
- Why correct / why incorrect explanation  
- Media attachment  

---

### 2.4 Review, Approval & Versioning
**Statuses:**  
DRAFT → IN_REVIEW → APPROVED → PUBLISHED → ARCHIVED  

**Audit Trail:**  
- Reviewer  
- Timestamp  
- Change history  

---

### 2.5 Ownership & Availability
**Ownership:** PrimeGurukul / School  

**Availability Scope:**  
GLOBAL, SCHOOL_ONLY, CLASS_ONLY, SECTION_ONLY, STUDENT_ONLY  

---

### 2.6 Analytics & AI Metadata
Captured metrics:
- Difficulty index  
- Discrimination index  
- Guessing factor  
- Avg / min / max time  
- Total attempts  

---

## 3. QUIZ MANAGEMENT

### 3.1 Quiz Creation & Assignment
- Topic-driven auto assignment  
- Manual scheduling supported  
- Performance-based grouping  

---

### 3.2 Quiz Configuration
Configurable parameters:
- Time limit  
- Attempts  
- Negative marking  
- Random order  
- Result publishing  

---

### 3.3 Behavioral Telemetry
Captured per question:
- Time spent  
- Answer changes  
- Revisits  
- Skipped questions  

**AI Use:** Predict readiness & guessing behavior  

---

### 3.4 Auto Retest Logic
If performance < threshold:
- AI generates new quiz  
- Assigned automatically  

---

## 4. QUEST (LEARNING QUEST)

### 4.1 Quest Definition
- Covers multiple lessons  
- Assigned after major topic completion  

---

### 4.2 Descriptive Evaluation
- Teacher checks descriptive answers  
- Rubric-ready design  

---

### 4.3 Result Publishing
- Scheduled result publishing  
- Performance auto-rated  

---

## 5. ONLINE EXAM

### 5.1 Exam Composition
- MCQ + Descriptive  
- Timer enforced  
- Secure attempt tracking  

---

### 5.2 Evaluation & Result
- Teacher evaluates descriptive  
- System calculates grade & division  
- Result card generated  

**NEP Mapping:** Holistic Progress Card  

---

## 6. STUDENT ATTEMPT & DASHBOARD

### 6.1 Unified Student Dashboard
Student can see:
- Due homework  
- Due quizzes  
- Due quests  
- Due exams  

---

### 6.2 Result Visibility Control
- Result visibility based on admin configuration  
- Scheduled publishing  

---

## FINAL NOTES

- Fully configuration driven  
- AI-ready design  
- NEP 2020 compliant  
- Suitable for ERP + LMS + LXP convergence  

**This document is ready for AI-driven DDL & API generation.**
