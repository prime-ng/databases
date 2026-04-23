# Screen Design Specification: Student Profile Module
## Document Version: 1.0
**Last Updated:** January 13, 2026

---

## 1. OVERVIEW

### 1.1 Purpose
This document provides detailed UI/UX specifications for the **Student Profile Module**, enabling administrators and staff to manage student lifecycles, including admission, profile management, family details, academic allocations, and health records.

### 1.2 User Roles & Permissions
| Role         | View | Create | Edit | Delete | Print | Export |
|--------------|------|--------|------|--------|-------|--------|
| Super Admin  |  ✓   |   ✓    |  ✓   |   ✓    |   ✓   |   ✓    |
| School Admin |  ✓   |   ✓    |  ✓   |   ✓    |   ✓   |   ✓    |
| Principal    |  ✓   |   ✗    |  ✗   |   ✗    |   ✓   |   ✓    |
| Teacher      |  ✓   |   ✗    |  ✓*  |   ✗    |   ✓   |   ✗    |
| Clerk        |  ✓   |   ✓    |  ✓   |   ✗    |   ✓   |   ✓    |

*\*Teachers may only edit specific fields like Attendance/Remarks.*

### 1.3 Data Context
Core Table: `std_students` linked with `std_student_profiles`, `std_student_academic_sessions`, `std_guardians`.

---

## 2. SCREEN LAYOUTS

### 2.1 Student List Screen
**Route:** `/students` or `/students/list`

#### 2.1.1 Page Layout
```ascii

┌──────────────────────────────────────────────────────────────────────────────────────┐
│ STUDENT MANAGEMENT > STUDENT LIST                                  [User Profile]    │
├──────────────────────────────────────────────────────────────────────────────────────┤
│  ┌──Tabs────────────────────────────────────────────────────────────────────────────────────────────┐  │
│  │ [List] [Admission] [Attendance] [Health] [Fees] [Marks] │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘  │
│ [ Search by Name, Adm No, Mobile...                 ]  [+ New Admission]  [Export]   │
├──────────────────────────────────────────────────────────────────────────────────────┤
│ SESSION: [2025-26 ▼]   CLASS: [Class 10 ▼]   SECTION: [All ▼]   STATUS: [Active ▼]   │
├──────────────────────────────────────────────────────────────────────────────────────┤
│ ☐ │ Adm No.  │ Student Name      │ Class-Sec │ Guardian       │ Gender │ Status      │
│───┼──────────┼───────────────────┼───────────┼────────────────┼────────┼─────────────│
│ ☐ │ ADM-001  │ Aarav Sharma      │ 10-A      │ Rajesh Sharma  │ Male   │ Active      │
│ ☐ │ ADM-002  │ Vivaan Singh      │ 10-A      │ Amit Singh     │ Male   │ Active      │
│ ☐ │ ADM-003  │ Diya Gupta        │ 10-B      │ Sneha Gupta    │ Female │ Suspended   │
│   │ ...      │ ...               │ ...       │ ...            │ ...    │ ...         │
│───┴──────────┴───────────────────┴───────────┴────────────────┴────────┴─────────────│
│ Showing 1-10 of 450 students                                         [< 1 2 3 >]     │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Components & Interactions
- **Filters**: Academic Session (Default Current), Class, Section, Status (Active, Alumni, Withdrawn).
- **Search**: Omni-search for Name, Admission No, Aadhar, or Mobile.
- **Actions**:
  - **Click Row**: Opens Student Detail View.
  - **Quick Actions (Hover)**: [View] [Edit] [ID Card].


---

### 2.2 Student Admission / Edit Screen
**Route:** `/students/create` or `/students/{id}/edit`

#### 2.2.1 Layout (Tabbed Interface)
```ascii
┌────────────────────────────────────────────────────────────────────────┐
│ STUDENT ADMISSION FORM                                      [Save] [x] │
├────────────────────────────────────────────────────────────────────────┤
│ [Basic Info] [Family] [Address] [Academic] [Prev. Edu] [Docs] [Health] │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│ STAGE 1: BASIC INFORMATION                                             │
│ ────────────────────────────────────────────────────────────────────── │
│ Admission No *       [ADM-2025-001____]  [Generate]                    │
│ Admission Date *     [DD/MM/YYYY]                                      │
│                                                                        │
│ First Name *         [______________]  Last Name *    [______________] │
│ Gender *             (o) Male ( ) Female ( ) Other                     │
│ DOB *                [DD/MM/YYYY]      (Age: 14 Yrs)                   │
│                                                                        │
│ Aadhar ID            [______________]  APAAR ID       [______________] │
│ Blood Group          [Select ▼]        Religion       [Select ▼]       │
│ Caste Category       [Select ▼]        Nationality    [Select ▼]       │
│                                                                        │
│ Student Mobile       [______________]  Student Email  [______________] │
│                                                                        │
│ [Upload Photo]                                                         │
│ ┌──────────┐                                                           │
│ │  IMG     │                                                           │
│ └──────────┘                                                           │
│                                                                        │
│                                                    [Next: Family info >] │
└────────────────────────────────────────────────────────────────────────┘
```

#### 2.2.2 Tabs Breakdown

**1. Basic Info**: Maps to `std_students` & `std_student_profiles`.
- **Validation**: Admission No unique, DOB required, Mobile format check.

**2. Family Info**: Maps to `std_guardians` & `std_student_guardian_jnt`.
```ascii
┌────────────────────────────────────────────────────────────┐
│ GUARDIAN DETAILS                                           │
│ ────────────────────────────────────────────────────────── │
│ [Search Existing Guardian] (Sibling check)                 │
│                                                            │
│ FATHER DETAILS                                             │
│ Name *           [______________] Job [______________]     │
│ Mobile *         [______________] Email [______________]   │
│ [ ] Is Emergency Contact  [ ] Can Pickup  [ ] Fee Payer    │
│                                                            │
│ MOTHER DETAILS                                             │
│ Name *           [______________] Job [______________]     │
│ Mobile           [______________] Email [______________]   │
│ [ ] Is Emergency Contact  [ ] Can Pickup  [ ] Fee Payer    │
└────────────────────────────────────────────────────────────┘
```

**3. Address**: Maps to `std_student_addresses`.
- **Correspondence Address**: Line 1, Line 2, City, State, Pincode.
- **Permanent Address**: [Check] Same as Correspondence.

**4. Academic Allocation**: Maps to `std_student_academic_sessions`.
```ascii
┌────────────────────────────────────────────────────────────┐
│ ACADEMIC DETAILS (Current Session)                         │
│ ────────────────────────────────────────────────────────── │
│ Class *          [Select Class ▼]                          │
│ Section *        [Select Section ▼] (Loads after Class)    │
│ Roll No          [____]                                    │
│ House            [Select House ▼]                          │
│ Subject Group    [Select Group ▼] (For higher classes)     │
└────────────────────────────────────────────────────────────┘
```

**5. Previous Education**: Maps to `std_previous_education` (New in v1.3).
- **Grid View**: School Name, Board, Year, Class Passed, Percentage.
- **[+ Add Previous School]** button.

**6. Documents**: Maps to `std_student_documents` (New in v1.3).
- **Upload Grid**: Document Type (TC, Aadhar), Doc No, File Upload, Verification Status.

---

### 2.3 Student Detail View (360° Profile)
**Route:** `/students/{id}`

#### 2.3.1 Layout
```ascii
┌──────────────────────────────────────────────────────────────────────────────────┐
│ < Back  |  AARAV SHARMA (ADM-001)                    [Edit] [Print Profile]      │
├──────────────────────────────────────────────────────────────────────────────────┤
│ ┌────────────┐   Basic Details               Academic Status                     │
│ │            │   Class: 10-A                 Current Status: Active              │
│ │   PHOTO    │   DOB: 12-Aug-2010            House: Red House                    │
│ │            │   Guardian: Rajesh Sharma     Transport: Route 5 (Bus 12)         │
│ └────────────┘   Contact: 9876543210                                             │
│                  Address: 123, MG Road...                                        │
├──────────────────────────────────────────────────────────────────────────────────┤
│ [OVERVIEW] [ATTENDANCE] [ACADEMICS] [FEES] [HEALTH] [TIMELINE] [DOCUMENTS]       │
├──────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│ ATTENDANCE SUMMARY (Current Month)           HEALTH VITALS                       │
│ ┌─────────────────────────┐                  Height: 165 cm                      │
│ │ P  P  P  A  P  P  L  P  │                  Weight: 55 kg                       │
│ │ 92% Present             │                  Blood Group: B+                     │
│ └─────────────────────────┘                  Allergies: Peanuts                  │
│                                                                                  │
│ FAMILY DETAILS                               LAST INCIDENTS                      │
│ Father: Rajesh Sharma (9988...)              - 12-Jan: Minor headache (Clinic)   │
│ Mother: Sneha Sharma (8877...)               - 10-Oct: Fever (Sent Home)         │
│                                                                                  │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. USER WORKFLOWS

### 3.1 New Admission Workflow
1.  Admin clicks **[+ New Admission]**.
2.  **Basic Info**: Fills name, DOB, etc. System checks Aadhar uniqueness.
3.  **Family**: Admin enters Father's Mobile.
    -   *System Check*: "Mobile 9988... exists linked to Student 'Rohan Sharma'".
    -   *Prompt*: "Link to existing Guardian?" -> **Yes**.
    -   Auto-fills Guardian details.
4.  **Academic**: Selects Class 10 -> Section A. System suggests next Roll No.
5.  **Docs**: Uploads Transfer Certificate (PDF).
6.  **Save**: System creates `std_students` record, links `std_guardians`, assigns `std_student_academic_sessions`.

### 3.2 Promote Student
1.  Navigate to **Academic Tab** in Edit Mode.
2.  Click **[Promote/Transfer]**.
3.  Select New Session, New Class, New Section.
4.  Select Update Status (e.g., Promoted).
5.  Save -> Creates new row in `std_student_academic_sessions`, updates `is_current` flags.

---

## 4. MOBILE / RESPONSIVE
- **Mobile View**: Tabs become a dropdown menu or horizontal scroll.
- **Grids**: Collapse to Card view on screens < 768px.
- **Uploads**: Support camera capture for Documents/Photo on mobile.

---
