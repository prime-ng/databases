# LXP — Learning Experience Platform
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** RBS_ONLY
**Module Code:** LXP | **Table Prefix:** `lxp_` | **Type:** Tenant | **DB:** tenant_db
**RBS Reference:** Module T (Learning Paths), Module W (Gamification & Engagement)
**V1 Reference:** `2-Detailed_Requirements/V1/Dev_Pending/LXP_Lxp_Requirement.md`

---

## 1. Executive Summary

The LXP (Learning Experience Platform) elevates Prime-AI from a transactional LMS (grades recorded, homework submitted) into a personalized, adaptive, and gamified learning ecosystem aligned with NEP 2020's vision of holistic, competency-based education.

While LMS modules (LmsExam, LmsQuiz, LmsHomework, Syllabus) manage the instructional delivery layer, the LXP orchestrates *how* each student experiences learning — through AI-curated personalized paths, skill-graph-driven progression, badge/points gamification, peer collaboration forums, formal mentorship programs, and a micro-learning content library. Every learning interaction generates engagement signals that feed the PredictiveAnalytics module for early-warning dropout and learning gap models.

**V2 additions over V1:** Three new tables (`lxp_forum_posts`, `lxp_mentor_mentee_jnt`, `lxp_mentorship_sessions`), expanded API endpoint set (REST + web), offline content download tracking, parent-portal visibility scope, certificate issuance on path completion, Bloom's taxonomy enforcement on content creation, and WCAG 2.1 AA accessibility requirement.

**Overall Implementation Status: 0% — Greenfield (RBS_ONLY)**

---

## 2. Module Overview

### 2.1 Business Purpose

Indian K-12 schools face two structural challenges the LXP directly addresses:

1. **Within-classroom learning diversity** — A single class of 40 students may span 3 learning levels. Teachers cannot manually curate differentiated sequences. The LXP personalizes the next-step content for each learner using performance signals (exam scores, quiz results, engagement history).
2. **Invisible progress** — Students and parents see only periodic marks. The LXP makes learning visible through path timelines, skill radar charts, badge galleries, and goal dashboards — real-time indicators of growth.

Additional outcomes: healthy competition via leaderboards, peer support via mentorship programs, teacher focus via engagement heatmaps, and system intelligence via engagement data flowing to PredictiveAnalytics.

### 2.2 Key Features Summary

| Feature Area | RBS Ref | Priority | V2 Status |
|---|---|---|---|
| Personalized Learning Paths | T1 | Critical | 📐 Proposed |
| Skill Framework & Competency Map | T2 | Critical | 📐 Proposed |
| AI Content Recommendations | T3 | High | 📐 Proposed |
| Learning Goals & Roadmaps | T4 | High | 📐 Proposed |
| Gamification — Badges & Points | W1, W2 | Critical | 📐 Proposed |
| Gamification — Leaderboards & Streaks | W3, W4 | High | 📐 Proposed |
| Micro-Learning Content Library | T1 | High | 📐 Proposed |
| Adaptive Difficulty Adjustment | T3 | High | 📐 Proposed |
| Discussion Forums & Peer Support | T6 | High | 📐 Proposed |
| Peer Mentoring & Mentorship Programs | T8 | Medium | 📐 Proposed |
| Student Progress Dashboard | T7 | Critical | 📐 Proposed |
| Teacher Analytics & Drop-off Analysis | T7 | High | 📐 Proposed |
| Personalized Activity Feed | T9 | Medium | 📐 Proposed |
| Path Completion Certificates | — | Medium | 📐 Proposed (New in V2) |
| Offline Content Download Tracking | — | Low | 📐 Proposed (New in V2) |
| Parent Portal Visibility | — | Medium | 📐 Proposed (New in V2) |

### 2.3 Module Statistics

| Metric | V1 Count | V2 Count | Delta |
|---|---|---|---|
| DB Tables (`lxp_*`) | 14 | 17 | +3 |
| Named Web Routes | ~40 | ~65 | +25 |
| Named API Routes | ~15 | ~30 | +15 |
| Blade Views | ~21 | ~32 | +11 |
| Controllers | 10 | 10 | 0 |
| Models | 14 | 17 | +3 |
| Services | 4 | 5 | +1 (CertificateService) |
| Jobs | 1 | 2 | +1 (ProcessEngagementJob) |
| Functional Requirements | 12 | 15 | +3 |

### 2.4 Menu Navigation

```
LXP [/lxp]
├── My Learning Path       [/lxp/my-path]              Student
├── Skill Map              [/lxp/skill-map]             Student
├── My Goals               [/lxp/goals]                 Student
├── My Badges              [/lxp/badges]                Student
├── Leaderboard            [/lxp/leaderboard]           Student/Teacher
├── Content Library        [/lxp/content-library]       All
├── Discussion Forums      [/lxp/forums]                All
├── Mentorship             [/lxp/mentorship]            Student/Teacher
├── Activity Feed          [/lxp/feed]                  Student
├── Teacher Analytics      [/lxp/teacher/analytics]     Teacher/Admin
└── Administration
    ├── Skill Management   [/lxp/admin/skills]          Admin
    ├── Badge Management   [/lxp/admin/badges]          Admin
    ├── Mentorship Programs [/lxp/admin/mentorship-programs] Admin
    └── Path Config        [/lxp/admin/path-config]     Admin
```

### 2.5 Proposed Module Architecture

```
Modules/Lxp/
├── Http/Controllers/
│   ├── LearningPathController.php       # Student path + activity progression
│   ├── SkillController.php              # Skill framework CRUD (admin) + student radar
│   ├── ContentLibraryController.php     # Library browse + CRUD
│   ├── GamificationController.php       # Badges, points, leaderboard, streaks
│   ├── LearningGoalController.php       # Goal CRUD + progress tracking
│   ├── ForumController.php              # Forums, threads, posts, moderation
│   ├── MentorshipController.php         # Programs, matching, sessions
│   ├── FeedController.php               # Personalized feed
│   ├── LxpAnalyticsController.php       # Teacher/admin analytics
│   └── LxpAdminController.php          # Path config + admin settings
├── Jobs/
│   ├── GenerateLearningPathJob.php      # Async AI path generation
│   └── ProcessEngagementJob.php        # Async batch engagement logging (NEW in V2)
├── Models/ (17 models)
├── Policies/ (7 policies)
└── Services/
    ├── PathSuggestionService.php        # AI path curation from rec_* + skill gaps
    ├── GamificationService.php          # Points + badge + streak logic
    ├── SkillTrackingService.php         # Skill score rolling average + radar data
    ├── FeedService.php                  # Feed aggregation + recency/relevance ranking
    └── CertificateService.php           # Path completion certificate generation (NEW in V2)
```

---

## 3. Stakeholders & Roles

| Actor | LXP Permissions | Scope |
|---|---|---|
| School Admin | Full CRUD on skills, badges, programs, content library; view all analytics; issue/revoke certificates | School-wide |
| Principal | View all analytics and reports; mentorship program oversight | School-wide (read) |
| Teacher | View class analytics; manage class forums; assign goals to students/sections; log mentoring sessions; contribute content | Class/section scoped |
| Student | View own path, skill map, goals, badges; post in forums; request mentors; reorder optional activities | Own data only |
| Parent | View child's learning path progress, badge gallery, skill radar, goal completion (read-only via parent portal) | Own ward only |
| System | Auto-generate path suggestions; award points/badges on trigger events; update engagement logs; send milestone notifications | System actor |
| Peer Mentor | Same as Student + can log mentoring session notes for assigned mentees | Mentor-mentee pairs |

---

## 4. Functional Requirements

### FR-LXP-01: Personalized Learning Path
**Status:** 📐 Proposed | **Priority:** Critical | **RBS:** T1
**Tables:** `lxp_learning_paths`, `lxp_path_activities`

**Description:** A personalized, ordered sequence of learning activities (lessons, quizzes, videos, readings, practice sets) generated per student per subject per academic session. Auto-generated by AI using performance signals; customizable by teachers and students.

**Acceptance Criteria:**
- AC1: One active path per student per subject per session (UNIQUE constraint enforced)
- AC2: Path auto-generated asynchronously via `GenerateLearningPathJob` dispatched on request
- AC3: Activities ordered by difficulty (easy → medium → hard) by default
- AC4: Locked activities cannot be started until prerequisites are completed
- AC5: Student can reorder `is_optional=true` activities; mandatory sequence is immutable
- AC6: On activity completion: path `completion_percent` recalculates; gamification triggered; next activity unlocked
- AC7: Path completion (100%) triggers `CertificateService` to generate a completion certificate (New in V2)

---

### FR-LXP-02: Skill Framework & Competency Mapping
**Status:** 📐 Proposed | **Priority:** Critical | **RBS:** T2
**Tables:** `lxp_skills`, `lxp_skill_content_jnt`, `lxp_student_skills`

**Description:** Hierarchical skill tree (up to 5 levels: Subject → Domain → Topic → Sub-topic → Micro-skill) linked to curriculum content. Each skill is tagged with Bloom's taxonomy level and category. Student skill scores (0–100) update via weighted rolling average after each linked content completion.

**Acceptance Criteria:**
- AC1: Skill hierarchy navigable and editable as a tree (admin)
- AC2: Circular dependency detection on skill creation (parent must not be a descendant)
- AC3: Multiple skills mappable to one content item with individual weights
- AC4: Skill score rolling average: `(existing × 0.7) + (new_score × 0.3)` — requires minimum 5 assessments for "reliable" status
- AC5: Radar chart data queryable per student per subject in < 500ms
- AC6: Skill gaps (score < configurable threshold, default 60) surfaced to PathSuggestionService

---

### FR-LXP-03: AI Recommendations Engine Integration
**Status:** 📐 Proposed | **Priority:** High | **RBS:** T3
**Tables:** Uses `rec_student_recommendations` (Recommendation module — read only)

**Description:** LXP consumes the Recommendation module's output (`rec_student_recommendations`) as its content suggestion engine. It does not run its own ML model. Two recommendation surfaces: "Recommended for You" (AI-ranked by skill gap) and "Peers Also Learned" (collaborative filtering via skill score similarity).

**Acceptance Criteria:**
- AC1: "Recommended for You" shows top 5 pending recommendations ranked by skill gap score DESC + difficulty ASC
- AC2: "Peers Also Learned" identifies peers in same class with skill scores within ±15 points and surfaces content completed by those peers that the current student has not completed
- AC3: Recommendations marked `viewed` in `rec_student_recommendations` on display
- AC4: Recommendations dismissed by student are excluded from subsequent pulls
- AC5: PathSuggestionService uses recommendations as primary input for path activity ordering

---

### FR-LXP-04: Micro-Learning Content Library
**Status:** 📐 Proposed | **Priority:** High | **RBS:** T1
**Tables:** `lxp_content_library`, `lxp_skill_content_jnt`

**Description:** Curated library of bite-sized learning content (target 5–15 minutes per item). Supported types: YouTube video (embed), PDF (uploaded via sys_media), external article (link), and mini-quiz reference. Each item tagged by subject, Bloom's level, difficulty, and skills. Full-text searchable. New in V2: download tracking for offline access logging.

**Acceptance Criteria:**
- AC1: Content creation validates Bloom's level and difficulty are set (required fields in V2)
- AC2: YouTube URLs auto-validated for format; video ID extracted and stored for embed
- AC3: Uploaded PDFs stored via `sys_media`; file size limit 50MB enforced
- AC4: FULLTEXT search on `title` + `description` returns results within 500ms
- AC5: Filter by subject, difficulty, bloom_level, content_type, skill — combinable
- AC6: `view_count` increments on each unique content view (student logs engagement)
- AC7: Offline download events logged in `lxp_engagement_logs` with `activity_type = 'content_download'` (New in V2)

---

### FR-LXP-05: Learning Goals & Roadmaps
**Status:** 📐 Proposed | **Priority:** High | **RBS:** T4
**Tables:** `lxp_learning_goals`

**Description:** Students self-set or receive teacher-assigned learning goals linked to a subject or specific skill. Goals have a target date and optional target skill score. Progress is auto-computed for skill-linked goals and manually updated for descriptive goals. Milestone notifications trigger at 25%, 50%, 75%, and 100%.

**Acceptance Criteria:**
- AC1: Student can create self-assigned goals; teacher can assign goals to individual student or bulk-assign to entire section
- AC2: Skill-linked goals auto-update `progress_percent` on each skill score update
- AC3: Progress crossing 25/50/75/100% thresholds triggers notification via Notification module
- AC4: Goals display on student dashboard with visual progress bar and days-remaining indicator
- AC5: Overdue active goals (target_date past, status still active) flagged as `missed` by scheduled job
- AC6: Parent can view child's goals and progress in parent portal (New in V2)

---

### FR-LXP-06: Student Progress Dashboard
**Status:** 📐 Proposed | **Priority:** Critical | **RBS:** T7
**Tables:** `lxp_learning_paths`, `lxp_student_skills`, `lxp_points_ledger`, `lxp_student_badges_jnt`, `lxp_engagement_logs`, `lxp_learning_goals`

**Description:** Student's personal learning hub showing: path completion per subject, skill radar chart, active goals with progress, total points, badges earned, current streak, recently completed activities, and personalized recommendations. Parent can access a read-only view of this dashboard for their ward via the parent portal.

**Acceptance Criteria:**
- AC1: Dashboard load time < 2 seconds (skill scores and path completion cached)
- AC2: Skill radar chart renders with Chart.js (no external paid library)
- AC3: Streak = consecutive calendar days with at least one engagement log entry
- AC4: "Recommended for You" section shows top 3 items from FR-LXP-03
- AC5: Parent portal read-only view shows same data scoped to the parent's ward (New in V2)
- AC6: Dashboard shows earned certificates with download links (New in V2)

---

### FR-LXP-07: Adaptive Difficulty Adjustment
**Status:** 📐 Proposed | **Priority:** High | **RBS:** T3 (Adaptive)
**Tables:** `lxp_path_activities`

**Description:** Dynamic path reordering based on activity completion scores. Score below 60%: insert a remedial activity at easier difficulty before the next planned activity. Score above 85%: skip the next same-difficulty activity and advance to harder content.

**Acceptance Criteria:**
- AC1: Score < 60% on an activity → `PathSuggestionService::adaptPathOnCompletion()` inserts `is_remedial=true` activity at `difficulty - 1` level
- AC2: Score > 85% → next activity at same difficulty level marked `skipped`; student advances to next difficulty tier
- AC3: Score 60–85% → normal linear progression (no adaptation)
- AC4: Student notified of path adaptation ("Your path has been updated based on your performance")
- AC5: Adaptation events recorded in `lxp_engagement_logs` with `activity_type = 'path_adapted'`

---

### FR-LXP-08: Discussion Forums & Peer Support
**Status:** 📐 Proposed | **Priority:** High | **RBS:** T6
**Tables:** `lxp_forums`, `lxp_forum_threads`, `lxp_forum_posts`

**Description:** Teacher-created discussion forums scoped to a class section and subject. Students post threads and replies. Moderators (teacher) can pin, close, and delete posts. Forum activity contributes to engagement score and points.

**Acceptance Criteria:**
- AC1: Only teachers and admins can create forums; students can only post threads and replies
- AC2: Forums scoped to class_id + section_id by default; cross-section forums require admin permission
- AC3: Threads support Markdown formatting and image attachment (via sys_media)
- AC4: Moderator can pin threads, mark as resolved, and delete posts
- AC5: Each forum post logs an engagement event and awards configurable points
- AC6: Student cannot delete another student's post; moderator can delete any post
- AC7: Forum closed at `closes_at` date — no new threads/replies accepted after closure

---

### FR-LXP-09: Gamification Engine
**Status:** 📐 Proposed | **Priority:** Critical | **RBS:** W1, W2, W3, W4
**Tables:** `lxp_badges`, `lxp_student_badges_jnt`, `lxp_points_ledger`

**Description:** Three-layer gamification: (1) Points ledger records every earning event. (2) Badge engine evaluates JSON-encoded criteria and auto-awards badges. (3) Leaderboard aggregates points with filters. Streak tracking for consecutive daily logins.

**Acceptance Criteria:**
- AC1: Points awarded immediately (synchronously) on trigger event; badge check queued asynchronously
- AC2: Badge criteria types supported: `streak` (days), `skill_score` (skill_id + min_score), `activity_complete` (count), `quiz_perfect` (score=100), `path_complete`, `forum_post` (count)
- AC3: Badge awarded only once per student (UNIQUE key on student_id + badge_id)
- AC4: Leaderboard filterable by: class, section, subject, period (weekly / monthly / all-time)
- AC5: Student's own rank always visible even when outside top N
- AC6: Points cannot be manually awarded by teachers; admin-only with justification note
- AC7: Streak resets if no engagement event for a calendar day; streak badge awarded at 7, 30, 100 days
- AC8: New in V2 — `rarity` field drives badge visual styling (common=grey, rare=blue, epic=purple, legendary=gold)

---

### FR-LXP-10: Teacher Analytics Dashboard
**Status:** 📐 Proposed | **Priority:** High | **RBS:** T7
**Tables:** `lxp_engagement_logs`, `lxp_student_skills`, `lxp_learning_paths`

**Description:** Class-level engagement and learning analytics for teachers. Shows average path completion, skill coverage heatmap, top/bottom students by engagement, students inactive for 7+ days, and activity-level drop-off rates.

**Acceptance Criteria:**
- AC1: Dashboard scoped to teacher's assigned class sections
- AC2: Skill heatmap shows % of class that has mastered (score >= 70) each skill — colour-coded green/yellow/red
- AC3: Students with `completion_percent < 30%` AND no engagement in 7 days flagged as at-risk
- AC4: Drop-off analysis shows top 10 activities ranked by `(starts - completions) / starts` abandonment rate
- AC5: Admin can view analytics for any class (school-wide view)
- AC6: All metrics exportable as CSV (New in V2)

---

### FR-LXP-11: Mentorship Program Management
**Status:** 📐 Proposed | **Priority:** Medium | **RBS:** T8
**Tables:** `lxp_mentorship_programs`, `lxp_mentor_mentee_jnt`, `lxp_mentorship_sessions`

**Description:** Formal mentorship programs (peer or teacher-student). Admin defines programs with matching criteria in JSON. System auto-suggests pairs; admin/teacher approves. Sessions are booked, logged with notes, and tracked toward program goals.

**Acceptance Criteria:**
- AC1: Mentor eligibility: skill score >= criteria `mentor_min_skill` in subject (default 75)
- AC2: Mentee eligibility: skill score <= criteria `mentee_max_skill` in subject (default 55)
- AC3: One mentor can have at most `max_mentees_per_mentor` active mentees (TINYINT, default 3)
- AC4: Session log requires: date, duration, topics_discussed, mentor_rating (1–5)
- AC5: Program dashboard shows sessions completed vs target, average mentor rating, and mentee progress

---

### FR-LXP-12: Personalized Activity Feed
**Status:** 📐 Proposed | **Priority:** Medium | **RBS:** T9
**Tables:** `lxp_feed_items`

**Description:** Ranked activity feed aggregating events from multiple sources: new path activity unlocked, peer badge earned, new forum thread in class, goal milestone reached, new content in library matching enrolled subjects, mentor session reminder. Scored by recency (0.6) + relevance (0.4).

**Acceptance Criteria:**
- AC1: Feed generation returns top 20 items in < 1 second
- AC2: Unread items visually distinguished; marked read on click/view
- AC3: Feed items are actionable — deep-link to relevant module screen
- AC4: Feed deduplicates: same event does not appear twice within 24 hours
- AC5: Student can dismiss feed items (preference stored — dismissed item never resurfaces)

---

### FR-LXP-13: Path Completion Certificates (New in V2)
**Status:** 📐 Proposed | **Priority:** Medium | **RBS:** — (new)
**Tables:** `lxp_certificates`

**Description:** When a student completes 100% of a learning path, the system auto-generates a PDF certificate via `CertificateService`. Certificate includes: student name, subject, path name, completion date, school name/logo, and teacher/principal digital signature field.

**Acceptance Criteria:**
- AC1: Certificate auto-triggered when `lxp_learning_paths.completion_percent` reaches 100
- AC2: PDF generated via DomPDF (already available in project stack)
- AC3: Certificate stored in `lxp_certificates` with `file_path` reference
- AC4: Student can download certificate from dashboard; parent can view in parent portal
- AC5: Admin can manually issue or revoke certificates with audit log entry

---

### FR-LXP-14: Offline Content Download Tracking (New in V2)
**Status:** 📐 Proposed | **Priority:** Low | **RBS:** — (new)
**Tables:** `lxp_engagement_logs`

**Description:** Track when a student downloads content for offline use. Log the event with content reference. Offline download events contribute to engagement score (same as content view). No server-side offline storage — tracking only.

**Acceptance Criteria:**
- AC1: Download action logs `activity_type = 'content_download'` in `lxp_engagement_logs`
- AC2: Download count visible to admin in content library management view
- AC3: Downloaded content items shown in student's "Downloaded" filter in content library

---

### FR-LXP-15: Parent Portal LXP Visibility (New in V2)
**Status:** 📐 Proposed | **Priority:** Medium | **RBS:** — (new)
**Tables:** Read-only across all `lxp_*` tables scoped to ward's student_id

**Description:** Parents access a read-only LXP summary for their child via the Parent Portal. Visible data: learning path completion per subject, skills radar chart, goals progress, badges earned, points total, streak, and completed certificates.

**Acceptance Criteria:**
- AC1: Parent can only view data for their own registered wards
- AC2: All write actions (post, goal-create, badge-award) are blocked for parent role
- AC3: Parent view clearly labelled as read-only with "(Your child's learning summary)" header
- AC4: Data refreshes in real-time (no separate parent-side cache)

---

## 5. Data Model

### 5.1 New Tables (lxp_* prefix)

| # | Table | Description | Key Columns | Status |
|---|---|---|---|---|
| 1 | `lxp_learning_paths` | One path per student per subject per session | student_id, subject_id, academic_session_id, status, completion_percent, generated_by | 📐 New |
| 2 | `lxp_path_activities` | Ordered activities within a path | path_id, activity_type, activity_ref_id, activity_ref_type, sequence_order, status, difficulty_level, is_optional, is_remedial, prerequisite_activity_id, score_achieved | 📐 New |
| 3 | `lxp_skills` | Hierarchical skill tree | name, code (UNIQUE), skill_category, parent_skill_id (self-ref), subject_id, bloom_level | 📐 New |
| 4 | `lxp_skill_content_jnt` | Maps skills to content items | skill_id, content_type, content_ref_id, skill_weight | 📐 New |
| 5 | `lxp_student_skills` | Per-student skill score (0–100) | student_id, skill_id, skill_score, assessments_count, last_assessed_at | 📐 New |
| 6 | `lxp_badges` | Badge definitions with JSON criteria | name, category, criteria_json, points, rarity, icon_path | 📐 New |
| 7 | `lxp_student_badges_jnt` | Badge awards per student | student_id, badge_id (UNIQUE pair), earned_at, trigger_ref_id, trigger_ref_type | 📐 New |
| 8 | `lxp_points_ledger` | Immutable point transaction log | student_id, points, action_type, reference_id, reference_type, notes | 📐 New |
| 9 | `lxp_learning_goals` | Student/teacher-assigned goals | student_id, subject_id, skill_id, goal_type, target_date, target_skill_score, progress_percent, status | 📐 New |
| 10 | `lxp_content_library` | Micro-learning content items | title, content_type, url, file_path, subject_id, bloom_level, difficulty, duration_minutes, view_count | 📐 New |
| 11 | `lxp_forums` | Discussion forums per class/section | title, subject_id, class_id, section_id, moderator_id, is_open, closes_at | 📐 New |
| 12 | `lxp_forum_threads` | Top-level threads in a forum | forum_id, title, body, posted_by, is_pinned, is_resolved, reply_count | 📐 New |
| 13 | `lxp_forum_posts` | Replies within a thread (New in V2) | thread_id, body, posted_by, parent_post_id (nullable for nested), media_id | 📐 New |
| 14 | `lxp_mentorship_programs` | Formal mentorship program definitions | program_name, program_type, matching_criteria_json, start_date, end_date, max_mentees_per_mentor, status | 📐 New |
| 15 | `lxp_mentor_mentee_jnt` | Approved mentor-mentee pairs (New in V2) | program_id, mentor_id, mentee_id, subject_id, status, sessions_completed, assigned_by | 📐 New |
| 16 | `lxp_mentorship_sessions` | Session logs per pair (New in V2) | pair_id, session_date, duration_minutes, topics_discussed, goals_covered, action_items, mentor_rating, mentee_feedback | 📐 New |
| 17 | `lxp_engagement_logs` | Immutable interaction event log | student_id, activity_type, reference_id, reference_type, duration_seconds, session_date | 📐 New |
| 18 | `lxp_certificates` | Path completion certificates (New in V2) | student_id, path_id, subject_id, file_path, issued_at, issued_by, is_revoked | 📐 New |
| 19 | `lxp_feed_items` | Materialized feed events per student | student_id, feed_type, reference_id, reference_type, title, is_read, dismissed_at, relevance_score | 📐 New |

### 5.2 Key Column Details

**`lxp_path_activities` — activity_type ENUM:**
`'lesson','quiz','homework','video','reading','quest','practice'`

**`lxp_path_activities` — status ENUM:**
`'locked','available','in_progress','completed','skipped'`

**`lxp_skills` — skill_category ENUM:**
`'technical','cognitive','soft','creative'`

**`lxp_skills` — bloom_level ENUM:**
`'remember','understand','apply','analyse','evaluate','create'`

**`lxp_badges` — category ENUM:**
`'achievement','streak','skill','milestone','participation'`

**`lxp_badges` — rarity ENUM:**
`'common','rare','epic','legendary'`

**`lxp_points_ledger` — action_type ENUM:**
`'activity_complete','badge_earned','forum_post','goal_achieved','streak_bonus','quiz_perfect','mentor_session','content_download'`

**`lxp_engagement_logs` — activity_type ENUM:**
`'path_activity_start','path_activity_complete','content_view','content_download','forum_post','goal_update','badge_earned','session_login','path_adapted'`

**`lxp_learning_goals` — status ENUM:**
`'active','achieved','missed','cancelled'`

**`lxp_mentorship_programs` — status ENUM:**
`'draft','active','completed','cancelled'`

**`lxp_mentor_mentee_jnt` — status ENUM:**
`'pending','active','paused','completed'`

### 5.3 Relationships

| From Table | Relationship | To Table | FK Column | Notes |
|---|---|---|---|---|
| lxp_learning_paths | BelongsTo | std_students | student_id | Cascade delete |
| lxp_learning_paths | HasMany | lxp_path_activities | path_id | Cascade delete |
| lxp_path_activities | BelongsTo | lxp_path_activities | prerequisite_activity_id | Self-ref, SET NULL |
| lxp_skills | BelongsTo | lxp_skills | parent_skill_id | Self-ref hierarchy, SET NULL |
| lxp_skill_content_jnt | BelongsTo | lxp_skills | skill_id | Cascade delete |
| lxp_student_skills | BelongsTo | std_students | student_id | Cascade delete |
| lxp_student_skills | BelongsTo | lxp_skills | skill_id | Cascade delete |
| lxp_student_badges_jnt | BelongsTo | std_students | student_id | Cascade delete |
| lxp_student_badges_jnt | BelongsTo | lxp_badges | badge_id | Cascade delete |
| lxp_points_ledger | BelongsTo | std_students | student_id | Cascade delete |
| lxp_learning_goals | BelongsTo | std_students | student_id | Cascade delete |
| lxp_learning_goals | BelongsTo | lxp_skills | skill_id | SET NULL |
| lxp_forums | HasMany | lxp_forum_threads | forum_id | Cascade delete |
| lxp_forum_threads | HasMany | lxp_forum_posts | thread_id | Cascade delete |
| lxp_forum_posts | BelongsTo | lxp_forum_posts | parent_post_id | Self-ref for nesting, SET NULL |
| lxp_mentorship_programs | HasMany | lxp_mentor_mentee_jnt | program_id | Cascade delete |
| lxp_mentor_mentee_jnt | HasMany | lxp_mentorship_sessions | pair_id | Cascade delete |
| lxp_certificates | BelongsTo | lxp_learning_paths | path_id | Cascade delete |
| lxp_engagement_logs | BelongsTo | std_students | student_id | Cascade delete; insert-only |
| lxp_feed_items | BelongsTo | std_students | student_id | Cascade delete |

### 5.4 UNIQUE Constraints

| Table | UNIQUE Key | Purpose |
|---|---|---|
| lxp_learning_paths | (student_id, subject_id, academic_session_id) | One path per student per subject per session |
| lxp_skills | (code) | Unique skill code |
| lxp_skill_content_jnt | (skill_id, content_type, content_ref_id) | No duplicate mappings |
| lxp_student_skills | (student_id, skill_id) | One score record per student per skill |
| lxp_student_badges_jnt | (student_id, badge_id) | Badge earned once only |

### 5.5 Indexes

| Table | Index | Columns | Purpose |
|---|---|---|---|
| lxp_engagement_logs | idx_engage_student_date | (student_id, session_date) | Streak calculation, daily active |
| lxp_points_ledger | idx_ledger_student | (student_id) | Leaderboard aggregation |
| lxp_path_activities | idx_path_status | (path_id, status) | Unlock next activity |
| lxp_student_skills | idx_skill_score | (skill_id, skill_score) | Peer comparison, leaderboard |
| lxp_content_library | FULLTEXT ft_content_search | (title, description) | Library search |
| lxp_feed_items | idx_feed_student_read | (student_id, is_read) | Unread feed count |

---

## 6. API Endpoints & Routes

### 6.1 Web Routes (tenant.php)

| Method | URI | Controller@Method | Auth | Description |
|---|---|---|---|---|
| GET | /lxp/my-path | LearningPathController@myPath | student | List student's active learning paths |
| GET | /lxp/my-path/{path} | LearningPathController@show | student | View single path with activity timeline |
| POST | /lxp/my-path/generate | LearningPathController@generate | student | Dispatch GenerateLearningPathJob |
| POST | /lxp/my-path/{path}/activity/{act}/start | LearningPathController@startActivity | student | Mark activity in_progress; log engagement |
| POST | /lxp/my-path/{path}/activity/{act}/complete | LearningPathController@completeActivity | student | Mark completed; trigger gamification + skill update |
| PATCH | /lxp/my-path/{path}/reorder | LearningPathController@reorder | student | Reorder optional activities |
| GET | /lxp/skill-map | SkillController@studentSkillMap | student | Radar chart data + skill tree for student |
| GET | /lxp/goals | LearningGoalController@index | student | My goals list |
| POST | /lxp/goals | LearningGoalController@store | student | Create self-assigned goal |
| PATCH | /lxp/goals/{goal} | LearningGoalController@update | student | Update goal description/date |
| DELETE | /lxp/goals/{goal} | LearningGoalController@destroy | student | Cancel goal |
| GET | /lxp/badges | GamificationController@badges | student | Badge gallery (earned + locked) |
| GET | /lxp/badges/points-history | GamificationController@pointsHistory | student | Points ledger history |
| GET | /lxp/leaderboard | GamificationController@leaderboard | auth | Leaderboard with filters |
| GET | /lxp/feed | FeedController@index | student | Personalized activity feed |
| POST | /lxp/feed/{item}/read | FeedController@markRead | student | Mark feed item read |
| POST | /lxp/feed/{item}/dismiss | FeedController@dismiss | student | Dismiss feed item |
| GET | /lxp/content-library | ContentLibraryController@index | auth | Browse content library |
| GET | /lxp/content-library/create | ContentLibraryController@create | teacher,admin | Content upload form |
| POST | /lxp/content-library | ContentLibraryController@store | teacher,admin | Store new content |
| GET | /lxp/content-library/{content} | ContentLibraryController@show | auth | Content detail + viewer/embed |
| PATCH | /lxp/content-library/{content} | ContentLibraryController@update | teacher,admin | Update content metadata |
| DELETE | /lxp/content-library/{content} | ContentLibraryController@destroy | admin | Soft-delete content |
| GET | /lxp/forums | ForumController@index | auth | Forum list for class/section |
| POST | /lxp/forums | ForumController@store | teacher,admin | Create new forum |
| GET | /lxp/forums/{forum} | ForumController@show | auth | Thread list in forum |
| POST | /lxp/forums/{forum}/threads | ForumController@createThread | student,teacher | Post new thread |
| GET | /lxp/forums/{forum}/threads/{thread} | ForumController@showThread | auth | Thread detail + replies |
| POST | /lxp/forums/{forum}/threads/{thread}/reply | ForumController@reply | student,teacher | Post reply |
| PATCH | /lxp/forums/{forum}/threads/{thread}/pin | ForumController@pin | teacher,admin | Pin/unpin thread |
| PATCH | /lxp/forums/{forum}/threads/{thread}/resolve | ForumController@resolve | teacher,admin | Mark thread resolved |
| DELETE | /lxp/forums/{forum}/posts/{post} | ForumController@deletePost | author,moderator,admin | Delete post |
| GET | /lxp/mentorship | MentorshipController@index | auth | My mentor/mentee pairs |
| GET | /lxp/mentorship/{pair}/sessions | MentorshipController@sessions | auth | Session log for pair |
| POST | /lxp/mentorship/{pair}/sessions | MentorshipController@logSession | mentor,teacher | Log mentoring session |
| GET | /lxp/teacher/analytics | LxpAnalyticsController@classOverview | teacher,admin | Class engagement dashboard |
| GET | /lxp/teacher/analytics/drop-off | LxpAnalyticsController@dropOff | teacher,admin | Drop-off analysis |
| GET | /lxp/teacher/analytics/export | LxpAnalyticsController@export | teacher,admin | CSV export of analytics |
| POST | /lxp/teacher/goals/assign | LearningGoalController@assignToClass | teacher | Bulk assign goal to section |
| GET | /lxp/certificates/{cert}/download | LearningPathController@downloadCert | student,parent | Download completion certificate |
| GET | /lxp/admin/skills | SkillController@index | admin | Skill framework admin |
| POST | /lxp/admin/skills | SkillController@store | admin | Create skill |
| PATCH | /lxp/admin/skills/{skill} | SkillController@update | admin | Update skill |
| DELETE | /lxp/admin/skills/{skill} | SkillController@destroy | admin | Soft-delete skill |
| POST | /lxp/admin/skills/{skill}/map-content | SkillController@mapContent | admin,teacher | Map skill to content |
| GET | /lxp/admin/badges | GamificationController@adminBadges | admin | Badge management |
| POST | /lxp/admin/badges | GamificationController@storeBadge | admin | Create badge with criteria JSON |
| PATCH | /lxp/admin/badges/{badge} | GamificationController@updateBadge | admin | Update badge |
| GET | /lxp/admin/mentorship-programs | MentorshipController@programs | admin | Mentorship program list |
| POST | /lxp/admin/mentorship-programs | MentorshipController@storeProgram | admin | Create mentorship program |
| POST | /lxp/admin/mentorship-programs/{prog}/generate-matches | MentorshipController@generateMatches | admin,teacher | Auto-suggest pairs |
| PATCH | /lxp/admin/mentorship-programs/{prog}/pairs/{pair}/approve | MentorshipController@approvePair | admin,teacher | Approve mentor-mentee pair |
| GET | /lxp/admin/path-config | LxpAdminController@pathConfig | admin | Path generation configuration |
| PATCH | /lxp/admin/path-config | LxpAdminController@updatePathConfig | admin | Save path config settings |

### 6.2 REST API Routes (api.php — Sanctum auth)

| Method | URI | Controller@Method | Description |
|---|---|---|---|
| GET | /api/v1/lxp/paths | LearningPathController@apiIndex | List student's paths (mobile) |
| GET | /api/v1/lxp/paths/{path} | LearningPathController@apiShow | Path detail with activities |
| POST | /api/v1/lxp/paths/{path}/activities/{act}/complete | LearningPathController@apiComplete | Mark activity complete (mobile) |
| GET | /api/v1/lxp/skills/radar | SkillController@apiRadar | Skill radar JSON for charts |
| GET | /api/v1/lxp/feed | FeedController@apiFeed | Feed items JSON |
| GET | /api/v1/lxp/leaderboard | GamificationController@apiLeaderboard | Leaderboard JSON |
| GET | /api/v1/lxp/badges | GamificationController@apiBadges | Badge gallery JSON |
| POST | /api/v1/lxp/engagement | LxpAdminController@logEngagement | Batch engagement log (offline sync) |
| GET | /api/v1/lxp/content | ContentLibraryController@apiIndex | Content library JSON |
| GET | /api/v1/lxp/goals | LearningGoalController@apiIndex | Goals list JSON |

---

## 7. UI Screens

| Screen ID | Screen Name | Route Name | Actor | Description |
|---|---|---|---|---|
| SCR-LXP-01 | My Learning Path | lxp.my-path | Student | Path timeline with activity cards; locked/available/completed states; path completion % |
| SCR-LXP-02 | Path Activity Detail | lxp.my-path.show | Student | Single path detail: activity list, prerequisites, adaptive notifications |
| SCR-LXP-03 | Skill Map | lxp.skill-map | Student | Radar chart (Chart.js) + hierarchical skill tree with score badges |
| SCR-LXP-04 | My Goals | lxp.goals.index | Student | Goal cards with progress bars, days remaining, milestone indicators |
| SCR-LXP-05 | Badge Gallery | lxp.badges | Student | Earned badges (full colour) + locked badges (grey); points total; streak counter |
| SCR-LXP-06 | Points History | lxp.badges.points | Student | Ledger table: action type, date, points earned |
| SCR-LXP-07 | Leaderboard | lxp.leaderboard | Student/Teacher | Ranked table with avatar/name/points; filter by class/subject/period; own rank highlighted |
| SCR-LXP-08 | Activity Feed | lxp.feed | Student | Ranked feed cards; unread indicator; dismiss button; click to navigate |
| SCR-LXP-09 | Content Library | lxp.content.index | All | Grid/list with filter panel (subject, difficulty, Bloom's, type); search bar |
| SCR-LXP-10 | Content Detail | lxp.content.show | All | Video embed / PDF viewer / link redirect; skill tags; difficulty badge; related content |
| SCR-LXP-11 | Add Content | lxp.content.create | Teacher/Admin | Upload form with Bloom's/difficulty/skill multi-select; YouTube URL validator |
| SCR-LXP-12 | Forum List | lxp.forums.index | All | Forum cards with thread/post counts; open/closed status badge |
| SCR-LXP-13 | Forum Detail | lxp.forums.show | All | Thread list with pinned threads at top; search threads; create thread button |
| SCR-LXP-14 | Thread Detail | lxp.forums.thread | All | Thread body + nested replies; reply box with Markdown editor; resolve/pin controls for moderator |
| SCR-LXP-15 | Mentorship Home | lxp.mentorship.index | All | My mentor / my mentees cards; session count; program info |
| SCR-LXP-16 | Session Log | lxp.mentorship.sessions | Mentor/Teacher | Session history table; log new session form |
| SCR-LXP-17 | Class Analytics | lxp.teacher.analytics | Teacher/Admin | KPI cards + skill heatmap + at-risk student list + engagement chart |
| SCR-LXP-18 | Drop-off Analysis | lxp.teacher.dropoff | Teacher/Admin | Bar chart of abandonment rate per activity; click to view content |
| SCR-LXP-19 | Skill Admin | lxp.admin.skills | Admin | Tree view of skills; inline add/edit; CSV import option |
| SCR-LXP-20 | Badge Admin | lxp.admin.badges | Admin | Badge cards with criteria JSON editor; rarity selector; award history |
| SCR-LXP-21 | Mentorship Programs | lxp.admin.programs | Admin | Program list; create/edit form; matching criteria JSON builder |
| SCR-LXP-22 | Mentor Matching | lxp.admin.matches | Admin/Teacher | Suggested pairs table; approve/reject; manual override |
| SCR-LXP-23 | Path Config | lxp.admin.path-config | Admin | Remedial threshold (default 60%), advance threshold (default 85%), points per action config |
| SCR-LXP-24 | Parent LXP View | (parent portal embedded) | Parent | Read-only: path %, skill radar, badges, goals, certificates for ward |
| SCR-LXP-25 | Certificate View | lxp.certificate.show | Student/Parent | Certificate display + download PDF button |
| SCR-LXP-26 | My Goals (Teacher Assign) | lxp.goals.assign | Teacher | Bulk goal assignment to section: subject selector, goal text, target date |
| SCR-LXP-27 | Content Library (Edit) | lxp.content.edit | Teacher/Admin | Edit content metadata, skill mappings, Bloom's level |
| SCR-LXP-28 | Program Dashboard | lxp.admin.programs.show | Admin | Program KPIs: pairs count, sessions total, avg rating, mentee progress chart |

---

## 8. Business Rules

| Rule ID | Rule | Enforcement | Source |
|---|---|---|---|
| BR-LXP-001 | One active learning path per student per subject per academic session | UNIQUE DB constraint + service validation | Data integrity |
| BR-LXP-002 | Locked activities cannot be started until their `prerequisite_activity_id` is marked `completed` | Service-level check in `LearningPathController@startActivity` | Learning design |
| BR-LXP-003 | A badge can only be earned once per student | UNIQUE key `(student_id, badge_id)` in `lxp_student_badges_jnt` | Gamification fairness |
| BR-LXP-004 | Points are insert-only in the ledger; removal requires admin action with mandatory `notes` justification | No DELETE on points_ledger; admin-only negative entry | Audit/fair play |
| BR-LXP-005 | Leaderboard defaults to class-section scope; cross-class view requires `lxp.leaderboard.all` permission | Route middleware + permission check | Privacy/DPDPA |
| BR-LXP-006 | Forum post deletion: author can delete own post; moderator (teacher) can delete any post in their forum; students cannot delete others | Policy check in `ForumController@deletePost` | Safety/moderation |
| BR-LXP-007 | Peer mentor must have skill score >= `matching_criteria_json.mentor_min_skill` (default 75); mentee must have score <= `mentee_max_skill` (default 55) | Validation in `MentorshipController@generateMatches` | Program quality |
| BR-LXP-008 | Engagement logs are insert-only — no updates or soft deletes | No `updated_at`/`deleted_at` columns; remove Laravel model timestamps for this table | Immutable audit |
| BR-LXP-009 | Skill score update formula: `(existing × 0.7) + (new_score × 0.3)`. Score marked 'reliable' only after >= 5 assessments | `SkillTrackingService::updateScore()` | Statistical validity |
| BR-LXP-010 | LXP does not author content — it curates and sequences content from Syllabus, LmsQuiz, LmsExam, LmsHomework, and ContentLibrary | Architecture boundary enforced at service layer | Module boundary |
| BR-LXP-011 | Path completion (100%) auto-triggers `CertificateService`; certificate issued once per path; re-issue requires admin action | Event listener on `path_activity_complete` | V2 new |
| BR-LXP-012 | Content Bloom's level and difficulty are required fields (null not allowed) from V2 onward; enforced by migration NOT NULL + form validation | DB constraint + FormRequest validation | V2 new |
| BR-LXP-013 | Adaptive path score thresholds (60% remedial, 85% advance) are configurable via admin path-config screen and stored in `sys_settings` | Not hardcoded; loaded from settings at runtime | Configurability |
| BR-LXP-014 | Feed items dismissed by a student are never shown again to that student; `dismissed_at` timestamp set and item excluded from future queries | FeedService::generateFeed() WHERE dismissed_at IS NULL | UX |
| BR-LXP-015 | Points cannot be manually awarded by teachers; only admin can insert a positive points record (manual); triggers are system-only for normal flows | Role check in `GamificationController@adminAwardPoints` | Fair play |

---

## 9. Workflow Diagrams (FSM Descriptions)

### 9.1 Learning Path Activity State Machine

```
States: locked → available → in_progress → completed
                                          → skipped (adaptive advance)
         available → locked (re-lock if prerequisite reverted — edge case)

Transitions:
  locked → available         WHEN: prerequisite_activity_id.status == 'completed' OR no prerequisite
  available → in_progress    TRIGGER: student clicks "Start"; POST /activity/{act}/start
  in_progress → completed    TRIGGER: linked module fires completion event; score recorded
  in_progress → available    TRIGGER: student exits without completing (timeout or navigation away)
  completed → [remedial inserted] WHEN: score < threshold (60%)
  available → skipped        WHEN: adaptive advance (score > 85% on prior activity of same difficulty)
```

### 9.2 Badge Award State Machine

```
States: not_earned → earned (terminal — no reversal)

Transitions:
  not_earned → earned   TRIGGER: GamificationService::checkAndAwardBadges(student, event)
                         CONDITION: criteria_json evaluation returns true AND badge not already earned
                         ACTIONS: INSERT lxp_student_badges_jnt; awardPoints(); notify student; add feed item
```

### 9.3 Learning Goal State Machine

```
States: active → achieved
              → missed
              → cancelled

Transitions:
  active → achieved    WHEN: progress_percent >= 100 (auto, triggered by skill score update)
  active → missed      WHEN: target_date < TODAY AND status still active (scheduled job — daily)
  active → cancelled   TRIGGER: student or teacher manually cancels
```

### 9.4 Mentorship Session Lifecycle

```
Program Status: draft → active → completed / cancelled

Pair Status: pending → active → paused → completed

Session Log:
  Mentor books session → creates lxp_mentorship_sessions record (status=scheduled)
  Session occurs → mentor logs notes + rating → status=completed
  sessions_completed counter increments on lxp_mentor_mentee_jnt
```

### 9.5 Peer Recommendation Flow

```
1. Student opens dashboard
2. FeedService / PathSuggestionService queries rec_student_recommendations
   WHERE student_id = X AND status IN ('pending','viewed') AND subject_id = Y
3. Results ranked: skill_gap_score DESC, difficulty ASC
4. Top 5 surfaced as "Recommended for You"
5. On display: rec_student_recommendations.status → 'viewed'
6. On dismiss: stored in session/local preference; excluded from next pull
7. On add-to-path: status → 'accepted'; activity inserted in lxp_path_activities
```

---

## 10. Non-Functional Requirements

| Category | Requirement | Target | Notes |
|---|---|---|---|
| Performance | Student dashboard load | < 2 seconds | Cache skill scores and path completion in Redis or MySQL summary row |
| Performance | Leaderboard query | < 1 second | Indexed aggregation on `lxp_points_ledger.student_id` |
| Performance | Engagement log insert | < 100ms | Lightweight; async batch via `ProcessEngagementJob` for bulk |
| Performance | Badge criteria evaluation | < 500ms per trigger event | In-memory JSON criteria evaluation; no external API call |
| Performance | Feed generation | < 1 second for 20 items | Scoring is arithmetic; no ML at query time |
| Performance | Content library search | < 500ms | MySQL FULLTEXT index |
| Scalability | Tenant isolation | 100% via stancl/tenancy v3.9 | All queries scoped to tenant DB |
| Scalability | Engagement log growth | Partition by `session_date` YEAR-MONTH | Expected high-volume table |
| Security | Role-based access | All routes protected via `sys_model_has_roles_jnt` | No student can access teacher/admin routes |
| Security | Parent data isolation | Parent can only query wards linked via `std_student_parents_jnt` | Enforced at Policy layer |
| Security | Forum moderation | Profanity filter via configurable word list (sys_settings) | Recommended; not enforced at DB |
| Reliability | Soft delete | `deleted_at` on all major tables except `lxp_engagement_logs`, `lxp_points_ledger` | Immutable tables excluded |
| Reliability | Audit trail | Data mutations logged via `sys_activity_logs` | Standard platform pattern |
| Accessibility | WCAG 2.1 AA | All LXP Blade views | Screen reader support for skill radar chart (New in V2) |
| Offline | Content download tracking | Log via engagement_logs; no server-side offline storage | Phase 1 — tracking only |
| Data Retention | Engagement logs | Retain 3 academic years; archive older records | Configurable |
| Certificate | PDF generation | DomPDF (already in stack) | No new dependency |

---

## 11. Module Dependencies

### 11.1 Inbound Dependencies (modules LXP reads from)

| Module | Prefix | Integration | Data Used |
|---|---|---|---|
| Recommendation | `rec_*` | Read | `rec_student_recommendations` — content suggestions for path generation |
| LmsExam | `exm_*` | Event subscription | Exam completion events → update path activity status + skill score |
| LmsQuiz | `quz_*` | Event subscription | Quiz completion events → path activity status + gamification trigger |
| LmsHomework | `hmw_*` | Event subscription | Homework grading events → path activity status |
| Syllabus | `slb_*` | Read | Syllabus topics used as path activity references (`activity_ref_type = 'slb_topics'`) |
| Student Management | `std_*` | Read | `std_students`, `std_student_sections_jnt`, `std_student_parents_jnt` |
| School Setup | `sch_*` | Read | `sch_subjects`, `sch_classes`, `sch_sections`, academic sessions |
| Notification | `ntf_*` | Outbound trigger | Badge earned, goal milestone, mentor session reminders, path adaptation |
| System / Auth | `sys_*` | Read | `sys_users`, `sys_media` (file uploads), `sys_settings` (path thresholds) |

### 11.2 Outbound Dependencies (modules that consume LXP data)

| Module | Prefix | Data Provided |
|---|---|---|
| PredictiveAnalytics | `pan_*` | `lxp_engagement_logs`, `lxp_student_skills` — consumed for learning gap + dropout prediction |
| Parent Portal | `stp_*` | Path completion, badges, goals, certificates — read-only parent view |
| HPC (Holistic Progress Card) | `hpc_*` | Skill scores per student — one dimension of the HPC multi-dimensional profile |
| Dashboard | — | LXP widgets: completion %, active badges, streak — for school-wide dashboard |

### 11.3 Laravel Package Dependencies

| Package | Version | Usage |
|---|---|---|
| stancl/tenancy | v3.9 | Tenant DB isolation for all `lxp_*` tables |
| nwidart/laravel-modules | v12 | Module scaffolding |
| barryvdh/laravel-dompdf | ^2.0 | Certificate PDF generation |
| Laravel Queue | Built-in | `GenerateLearningPathJob`, `ProcessEngagementJob` |
| Laravel Events | Built-in | Cross-module completion event listeners |

---

## 12. Test Scenarios

| # | Test Case | Type | FR Ref | Priority |
|---|---|---|---|---|
| T01 | Dispatch path generation job; activities created ordered by difficulty ascending | Feature | FR-LXP-01 | High |
| T02 | Complete mandatory activity; prerequisite unlocks next activity | Feature | FR-LXP-01 | High |
| T03 | Student cannot start locked activity (prerequisite not met) | Feature | FR-LXP-01 | High |
| T04 | Reorder optional activities; mandatory order unchanged | Feature | FR-LXP-01 | Medium |
| T05 | Path completion 100% → certificate auto-generated → downloadable | Feature | FR-LXP-01, FR-LXP-13 | High |
| T06 | Complete quiz with score 45% → remedial activity inserted before next | Feature | FR-LXP-07 | High |
| T07 | Complete quiz with score 90% → next same-difficulty activity skipped | Feature | FR-LXP-07 | High |
| T08 | Create skill 3 levels deep; circular dependency rejected | Feature | FR-LXP-02 | High |
| T09 | Map quiz to skill; complete quiz; skill score updates via rolling average | Feature | FR-LXP-02 | High |
| T10 | Skill score rolling average: existing=70, new_score=50 → result=64 | Unit | FR-LXP-02 | High |
| T11 | Skill score below 5 assessments → marked as 'not reliable' | Unit | FR-LXP-02 | Medium |
| T12 | Recommendation pull returns top 5 ranked by skill_gap DESC | Feature | FR-LXP-03 | High |
| T13 | Content library: FULLTEXT search returns results in < 500ms | Feature | FR-LXP-04 | High |
| T14 | Content created without Bloom's level → validation error (V2) | Feature | FR-LXP-04 | High |
| T15 | Set goal; progress crosses 25% → notification triggered | Feature | FR-LXP-05 | Medium |
| T16 | Teacher bulk-assigns goal to section; all active students receive goal | Feature | FR-LXP-05 | Medium |
| T17 | Overdue active goal → scheduled job marks as missed | Feature | FR-LXP-05 | Medium |
| T18 | 7-day streak → streak badge auto-awarded; duplicate blocked | Feature | FR-LXP-09 | High |
| T19 | Badge awarded only once per student; second trigger has no effect | Feature | FR-LXP-09 | High |
| T20 | Leaderboard sum matches points ledger sum for student | Feature | FR-LXP-09 | High |
| T21 | Leaderboard filtered by subject shows only subject-earned points | Feature | FR-LXP-09 | Medium |
| T22 | Teacher analytics: at-risk students (< 30% complete + 7 days inactive) flagged | Feature | FR-LXP-10 | High |
| T23 | Drop-off analysis: activity with 80% abandonment rate ranked first | Feature | FR-LXP-10 | Medium |
| T24 | Analytics CSV export contains all class students | Feature | FR-LXP-10 | Medium |
| T25 | Create forum; student posts thread; reply count increments | Feature | FR-LXP-08 | Medium |
| T26 | Student cannot delete another student's forum post | Feature | FR-LXP-08 | High |
| T27 | Forum closes at closes_at date; new posts rejected | Feature | FR-LXP-08 | Medium |
| T28 | Mentorship matching: mentor skill 80, mentee skill 45 → valid pair | Feature | FR-LXP-11 | Medium |
| T29 | Mentor exceeds max_mentees_per_mentor limit → new pair rejected | Feature | FR-LXP-11 | Medium |
| T30 | Feed generation < 1 second for 20 items; dismissed items excluded | Feature | FR-LXP-12 | Medium |
| T31 | Parent can view child's path/badges; cannot post or modify anything | Feature | FR-LXP-15 | High |
| T32 | Admin manually awards points with notes; audit log entry created | Feature | BR-LXP-004 | High |
| T33 | Cross-class leaderboard access blocked without permission | Feature | BR-LXP-005 | High |
| T34 | Content download logs engagement event with activity_type=content_download | Feature | FR-LXP-14 | Low |

---

## 13. Glossary

| Term | Definition |
|---|---|
| Learning Path | Personalized ordered sequence of learning activities for a student per subject per session |
| Skill | A discrete competency node in the hierarchical skill framework (linked to Bloom's taxonomy) |
| Skill Score | Rolling weighted average (0–100) representing a student's mastery of a skill |
| Bloom's Taxonomy | Six-level cognitive framework: Remember → Understand → Apply → Analyse → Evaluate → Create |
| Micro-learning | Short-form content designed for 5–15 minute focused learning sessions |
| Gamification | Application of game elements (points, badges, leaderboards, streaks) to motivate learning |
| Badge | Digital achievement award earned when configurable criteria are met |
| Streak | Consecutive calendar days with at least one learning engagement event |
| Leaderboard | Ranked list of students by total points earned within a scope (class/subject/period) |
| Remedial Activity | An easier-difficulty activity automatically inserted when a student scores below the threshold |
| Adaptive Path | A learning path that dynamically adjusts content difficulty based on student performance |
| Engagement Log | Immutable record of every student learning interaction (view, start, complete, post, download) |
| Feed | Personalized ranked stream of learning events and recommendations for a student |
| Mentor | A higher-performing student or teacher guiding a lower-performing student in a subject |
| Mentee | A student receiving structured support from a mentor |
| Peer Recommendation | Content suggestions derived from what similar-skill-score peers have successfully completed |
| NEP 2020 | India's National Education Policy 2020 — mandates holistic, competency-based assessment |
| CBSE | Central Board of Secondary Education — primary curriculum board for LXP content alignment |
| RBS | Requirement Breakdown Structure — hierarchical feature decomposition used in this platform |
| HPC | Holistic Progress Card — multi-dimensional student assessment module consuming LXP skill data |

---

## 14. Suggestions & Improvements

### 14.1 Architectural Suggestions

| # | Suggestion | Rationale | Priority |
|---|---|---|---|
| S01 | Partition `lxp_engagement_logs` by YEAR-MONTH | Table will grow to millions of rows per school year; partition improves query performance for streak/analytics | High |
| S02 | Cache leaderboard results in Redis with 5-minute TTL | Leaderboard query aggregates entire ledger; caching avoids repeated full-table aggregation | High |
| S03 | Cache student skill radar data per student (invalidate on score update) | Radar data loaded on every dashboard open; caching prevents repeated JOIN queries | Medium |
| S04 | Extract `ProcessEngagementJob` for batch offline sync | Mobile apps will batch engagement events; synchronous logging would create bottleneck on reconnect | Medium |
| S05 | Use Laravel Events for cross-module completion signals | Avoid tight coupling between LMS modules and LXP; use `ExamCompleted`, `QuizSubmitted`, `HomeworkGraded` events | High |

### 14.2 Feature Suggestions (Post-V2)

| # | Suggestion | Rationale | Phase |
|---|---|---|---|
| S06 | LTI 1.3 content import | Allow schools to import SCORM/xAPI content packages from external providers | V3 |
| S07 | AI-powered difficulty calibration | Use item-response theory to auto-tag content difficulty based on student performance data | V3 |
| S08 | Study group rooms | Small-group collaboration spaces linked to a topic/skill (3–6 students + teacher) | V3 |
| S09 | Video completion tracking | Track percentage of YouTube video watched (requires YouTube IFrame API events) | V2.1 |
| S10 | Configurable leaderboard privacy | Option for students to make their rank private (opt-out of public leaderboard) | V2.1 |
| S11 | Parent goal-setting from parent portal | Allow parents to set aspirational goals for their wards (visible to teacher) | V2.1 |
| S12 | Teacher content endorsement | Teacher can 'endorse' content library items for their class, surfacing them prominently | V2.1 |

### 14.3 Indian School Context Adaptations

| # | Suggestion | Context |
|---|---|---|
| S13 | Hindi/regional language content tagging | Add `language` field to `lxp_content_library`; filter by medium of instruction | Required for vernacular schools |
| S14 | Board-specific skill alignment | Tag skills with board code (CBSE, ICSE, IB, State) for multi-board school chains | Multi-school chains |
| S15 | NCERT chapter mapping | Link skills to NCERT textbook chapters for seamless alignment with teacher's lesson plan | Ubiquitous in Indian K-12 |
| S16 | Parental consent workflow for mentor pairing | Student-student mentoring requires parental consent for < Grade 8 students | POCSO compliance |

---

## 15. Appendices

### 15.1 Points Earning Reference Table (Default Configuration)

| Action | Default Points | Configurable | Badge Trigger |
|---|---|---|---|
| Complete a path activity | 10 | Yes | activity_complete |
| Complete quiz with 100% | 25 | Yes | quiz_perfect |
| Earn a badge | Badge.points value | Per badge | badge_earned |
| Post in forum | 5 | Yes | forum_post |
| Achieve a learning goal | 50 | Yes | goal_achieved |
| Daily login streak bonus (per day) | 3 | Yes | streak_bonus |
| Complete a mentoring session | 15 | Yes | mentor_session |
| Download content for offline | 2 | Yes | content_download |

### 15.2 Badge Criteria JSON Examples

```json
// 7-day streak badge
{"type": "streak", "days": 7}

// Skill mastery badge
{"type": "skill_score", "skill_id": 12, "min_score": 80}

// Path completion badge
{"type": "path_complete", "subject_id": null}

// Perfect quiz badge
{"type": "quiz_perfect", "count": 1}

// Forum participation badge
{"type": "forum_post", "count": 10}

// First activity complete
{"type": "activity_complete", "count": 1}
```

### 15.3 Adaptive Path Threshold Config (sys_settings keys)

| Setting Key | Default Value | Description |
|---|---|---|
| `lxp.adaptive.remedial_threshold` | 60 | Score (%) below which remedial activity inserted |
| `lxp.adaptive.advance_threshold` | 85 | Score (%) above which next same-difficulty activity skipped |
| `lxp.gamification.points_activity_complete` | 10 | Points per activity completion |
| `lxp.gamification.points_quiz_perfect` | 25 | Points for 100% quiz score |
| `lxp.gamification.points_forum_post` | 5 | Points per forum post |
| `lxp.leaderboard.default_scope` | section | Default leaderboard scope: section / class / school |
| `lxp.skill_score.reliable_min_assessments` | 5 | Minimum assessments for reliable skill score |

### 15.4 Service Method Signatures

**PathSuggestionService**
```php
suggest(Student $student, Subject $subject): array
buildFromSuggestions(Student $student, Subject $subject, int $sessionId): LearningPath
adaptPathOnCompletion(PathActivity $activity, float $score): void
```

**GamificationService**
```php
awardPoints(Student $student, string $actionType, int $points, ?int $refId, ?string $refType): void
checkAndAwardBadges(Student $student, string $triggerEvent): array
calculateStreak(Student $student): int
getLeaderboard(array $filters): Collection
```

**SkillTrackingService**
```php
updateScore(int $studentId, int $skillId, float $rawScore): LxpStudentSkill
getRadarData(int $studentId, int $subjectId): array
identifyGaps(int $studentId, float $threshold = 60.0): Collection
```

**FeedService**
```php
generateFeed(int $studentId, int $limit = 20): array
markItemRead(int $studentId, int $feedItemId): void
dismissItem(int $studentId, int $feedItemId): void
```

**CertificateService** (New in V2)
```php
generate(LearningPath $path): LxpCertificate
download(LxpCertificate $cert): StreamedResponse
revoke(LxpCertificate $cert, string $reason, int $adminId): void
```

---

## 16. V1 → V2 Delta

### 16.1 New Tables in V2

| Table | Purpose |
|---|---|
| `lxp_forum_posts` | Nested replies within forum threads (V1 only had threads — no dedicated reply table) |
| `lxp_mentor_mentee_jnt` | Approved mentor-mentee pairs (V1 referenced this table in text but had no DDL) |
| `lxp_mentorship_sessions` | Session logs per pair (V1 referenced in text but had no DDL) |
| `lxp_certificates` | Path completion certificate storage (entirely new in V2) |
| `lxp_feed_items` | Materialized feed events (V1 described feed as purely computed at query time) |

### 16.2 Schema Changes to Existing V1 Tables

| Table | Column | Change | Reason |
|---|---|---|---|
| `lxp_content_library` | `bloom_level` | NULL → NOT NULL | V2 enforces Bloom's tagging as required |
| `lxp_content_library` | `difficulty` | Default 'medium' kept; validation now enforced in FormRequest | Consistency |
| `lxp_engagement_logs` | `activity_type` ENUM | Added `'content_download'`, `'path_adapted'` | New tracking events |
| `lxp_points_ledger` | `action_type` ENUM | Added `'content_download'` | New earning action |
| `lxp_badges` | `rarity` ENUM | Always present; V2 documents visual styling tied to rarity | UX clarification |

### 16.3 New Functional Requirements in V2

| FR | Title | Status |
|---|---|---|
| FR-LXP-13 | Path Completion Certificates | 📐 Proposed (New) |
| FR-LXP-14 | Offline Content Download Tracking | 📐 Proposed (New) |
| FR-LXP-15 | Parent Portal LXP Visibility | 📐 Proposed (New) |

### 16.4 New Screens in V2

SCR-LXP-24 (Parent LXP View), SCR-LXP-25 (Certificate View), SCR-LXP-26 (Teacher Goal Assign), SCR-LXP-27 (Content Edit), SCR-LXP-28 (Program Dashboard)

### 16.5 New Business Rules in V2

BR-LXP-011 (certificate issuance), BR-LXP-012 (Bloom's required), BR-LXP-013 (configurable thresholds), BR-LXP-014 (feed dismissal persistence), BR-LXP-015 (teacher cannot award points)

### 16.6 NFR Changes in V2

- Added WCAG 2.1 AA accessibility requirement (all LXP views)
- Added data retention policy (3 academic years for engagement logs)
- Added partitioning recommendation for `lxp_engagement_logs`
- Added `ProcessEngagementJob` for async batch engagement logging (offline sync support)

### 16.7 Unchanged from V1

All 12 original functional requirements (FR-LXP-01 through FR-LXP-12) are retained and refined. All 14 original table definitions are retained with minor column additions. All 10 business rules (BR-LXP-001 through BR-LXP-010) are retained verbatim. All 4 original services are retained; `CertificateService` added as fifth.

---

*Document generated: 2026-03-26 | Next review: Before Sprint LXP-01 kickoff*
*Owner: Prime-AI Architecture Team | Approver: Tech Lead*

