# Timetable Module - Report Designs (v1)

**Document Version:** 1.0  
**Format:** PDF, Excel, HTML View  
**Reference:** `tt_timetable_ddl_v6.0.sql`

---

## Report 1: Consolidated Master Timetable
**Audience:** Principal, Admin  
**Parameter:** Session, Timetable Version  
**Layout:** Matrix (Rows: Class / Cols: Periods)

### 1.1 Layout Design

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  PRIME SCHOOL - MASTER TIMETABLE (Session: 2025-26)                               Date: 14 Oct 2025    │
│  Type: Morning Regular Shift                                                                           │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  CLASS  | P1 (8:00)      | P2 (8:45)      | BREAK     | P3 (9:45)      | P4 (10:30)     | ...          │
│  -------|----------------|----------------|-----------|----------------|----------------|--------------│
│  10-A   | MATH           | ENG            |           | SCI (Phy)      | HIST           |              │
│         | (R. Sharma)    | (S. Das)       |           | (A. Einstein)  | (B. Singh)     |              │
│  -------|----------------|----------------|-----------|----------------|----------------|--------------│
│  10-B   | SCI (Bio)      | MATH           |           | ENG            | P.E.           |              │
│         | (M. Currie)    | (R. Sharma)    |           | (S. Das)       | (P.T. Usha)    |              │
│  -------|----------------|----------------|-----------|----------------|----------------|--------------│
│  11-A   | PHY LAB        | PHY LAB        |           | MATH           | CHEM           |              │
│         | (Lab 1)        | (Lab 1)        |           | (V. Raman)     | (H. Devi)      |              │
│  -------|----------------|----------------|-----------|----------------|----------------|--------------│
│  ...                                                                                                   │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Report 2: Teacher Workload Summary
**Audience:** HR, Principal  
**Parameter:** Date Range (Weekly)

### 2.1 Layout Design

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  TEACHER WORKLOAD REPORT (Week 14-19 Oct)                                                              │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  TEACHER NAME     | DEPT      | TOTAL PERIODS | AVG/DAY | FREE PERIODS | UTILIZATION % | STATUS        │
│  -----------------|-----------|---------------|---------|--------------|---------------|---------------│
│  1. R. Sharma     | Math      | 28            | 5.6     | 12           | 92%           | [OVERLOAD]    │
│  2. S. Das        | English   | 24            | 4.8     | 16           | 80%           | [OPTIMAL]     │
│  3. P.T. Usha     | Sports    | 15            | 3.0     | 25           | 50%           | [UNDERLOAD]   │
│  ...                                                                                                   │
│                                                                                                        │
│  * Overload Threshold: >26 Periods/Week                                                                │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Filters
- **Department**: Multi-select
- **Status**: Included/Excluded Overloaded teachers

---

## Report 3: Daily Substitution Sheet
**Audience:** Notice Board, Staff Room  
**Parameter:** Date (Today)

### 3.1 Layout Design

```ascii
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  NOTICE: SUBSTITUTION ARRANGEMENTS                                            Date: 14 Oct 2025        │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  The following classes have been reassigned due to teacher absence.                                    │
│  Please report to the assigned room promptly.                                                          │
│                                                                                                        │
│  PERIOD | CLASS | SUBJECT      | ABSENT TEACHER    | SUBSTITUTE TEACHER | ROOM   | REMARKS             │
│  -------|-------|--------------|-------------------|--------------------|--------|---------------------│
│  1      | 10-A  | Math         | Mr. J. Doe        | Mrs. B. Kaur       | 101    | Revision Ch.4       │
│  2      | 9-B   | Science      | Mr. J. Doe        | Mr. C. Lal         | Lab 2  | Complet Lab Rec     │
│  4      | 12-C  | Physics      | Mrs. P. Guha      | SELF STUDY         | Lib    | Library Period      │
│                                                                                                        │
│  Signed: __________________________ (Principal)                                                        │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```
