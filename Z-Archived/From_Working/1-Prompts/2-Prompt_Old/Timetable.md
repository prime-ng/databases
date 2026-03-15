SYSTEM:
You are "ERP Architect GPT" — a senior software architect, data modeler, API designer, and UX/UI systemizer specializing in SCHOOL ERP systems. 
You will design a fully production-grade **Timetable Module** for a modern School ERP, using all files I provide.

You MUST strictly learn and replicate the screen-design style found in the sample file **Scr-LESSON.md**
Match:
- format
- structure
- sections
- diagrams
- naming conventions
- tone & explanation depth

Your outputs must be precise, developer-ready, and formatted cleanly in Markdown.

----------------------------------------------------------------------
USER:

I am providing below input files:

A) **Working/Timetable_Requirement.txt** — Functional requirement summary  
B) **Working/z_consolidated_ddl.sql** — Existing ERP database schema  
C) **Working/tim_timetable_ddl_v2.sql** — Preliminary Timetable module schema  
D) **Working/Prompts/Scr-LESSON.md** — Sample screen design format/style that you MUST imitate

You can also use below support files:
E) **Working/tt_screen_design/1-constraint_list.md** — List of some Constraints
F) **Working/tt_screen_design/2-constraint_evaluation_engine.md** — Constraints Evaluation Engine
----------------------------------------------------------------------
## YOUR MISSION (Very Important)
----------------------------------------------------------------------

1. Parse all 6 files A–F.  
2. Understand the functional requirements, existing schema, preliminary timetable schema, support files, and the sample screen design style.  
3. Produce a **fully integrated, production-quality Timetable Module Screens** that:
   - Fits into the existing ERP architecture  
   - Follows advanced academic scheduling logic  
   - Includes complete backend design, frontend design, UX flows, permissions, APIs, and DDL  
   - Uses EXACT SAME screen-design pattern as **Scr-LESSON.md**  

----------------------------------------------------------------------
## DELIVERABLE A — Module Architecture & Analysis
----------------------------------------------------------------------

1. Summarize the Timetable requirements.  
2. Map every related table from **z_consolidated_ddl.sql** and **tim_timetable_ddl_v2.sql** to Timetable module entities.  
3. Identify missing tables and propose required new ones.  
4. Provide a **Module Boundary Diagram** (ASCII or Mermaid).  
5. Provide a **canonical Timetable Architecture**, covering:
   - Periods, sessions, slots  
   - Teachers, subjects, classes, sections  
   - Rooms/resources  
   - Constraint system (hard/soft)  
   - Auto-scheduler system  
   - Manual drag-drop editor  
   - Substitution workflow  

----------------------------------------------------------------------
## DELIVERABLE B — Complete Refactored DDL (MySQL 8 / Laravel-ready)
----------------------------------------------------------------------

Produce a consolidated, cleaned, fully normalized DDL for the Timetable Module:

- CREATE TABLE with strict types  
- Primary keys, foreign keys, unique constraints  
- Composite indexes  
- Check constraints  
- Soft delete (`deleted_at`)  
- Seed data (INSERTs) for required lookups  
- Integration notes referencing existing ERP tables  
- A separate **_diff.sql** section explaining changes needed in existing tables  

Output as two files (in code blocks):

1. **timetable_ddl_clean.sql**  
2. **timetable_ddl_diff.sql**

Each table must include an explanation block:
- Purpose  
- Key fields  
- Relationship context  
- Growth considerations  

----------------------------------------------------------------------
## DELIVERABLE C — Full 10-Section Design Document
----------------------------------------------------------------------

Create a detailed design document with EXACTLY these 10 sections:

1. Overview  
2. Data Context  
3. Screen Layouts  
4. Data Models  
5. User Workflows  
6. Visual Design  
7. Accessibility  
8. Testing  
9. Deployment / Runbook  
10. Future Enhancements  

**IMPORTANT:**  
All **Screen Layouts** MUST follow the same style/format/structure used in **Scr-LESSON.md**.

----------------------------------------------------------------------
## DELIVERABLE D — Permissions (7-Role Matrix)
----------------------------------------------------------------------

Use the standard 7 ERP roles:

- SuperAdmin  
- Management  
- Principal  
- Teacher  
- Accountant  
- Parent  
- Student  

Provide:

1. CRUD permissions per entity  
2. Special permissions: Publish, Lock, Unlock, Auto-generate, Substitute, Export  
3. SQL schema for RBAC  
4. JWT claim examples  
5. Custom row-level rules  
6. Access rules for substitution workflow and timetable visibility

----------------------------------------------------------------------
## DELIVERABLE E — Screen Designs (Follow EXACT format of Scr-LESSON.md)
----------------------------------------------------------------------

For each key Timetable screen, produce:

### Required Screens:
- Class-Section Timetable  
- Teacher Timetable  
- Room/Resource Timetable  
- Period/Slot Manager  
- Auto-Scheduler Console  
- Manual Drag-Drop Editor  
- Substitution Workflow  
- Publish/Lock Screen  

And for each screen you MUST:

1. Follow the EXACT formatting style of **Scr-LESSON.md**
2. Include ASCII UI diagrams (same style and spacing)
3. Include detailed explanation sections
4. Include field lists, actions, validations, workflow notes

----------------------------------------------------------------------
## DELIVERABLE F — REST API Contracts
----------------------------------------------------------------------

For each API, include:

- HTTP Method  
- Endpoint  
- Description  
- Authentication (JWT / scope)  
- Request JSON schema  
- Response JSON schema  
- Validation rules  
- Errors (with examples)  
- Pagination rules  
- Filtering & sorting rules  
- **1 curl example per endpoint**  
- Webhooks:  
  - `timetable_published`  
  - `substitution_required`  

----------------------------------------------------------------------
## DELIVERABLE G — Testing & QA
----------------------------------------------------------------------

Include:

- Developer test checklist  
- QA test checklist  
- 12+ table-driven test cases for:  
  - collision detection  
  - class-room-teacher conflicts  
  - subject load constraints  
  - back-to-back periods  
  - auto-scheduler  
  - substitution logic  
  - publish/lock flow  
  - rollback  

----------------------------------------------------------------------
## DELIVERABLE H — Auto-Scheduler Engine Specification
----------------------------------------------------------------------

Provide:

- Hard constraints (non-negotiable)  
- Soft constraints (weighted)  
- Scoring system  
- Pseudocode for scheduling engine  
- Optimization heuristics  
- Manual override logic  
- Conflict detection algorithm  
- Substitution selection algorithm  

----------------------------------------------------------------------
## OUTPUT RULES
----------------------------------------------------------------------

- Format everything cleanly in Markdown.  
- Use fenced code blocks for SQL, JSON, cURL.  
- Use Mermaid or ASCII diagrams for ERDs.  
- If assumptions are required, add an **ASSUMPTIONS** section before continuing.  
- If inconsistencies are present in inputs, highlight them and propose fixes.  
- SCREEN DESIGNS MUST MATCH THE STYLE OF **Scr-LESSON.md EXACTLY**.

----------------------------------------------------------------------
## BEGIN
Parse **Timetable_Requirement.txt**, **z_consolidated_ddl.sql**, **tim_timetable_ddl.sql**, and **Scr-LESSON.md**,**_**

