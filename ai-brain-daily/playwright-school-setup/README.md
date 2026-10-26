# School Setup — Playwright Automated Test Runner & Dashboard

Automated Visual Browser Testing suite for **School Setup (Classes & Sections)** on `http://test.localhost:8000/school-setup/school-class`.

Built based on the production database schema in [`SchoolSetup_DDL_v4.6.sql`](/home/shailesh/shailesh/pgdatabase/2-DDL_Tenant_Enhanced/SchoolSetup/SchoolSetup_DDL_v4.6.sql).

---

## 🚀 Quick Start

Run the dashboard server:

```bash
cd /home/shailesh/shailesh/playwright-school-setup
./run.sh
```

Then open your browser and navigate to:
👉 **`http://localhost:3050`**

On the webpage:
1. Select any tab (Sections, Class, Subject Type, Study Format, Subject, Stream, etc.).
2. Toggle **Visible Chrome (Headed)** on or off.
3. Click the **"▶ Play"** button on any testcase to watch Google Chrome open and run the test visually!
4. Or click **"▶ Run All in Tab"** to run the complete suite for that tab.

---

## 📁 Project Structure

```text
/home/shailesh/shailesh/playwright-school-setup/
├── package.json                   # Node dependencies (@playwright/test, express)
├── playwright.config.js           # Headed, slowMo, timeout & reporter configuration
├── server.js                      # Express runner API with Server-Sent Events (SSE)
├── run.sh                         # One-click startup script
├── public/
│   └── index.html                 # Interactive Test Runner Dashboard
└── tests/
    ├── helpers/
    │   └── auth.js                # Auto-login helper for tenant admin (root@tenant.com)
    ├── 01_sections.spec.js        # Sections CRUD, Duplicates, DDL checks
    ├── 02_class.spec.js           # Class & Class-Section junction tests
    ├── 03_subject_type.spec.js    # Subject Type CRUD & Duplicates
    ├── 04_study_format.spec.js    # Study Format CRUD, Duplicates & System flag
    ├── 05_subject.spec.js         # Subject CRUD, Duplicates & Optionals
    ├── 06_subject_study_format.spec.js # Junction mapping & uniqueness
    ├── 07_class_group.spec.js     # Class Group mapping & filter tests
    ├── 08_subject_group.spec.js   # Subject Group & sub-subjects (decision D9)
    └── 09_stream.spec.js          # Class Stream CRUD & Duplicates
```

---

## 📋 Tabs & Test Cases Covered

### 1. Sections (`sch_sections`)
- **TC-SEC-01**: Load Tab & Verify Table structure
- **TC-SEC-REQ-02**: Mandatory field validation (empty form submission)
- **TC-SEC-LEN-03**: DDL constraint check — Code max length `CHAR(4)`
- **TC-SEC-CREATE-04**: Create new section (Positive flow)
- **TC-SEC-DUP-05**: Duplicate Code uniqueness (`uq_sections_code`)
- **TC-SEC-DUP-06**: Duplicate Name uniqueness (`uq_sections_name`)
- **TC-SEC-EDIT-07**: Edit existing section name
- **TC-SEC-DEL-08**: Soft-delete section with SweetAlert confirmation

### 2. Class (`sch_classes` & `sch_class_section_jnt`)
- **TC-CLS-01**: Class Table & section tags verification
- **TC-CLS-REQ-02**: Empty submission validation
- **TC-CLS-LEN-03**: DDL constraint check — Code max length `CHAR(5)`
- **TC-CLS-CREATE-04**: Create class with section mappings
- **TC-CLS-DUP-05**: Duplicate Class Code rejection (`uq_classes_code`)
- **TC-CLS-DUP-06**: Duplicate Class Name rejection (`uq_classes_name`)

### 3. Subject Type (`sch_subject_types`)
- **TC-STP-01**: Subject Type list verification
- **TC-STP-REQ-02**: Form validation check
- **TC-STP-CREATE-03**: Create new Subject Type (Theory, Practical, Core, etc.)
- **TC-STP-DUP-04**: Duplicate Code check (`uq_subjectTypes_code`)

### 4. Study Format (`sch_study_formats`)
- **TC-SFM-01**: Study Format table verification
- **TC-SFM-REQ-02**: Empty submission check
- **TC-SFM-CREATE-03**: Create Study Format
- **TC-SFM-DUP-04**: Duplicate Code check (`uq_studyFormats_code`)

### 5. Subject (`sch_subjects`)
- **TC-SBJ-01**: Subject table & filter render
- **TC-SBJ-REQ-02**: Empty submission check
- **TC-SBJ-CREATE-03**: Create Subject
- **TC-SBJ-DUP-04**: Duplicate Subject Code check (`uq_subjects_code`)

### 6. Subject + Study Format (`sch_subject_study_format_jnt`)
- **TC-SSF-01**: Junction table verification
- **TC-SSF-02**: Keyword search & filter verification
- **TC-SSF-03**: DDL Constraint — Code Uniqueness (`uq_ssfj_code`)
- **TC-SSF-04**: DDL Constraint — Triple Uniqueness (`uq_ssfj_subjectId_stFormat`)

### 7. Class Group (`sch_class_groups_jnt`)
- **TC-CGP-01**: Class Group table verification
- **TC-CGP-02**: Search & filter verification
- **TC-CGP-03**: DDL Constraint — Code size `CHAR(50)` check

### 8. Subject Group
- **TC-SGP-01**: Subject Group table & children verification
- **TC-SGP-02**: Search & filter verification
- **TC-SGP-03**: Business Logic Verify — Generated group edit modal & readonly code check (decision D9)

### 9. Stream (`sch_class_streams`)
- **TC-STR-01**: Stream table render
- **TC-STR-REQ-02**: Empty submission validation
- **TC-STR-CREATE-03**: Create new Stream
- **TC-STR-DUP-04**: Duplicate Stream Code check (`uq_classStreams_code`)

---

## 🛠 Manual CLI Execution (Optional)

You can also run any test via CLI:

```bash
# Run single test
npx playwright test tests/01_sections.spec.js -g "TC-SEC-01"

# Run entire tab
npx playwright test tests/01_sections.spec.js

# Run in headless mode
npx playwright test tests/01_sections.spec.js --headed=false
```
