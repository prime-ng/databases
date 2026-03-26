# LXP — Learner Experience Platform Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** LXP | **Module Path:** `Modules/Lxp`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `lxp_*` | **Processing Mode:** RBS_ONLY (Greenfield)
**RBS Reference:** Module T — Learner Experience Platform (lines 3921-4037)

---

## 1. EXECUTIVE SUMMARY

### 1.1 Purpose

The LXP (Learner Experience Platform) module transforms Prime-AI from a transactional LMS (assignments submitted, exams taken, marks recorded) into a personalized, adaptive, gamified learning ecosystem. While the LMS modules (LmsExam, LmsQuiz, LmsHomework, Syllabus) manage the instructional layer, the LXP sits above them to orchestrate *how* a student experiences learning — through personalized paths, skill graphs, badges, peer collaboration, mentorship, and an AI-curated activity feed. The LXP leverages output from the Recommendation module (`rec_*`) as a content-suggestion engine and feeds engagement signals to the PredictiveAnalytics module (`pan_*`) for learning outcome predictions.

### 1.2 Scope

This module covers:
- Personalized learning paths: AI-curated activity sequences mapped to a student's competency target
- Skill framework and competency mapping: hierarchical skill tree linked to Syllabus content
- Gamification engine: points ledger, badges, streak tracking, leaderboards
- Micro-learning content library: bite-sized video/PDF/article/quiz content with Bloom's taxonomy tagging
- Learning goals and roadmaps: student-set and teacher-assigned goals with milestone tracking
- Social learning: discussion forums, peer mentoring, study groups
- Mentorship program management: mentor-mentee matching, session scheduling, progress tracking
- Personalized activity feed: aggregates announcements, peer activity, new content, badges earned
- Learning analytics: engagement tracking, time-on-task, drop-off identification
- Teacher analytics: class-level engagement and progress dashboard

Out of scope: direct content authoring (handled by HPC/Syllabus modules), external LTI-compliant course import, video streaming infrastructure (external links and YouTube embeds only), mobile push notifications (web notification only in v1).

### 1.3 Module Statistics

| Metric | Count |
|---|---|
| RBS Features (F.T*) | 19 (T1–T9) |
| RBS Tasks | 31 |
| RBS Sub-tasks | 47 |
| Proposed DB Tables (lxp_*) | 14 |
| Proposed Named Routes | ~65 |
| Proposed Blade Views | ~40 |
| Proposed Controllers | 10 |
| Proposed Models | 14 |
| Proposed Services | 4 |
| Proposed Jobs | 1 (path suggestion generation) |

### 1.4 Implementation Status

| Layer | Status | Notes |
|---|---|---|
| DB Schema / Migrations | ❌ Not Started | 14 tables proposed |
| Models | ❌ Not Started | 14 models proposed |
| Controllers | ❌ Not Started | 10 controllers proposed |
| Services | ❌ Not Started | PathSuggestionService, GamificationService, SkillTrackingService, FeedService |
| Blade Views | ❌ Not Started | ~40 views proposed |
| Routes | ❌ Not Started | tenant.php additions required |
| Tests | ❌ Not Started | Browser + Feature + Unit tests proposed |

**Overall Implementation: 0% — Greenfield**

---

## 2. MODULE OVERVIEW

### 2.1 Business Purpose

Indian K-12 schools increasingly recognize that uniform instruction does not account for the significant variation in student learning levels within a single classroom. A student who struggles with fractions needs different next-step content from one who has mastered them. Yet teachers managing 40+ students cannot individually curate learning sequences.

The LXP addresses this by:

1. **Personalizing the learning sequence** — the platform uses performance signals (exam scores, quiz results, attendance patterns) to recommend what a student should learn next, adapting difficulty in real time.
2. **Making learning visible** — students see a visual "learning path" showing completed, in-progress, and locked activities. Progress is no longer invisible.
3. **Motivating through gamification** — points, badges, streaks, and leaderboards introduce healthy competition and intrinsic motivation mechanisms proven effective in Indian school contexts.
4. **Building skills systematically** — the skill graph maps every piece of content to competencies aligned with NCERT/CBSE learning outcomes. Teachers and parents can see exactly which competencies a child has achieved.
5. **Enabling peer and mentor learning** — discussion forums and mentorship programs allow stronger students to support weaker ones under teacher supervision.
6. **Feeding intelligence back to the system** — every learning interaction generates engagement signals that flow into the PredictiveAnalytics module to power dropout risk and learning gap models.

### 2.2 Key Features Summary

| Feature Area | Description | RBS Ref | Status |
|---|---|---|---|
| Personalized Learning Paths | AI-curated activity sequence per student per subject | F.T1.1, F.T1.2 | ❌ Not Started |
| Skill Framework & Competency Map | Hierarchical skill tree; map content to competencies | F.T2.1, F.T2.2 | ❌ Not Started |
| AI Content Recommendations | Use Recommendation module + behavior signals | F.T3.1, F.T3.2 | ❌ Not Started |
| Learning Goals & Roadmaps | Student/teacher-set goals with timeline and milestones | F.T4.1, F.T4.2 | ❌ Not Started |
| Gamification — Badges & Points | Points ledger, badge awards, streaks | F.T5.1 | ❌ Not Started |
| Gamification — Leaderboards | Class/subject leaderboards | F.T5.2 | ❌ Not Started |
| Discussion Forums | Topic-based forums with threading and attachments | F.T6.1 | ❌ Not Started |
| Peer Mentoring | Mentor-mentee assignment and session logging | F.T6.2 | ❌ Not Started |
| Learning Analytics | Engagement, time-on-task, drop-off, teacher dashboard | F.T7.1, F.T7.2 | ❌ Not Started |
| Mentorship Programs | Formal programs with matching criteria and feedback | F.T8.1, F.T8.2 | ❌ Not Started |
| Personalized Activity Feed | Ranked aggregated feed from all learning activity | F.T9.1 | ❌ Not Started |
| Micro-Learning Content Library | Bite-sized content with Bloom's level and difficulty | FR-LXP-009 | ❌ Not Started |

### 2.3 Menu Navigation Path

```
School Admin / Student Panel
└── LXP [/lxp]
    ├── My Learning Path          [/lxp/my-path]              (student view)
    ├── Skill Map                 [/lxp/skill-map]             (student view)
    ├── My Goals                  [/lxp/goals]
    ├── My Badges                 [/lxp/badges]
    ├── Leaderboard               [/lxp/leaderboard]
    ├── Content Library           [/lxp/content-library]
    ├── Discussion Forums         [/lxp/forums]
    ├── Mentorship                [/lxp/mentorship]
    ├── Activity Feed             [/lxp/feed]
    ├── Teacher Analytics         [/lxp/teacher/analytics]    (teacher/admin view)
    ├── Administration
    │   ├── Skill Management      [/lxp/admin/skills]
    │   ├── Badge Management      [/lxp/admin/badges]
    │   ├── Mentorship Programs   [/lxp/admin/mentorship-programs]
    │   └── Learning Path Config  [/lxp/admin/path-config]
    └── Reports                   [/lxp/reports]
```

### 2.4 Proposed Module Architecture

```
Modules/Lxp/
├── app/
│   ├── Http/Controllers/
│   │   ├── LearningPathController.php         # Student path view + progress
│   │   ├── SkillController.php                # Skill framework CRUD (admin)
│   │   ├── ContentLibraryController.php       # Content CRUD + browse
│   │   ├── GamificationController.php         # Badges, points, leaderboard
│   │   ├── LearningGoalController.php         # Goal CRUD + tracking
│   │   ├── ForumController.php                # Discussion forums + threads
│   │   ├── MentorshipController.php           # Programs + matching + sessions
│   │   ├── FeedController.php                 # Personalized activity feed
│   │   ├── LxpAnalyticsController.php         # Teacher analytics + insights
│   │   └── LxpAdminController.php             # Admin configuration
│   ├── Jobs/
│   │   └── GenerateLearningPathJob.php        # Async AI path generation
│   ├── Models/
│   │   ├── LearningPath.php
│   │   ├── PathActivity.php
│   │   ├── LxpSkill.php
│   │   ├── LxpSkillContentJnt.php
│   │   ├── LxpStudentSkill.php
│   │   ├── LxpBadge.php
│   │   ├── LxpStudentBadgeJnt.php
│   │   ├── LxpPointsLedger.php
│   │   ├── LxpLearningGoal.php
│   │   ├── LxpContentLibrary.php
│   │   ├── LxpForum.php
│   │   ├── LxpForumThread.php
│   │   ├── LxpMentorshipProgram.php
│   │   ├── LxpMentorMenteeJnt.php
│   │   └── LxpEngagementLog.php
│   ├── Policies/ (6 policies)
│   ├── Providers/
│   │   ├── LxpServiceProvider.php
│   │   └── RouteServiceProvider.php
│   └── Services/
│       ├── PathSuggestionService.php          # AI path curation using rec_* + performance signals
│       ├── GamificationService.php            # Points award + badge trigger + streak calculation
│       ├── SkillTrackingService.php           # Skill score updates after assessment completion
│       └── FeedService.php                   # Feed aggregation + ranking algorithm
├── database/migrations/ (14 migrations)
├── resources/views/lxp/
│   ├── student/          # My path, skill map, goals, badges, leaderboard, feed
│   ├── content/          # Library browse, content detail
│   ├── gamification/     # Badge gallery, leaderboard, points history
│   ├── forums/           # Forum list, thread view, create forum, create thread
│   ├── mentorship/       # Programs, my mentor/mentees, sessions
│   ├── teacher/          # Class analytics, engagement dashboard
│   ├── admin/            # Skills, badges, path config, program management
│   └── reports/          # Engagement, path completion, skill coverage
└── routes/
    ├── api.php
    └── web.php
```

---

## 3. STAKEHOLDERS & ACTORS

| Actor | Role in LXP Module | Permissions |
|---|---|---|
| School Admin | Configure skills framework, badges, mentorship programs, content library, reports | All permissions |
| Principal | View school-wide analytics, mentor program oversight | view-all, analytics |
| Teacher | View class analytics, manage forums for their class, assign learning goals, act as mentor | class-scoped analytics, forum.manage, goal.assign |
| Student | Navigate own learning path, set goals, earn badges, join forums, request mentor | student-scoped access |
| Parent | View child's learning path and badge progress (read-only via portal) | view (own ward) |
| System | Auto-generate path suggestions, award points/badges on triggers, update engagement logs | system actor |

---

## 4. FUNCTIONAL REQUIREMENTS

---

### FR-LXP-001: Personalized Learning Path

**RBS Reference:** F.T1.1 — Path Creation, F.T1.2 — AI-Based Path Suggestions
**Priority:** 🔴 Critical
**Status:** ❌ Not Started
**Table(s):** `lxp_learning_paths`, `lxp_path_activities`

#### Requirements

**REQ-LXP-001.1: Create Learning Path for Student**
| Attribute | Detail |
|---|---|
| Description | A learning path is a personalized, ordered sequence of learning activities (lessons, quizzes, homework sets, videos, readings, practice questions) created for a specific student and subject. The system generates a suggested path automatically based on performance data; teachers and students can customize it. |
| Actors | System (auto-generation), Teacher (manual creation/editing), Student (reordering optional items) |
| Preconditions | Student enrolled in academic session; subject exists in `sch_subjects` |
| Input | student_id, subject_id, academic_session_id, competency_target_id (optional), goal_description (optional) |
| Processing | Dispatch `GenerateLearningPathJob`; job queries: recent quiz/exam scores for this student+subject; identifies weak competencies; pulls recommended content from `rec_student_recommendations`; orders activities by difficulty (easy → medium → hard); creates `lxp_learning_paths` record + child `lxp_path_activities` records |
| Output | Learning path created with initial set of activities; student notified |
| Status | 📐 Proposed |

**REQ-LXP-001.2: Learning Path Activity Management**
| Attribute | Detail |
|---|---|
| Description | Each activity in the path can be locked (prerequisites not met), available, in-progress, or completed. Activities unlock sequentially or based on prerequisite activity completion. |
| Input | path_id, activity modifications (add/remove/reorder — teacher only); student marks activity as started |
| Processing | On activity start: update status to 'in_progress'; log start in `lxp_engagement_logs`; On completion event received from linked module (LmsQuiz, LmsExam, LmsHomework): update status to 'completed'; recalculate `completion_percent`; trigger GamificationService.onActivityComplete(); unlock next activity |
| Output | Path progress updated; points awarded; next activity unlocked |
| Status | 📐 Proposed |

**REQ-LXP-001.3: AI-Based Path Suggestions**
| Attribute | Detail |
|---|---|
| Description | System analyzes learner profile (past scores, engagement patterns, learning speed, peer comparison) and recommends a personalized activity sequence. Suggestions come from the Recommendation module's active rules and are ranked by relevance score. |
| Addresses | ST.T1.2.1.1 — Analyze learner profile & behavior; ST.T1.2.1.2 — Recommend personalized path |
| Processing | `PathSuggestionService::suggest(student, subject)` — pull `rec_student_recommendations` with status='pending'; filter by subject; rank by rec_recommendation_materials.difficulty + current skill level; create ordered path |
| Output | Suggested path activities listed for teacher/student review before activation |
| Status | 📐 Proposed |

**REQ-LXP-001.4: Path Customization by Student**
| Attribute | Detail |
|---|---|
| Description | Students can reorder optional activities in their path (marked `is_optional=true`). Required activities maintain their locked/sequenced order. |
| Addresses | ST.T1.1.2.1 — Allow learners to reorder items; ST.T1.1.2.2 — Enable optional modules |
| Processing | Reorder only affects `sequence_order` on `is_optional=true` activities; mandatory activities remain in fixed order |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.T1.1.1.1 — Path creation requires selecting a competency or subject goal
- [ ] ST.T1.1.1.2 — Activities added in correct sequence with prerequisites defined
- [ ] ST.T1.1.1.3 — Prerequisites for each activity can be configured
- [ ] ST.T1.1.2.1 — Student can reorder optional activities
- [ ] ST.T1.2.1.1 — AI suggestion analyzes past quiz/exam scores and engagement
- [ ] ST.T1.2.1.2 — Suggested path is ranked by relevance (weakest competencies first)

**Proposed Test Cases:**
| # | Scenario | Type | Priority |
|---|---|---|---|
| 1 | Auto-generate path for student; activities ordered by difficulty | Feature | High |
| 2 | Complete an activity; next activity unlocks; completion_percent updates | Feature | High |
| 3 | Complete activity; points awarded via GamificationService | Feature | High |
| 4 | Student reorders optional activities; mandatory order unchanged | Feature | Medium |

---

### FR-LXP-002: Skill Framework and Competency Mapping

**RBS Reference:** F.T2.1 — Skill Framework, F.T2.2 — Skill Tracking
**Priority:** 🔴 Critical
**Status:** ❌ Not Started
**Table(s):** `lxp_skills`, `lxp_skill_content_jnt`, `lxp_student_skills`

#### Requirements

**REQ-LXP-002.1: Skill Framework Configuration**
| Attribute | Detail |
|---|---|
| Description | Admin defines a hierarchical skill framework. Skills are organized in categories (Technical/Cognitive/Soft/Creative) and linked to subjects. Each skill can have a parent skill (hierarchy). Examples: Mathematics → Number Theory → Fractions → Addition of Fractions. |
| Actors | School Admin |
| Input | skill_name, skill_code (unique), skill_category ENUM('technical','cognitive','soft','creative'), parent_skill_id (optional), subject_id FK, description, bloom_level ENUM('remember','understand','apply','analyse','evaluate','create') |
| Processing | Create `lxp_skills` record; build hierarchy via `parent_skill_id` self-join; validate no circular dependency |
| Output | Skill appears in skill framework tree |
| Status | 📐 Proposed |

**REQ-LXP-002.2: Map Skills to Content**
| Attribute | Detail |
|---|---|
| Description | Admin/teacher maps content items (from LMS content, content library, syllabus topics) to one or more skills. This mapping drives what skills get updated when a student completes a piece of content. |
| Addresses | ST.T2.1.2.1 — Assign skills to lessons; ST.T2.1.2.2 — Link assessments to competencies |
| Input | content_type ENUM('lesson','quiz','homework','library_content','syllabus_topic'), content_ref_id, skill_ids (multiple), skill_weight DECIMAL(3,2) DEFAULT 1.0 |
| Processing | Create `lxp_skill_content_jnt` records; when content is completed by student → trigger SkillTrackingService |
| Status | 📐 Proposed |

**REQ-LXP-002.3: Student Skill Score Tracking**
| Attribute | Detail |
|---|---|
| Description | Each student has a skill score (0–100) per skill, updated when they complete assessments linked to that skill. Score is a weighted rolling average of performance across all linked content completed. |
| Addresses | ST.T2.2.1.1 — Update skill score after assessment; ST.T2.2.1.2 — Generate skill radar chart |
| Processing | `SkillTrackingService::updateScore(student, skill, rawScore)` — weighted average of existing score (70%) + new score (30%); upsert `lxp_student_skills` record |
| Output | Skill score updated; radar chart data refreshed for student dashboard |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] Skill hierarchy can be configured 3+ levels deep (subject → topic → sub-topic skill)
- [ ] Multiple skills can be mapped to a single piece of content
- [ ] Student skill score updates correctly after completing a linked quiz
- [ ] Skill radar chart data is queryable per student per subject

---

### FR-LXP-003: AI Recommendations Engine Integration

**RBS Reference:** F.T3.1 — Content Recommendations, F.T3.2 — Peer-Based Recommendations
**Priority:** 🟡 High
**Status:** ❌ Not Started
**Table(s):** `lxp_learning_paths`, `lxp_path_activities` (uses `rec_student_recommendations`)

#### Requirements

**REQ-LXP-003.1: Content Recommendation Pull**
| Attribute | Detail |
|---|---|
| Description | LXP pulls active recommendations from `rec_student_recommendations` (Recommendation module) and surfaces them as "Suggested Next" items in the learning path and content feed. The LXP does not generate recommendations independently — it consumes the Recommendation module's output. |
| Addresses | ST.T3.1.1.1 — Use ML model to recommend next lesson; ST.T3.1.1.2 — Rank by relevance |
| Processing | Query `rec_student_recommendations` where student_id = current student AND status IN ('pending','viewed'); filter by subject; rank by (skill_gap_score DESC, difficulty ASC); surface top 5 as "Recommended for You" |
| Status | 📐 Proposed |

**REQ-LXP-003.2: Peer-Based Suggestions**
| Attribute | Detail |
|---|---|
| Description | Identify similar learners (same class, similar skill scores within ±15 points) and surface content that peers with slightly higher scores have recently completed successfully. |
| Addresses | ST.T3.2.1.1 — Identify similar learners; ST.T3.2.1.2 — Suggest content based on peer success |
| Processing | Query `lxp_student_skills` for peers with similar score profile; find `lxp_path_activities` status='completed' by those peers; deduplicate against current student's completed activities; surface as "Peers Also Learned" |
| Output | "Peers Also Learned" section in student dashboard |
| Status | 📐 Proposed |

---

### FR-LXP-004: Micro-Learning Content Library

**RBS Reference:** FR-LXP-009 (platform specification)
**Priority:** 🟡 High
**Status:** ❌ Not Started
**Table(s):** `lxp_content_library`

#### Requirements

**REQ-LXP-004.1: Content Library Management**
| Attribute | Detail |
|---|---|
| Description | Curated library of bite-sized learning content (5–15 minutes). Content types: YouTube video link, PDF document (uploaded), article (external URL), embedded quiz. Tagged by subject, Bloom's taxonomy level, difficulty, and skills addressed. |
| Actors | Admin, Teacher (contribute content), Student (browse) |
| Input | title, content_type ENUM('video','pdf','article','link','quiz'), url (external) NULL, file_path (uploaded) NULL, subject_id FK, bloom_level ENUM('remember','understand','apply','analyse','evaluate','create'), difficulty ENUM('easy','medium','hard','advanced'), duration_minutes TINYINT, skill_ids (multi-select), description, thumbnail_url NULL, source_attribution VARCHAR(200) NULL |
| Processing | For uploaded PDFs: store via sys_media; For YouTube URLs: extract video ID, store embed URL; create `lxp_content_library` record; auto-link skills via `lxp_skill_content_jnt` |
| Output | Content appears in library browse view |
| Status | 📐 Proposed |

**REQ-LXP-004.2: Content Browse and Search**
| Attribute | Detail |
|---|---|
| Description | Students and teachers can browse the content library with filters: subject, difficulty, Bloom's level, skill, content type. Full-text search on title and description. |
| Processing | MySQL FULLTEXT index on `title`, `description`; filter by linked attributes |
| Output | Paginated content list with thumbnail/icon, type badge, duration, difficulty badge |
| Status | 📐 Proposed |

---

### FR-LXP-005: Learning Goals and Roadmaps

**RBS Reference:** F.T4.1 — Goal Setting, F.T4.2 — Goal Tracking
**Priority:** 🟡 High
**Status:** ❌ Not Started
**Table(s):** `lxp_learning_goals`

#### Requirements

**REQ-LXP-005.1: Set Learning Goal**
| Attribute | Detail |
|---|---|
| Description | Students can self-set learning goals (e.g., "Master fractions by end of term") or teachers can assign goals to individual students or entire class sections. Goals are linked to a subject and optionally to specific skills. |
| Actors | Student (self-set), Teacher (assign to student/class) |
| Input | student_id, subject_id, skill_id NULL (optional), goal_description, goal_type ENUM('self','teacher_assigned'), target_date, target_skill_score INT NULL |
| Processing | Create `lxp_learning_goals` record; if teacher assigns to section: bulk-create for all active students in that section |
| Output | Goal appears on student's "My Goals" page with progress bar |
| Status | 📐 Proposed |

**REQ-LXP-005.2: Goal Progress Tracking**
| Attribute | Detail |
|---|---|
| Description | Goal progress is computed as: `(current_skill_score / target_skill_score) * 100` for skill-linked goals, or as manual teacher-updated percent for descriptive goals. Milestone reminders are sent when goal is 25%, 50%, 75% complete. |
| Addresses | ST.T4.2.1.1 — View completion bar; ST.T4.2.1.2 — Receive milestone reminders |
| Processing | Recompute progress on each skill score update; if progress crosses 25/50/75/100% thresholds → trigger notification |
| Output | Updated progress bar; notification triggered |
| Status | 📐 Proposed |

---

### FR-LXP-006: Student Progress Dashboard

**RBS Reference:** F.T7.1 — Engagement Analytics, F.T7.2 — AI Insights (student perspective)
**Priority:** 🔴 Critical
**Status:** ❌ Not Started
**Table(s):** `lxp_engagement_logs`, `lxp_learning_paths`, `lxp_student_skills`

#### Requirements

**REQ-LXP-006.1: Student Learning Dashboard**
| Attribute | Detail |
|---|---|
| Description | Each student's personal dashboard showing: overall path completion percentage, active goals with progress, total points earned, badges earned, current streak, skill radar chart, recently completed activities, and "Recommended for You" section. |
| Actors | Student, Parent (read-only) |
| Processing | Aggregate from: `lxp_learning_paths` (completion_percent), `lxp_learning_goals` (progress), `lxp_points_ledger` (sum), `lxp_student_badges_jnt` (badges), `lxp_student_skills` (radar chart data), `lxp_engagement_logs` (streak calculation) |
| Output | Visual dashboard with charts, badges, progress bars |
| Status | 📐 Proposed |

**REQ-LXP-006.2: Engagement Logging**
| Attribute | Detail |
|---|---|
| Description | Every learning interaction is logged: activity started, activity completed, content viewed, time spent (session duration), quiz attempted. This powers engagement analytics and streak calculation. |
| Input | student_id, activity_type ENUM('path_activity_start','path_activity_complete','content_view','forum_post','goal_update'), reference_id, reference_type, duration_seconds INT NULL, session_date DATE |
| Processing | Insert `lxp_engagement_logs` record on every interaction; streak = consecutive calendar days with at least one engagement event |
| Status | 📐 Proposed |

---

### FR-LXP-007: Adaptive Assessment Integration

**RBS Reference:** F.T7.2 — AI Insights (difficulty adaptation)
**Priority:** 🟡 High
**Status:** ❌ Not Started
**Table(s):** `lxp_path_activities`, `lxp_student_skills`

#### Requirements

**REQ-LXP-007.1: Difficulty Adaptation in Path**
| Attribute | Detail |
|---|---|
| Description | When a student completes a path activity and scores below threshold (< 60%), the next suggested activity is adjusted to an easier difficulty level for the same competency. If they score above 85%, the next activity advances to a harder level, skipping intermediate content. |
| Processing | On activity completion event: check score; if score < 60%: insert a 'remedial' activity at easier difficulty before the next planned activity; if score > 85%: mark next same-difficulty activity as 'skipped'; proceed to next difficulty level |
| Output | Path dynamically reordered; student notified of path update |
| Status | 📐 Proposed |

---

### FR-LXP-008: Social Learning — Discussion Forums and Peer Support

**RBS Reference:** F.T6.1 — Discussion Forums, F.T6.2 — Peer Support
**Priority:** 🟡 High
**Status:** ❌ Not Started
**Table(s):** `lxp_forums`, `lxp_forum_threads`, `lxp_forum_posts`

#### Requirements

**REQ-LXP-008.1: Discussion Forum Management**
| Attribute | Detail |
|---|---|
| Description | Teachers create discussion forums tied to a subject or topic. Students can post threads, reply to threads, and upload attachments (images, PDFs). Forums are scoped to a class section (not cross-section by default). |
| Actors | Teacher (create forum, moderate), Student (post, reply) |
| Input | For forum creation: title, subject_id, class_id, section_id, description, moderator_user_id, is_open TINYINT(1), closes_at DATE NULL |
| Processing | Create `lxp_forums` record; notify section students of new forum; student posts create `lxp_forum_threads` or `lxp_forum_posts` depending on level |
| Output | Forum visible to section students; posting activity feeds into engagement log |
| Status | 📐 Proposed |

**REQ-LXP-008.2: Peer Mentoring**
| Attribute | Detail |
|---|---|
| Description | Teacher assigns a higher-performing student as a peer mentor to a struggling student for a specific subject. Mentoring sessions are tracked (date, duration, topics covered, notes). |
| Addresses | ST.T6.2.1.1 — Assign mentors; ST.T6.2.1.2 — Track mentoring sessions |
| Input | mentor_student_id, mentee_student_id, subject_id, academic_session_id, assigned_by (teacher_id) |
| Processing | Create `lxp_mentor_mentee_jnt` record; peer mentor receives notification; sessions logged via `lxp_mentorship_sessions` |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.T6.1.1.1 — Forum can be created with topic and subject assignment
- [ ] ST.T6.1.1.2 — Moderator assigned to forum
- [ ] ST.T6.1.2.1 — Students can post comments/threads
- [ ] ST.T6.1.2.2 — Attachments can be uploaded in threads
- [ ] ST.T6.2.1.1 — Peer mentor-mentee pairing can be created
- [ ] ST.T6.2.1.2 — Mentoring sessions logged with notes and duration

---

### FR-LXP-009: Gamification Engine

**RBS Reference:** F.T5.1 — Badges & Rewards, F.T5.2 — Leaderboards
**Priority:** 🔴 Critical
**Status:** ❌ Not Started
**Table(s):** `lxp_badges`, `lxp_student_badges_jnt`, `lxp_points_ledger`

#### Requirements

**REQ-LXP-009.1: Badge Management**
| Attribute | Detail |
|---|---|
| Description | Admin defines badges with criteria (JSON-encoded trigger rules). Badges are auto-awarded when criteria are met. Badge categories: achievement (first quiz above 90%), streak (7-day learning streak), skill (reach score 80 in a skill), milestone (complete entire learning path). |
| Actors | Admin (define badges), System (auto-award) |
| Input | name, description, icon_path (upload), category ENUM('achievement','streak','skill','milestone','participation'), criteria_json (e.g., `{"type":"streak","days":7}` or `{"type":"skill_score","skill_id":5,"min_score":80}`), points INT, rarity ENUM('common','rare','epic','legendary') |
| Processing | `GamificationService::checkAndAwardBadges(student, triggerEvent)` — evaluate all active badge criteria against student data; award badges not yet earned; insert `lxp_student_badges_jnt`; add points to `lxp_points_ledger`; notify student |
| Output | Badge displayed on student profile; points added; feed event generated |
| Status | 📐 Proposed |

**REQ-LXP-009.2: Points Ledger**
| Attribute | Detail |
|---|---|
| Description | Every point-earning event (complete activity, earn badge, forum post, goal achieved, streak) is recorded in the ledger with the action type and reference. Total points determine leaderboard rank. |
| Input | student_id, points (positive for earn, negative for penalties if applicable), action_type ENUM('activity_complete','badge_earned','forum_post','goal_achieved','streak_bonus','quiz_perfect'), reference_id INT NULL, reference_type VARCHAR(50) NULL |
| Processing | Insert `lxp_points_ledger` record; sum cached on `lxp_learning_paths.total_points` or computed at query time |
| Status | 📐 Proposed |

**REQ-LXP-009.3: Leaderboard**
| Attribute | Detail |
|---|---|
| Description | Real-time leaderboard showing top students by total points. Filterable by: class, section, subject, academic session, time period (weekly/monthly/all-time). |
| Addresses | ST.T5.2.1.1 — List top performers; ST.T5.2.1.2 — Filter by class/subject |
| Processing | Aggregate `SUM(points)` from `lxp_points_ledger` grouped by student_id with filters applied; join student name and class data; rank order |
| Output | Paginated leaderboard table; current student's rank highlighted |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.T5.1.1.1 — Badge criteria configurable via JSON (streak, score threshold, completion)
- [ ] ST.T5.1.1.2 — Badge auto-awarded on meeting criteria; student notified
- [ ] ST.T5.2.1.1 — Leaderboard shows ranked student list with points
- [ ] ST.T5.2.1.2 — Leaderboard filterable by class/subject

---

### FR-LXP-010: Teacher Analytics Dashboard

**RBS Reference:** F.T7.1 — Engagement Analytics, F.T7.2 — AI Insights
**Priority:** 🟡 High
**Status:** ❌ Not Started
**Table(s):** `lxp_engagement_logs`, `lxp_student_skills`, `lxp_learning_paths`

#### Requirements

**REQ-LXP-010.1: Class Engagement Overview**
| Attribute | Detail |
|---|---|
| Description | Teacher sees a class-level analytics dashboard showing: average path completion per subject, top 5 / bottom 5 students by engagement, skill coverage heatmap (which skills are mastered across the class), average time-on-task per subject, students with no activity in last 7 days. |
| Actors | Teacher, Admin |
| Processing | Aggregate `lxp_engagement_logs` and `lxp_student_skills` for the teacher's class sections; compute metrics; highlight at-risk students (< 30% path completion + no activity in 7 days) |
| Output | Dashboard with charts and at-risk student alerts |
| Status | 📐 Proposed |

**REQ-LXP-010.2: Drop-off Analysis**
| Attribute | Detail |
|---|---|
| Description | Identify which activities in a learning path have the highest abandonment rate (started but not completed). These are flagged so teachers can review the content or difficulty. |
| Addresses | ST.T7.1.1.2 — Identify drop-off points |
| Processing | Count (path_activity_start - path_activity_complete) per activity_ref_id; order by abandonment rate; surface top 10 highest drop-off activities |
| Output | Drop-off heatmap in teacher analytics |
| Status | 📐 Proposed |

---

### FR-LXP-011: Mentorship Program Management

**RBS Reference:** F.T8.1 — Mentorship Program Setup, F.T8.2 — Mentorship Tracking
**Priority:** 🟡 High
**Status:** ❌ Not Started
**Table(s):** `lxp_mentorship_programs`, `lxp_mentor_mentee_jnt`, `lxp_mentorship_sessions`

#### Requirements

**REQ-LXP-011.1: Formal Mentorship Program**
| Attribute | Detail |
|---|---|
| Description | Admin creates formal mentorship programs (e.g., "Senior-Junior Math Buddies 2025-26") with defined goals, duration, target student groups, and matching criteria (skill level, subject interest, availability). Programs can involve teacher-student or student-student mentoring. |
| Addresses | ST.T8.1.1.1 — Define program goals, duration, target audience; ST.T8.1.1.2 — Set matching criteria |
| Input | program_name, description, program_type ENUM('teacher_student','peer'), subject_id NULL, matching_criteria_json (e.g., `{"mentor_min_skill":75,"mentee_max_skill":50}`), start_date, end_date, max_mentees_per_mentor TINYINT |
| Processing | Create `lxp_mentorship_programs` record; when matching is triggered, system uses criteria to suggest pairs |
| Status | 📐 Proposed |

**REQ-LXP-011.2: Mentor-Mentee Matching**
| Attribute | Detail |
|---|---|
| Description | System auto-suggests mentor-mentee pairs based on matching criteria. Admin/teacher can accept, reject, or manually override. |
| Addresses | ST.T8.1.2.1 — Auto-suggest pairs; ST.T8.1.2.2 — Manual override and approval |
| Processing | Score potential pairs by criteria match; suggest top matches; on approval create `lxp_mentor_mentee_jnt` with status='active' |
| Status | 📐 Proposed |

**REQ-LXP-011.3: Session Scheduling and Logging**
| Attribute | Detail |
|---|---|
| Description | Mentors book sessions with their mentees (date, time, duration). After each session, mentor logs: topics discussed, goals covered, action items, and rating. Mentee provides feedback. |
| Addresses | ST.T8.2.1.1 — Book sessions via calendar; ST.T8.2.1.2 — Log notes, goals, action items |
| Input | pair_id FK lxp_mentor_mentee_jnt, session_date, duration_minutes, topics_discussed TEXT, goals_covered TEXT, action_items TEXT, mentor_rating TINYINT |
| Processing | Create `lxp_mentorship_sessions`; update `lxp_mentor_mentee_jnt.sessions_completed`; check program goals progress |
| Status | 📐 Proposed |

---

### FR-LXP-012: Personalized Activity Feed

**RBS Reference:** F.T9.1 — Feed Configuration
**Priority:** 🟢 Medium
**Status:** ❌ Not Started
**Table(s):** `lxp_feed_items`

#### Requirements

**REQ-LXP-012.1: Activity Feed Aggregation**
| Attribute | Detail |
|---|---|
| Description | Each student has a personalized activity feed showing ranked items from multiple sources: new content added to their learning path, announcements from their class, badge earned by a peer, new forum thread in their class, mentor note, goal milestone reached. Feed is ranked by recency and relevance. |
| Addresses | ST.T9.1.1.1 — Aggregate from announcements, course materials, peer activity; ST.T9.1.2.1 — Rank by user role, enrolled courses, interests |
| Processing | `FeedService::generateFeed(student)` — pull last 50 events from `lxp_engagement_logs`, `lxp_student_badges_jnt`, `lxp_forum_threads`, school notification table; score by recency (weight 0.6) + relevance-to-enrolled-subjects (weight 0.4); deduplicate; return top 20 |
| Output | Ranked feed list; unread items highlighted |
| Status | 📐 Proposed |

**REQ-LXP-012.2: Feed Item Actions**
| Attribute | Detail |
|---|---|
| Description | Feed items are actionable — clicking a "New content added" item opens the content; clicking a "Peer earned badge" shows the badge; clicking a "Forum thread" opens the thread. Unread feed items are marked read on click. |
| Addresses | ST.T9.1.2.2 — Prioritize unread/important items; filter irrelevant content |
| Status | 📐 Proposed |

---

## 5. PROPOSED DATABASE SCHEMA

### 5.1 Table: `lxp_learning_paths`

```sql
CREATE TABLE `lxp_learning_paths` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id`            INT UNSIGNED NOT NULL COMMENT 'FK → std_students',
  `subject_id`            INT UNSIGNED NOT NULL COMMENT 'FK → sch_subjects',
  `academic_session_id`   INT UNSIGNED NOT NULL,
  `status`                ENUM('active','completed','paused','archived') NOT NULL DEFAULT 'active',
  `completion_percent`    DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `total_activities`      SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `completed_activities`  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `generated_by`          ENUM('system','teacher','student') NOT NULL DEFAULT 'system',
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            BIGINT UNSIGNED NULL,
  `created_at`            TIMESTAMP NULL,
  `updated_at`            TIMESTAMP NULL,
  `deleted_at`            TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lxp_path_student_subject_session` (`student_id`,`subject_id`,`academic_session_id`),
  CONSTRAINT `fk_lxpPath_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.2 Table: `lxp_path_activities`

```sql
CREATE TABLE `lxp_path_activities` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `path_id`               INT UNSIGNED NOT NULL,
  `activity_type`         ENUM('lesson','quiz','homework','video','reading','quest','practice') NOT NULL,
  `activity_ref_id`       INT UNSIGNED NULL COMMENT 'ID in source module (lms_quizzes.id, etc)',
  `activity_ref_type`     VARCHAR(80) NULL COMMENT 'Source table/model name',
  `title`                 VARCHAR(200) NOT NULL COMMENT 'Cached title for display without join',
  `sequence_order`        SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `status`                ENUM('locked','available','in_progress','completed','skipped') NOT NULL DEFAULT 'locked',
  `difficulty_level`      ENUM('easy','medium','hard','advanced') NOT NULL DEFAULT 'medium',
  `is_optional`           TINYINT(1) NOT NULL DEFAULT 0,
  `is_remedial`           TINYINT(1) NOT NULL DEFAULT 0,
  `prerequisite_activity_id` INT UNSIGNED NULL,
  `score_achieved`        DECIMAL(5,2) NULL,
  `completed_at`          TIMESTAMP NULL,
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            BIGINT UNSIGNED NULL,
  `created_at`            TIMESTAMP NULL,
  `updated_at`            TIMESTAMP NULL,
  `deleted_at`            TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_lxpAct_path` FOREIGN KEY (`path_id`) REFERENCES `lxp_learning_paths` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_lxpAct_prereq` FOREIGN KEY (`prerequisite_activity_id`) REFERENCES `lxp_path_activities` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.3 Table: `lxp_skills`

```sql
CREATE TABLE `lxp_skills` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`                  VARCHAR(200) NOT NULL,
  `code`                  VARCHAR(30) NOT NULL,
  `skill_category`        ENUM('technical','cognitive','soft','creative') NOT NULL DEFAULT 'cognitive',
  `parent_skill_id`       INT UNSIGNED NULL,
  `subject_id`            INT UNSIGNED NULL COMMENT 'FK → sch_subjects; NULL = cross-subject',
  `description`           TEXT NULL,
  `bloom_level`           ENUM('remember','understand','apply','analyse','evaluate','create') NULL,
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            BIGINT UNSIGNED NULL,
  `created_at`            TIMESTAMP NULL,
  `updated_at`            TIMESTAMP NULL,
  `deleted_at`            TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lxp_skill_code` (`code`),
  CONSTRAINT `fk_lxpSkill_parent` FOREIGN KEY (`parent_skill_id`) REFERENCES `lxp_skills` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.4 Table: `lxp_skill_content_jnt`

```sql
CREATE TABLE `lxp_skill_content_jnt` (
  `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `skill_id`        INT UNSIGNED NOT NULL,
  `content_type`    ENUM('lesson','quiz','homework','library_content','syllabus_topic') NOT NULL,
  `content_ref_id`  INT UNSIGNED NOT NULL,
  `skill_weight`    DECIMAL(3,2) NOT NULL DEFAULT 1.00,
  `created_at`      TIMESTAMP NULL,
  `updated_at`      TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lxp_skill_content` (`skill_id`,`content_type`,`content_ref_id`),
  CONSTRAINT `fk_lxpSkillCnt_skill` FOREIGN KEY (`skill_id`) REFERENCES `lxp_skills` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.5 Table: `lxp_student_skills`

```sql
CREATE TABLE `lxp_student_skills` (
  `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id`        INT UNSIGNED NOT NULL,
  `skill_id`          INT UNSIGNED NOT NULL,
  `skill_score`       DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT 'Score 0-100',
  `assessments_count` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `last_assessed_at`  TIMESTAMP NULL,
  `is_active`         TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`        BIGINT UNSIGNED NULL,
  `created_at`        TIMESTAMP NULL,
  `updated_at`        TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lxp_student_skill` (`student_id`,`skill_id`),
  CONSTRAINT `fk_lxpStdSkill_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_lxpStdSkill_skill` FOREIGN KEY (`skill_id`) REFERENCES `lxp_skills` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.6 Table: `lxp_badges`

```sql
CREATE TABLE `lxp_badges` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`          VARCHAR(150) NOT NULL,
  `description`   TEXT NULL,
  `icon_path`     VARCHAR(500) NULL,
  `category`      ENUM('achievement','streak','skill','milestone','participation') NOT NULL DEFAULT 'achievement',
  `criteria_json` JSON NOT NULL COMMENT 'E.g. {"type":"streak","days":7} or {"type":"skill_score","skill_id":5,"min_score":80}',
  `points`        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `rarity`        ENUM('common','rare','epic','legendary') NOT NULL DEFAULT 'common',
  `is_active`     TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`    BIGINT UNSIGNED NULL,
  `created_at`    TIMESTAMP NULL,
  `updated_at`    TIMESTAMP NULL,
  `deleted_at`    TIMESTAMP NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.7 Table: `lxp_student_badges_jnt`

```sql
CREATE TABLE `lxp_student_badges_jnt` (
  `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id`    INT UNSIGNED NOT NULL,
  `badge_id`      INT UNSIGNED NOT NULL,
  `earned_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `trigger_ref_id`   INT UNSIGNED NULL COMMENT 'What activity/event triggered the badge',
  `trigger_ref_type` VARCHAR(80) NULL,
  `created_at`    TIMESTAMP NULL,
  `updated_at`    TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lxp_student_badge` (`student_id`,`badge_id`),
  CONSTRAINT `fk_lxpStdBadge_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_lxpStdBadge_badge` FOREIGN KEY (`badge_id`) REFERENCES `lxp_badges` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.8 Table: `lxp_points_ledger`

```sql
CREATE TABLE `lxp_points_ledger` (
  `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id`      INT UNSIGNED NOT NULL,
  `points`          SMALLINT NOT NULL COMMENT 'Positive = earned, Negative = deducted',
  `action_type`     ENUM('activity_complete','badge_earned','forum_post','goal_achieved','streak_bonus','quiz_perfect','mentor_session') NOT NULL,
  `reference_id`    INT UNSIGNED NULL,
  `reference_type`  VARCHAR(80) NULL,
  `notes`           VARCHAR(200) NULL,
  `created_at`      TIMESTAMP NULL,
  `updated_at`      TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_lxpLedger_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.9 Table: `lxp_learning_goals`

```sql
CREATE TABLE `lxp_learning_goals` (
  `id`                    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id`            INT UNSIGNED NOT NULL,
  `subject_id`            INT UNSIGNED NULL,
  `skill_id`              INT UNSIGNED NULL,
  `goal_description`      VARCHAR(500) NOT NULL,
  `goal_type`             ENUM('self','teacher_assigned') NOT NULL DEFAULT 'self',
  `assigned_by`           BIGINT UNSIGNED NULL COMMENT 'FK → sys_users (teacher)',
  `target_date`           DATE NOT NULL,
  `target_skill_score`    TINYINT UNSIGNED NULL,
  `progress_percent`      DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `status`                ENUM('active','achieved','missed','cancelled') NOT NULL DEFAULT 'active',
  `achieved_at`           TIMESTAMP NULL,
  `is_active`             TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`            BIGINT UNSIGNED NULL,
  `created_at`            TIMESTAMP NULL,
  `updated_at`            TIMESTAMP NULL,
  `deleted_at`            TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_lxpGoal_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_lxpGoal_skill` FOREIGN KEY (`skill_id`) REFERENCES `lxp_skills` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.10 Table: `lxp_content_library`

```sql
CREATE TABLE `lxp_content_library` (
  `id`                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title`               VARCHAR(300) NOT NULL,
  `content_type`        ENUM('video','pdf','article','link','quiz') NOT NULL,
  `url`                 VARCHAR(1000) NULL COMMENT 'External URL or YouTube embed',
  `file_path`           VARCHAR(500) NULL COMMENT 'Uploaded file path via sys_media',
  `subject_id`          INT UNSIGNED NULL,
  `bloom_level`         ENUM('remember','understand','apply','analyse','evaluate','create') NULL,
  `difficulty`          ENUM('easy','medium','hard','advanced') NOT NULL DEFAULT 'medium',
  `duration_minutes`    TINYINT UNSIGNED NULL,
  `description`         TEXT NULL,
  `thumbnail_url`       VARCHAR(500) NULL,
  `source_attribution`  VARCHAR(200) NULL,
  `view_count`          INT UNSIGNED NOT NULL DEFAULT 0,
  `is_active`           TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`          BIGINT UNSIGNED NULL,
  `created_at`          TIMESTAMP NULL,
  `updated_at`          TIMESTAMP NULL,
  `deleted_at`          TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  FULLTEXT KEY `ft_lxp_content_search` (`title`,`description`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.11 Table: `lxp_forums`

```sql
CREATE TABLE `lxp_forums` (
  `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title`           VARCHAR(300) NOT NULL,
  `description`     TEXT NULL,
  `subject_id`      INT UNSIGNED NULL,
  `class_id`        INT UNSIGNED NULL,
  `section_id`      INT UNSIGNED NULL,
  `moderator_id`    BIGINT UNSIGNED NULL COMMENT 'FK → sys_users',
  `is_open`         TINYINT(1) NOT NULL DEFAULT 1,
  `closes_at`       DATE NULL,
  `thread_count`    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `post_count`      INT UNSIGNED NOT NULL DEFAULT 0,
  `is_active`       TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`      BIGINT UNSIGNED NULL,
  `created_at`      TIMESTAMP NULL,
  `updated_at`      TIMESTAMP NULL,
  `deleted_at`      TIMESTAMP NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.12 Table: `lxp_forum_threads`

```sql
CREATE TABLE `lxp_forum_threads` (
  `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `forum_id`        INT UNSIGNED NOT NULL,
  `title`           VARCHAR(300) NOT NULL,
  `body`            TEXT NOT NULL,
  `posted_by`       BIGINT UNSIGNED NOT NULL COMMENT 'FK → sys_users',
  `is_pinned`       TINYINT(1) NOT NULL DEFAULT 0,
  `is_resolved`     TINYINT(1) NOT NULL DEFAULT 0,
  `reply_count`     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `is_active`       TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`      BIGINT UNSIGNED NULL,
  `created_at`      TIMESTAMP NULL,
  `updated_at`      TIMESTAMP NULL,
  `deleted_at`      TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_lxpThread_forum` FOREIGN KEY (`forum_id`) REFERENCES `lxp_forums` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.13 Table: `lxp_mentorship_programs`

```sql
CREATE TABLE `lxp_mentorship_programs` (
  `id`                        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `program_name`              VARCHAR(200) NOT NULL,
  `description`               TEXT NULL,
  `program_type`              ENUM('teacher_student','peer') NOT NULL DEFAULT 'peer',
  `subject_id`                INT UNSIGNED NULL,
  `academic_session_id`       INT UNSIGNED NOT NULL,
  `matching_criteria_json`    JSON NULL,
  `start_date`                DATE NOT NULL,
  `end_date`                  DATE NOT NULL,
  `max_mentees_per_mentor`    TINYINT UNSIGNED NOT NULL DEFAULT 3,
  `status`                    ENUM('draft','active','completed','cancelled') NOT NULL DEFAULT 'draft',
  `is_active`                 TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`                BIGINT UNSIGNED NULL,
  `created_at`                TIMESTAMP NULL,
  `updated_at`                TIMESTAMP NULL,
  `deleted_at`                TIMESTAMP NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 5.14 Table: `lxp_engagement_logs`

```sql
CREATE TABLE `lxp_engagement_logs` (
  `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `student_id`      INT UNSIGNED NOT NULL,
  `activity_type`   ENUM('path_activity_start','path_activity_complete','content_view','forum_post','goal_update','badge_earned','session_login') NOT NULL,
  `reference_id`    INT UNSIGNED NULL,
  `reference_type`  VARCHAR(80) NULL,
  `duration_seconds` MEDIUMINT UNSIGNED NULL,
  `session_date`    DATE NOT NULL,
  `created_at`      TIMESTAMP NULL,
  `updated_at`      TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  KEY `idx_lxp_engagement_student_date` (`student_id`,`session_date`),
  CONSTRAINT `fk_lxpEngage_student` FOREIGN KEY (`student_id`) REFERENCES `std_students` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 6. PROPOSED ROUTES

```
Route Group: prefix='lxp', middleware=['auth','verified','tenant']

Student Routes
  GET  /lxp/my-path                       → LearningPathController@myPath
  GET  /lxp/my-path/{path}                → LearningPathController@show
  POST /lxp/my-path/{path}/activity/{act}/start    → LearningPathController@startActivity
  POST /lxp/my-path/{path}/activity/{act}/complete → LearningPathController@completeActivity
  GET  /lxp/skill-map                     → SkillController@studentSkillMap
  GET  /lxp/goals                         → LearningGoalController@index
  POST /lxp/goals                         → LearningGoalController@store
  GET  /lxp/badges                        → GamificationController@badges
  GET  /lxp/leaderboard                   → GamificationController@leaderboard
  GET  /lxp/feed                          → FeedController@index
  GET  /lxp/content-library               → ContentLibraryController@index
  GET  /lxp/content-library/{content}     → ContentLibraryController@show

Forums
  GET  /lxp/forums                        → ForumController@index
  GET  /lxp/forums/{forum}               → ForumController@show
  POST /lxp/forums/{forum}/threads        → ForumController@createThread
  POST /lxp/forums/{forum}/threads/{t}/reply → ForumController@reply

Mentorship
  GET  /lxp/mentorship                    → MentorshipController@index
  GET  /lxp/mentorship/{pair}/sessions    → MentorshipController@sessions
  POST /lxp/mentorship/{pair}/sessions    → MentorshipController@logSession

Teacher Routes
  GET  /lxp/teacher/analytics             → LxpAnalyticsController@classOverview
  GET  /lxp/teacher/analytics/drop-off    → LxpAnalyticsController@dropOff
  POST /lxp/teacher/goals/assign          → LearningGoalController@assignToClass

Admin Routes
  GET  /lxp/admin/skills                  → SkillController@index
  POST /lxp/admin/skills                  → SkillController@store
  GET  /lxp/admin/badges                  → GamificationController@adminBadges
  POST /lxp/admin/badges                  → GamificationController@storeBadge
  GET  /lxp/admin/mentorship-programs     → MentorshipController@programs
  POST /lxp/admin/mentorship-programs     → MentorshipController@storeProgram
  POST /lxp/admin/mentorship-programs/{prog}/generate-matches → MentorshipController@generateMatches
  GET  /lxp/admin/path-config             → LxpAdminController@pathConfig
  GET  /lxp/content-library/create        → ContentLibraryController@create
  POST /lxp/content-library               → ContentLibraryController@store
```

---

## 7. PROPOSED BLADE VIEWS

| View Path | Purpose |
|---|---|
| `lxp/student/my-path.blade.php` | Student's learning path timeline with activity cards |
| `lxp/student/skill-map.blade.php` | Radar chart + skill tree view |
| `lxp/student/goals.blade.php` | My goals list with progress bars |
| `lxp/student/badges.blade.php` | Badge gallery (earned + locked) |
| `lxp/student/feed.blade.php` | Personalized activity feed |
| `lxp/gamification/leaderboard.blade.php` | Leaderboard table with filters |
| `lxp/gamification/points-history.blade.php` | Points ledger history |
| `lxp/content/index.blade.php` | Content library browse |
| `lxp/content/show.blade.php` | Content detail + viewer/embed |
| `lxp/content/create.blade.php` | Add content to library |
| `lxp/forums/index.blade.php` | Forum list |
| `lxp/forums/show.blade.php` | Thread list inside forum |
| `lxp/forums/thread-show.blade.php` | Thread replies + reply form |
| `lxp/mentorship/index.blade.php` | My mentor/mentee pairs |
| `lxp/mentorship/sessions.blade.php` | Session log per pair |
| `lxp/mentorship/programs.blade.php` | Admin — mentorship programs list |
| `lxp/mentorship/matches.blade.php` | Admin — suggested pairs review |
| `lxp/teacher/class-analytics.blade.php` | Class engagement dashboard |
| `lxp/teacher/drop-off.blade.php` | Drop-off analysis chart |
| `lxp/admin/skills.blade.php` | Skill framework tree management |
| `lxp/admin/badges.blade.php` | Badge management |
| `lxp/admin/path-config.blade.php` | Path generation configuration |

---

## 8. PROPOSED SERVICES

### 8.1 `PathSuggestionService`
- `suggest(Student $student, Subject $subject): array` — pulls rec_student_recommendations + skill gaps; returns ordered activity list
- `buildFromSuggestions(Student $student, Subject $subject, int $sessionId): LearningPath` — creates path + activities from suggestion output
- `adaptPathOnCompletion(PathActivity $activity, float $score): void` — inserts remedial or advances difficulty

### 8.2 `GamificationService`
- `awardPoints(Student $student, string $actionType, int $points, ?int $refId, ?string $refType): void`
- `checkAndAwardBadges(Student $student, string $triggerEvent): array` — returns newly awarded badges
- `calculateStreak(Student $student): int` — counts consecutive days with engagement events
- `getLeaderboard(array $filters): Collection`

### 8.3 `SkillTrackingService`
- `updateScore(int $studentId, int $skillId, float $rawScore): LxpStudentSkill`
- `getRadarData(int $studentId, int $subjectId): array`
- `identifyGaps(int $studentId, float $threshold = 60.0): Collection`

### 8.4 `FeedService`
- `generateFeed(int $studentId, int $limit = 20): array`
- `markItemRead(int $studentId, int $feedItemId): void`

---

## 9. EXTERNAL DEPENDENCIES

| Dependency | Version | Usage |
|---|---|---|
| Recommendation Module (`rec_*`) | Existing | Content suggestion source for PathSuggestionService |
| PredictiveAnalytics Module (`pan_*`) | Planned | Receives engagement signals from LXP for learning outcome prediction |
| LMS Modules (LmsExam, LmsQuiz, LmsHomework) | Existing | Source of activity completion events that update path progress |
| Syllabus Module (`slb_*`) | Existing | Syllabus topics used as content references in path activities |
| stancl/tenancy | v3.9 | Tenant isolation |
| Laravel Queue | built-in | Async path generation via `GenerateLearningPathJob` |

---

## 10. BUSINESS RULES

| Rule ID | Rule | Source |
|---|---|---|
| BR-LXP-001 | A student can have only ONE active learning path per subject per academic session | Data integrity |
| BR-LXP-002 | Locked activities cannot be started until their prerequisite is marked 'completed' | Learning design |
| BR-LXP-003 | A badge can only be earned once per student (unique constraint on student_id + badge_id) | Gamification |
| BR-LXP-004 | Points are never retroactively removed except for duplicate/error corrections (admin action with justification) | Fair play |
| BR-LXP-005 | Leaderboard is scoped to the same class section by default; cross-class view requires admin permission | Privacy |
| BR-LXP-006 | Forum posts can only be deleted by the author or a moderator (teacher/admin) — never by other students | Safety |
| BR-LXP-007 | Peer mentor must have a skill score >= 75 in the subject and the mentee must have score <= 55 (configurable in matching_criteria_json) | Quality |
| BR-LXP-008 | Engagement logs are insert-only; no updates or soft deletes | Immutable audit |
| BR-LXP-009 | Skill score update uses weighted rolling average: (existing × 0.7) + (new × 0.3). Minimum 5 assessments before score is considered 'reliable' | Statistical validity |
| BR-LXP-010 | LXP does not generate its own content — it curates and sequences content from other modules | Architecture boundary |

---

## 11. NON-FUNCTIONAL REQUIREMENTS

| Requirement | Target | Notes |
|---|---|---|
| Student Dashboard Load | < 2 seconds | Cached skill scores and path completion |
| Leaderboard Query | < 1 second | Aggregation on indexed points_ledger |
| Engagement Log Insert | < 100ms | Lightweight insert; async where possible |
| Gamification Trigger | < 500ms per event | Badge criteria evaluation is in-memory |
| Feed Generation | < 1 second for 20 items | Ranking is lightweight scoring, not ML |
| Soft Delete | All major tables support `deleted_at` | Standard pattern |
| Audit | Data changes logged via `sys_activity_logs` | Standard pattern |
| Tenant Isolation | All queries scoped to tenant via stancl/tenancy | Required |

---

## 12. INTEGRATION POINTS

| Module | Integration Type | Direction | Description |
|---|---|---|---|
| Recommendation (`rec_*`) | Data Read | LXP reads REC | `rec_student_recommendations` provides content suggestions for learning path generation |
| LmsExam (`exm_*`) | Event Subscription | LMS → LXP | Exam completion events update path activity status and skill scores |
| LmsQuiz (`quz_*`) | Event Subscription | LMS → LXP | Quiz completion events update path activity status and trigger gamification |
| LmsHomework | Event Subscription | LMS → LXP | Homework submission/grading events update path activity status |
| PredictiveAnalytics (`pan_*`) | Data Feed | LXP → PAN | Engagement logs and skill scores consumed by PAN for learning gap and dropout prediction |
| Syllabus (`slb_*`) | Data Read | LXP reads SLB | Syllabus topics used as path activity references |
| Student Management (`std_*`) | Data Read | LXP reads STD | Student profiles, class/section data |
| School Setup (`sch_*`) | Data Read | LXP reads SCH | Subjects, classes, sections, academic sessions |
| Notification System | Outbound trigger | LXP triggers | Badge earned, goal milestone, mentor session reminders |

---

## 13. PROPOSED TEST CASES

| # | Test Case | Type | FR Reference | Priority |
|---|---|---|---|---|
| 1 | Generate AI-suggested learning path for student; activities ordered by difficulty ascending | Feature | FR-LXP-001 | High |
| 2 | Complete path activity; next activity status changes to 'available' | Feature | FR-LXP-001 | High |
| 3 | Complete activity with score < 60%; remedial activity inserted before next | Feature | FR-LXP-007 | High |
| 4 | Create skill; map to quiz; complete quiz → skill score updates | Feature | FR-LXP-002 | High |
| 5 | Skill score rolling average correct: existing=70, new=50, result=64 | Unit | FR-LXP-002 | High |
| 6 | Complete 7-day streak; streak badge auto-awarded | Feature | FR-LXP-009 | High |
| 7 | Badge awarded only once per student (duplicate blocked by unique key) | Feature | FR-LXP-009 | High |
| 8 | Points ledger correct sum matches leaderboard rank | Feature | FR-LXP-009 | High |
| 9 | Set learning goal; reach 25% progress; milestone notification triggered | Feature | FR-LXP-005 | Medium |
| 10 | Student reorders optional activities; mandatory activity order unchanged | Feature | FR-LXP-001 | Medium |
| 11 | Teacher analytics shows drop-off rate for highest-abandonment activity | Browser | FR-LXP-010 | Medium |
| 12 | Forum thread created; reply count increments; engagement log entry created | Feature | FR-LXP-008 | Medium |
| 13 | Mentorship program matching — mentor has skill score >= 75, mentee <= 55 | Feature | FR-LXP-011 | Medium |
| 14 | Content library full-text search returns relevant results | Feature | FR-LXP-004 | Medium |
| 15 | Activity feed shows unread badge earned item; marked read on click | Browser | FR-LXP-012 | Low |
