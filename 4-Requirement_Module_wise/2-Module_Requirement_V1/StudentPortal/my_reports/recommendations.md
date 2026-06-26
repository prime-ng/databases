# My Reports — Recommendations Tab Requirements

## 1. Functional Overview
A dashboard listing study recommendations triggered by exam performance or assigned manually by teachers.

---

## 2. Page Structure & Parameters

### A. Source Filter Tabs
- **All**: List of all recommendations.
- **Quiz-triggered**: System-generated recommendations from quiz results.
- **Quest-triggered**: System-generated recommendations from quest results.
- **Manual**: Recommendations assigned directly by teachers.

### B. Recommendations Grid
- Cards for each recommendation displaying:
  - Material Name & Type (Video, Document, etc.).
  - Purpose (e.g. Remedial study).
  - Status Badge: `PENDING` (Grey), `VIEWED` (Blue), `IN_PROGRESS` (Orange), `COMPLETED` (Green).
  - Subject and Topic name.
  - Assigned Date.

### C. Details & Rating Modal
- Viewing details:
  - Automatically transitions the recommendation status to `VIEWED` if it was previously `PENDING`.
- **Status Updates**: Students can set status to `VIEWED`, `IN_PROGRESS`, or `COMPLETED`.
- **Rating**: Rate material (1-5 stars) and submit review comments.

---

## 3. Database References
- **Model**: `Modules\Recommendation\Models\StudentRecommendation`
- **Table**: `rec_student_recommendations`
- **Fields**:
  - `student_id`
  - `material_id`
  - `status`
  - `assigned_at`
  - `rating`
  - `feedback`
