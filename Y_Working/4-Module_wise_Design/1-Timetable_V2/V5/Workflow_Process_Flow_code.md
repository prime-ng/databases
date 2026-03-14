graph TD
    %% PHASE 0: PRE-REQUISITES
    subgraph "PHASE 0: PRE-REQUISITES SETUP"
        A0[System Configuration] --> A1[Master Data Setup]
        A1 --> A2[Academic Structure Setup]
    end

    %% PHASE 1: ACADEMIC TERM & TIMETABLE TYPE
    subgraph "PHASE 1: ACADEMIC TERM & TIMETABLE TYPE"
        B1[Academic Term Setup] --> B2[Timetable Type Definition]
        B2 --> B3[Calendar Setup]
        B3 --> B4[Period Set Assignment]
    end

    %% PHASE 2: REQUIREMENT GENERATION
    subgraph "PHASE 2: REQUIREMENT GENERATION"
        C1[Slot Requirement Generation] --> C2[Class Requirement Groups]
        C2 --> C3[Class Requirement Subgroups]
        C3 --> C4[Student Count Calculation]
        C4 --> C5[Eligible Teacher Calculation]
        C5 --> C6[Requirement Consolidation]
    end

    %% PHASE 3: RESOURCE AVAILABILITY
    subgraph "PHASE 3: RESOURCE AVAILABILITY"
        D1[Teacher Availability] --> D2[Room Availability]
        D2 --> D3[Constraint Application]
        D3 --> D4[Availability Scoring]
    end

    %% PHASE 4: VALIDATION
    subgraph "PHASE 4: VALIDATION"
        E1[Teacher Availability Validation] --> E2[Room Availability Validation]
        E2 --> E3[Requirement vs Availability]
        E3 --> E4{Validation Passed?}
        E4 -->|No| E5[Generate Validation Report]
        E5 --> E6[Manual Intervention]
        E6 --> E3
        E4 -->|Yes| E7[Proceed to Activity Creation]
    end

    %% PHASE 5: ACTIVITY CREATION
    subgraph "PHASE 5: ACTIVITY CREATION"
        F1[Activity Generation] --> F2[Difficulty Score Calculation]
        F2 --> F3[Priority Score Calculation]
        F3 --> F4[Sub-Activity Creation]
        F4 --> F5[Activity-Teacher Mapping]
        F5 --> F6[Activity-Room Mapping]
    end

    %% PHASE 6: TIMETABLE GENERATION
    subgraph "PHASE 6: TIMETABLE GENERATION"
        G1[Generation Queue] --> G2[Strategy Selection]
        G2 --> G3[Initial Placement - Recursive]
        G3 --> G4{All Activities Placed?}
        G4 -->|No| G5[Conflict Detection]
        G5 --> G6[Swapping Algorithm]
        G6 --> G7{Max Depth Reached?}
        G7 -->|No| G3
        G7 -->|Yes| G8[Conflict Resolution]
        G8 --> G9{Resolved?}
        G9 -->|Yes| G3
        G9 -->|No| G10[Log Conflicts]
        G4 -->|Yes| G11[Optimization Phase]
        G11 --> G12[Simulated Annealing]
        G12 --> G13[Tabu Search]
        G13 --> G14[Final Score Calculation]
    end

    %% PHASE 7: POST-GENERATION
    subgraph "PHASE 7: POST-GENERATION"
        H1[Analytics Generation] --> H2[Teacher Workload Analysis]
        H2 --> H3[Room Utilization Analysis]
        H3 --> H4[Constraint Violation Report]
    end

    %% PHASE 8: MANUAL REFINEMENT
    subgraph "PHASE 8: MANUAL REFINEMENT"
        I1[Cell Lock/Unlock] --> I2[Manual Adjustments]
        I2 --> I3[Change Tracking]
        I3 --> I4[Impact Analysis]
        I4 --> I5{Changes Valid?}
        I5 -->|No| I2
        I5 -->|Yes| I6[Re-validation]
    end

    %% PHASE 9: PUBLICATION
    subgraph "PHASE 9: PUBLICATION"
        J1[Quality Check] --> J2[Approval Workflow]
        J2 --> J3[Publish Timetable]
        J3 --> J4[Generate Outputs]
        J4 --> J5[Notify Stakeholders]
    end

    %% PHASE 10: SUBSTITUTION MANAGEMENT
    subgraph "PHASE 10: SUBSTITUTION MANAGEMENT"
        K1[Absence Recording] --> K2[Affected Cell Identification]
        K2 --> K3[Eligible Teacher Search]
        K3 --> K4[Compatibility Scoring]
        K4 --> K5[Recommendation Generation]
        K5 --> K6[Substitution Assignment]
        K6 --> K7[Pattern Learning]
        K7 --> K8[Historical Success Update]
    end

    %% Flow Connections
    A2 --> B1
    B4 --> C1
    C6 --> D1
    D4 --> E1
    E7 --> F1
    F6 --> G1
    G10 --> I1
    G14 --> H1
    I6 --> J1
    J5 --> K1

    %% Feedback Loops
    H4 -.->|Insights| C6
    K8 -.->|ML Data| K4
    