# Understanding the `is_system` Field in Subjects & Study Formats

This document explains why the `is_system` field is used in the **Subjects** and **Study Formats** tables outside of their standard management screens (CRUD), written in plain, non-technical business language.

---

## 1. The Core Purpose: System Fallback & Safety Net
The primary reason the `is_system` flag exists on these two tables is to ensure that a **default fallback record (Free Period)** is always guaranteed to exist in the database. 

During normal operations, if a school administrator deletes or disables a subject or format that they created (e.g., Mathematics or Lecture), the system can handle it. However, if they were to delete the default **"Free Period"** records, it would break the scheduling engine. 

By marking these default records with `is_system = True`, the application permanently locks them, preventing anyone from modifying, renaming, deactivating, or deleting them.

---

## 2. Integration with the Timetable Scheduling Engine
The Timetable Solver Engine is the main module outside of the CRUD screen that relies on these records. 

* **Filling Empty Slots:** When the scheduling engine builds or displays a school timetable, every single period of the day must have a value. If a class has no teacher or class assigned during a particular period, the engine cannot leave it blank in the database. Instead, it automatically fills that slot using the default `'FREE'` Subject and `'FREE'` Study Format records.
* **Scheduling Diagnostics & Rules:** When evaluating scheduling conflicts (for example, verifying that a class has the correct number of free slots per week), the timetable engine counts these specific system-locked fallback records.

---

## 3. Scenario: How Both Tables Are Used Together

Both tables are used simultaneously when the system encounters an unscheduled slot in the timetable. 

* **The Subject Scenario (`sch_subjects`):**
  * When a student or teacher views their schedule and a period is blank, the system displays the name **"Free Period"** to them. It pulls this name directly from the protected record in the **Subjects** table.
* **The Format Scenario (`sch_study_formats`):**
  * In the background, the system must assign a "delivery method" (such as a Lecture, Lab, or Practical session) to every scheduled slot. Since a free period has no delivery method, the system assigns the delivery method as **"FREE PERIOD"** from the **Study Formats** table to satisfy database rules and keep formatting clean.

By using both records, the system ensures the database remains structurally complete while displaying a clear, readable schedule on the screen.

---

## Summary
In short, the `is_system` field acts as a **safety lock**. Outside of the management screens, it ensures that the **Timetable Engine** always has a permanent, unalterable "Free Period" record to assign to any unscheduled time slots.
