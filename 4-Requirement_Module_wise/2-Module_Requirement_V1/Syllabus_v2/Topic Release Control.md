# Topic Release Control — Business Requirements

## What This Screen Does

The **Topic Release Control** screen is the automation engine that governs the visibility of the syllabus. Think of it as a "digital gatekeeper". It dictates exactly when students and parents can see specific syllabus content, homework, quizzes, or multimedia resources on their digital portals.

Instead of displaying the entire year's syllabus at once—which can overwhelm students and encourage skipping ahead—this screen uses the Syllabus Schedule and strict prerequisite logic to automatically "drip-feed" or unlock topics dynamically as they are taught in the physical classroom.

---

## When This Screen Is Used

- **Daily Operations:** Used by teachers at the end of every physical class to mark a topic as "Released", unlocking the associated study materials for their students.
- **Global Automation Setup:** Used by System Administrators to establish rules like auto-releasing all topics on their scheduled start date.
- **Prerequisite Enforcement:** Used by the system silently in the background to ensure students clear basic assessments before accessing advanced materials.

---

## Key Features and Automated Triggers

### 1. Manual Release Toggle
A simple switch on the teacher's dashboard acts as an override. A teacher explicitly selects a Section and marks a Topic as "Released". This instantly overrides all date-based rules and makes the content visible to that specific section.

### 2. Date-Based Auto-Release
The system reads the scheduled start date from the **Lesson Date Planning** screen. The system runs an automated background process every night. At exactly 00:01 AM on the scheduled date, the topic, its PDFs, and its videos automatically transition from "Locked" to "Visible" for the assigned students.

### 3. Completion-Based Auto-Release
As configured in the Topics master setup, marking a topic as "Taught" in the progress tracker instantly and automatically unlocks the associated quizzes or homework for that topic.

### 4. Prerequisite Hard Locking
Even if a scheduled date arrives or a teacher attempts to manually release a topic, the system checks the prerequisites defined for that topic. If the student hasn't cleared the required prerequisite quiz, the new topic remains locked with a padlock icon, enforcing true mastery-based learning.

---

## Business Rules and Conditions

### Granular Section-Level Control
Release control must operate strictly at the classroom **Section level**. If Class 10-A is taught Trigonometry on Monday, the teacher unlocks it for 10-A. The content must remain completely locked for Class 10-B until their teacher teaches it to them on Wednesday.

### Total Resource Visibility Binding
When a Topic is locked, it is not just the title that is greyed out. Any multimedia resources, PDF documents, or web links attached to that topic must be completely hidden from the student app. Homework or Quizzes linked to a locked topic cannot be attempted.

### Manual Override Precedence
The system must allow a manual override lock or unlock button to accommodate real-world classroom realities. If a teacher finishes a topic 3 days earlier than the scheduled start date, they must be able to unlock the study materials immediately without waiting for the automated date-based release.

---

## Deep Requirements (User-Friendly Language)

### 1. Who Sees What? (Visual Indicators)
- **For Teachers:** Teachers will see a simple list of topics with toggle switches (On = Released, Off = Locked). They will also see small warning icons if they try to unlock a topic that has a strict prerequisite.
- **For Students:** Students will see upcoming topics greyed out with a "Padlock" icon. When they click a locked topic, a friendly message should appear explaining *why* it's locked (e.g., "This topic will unlock on Oct 5" or "Please complete the Chapter 9 Quiz to unlock this topic").
- **For Parents:** Parents will see exactly what the student sees, plus an indicator showing how much of the total syllabus is currently unlocked vs. locked.

### 2. Notifications & Alerts
- **Instant Alerts:** When a teacher manually releases a topic, an instant Push Notification goes to the students' and parents' mobile app: *"New Study Material Unlocked for Physics: Reflection of Light!"*
- **Daily Digest:** For automated date-releases (happening at midnight), students should see a "What's New Today" summary when they log in the next morning.

### 3. Handling Edge Cases
- **Late Admissions (New Students):** If a student joins mid-year, the system should automatically unlock all topics that have already been released to their assigned section up to that date.
- **Teacher Forgets to Release:** If a teacher finishes teaching a topic but forgets to toggle the switch, the Principal or Admin should be able to see a dashboard highlighting "Topics Taught but Not Released" and send a reminder to the teacher.
- **Holiday/Absence Adjustments:** If the school closes unexpectedly, the automated date-based release should have a "Pause All Releases" global button for Admins, so topics don't unlock while students are at home not being taught.

---

## Workflow Steps

### Manual Classroom Release Workflow
A Teacher finishes a 40-minute physical class explaining "Reflection of Light". The Teacher opens the Topic Release Control screen on their mobile or tablet app. They find "Reflection of Light" for Class 10-A and toggle the switch from Locked to Released. Instantly, all students in 10-A receive a push notification stating that new study material and homework have been unlocked for Physics.

### Automated Date Release Workflow
The Admin configures a global setting to auto-release topics based on schedule. A Teacher schedules "Refraction" for October 5th in the Lesson Date Planning screen. On October 5th at midnight, the background automation executes, flips the release status, and makes the topic and its video resources visible on the student portal without any manual intervention.

---

## Example Scenario

To prevent cheating and ensure students follow the teacher's pace, the school uses Topic Release Control strictly. 

A highly eager student logs into the app and tries to click on **Chapter 10: Electricity**. However, it displays a padlock icon with a warning message stating it is locked because the prerequisite Chapter 9 has not been completed. 
The student realizes they missed the quiz for Chapter 9. Once they take and pass the Chapter 9 quiz, the system processes the prerequisite logic and Chapter 10 automatically unlocks for them, allowing access to the new lecture videos.

---

## Related Screens

- **Lesson Date Planning** — Provides the foundational dates for the automated release triggers
- **Topics Master** — Contains the prerequisite list and the configuration toggles that govern this engine
- **Student Progress Dashboard** — Where the impact of these release controls is actually visible to the student
