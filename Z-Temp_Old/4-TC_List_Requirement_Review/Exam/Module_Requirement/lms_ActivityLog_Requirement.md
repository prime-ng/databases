# Activity Log Screen — Student Activity & Pending Attempts

---

## What Does This Screen Do?

Imagine you're a teacher who just finished an online exam. You want to check:
- Did any student switch tabs too many times? (Possible cheating)
- Who is still taking the exam right now?
- Did a student's internet disconnect in the middle?

This screen answers all those questions. It has two tabs:

**Tab 1: Activity Log** — Like a security camera recording. It shows every action a student did during the exam — switching tabs, leaving fullscreen, copying text, etc.

**Tab 2: Pending Attempts** — Like a live dashboard showing who is still writing the exam right now, which question they're on, and how many they've answered.

---

## Real-Life Example

**Scenario:** Teacher Priya just finished "Annual Exam 2026" for Class 10. Student Rahul scored 95% but usually scores 60%. She suspects cheating.

**What Priya does:**
1. Opens Activity Log
2. Selects Class 10 → Section A → Student "Rahul Sharma"
3. Selects Event Type: "Tab Switch"
4. Clicks Filter
5. Result: Rahul switched tabs **12 times** during the exam. Case confirmed.

**Without this screen:** Priya would have no proof. The activity log provides evidence.

---

## How the Screen Works (Simple Explanation)

When you click the "Log / Grievance" tab, the system does these steps automatically:

**Step 1 - Permission Check:** The system asks "Does this user have permission to see logs, event logs, AND grievances?" If you don't have all three, you get a "Forbidden" error.

**Step 2 - Auto-Create Event Types (first time only):** The system checks if event types exist in the database. If this is a fresh installation (no event types yet), it automatically creates 5 basic types:
   - **Attempt Started** — Student began the exam
   - **Tab Switch** — Student clicked another browser tab
   - **Window Blur** — Student clicked outside the exam window
   - **Fullscreen Exit** — Student left fullscreen mode  
   - **Security Violation** — Something suspicious detected

> **Why this matters:** Without this auto-creation, the filter dropdown would be empty on a new system. The teacher would see no event types to filter by.

**Step 3 - Check Which Tab to Show:** The system looks at the URL to see which tab you clicked. If the URL has `active_tab=activity_log`, it shows the Activity Log. If it has `active_tab=event_log_pending`, it shows Pending Attempts. If nothing is specified, it shows the Grievance tab by default.

**Step 4 - Find Students for the Filter:** If you selected a Class (like "Class 10") or Section (like "Section A"), the system finds all students who belong to that class/section in the current academic year. It only looks at students who are enrolled this year.

**Step 5 - Load Everything at Once:** The system loads ALL three tabs' data in one go — even though you can only see one tab at a time. This means when you click between tabs, they switch instantly without waiting.

**Step 6 - Show the Screen:** The system sends all the data to your browser and renders the page.

---

## Activity Log Tab — Detailed Explanation

### What You See on Screen

The Activity Log tab shows a table with these columns:

| Column | What It Shows | Example |
|--------|---------------|---------|
| # | Serial number (continues across pages) | 1, 2, 3... or 16, 17, 18... on page 2 |
| Student | Student name + attempt ID number | "Rahul Sharma (Attempt #42)" |
| Exam / Paper | Which exam + paper title | "Annual Exam 2026 - Mathematics" |
| Occurred At | Date and time of the event | "23 Jul 2026, 02:30:45 PM" |
| Event Type | What happened, shown as a colored badge | "Tab Switch" in blue badge |
| Details | Extra information about the event | "Ip: 192.168.1.1, Fullscreen: false" |

### Filters Available

The Activity Log tab has 5 filters:

| Filter | What It Does | How It Works |
|--------|-------------|--------------|
| **Class** | Show only students from this class | Dropdown, selecting it loads Sections |
| **Section** | Show only students from this section | Dropdown, appears after Class is selected |
| **Student** | Show only this specific student | Dropdown, appears after Section is selected |
| **Event Type** | Show only this type of event (e.g., only Tab Switches) | Dropdown with all event types |
| **Date Range** | Show only events within this date period | Calendar picker with presets: Today, Yesterday, Last 7 Days, Last 30 Days, This Month, Last Month |

**Important - How Filters Work Together:**

The system applies filters in a specific order:

1. **Student filter has highest priority.** If you select a specific student, the class/section filter is ignored for that student. Example: You select Class "10A" AND Student "Rahul" → only Rahul's events show, regardless of class.

2. **Class/section filter is mid-priority.** If you select a class but NOT a specific student, all events for all students in that class show.

3. **No filter = everything.** If you select nothing, all events from all students show.

4. **Filters only work on the active tab.** If you set filters on the Activity Log tab and click to the Pending Attempts tab, those filters don't apply to the Pending data. When you come back to Activity Log, the filters re-apply.

### Example: Filter Combinations

| What User Selects | What System Shows |
|------------------|-------------------|
| Nothing (all defaults) | All events for ALL students, ALL event types, ALL time |
| Class: "10A" | All events for ALL students in Class 10A |
| Class: "10A" + Event Type: "Tab Switch" | Only Tab Switch events for students in Class 10A |
| Class: "10A" + Student: "Rahul" | All events for Rahul only (class filter is not needed but selected) |
| Event Type: "Fullscreen Exit" + Date: "Last 7 Days" | All Fullscreen Exit events in the last 7 days, all students |
| All 5 filters at once | Only events matching ALL conditions simultaneously |

---

## Pending Attempts Tab — Detailed Explanation

### What You See on Screen

The Pending Attempts tab shows students who are CURRENTLY taking an exam (status = IN_PROGRESS). It's like a live scoreboard.

| Column | What It Shows | Example |
|--------|---------------|---------|
| # | Serial number | 1, 2, 3... |
| Student | Student name + attempt ID | "Rahul Sharma (Attempt #42)" |
| Exam / Paper | Which exam + paper | "Annual Exam 2026 - Mathematics" |
| Last Saved | When the system last saved student's progress | "23 Jul 2026, 02:35:00 PM" |
| Status | Always shows "In Progress" | Green "IN_PROGRESS" badge |
| Progress | Question number, answered count, flagged count | "Q: 6, Answered: 15, Flagged: 2" |
| Action | Button to see full checkpoint data | Database icon → click to see JSON |

### Filters Available

Simpler than Activity Log — only 3 filters:

| Filter | What It Does |
|--------|-------------|
| **Class** | Show only students from this class |
| **Section** | Show only students from this section |
| **Student** | Show only this specific student |

No event type filter, no date range filter.

### Example: Monitoring Live Exam

**Scenario:** Teacher Priya is monitoring a live exam. She wants to check if anyone is stuck.

1. Opens Pending Attempts tab
2. Sees Student "Amit" with "Last Saved: 15 minutes ago" but only on Question 3 of 30
3. Amit might be stuck or have internet issues
4. Teacher clicks the database icon → sees Amit's saved answers
5. Decides to check on Amit physically

**Why this matters:** Without this tab, teachers wouldn't know if a student has technical issues until after the exam ends.

---

## Key Differences Between the Two Tabs

| Feature | Activity Log Tab | Pending Attempts Tab |
|---------|-----------------|---------------------|
| What it shows | Past events (completed actions) | Current state (ongoing exams) |
| Can data be deleted? | **NO** — Records are permanent, never deleted | **YES** — Records are deleted when student submits exam |
| Event type filter? | Yes | No |
| Date range filter? | Yes | No |
| Search by attempt ID? | No | Yes |
| Sort order | Most recent event first | Most recently saved first |
| Items per page | 15 | 15 |
| Page URL parameter | `log_page` | `event_page` |
| Filter button | "Filter" | "Search" |

---

## How the Filter Dropdowns Work (Class → Section → Student)

This is a 3-step cascade:

**Step 1:** Select a Class
- The Section dropdown automatically loads with sections of that class
- Example: Select "Class 10" → Sections show: "A", "B", "C"

**Step 2:** Select a Section (or leave as "All Sections")
- The Student dropdown automatically loads with students in that class/section
- Example: Select Section "A" → Students show: "Rahul Sharma", "Priya Singh", etc.
- **Note:** Only students who have taken at least one exam appear in this list. New students who never attempted an exam won't show up.

**Step 3:** Select a Student (or leave as "All Students")
- Events filtered to that specific student

**What happens if no class is selected:** The Section dropdown shows "All Sections" but the Student dropdown stays empty. Students only load when a class is selected.

---

## Event Types — What Each One Means

The system automatically creates 5 default event types:

| Event Name | Severity | What It Means |
|------------|----------|---------------|
| **Attempt Started** | Low | Student began the exam — this is normal |
| **Tab Switch** | Medium | Student clicked away to another browser tab — suspicious if many |
| **Window Blur** | Medium | Student clicked outside the exam window — could be checking notes |
| **Fullscreen Exit** | High | Student exited fullscreen mode — serious, could mean external help |
| **Security Violation** | High | A security rule was broken — developer tools, right-click, copy-paste |

**How Events are Recorded:**

During an exam, JavaScript code in the student's browser monitors their behavior:
- If the student presses "Alt+Tab" → a TAB_SWITCH event is saved
- If the student presses "F11" to exit fullscreen → a FULLSCREEN_EXIT event is saved
- If the student right-clicks → a VIOLATION event is saved

Each event stores extra details like:
- The student's IP address
- Whether the browser was in fullscreen mode
- Which key was pressed
- The URL they tried to navigate to

---

## Event Data — The "Details" Column

When you see an event in the table, the "Details" column shows extra information stored as key-value pairs. Examples of what you might see:

| Detail Shown | What It Tells You |
|-------------|-------------------|
| `Ip: 192.168.1.1` | Student's IP address at the time |
| `Fullscreen: false` | Student was not in fullscreen mode |
| `Key Code: 27` | Student pressed the Escape key |
| `Url: /question/5` | Which question they were on when the event happened |

If there are no details, it shows "System triggered event" in italic.

---

## Important Rules to Remember

| # | Rule | Why It Matters |
|---|------|----------------|
| 1 | **Logs are permanent** — Activity logs can NEVER be deleted or edited. They are like a bank transaction record. | You can trust the data. Even if someone tries to delete evidence, they can't. |
| 2 | **Checkpoints are temporary** — Pending attempt data is deleted automatically when the student submits the exam. | If a student finishes and submits, they disappear from Pending Attempts. If they're still there, they haven't submitted. |
| 3 | **Only Exam data shown** — The same table structure is shared with Quiz and Quest modules, but this screen only shows Exam records. | You won't see data from other modules mixed in. |
| 4 | **Three permissions required** — To see this screen, a user needs ALL of: grievance view + activity log view + event log view. | Having just one or two isn't enough. If someone can't access, check all three permissions. |
| 5 | **Student filter overrides class filter** — If you select both a class AND a specific student, only the student filter works. | Don't be confused if selecting a student shows results from a different class. |
| 6 | **Filters only work on active tab** — Switching tabs doesn't carry filters over. | Set your filters AFTER clicking the tab you want. |
| 7 | **Serial numbers continue across pages** — Page 2 starts with #16, not #1. | This helps you know the total position. |

---

## Error Scenarios — What Can Go Wrong

| What Happens | What the User Sees | Why It Happens |
|-------------|-------------------|----------------|
| User doesn't have permission | "403 Forbidden" error page | Missing one or more of the 3 required permissions |
| No event types in database | Event Type dropdown is populated (auto-created) | System creates them automatically on first load |
| No activity logs match filters | "No activity logs found." message | Either no data exists or filters are too restrictive |
| No pending attempts | "No active/pending exam attempts found." message | All students have submitted or no exams are running |
| Class selected but no sections | Section shows "All Sections" only | The class might not have sections defined |
| Section selected but no students | Student shows "All Students" only | No students in that section have taken exams |
| Exam paper was deleted | Shows "N/A" instead of paper title | The paper record was removed but the log still exists |
| Student was deleted from system | Shows "Student ID: X" instead of name | The student record was removed but the log remains (audit trail) |
| Invalid date entered | System may show error or use defaults | Date format must be valid |

---

## Complete Walkthrough: Investigating a Student

**Step-by-step scenario for a non-technical teacher:**

Let's say you're Teacher Priya. You just finished "Annual Exam 2026" for Class 10. Student "Amit Verma" scored suspiciously high.

**Step 1:** Click "Log / Grievance" tab in the Exam module
- You see 3 sub-tabs: Re-Evaluation, Activity Log, Pending Attempts
- Click "Activity Log"

**Step 2:** The page shows a table (probably empty if no filters applied)

**Step 3:** In the filter bar at top:
- Click the Class dropdown → Select "Class 10"
- Section dropdown automatically appears with "A", "B", "C" → Select "A"
- Student dropdown appears with names → Type "Amit" → Select "Amit Verma"

**Step 4:** In Event Type dropdown → Select "Tab Switch"

**Step 5:** In Date Range → Click the calendar → Select "Last 7 Days"

**Step 6:** Click "Filter" button (blue)

**Step 7:** The table now shows only Amit's Tab Switch events in the last 7 days

**Step 8:** Count the events. If Amit switched tabs 15+ times during a 1-hour exam, that's abnormal.

**Step 9:** Clear the Event Type filter and click Filter again → Shows ALL of Amit's events

**Step 10:** Check for "Fullscreen Exit" or "Security Violation" events

**Step 11:** If evidence found, take screenshot as proof and proceed with disciplinary action

---

## Complete Walkthrough: Monitoring a Live Exam

**Step 1:** Click "Log / Grievance" → Click "Pending Attempts" tab

**Step 2:** See a table of all students currently taking exams

**Step 3:** Notice Student "Riya" has "Last Saved: 25 minutes ago" but still on Question 3

**Step 4:** Click the database icon (Action column) → See her checkpoint data shows she's been on Q3 for 25 minutes

**Step 5:** This might mean Riya is stuck or disconnected. Teacher can check on her.

**Step 6:** Notice Student "Karan" has "Answered: 28 of 30" and "Flagged: 5" — he's almost done

---

## Tables Where Data is Stored

For anyone who needs to understand the data structure:

**Activity Logs Table** — Stores every event. Think of it as a ticketing machine that only writes, never erases:
- Event ID (auto-number)
- Which module: EXAM, QUEST, or QUIZ
- Which attempt
- What type of event (Tab Switch, etc.)
- Extra details (IP address, etc.)
- When it happened
- **This data can never be deleted or changed**

**Event Types Table** — Stores the list of possible event types:
- Code: TAB_SWITCH, FULLSCREEN_EXIT, etc.
- Name: "Tab Switch", "Fullscreen Exit"
- Severity: LOW, MEDIUM, HIGH
- Description: What this event means

**Checkpoints Table** — Stores in-progress exam state:
- Which attempt
- Current question number (0-based, so 5 means question 6)
- Which questions are answered (list of IDs)
- Which questions are flagged (list of IDs)
- Full answer snapshot (all answers saved so far)
- Last save time
- **This data IS deleted when student submits** — it's temporary

---

## How This Same System is Used by Other Modules

The same database tables are shared across 3 modules:
- **EXAM** — The Exam module (what we're documenting here)
- **QUEST** — The Question Bank module (different feature)
- **QUIZ** — Quiz module

Each module stores its data separately using the `attempt_type` column. The Exam module ONLY shows its own data. You won't see Quiz or Quest records in this screen.

---

## Permissions — Who Can Access

To access this screen, a user needs ALL three permissions:

1. **Re-evaluation Requests View** — Can see the Grievance tab
2. **Activity Log View** — Can see the Activity Log tab
3. **Event Log View** — Can see the Pending Attempts tab

If a user has only one or two of these, they will get a "403 Forbidden" error. All three are mandatory.

**Who typically has these permissions:**
- School admin
- Exam controller / coordinator
- Head of department
- Class teacher (for their own class)

**Who typically does NOT:**
- Students (they shouldn't see other students' activity)
- Guest users
- Teachers without exam responsibilities

---

## Related Features

| Feature | How It Connects |
|---------|----------------|
| **Grievance / Re-Evaluation** | Same tab group — students can request re-evaluation here |
| **Online Assessment** | After checking papers, teachers come here to monitor |
| **Exam Summary** | Summary of all exam results — this screen focuses on behavior |
| **Student Portal** | Students attempt exams here → their behavior is logged here |

---

## Summary

The Activity Log screen is the exam module's security and monitoring tool. It serves two purposes:

1. **Looking back (Activity Log tab):** A permanent record of everything that happened during exams. Used for cheating investigations and audits.

2. **Looking now (Pending Attempts tab):** A live view of who is currently taking exams. Used for real-time monitoring and technical support.

Both tabs help teachers ensure exam integrity and provide evidence when needed.
