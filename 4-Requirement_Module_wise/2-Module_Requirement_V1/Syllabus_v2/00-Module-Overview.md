# Syllabus and Exam Management Module — Business Requirements Overview

## Module Purpose

The Syllabus and Exam Management Module is the architectural spine of the school's academic operations. It completely transforms the curriculum from a static piece of paper into a highly dynamic, measurable, and automated digital framework.

It enables schools to dissect their subjects into precise hierarchies like Lessons, Topics, and Micro-topics, and map them to external educational mandates like NEP 2020, NCF, and Bloom's Taxonomy. By integrating daily teacher pacing, automated AI remediation triggers, and deep competency audits, this module ensures that teaching is structured, outcomes are proven, and institutional planning is constantly improving.

---

## Core Structure — Master Configuration

The Master section provides the structural building blocks of the curriculum, linking textbooks to actionable daily teaching units.

**Lessons**
Top-level chapters, textbook mapping, learning objectives, and version control.

**Topic Types**
Defines the mathematical depth hierarchy and assessment gatekeeper flags for sub-topics.

**Topics**
The materialized path engine linking content, teaching duration, and automation triggers.

**Competency Types**
Broad pedagogical domains like Knowledge, Skill, and Attitude enforcing structural dependencies.

**Competencies**
Deeply nested, specific learning outcomes mapped strictly to NEP and NCF standards.

**Topic-Competency Mapping**
The critical junction mapping matrix calculating primary and secondary weightages for skills taught.

**Performance Categories**
Percentage bands triggering automated AI actions like re-tests and parent escalations.

**Grade Divisions Master**
Official report card grading scales with strict multi-scope fallback logic for printing results.

**Question Types**
Formats of questions governing frontend UI rendering and auto-grading logic, such as MCQ or Essay.

**Complexity Levels**
Mathematical difficulty scaling required for adaptive testing algorithms.

---

## Cognitive Framework — Bloom Taxonomy Setup

This section defines the psychological depth of the assessments, ensuring students are not just tested on rote memorization.

**Bloom Taxonomy**
The 6 core cognitive levels providing the foundation for depth analytics, from Remembering to Creating.

**Cognitive Skills**
Granular tagging vocabulary and verbs used by teachers when creating questions to define mental effort.

**Question Type Specificity**
Linking specific practical actions like Label the Diagram directly to their cognitive intent.

---

## Execution — Planning and Operations

This section maps the theoretical syllabus to the physical school calendar and automates its delivery.

**Lesson Date Planning**
Dynamic time-bounding of topics to specific dates, sections, and proxy teachers.

**Topic Release Control**
The cron-driven automation engine locking and dripping content to students based on prerequisites and dates.

---

## Analytics — Reports and Dashboards

This section consumes all the data generated above to provide actionable intelligence to the school management.

**Overview Dashboard**
Executive BI widgets, red-alert lists for lagging classes, and role-based filtered compliance scores.

**Progress Tracker**
Detailed tabular variance tracking holding teachers accountable for daily pacing.

**Coverage Audit**
Advanced radar charts and weighted calculations proving NEP compliance to external boards.

**Resource Matrix**
Deep document parsing audit ensuring lessons have required multimedia assets before teaching begins.

**Planning Accuracy**
Post-mortem pacing analysis identifying structural scheduling flaws for the next academic year.
