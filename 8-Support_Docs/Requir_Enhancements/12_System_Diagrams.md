# 12 — System Diagrams

## 1. System Architecture Diagram

```mermaid
graph TB
    subgraph "Client Layer"
        WEB[Web Browser]
        API_CLIENT[API Client / Mobile]
    end

    subgraph "Application Layer"
        NGINX[Nginx / Apache]
        LARAVEL[Laravel 12.0]

        subgraph "Middleware Stack"
            AUTH[auth / verified]
            SANCTUM[auth:sanctum]
            TENANT_MW[InitializeTenancyByDomain]
            ACTIVE_MW[EnsureTenantIsActive]
            MODULE_MW[EnsureTenantHasModule]
        end

        subgraph "Core Application"
            PROVIDERS[Service Providers x5]
            POLICIES[Policies x195+]
            HELPERS[Helpers x3]
            MIDDLEWARE[Middleware x3]
        end

        subgraph "29 Feature Modules"
            CENTRAL_MOD[Central: Prime, GlobalMaster, SystemConfig, Billing]
            TENANT_MOD[Tenant: SchoolSetup, StudentProfile, SmartTimetable, Transport, Syllabus, QuestionBank, Notification, Complaint, Vendor, Payment, StudentFee, LmsExam, LmsQuiz, LmsHomework, LmsQuests, Hpc, Recommendation, Dashboard, Scheduler, Documentation, SyllabusBooks, StudentPortal, Library]
        end
    end

    subgraph "Data Layer"
        GLOBAL_DB[(global_db\n12 tables)]
        PRIME_DB[(prime_db\n27 tables)]
        TENANT_DB[(tenant_{uuid}\n368 tables)]
    end

    subgraph "External Services"
        RAZORPAY[Razorpay API]
        SMTP[SMTP / SES]
        STORAGE[File Storage]
    end

    WEB --> NGINX
    API_CLIENT --> NGINX
    NGINX --> LARAVEL
    LARAVEL --> AUTH
    AUTH --> SANCTUM
    AUTH --> TENANT_MW
    TENANT_MW --> ACTIVE_MW
    ACTIVE_MW --> MODULE_MW
    MODULE_MW --> CENTRAL_MOD
    MODULE_MW --> TENANT_MOD
    CENTRAL_MOD --> GLOBAL_DB
    CENTRAL_MOD --> PRIME_DB
    TENANT_MOD --> TENANT_DB
    TENANT_MOD --> GLOBAL_DB
    TENANT_MOD --> RAZORPAY
    TENANT_MOD --> SMTP
    TENANT_MOD --> STORAGE
```

---

## 2. Module Dependency Diagram

```mermaid
graph LR
    subgraph "Central Scope"
        PRIME[Prime Module]
        GM[GlobalMaster]
        SC[SystemConfig]
        BILL[Billing]
        DOC[Documentation]
        SCHED[Scheduler]
    end

    subgraph "Core Tenant"
        SS[SchoolSetup]
        SP[StudentProfile]
        ST[SmartTimetable]
    end

    subgraph "Operations"
        TPT[Transport]
        VND[Vendor]
        CMP[Complaint]
        NTF[Notification]
        PAY[Payment]
        DASH[Dashboard]
    end

    subgraph "Curriculum"
        SYL[Syllabus]
        SB[SyllabusBooks]
        QB[QuestionBank]
    end

    subgraph "LMS / Assessment"
        EXM[LmsExam]
        QUZ[LmsQuiz]
        HW[LmsHomework]
        QST[LmsQuests]
    end

    subgraph "Analytics"
        HPC[Hpc]
        REC[Recommendation]
        SF[StudentFee]
    end

    %% Dependencies
    PRIME --> GM
    PRIME --> SC
    PRIME --> BILL
    SS --> GM
    SS --> PRIME
    SP --> SS
    ST --> SS
    TPT --> SS
    TPT --> SP
    SYL --> SS
    SB --> SYL
    QB --> SYL
    EXM --> QB
    QUZ --> QB
    HW --> SYL
    QST --> QB
    HPC --> SYL
    HPC --> QB
    REC --> HPC
    REC --> SYL
    SF --> SP
    SF --> PAY
    CMP --> SP
    NTF -.-> CMP
    NTF -.-> SF
    NTF -.-> BILL
```

---

## 3. Route → Controller → Model Flow Diagram

```mermaid
flowchart TD
    subgraph "Route Layer"
        WR[routes/web.php\n973 lines]
        TR[routes/tenant.php\n2,628 lines]
        AR[routes/api.php\n9 lines]
        MR[Module routes/web.php\n+ routes/api.php]
    end

    subgraph "Middleware"
        MW1[auth + verified]
        MW2[InitializeTenancyByDomain]
        MW3[EnsureTenantIsActive]
        MW4[EnsureTenantHasModule]
        MW5[auth:sanctum]
    end

    subgraph "Controller Layer (283 total)"
        CC[Central Controllers x13]
        MC[Module Controllers x270]
    end

    subgraph "Service Layer (12 total)"
        SVC1[ActivityScoreService]
        SVC2[RoomAvailabilityService]
        SVC3[SubActivityService]
        SVC4[TimetableStorageService]
        SVC5[ComplaintAIInsightEngine]
        SVC6[NotificationService]
        SVC7[PaymentService]
        SVC8[TenantPlanAssigner]
    end

    subgraph "Model Layer (381 total)"
        M1[User]
        M2[Tenant + Domain]
        M3[Student + Details + Profile]
        M4[Teacher + Profile]
        M5[Timetable + Cells + Activities]
        M6[Vehicle + Route + Trip]
        M7[Question + Options + Tags]
        M8[Complaint + Actions + AI]
        M9[FeeStructure + Invoice + Transaction]
        M10[381 Eloquent Models...]
    end

    subgraph "Database Layer"
        DB1[(global_db - 12 tables)]
        DB2[(prime_db - 27 tables)]
        DB3[(tenant_db - 368 tables)]
    end

    WR --> MW1 --> CC
    TR --> MW2 --> MW3 --> MW4 --> MC
    AR --> MW5 --> CC
    MR --> MW5 --> MC
    CC --> SVC8
    MC --> SVC1 & SVC2 & SVC3 & SVC4 & SVC5 & SVC6 & SVC7
    CC --> M1 & M2
    MC --> M3 & M4 & M5 & M6 & M7 & M8 & M9 & M10
    M1 & M2 --> DB2
    M2 --> DB1
    M3 & M4 & M5 & M6 & M7 & M8 & M9 & M10 --> DB3
```

---

## 4. Database Relationship Diagram (ERD) — Core Entities

```mermaid
erDiagram
    %% Central
    prm_tenant ||--o{ prm_tenant_domains : "has domains"
    prm_tenant ||--o{ prm_tenant_plan_jnt : "has plans"
    prm_plans ||--o{ prm_tenant_plan_jnt : "assigned to"
    prm_tenant_plan_jnt ||--o{ prm_tenant_plan_module_jnt : "includes modules"
    prm_tenant_plan_jnt ||--o{ bil_tenant_invoices : "generates"

    %% School Setup
    sch_organizations ||--o{ sch_classes : "has"
    sch_organizations ||--o{ sch_sections : "has"
    sch_organizations ||--o{ sch_buildings : "has"
    sch_classes ||--o{ sch_class_section_jnt : "mapped to"
    sch_sections ||--o{ sch_class_section_jnt : "mapped to"
    sch_buildings ||--o{ sch_rooms : "contains"
    sch_subjects ||--o{ sch_subject_teachers : "taught by"
    sch_teachers ||--o{ sch_subject_teachers : "teaches"
    sys_users ||--o| sch_teachers : "is a"
    sys_users ||--o| sch_employees : "is a"

    %% Students
    sys_users ||--o| std_students : "is a"
    std_students ||--|| std_student_details : "has"
    std_students ||--o| std_student_profiles : "has"
    std_students ||--o{ std_student_academic_session : "enrolled in"
    sch_class_section_jnt ||--o{ std_student_academic_session : "contains"
    std_students ||--o{ std_student_guardian_jnt : "has guardians"
    std_guardians ||--o{ std_student_guardian_jnt : "guardian of"
    std_students ||--o{ std_attendance_details : "attendance"

    %% Timetable
    tt_timetables ||--o{ tt_timetable_cells : "contains"
    tt_timetable_cells ||--o{ tt_timetable_cell_teachers : "assigned"
    tt_activities ||--o{ tt_timetable_cells : "placed in"
    tt_activities ||--o{ tt_activity_teachers : "taught by"
    tt_activities ||--o{ tt_sub_activities : "has parts"
    tt_constraints ||--o{ tt_constraint_violations : "violated in"
    tt_timetables ||--o{ tt_generation_runs : "generated by"

    %% Finance
    fin_fee_structure_masters ||--o{ fin_fee_structure_details : "has heads"
    fin_fee_structure_masters ||--o{ fin_fee_installments : "split into"
    fin_fee_head_masters ||--o{ fin_fee_structure_details : "referenced"
    fin_fee_group_masters ||--o{ fin_fee_group_heads_jnt : "contains"
    std_students ||--o{ fin_fee_student_assignments : "assigned"
    std_students ||--o{ fin_fee_invoices : "invoiced"
    fin_fee_invoices ||--o{ fin_fee_transactions : "paid via"
    fin_fee_transactions ||--o{ fin_fee_transaction_details : "details"

    %% Transport
    tpt_vehicle ||--o{ tpt_driver_route_vehicle_jnt : "assigned"
    tpt_routes ||--o{ tpt_driver_route_vehicle_jnt : "served by"
    tpt_routes ||--o{ tpt_pickup_points : "has stops"
    tpt_trips ||--o{ tpt_student_boarding_logs : "tracks"
    tpt_vehicle ||--o{ tpt_daily_vehicle_inspections : "inspected"

    %% Curriculum
    slb_lessons ||--o{ slb_topics : "contains"
    slb_topics ||--o{ slb_topic_competencies : "mapped to"
    slb_competencies ||--o{ slb_topic_competencies : "linked"

    %% Questions & Assessment
    qns_questions_bank ||--o{ qns_question_options : "has options"
    qns_questions_bank ||--o{ qns_question_question_tag_jnt : "tagged"
    lms_exams ||--o{ lms_exam_papers : "has papers"
    lms_exam_papers ||--o{ lms_exam_paper_sets : "has sets"
    lms_quizzes ||--o{ lms_quiz_questions : "contains"

    %% Complaints
    cmp_complaints ||--o{ cmp_complaint_actions : "has actions"
    cmp_complaints ||--o| cmp_ai_insights : "analyzed by AI"
    cmp_complaint_categories ||--o{ cmp_complaints : "categorized"
```

---

## 5. Timetable Generation Flow Diagram

```mermaid
flowchart TD
    A[Setup: Classes, Subjects, Teachers, Rooms] --> B[Create Activities]
    B --> C[Define Constraints: Hard + Soft]
    C --> D[Configure Period Sets & School Days]
    D --> E[Pre-Generation]

    E --> E1[ActivityScoreService\nCalculate difficulty + priority]
    E --> E2[RoomAvailabilityService\nGenerate room matrix]
    E --> E3[SubActivityService\nCreate sub-activities for blocks]

    E1 & E2 & E3 --> F[DatabaseConstraintService\nLoad all constraints]

    F --> G[FET Solver\n50K max iterations\n25s timeout]

    G --> G1{For each activity\nordered by priority}
    G1 --> G2[SlotGenerator\nGenerate candidate slots]
    G2 --> G3[SlotEvaluator\nScore against constraints]
    G3 --> G4{Hard constraints\nsatisfied?}
    G4 -->|No| G5[Backtrack]
    G5 --> G1
    G4 -->|Yes| G6[Place in best slot]
    G6 --> G1

    G1 -->|All placed| H[TimetableStorageService\nAtomic DB persist]

    H --> I[tt_timetables: GENERATED]
    I --> J[Approval Workflow]
    J --> K[tt_timetables: PUBLISHED]
```

---

## 6. Authentication & Authorization Flow

```mermaid
sequenceDiagram
    participant U as User/Browser
    participant R as Routes
    participant MW as Middleware Stack
    participant C as Controller
    participant P as Policy
    participant DB as Database

    U->>R: HTTP Request
    R->>MW: auth middleware
    MW->>MW: Verify session/token
    alt Tenant Route
        MW->>MW: InitializeTenancyByDomain
        MW->>DB: Resolve tenant from domain
        DB-->>MW: Tenant found
        MW->>MW: Bootstrap DB/Cache/FS/Queue
        MW->>MW: EnsureTenantIsActive
        MW->>MW: EnsureTenantHasModule
    end
    MW->>C: Request authorized
    C->>P: $this->authorize('action', Model)
    P->>P: Check user roles/permissions
    P-->>C: Allowed/Denied
    C->>DB: Query (tenant-scoped)
    DB-->>C: Results
    C-->>U: Response (HTML/JSON)
```

---

## 7. Multi-Tenancy Data Flow

```mermaid
flowchart LR
    subgraph "DNS"
        D1[school1.prime-ai.com]
        D2[school2.prime-ai.com]
        D3[admin.prime-ai.com]
    end

    subgraph "Laravel Application"
        MW[Tenancy Middleware]
        BOOT[Bootstrappers:\nDatabase\nCache\nFilesystem\nQueue]
    end

    subgraph "Databases"
        GDB[(global_db\nShared Read-Only)]
        PDB[(prime_db\nCentral Management)]
        T1DB[(tenant_abc123\nSchool 1 Data)]
        T2DB[(tenant_def456\nSchool 2 Data)]
    end

    D1 --> MW
    D2 --> MW
    D3 --> PDB
    MW --> BOOT
    BOOT -->|school1| T1DB
    BOOT -->|school2| T2DB
    T1DB -.->|views| GDB
    T2DB -.->|views| GDB
```

---

## 8. Fee Payment Workflow

```mermaid
flowchart TD
    A[Fee Structure Setup] --> B[Student Fee Assignment]
    B --> C[Invoice Generation\nper Installment]
    C --> D{Payment Method}

    D -->|Online| E[Razorpay Checkout]
    E --> F[PaymentService\ncreatePayment]
    F --> G[RazorpayGateway\ncreateOrder]
    G --> H[Student Pays]
    H --> I[Webhook Callback]
    I --> J[Verify Signature]
    J -->|Valid| K[Create Transaction\n+ Receipt]
    J -->|Invalid| L[Log Error]

    D -->|Offline| M[Manual Entry]
    M --> K

    K --> N[Update Invoice\nStatus: Paid]
    N --> O[fin_fee_receipts\nGenerated]
```
