# Lessons Master — Business Requirements

## What This Screen Does

The Lessons Master screen is the structural foundation of the school's curriculum. It defines the major chapters, units, or modules taught within a specific subject for a specific class. 

This screen connects the school's internal teaching structure directly to physical or digital textbooks. It mandates the definition of learning objectives, prerequisites, and resource planning right at the top level, ensuring teachers have a clear roadmap before they step into the classroom. It also integrates with the school's version control system to track curriculum changes year-over-year.

---

## When This Screen Is Used

- Start of Academic Year Setup by Academic Coordinators when defining the curriculum for a new academic session
- Curriculum Redesign when a school changes its core textbook and needs to re-map existing lessons to the new textbook's chapters
- Pre-requisite Mapping when HODs decide that students cannot begin "Advanced Mechanics" without first completing "Basic Algebra"

---

## Key Fields at a Glance

**Core Identity**
Every lesson must have a name, such as "Chapter 1: Matter in Our Surroundings". A shorter version of the name is also captured to be used for mobile app displays and report card printing. A system-generated tracking ID and auto-generated code are automatically assigned in the background to ensure standardized sorting and long-term analytics tracking, even if the lesson's name changes in the future. The sequence or ordinal value determines the display order, and changing this automatically shifts the sequence of other lessons.

**Relational Mapping**
The lesson is locked to a specific academic session, class, and subject, which defines the exact student group this lesson belongs to. The lesson is also linked to a specific physical or digital book from the Library. An additional field captures the exact book chapter detail, explaining exactly where in the book this lesson is found, such as "Page 14, Section 2.1".

**Academic and Planning Details**
The estimated periods field captures the expected number of classes required to complete the lesson, acting as the baseline for planning accuracy reports. The weightage percentage represents how much this chapter contributes to the final exam marks. A scheduled timeframe defines the macro-level target week or month for completion.

**Advanced Requirements**
Multiple learning objectives are defined to clearly state what the student should achieve. Prerequisites link to other lessons that must be completed first. Study resources allow attaching multimedia links like videos or reference documents directly to the lesson.

---

## Business Rules and Conditions

**Unique Constraints**
A school cannot have two lessons with the exact same name in the same class and subject. The system must block duplicate entries to prevent confusion in reports and planning.

**Immutability and Version Control**
If a lesson is imported from a master board repository like CBSE or NCERT, it is marked as a System Standard. In this state, the school cannot edit its core name or weightage. If the school wishes to alter the lesson, the system creates a "Derived" custom copy, leaving the original intact. Once an academic term begins, the lesson is locked. No structural changes can be made without generating a formal Curriculum Change Request.

**Deletion Restrictions**
You cannot delete a Lesson if it already contains smaller Topics inside it. The user must delete or move the topics first. Additionally, changing the academic year is prohibited once student progress is recorded against the lesson.

---

## Workflow Steps

**Adding a New Custom Lesson**
The Academic Coordinator navigates to Syllabus Master and selects Lessons. They choose the target Class and Subject, then click Add Lesson. They select the physical textbook from a searchable dropdown, enter the Lesson Name and Short Name, and add the estimated periods and weightage percentage. They define learning objectives and click Save. The system checks for duplicates and saves the record.

**Adding Prerequisites and Resources**
While editing a lesson, the HOD selects other existing lessons from a dropdown to mark them as prerequisites. They also paste web links or attach documents into the Study Resources section, which instantly become available to the teachers assigned to this lesson.

---

## Example Scenario

At the start of the academic year, the school adopts a new Computer Science curriculum for Grade 8. The HOD creates a new Lesson named "Introduction to Machine Learning". 

Because this is a difficult topic, the HOD adds a prerequisite, selecting a Grade 7 lesson called "Basic Algorithms". They also attach a reference video link. 

When a Grade 8 student attempts to open "Introduction to Machine Learning" on their student portal, the system checks the prerequisites. If the student failed the quiz for "Basic Algorithms" last year, the system displays a warning message advising them to clear the basics first. Meanwhile, the teacher sees the attached reference video on their dashboard, ready to be played in class.

---

## Related Screens

- **Topics** — Defines the granular breakdown of this lesson
- **Lesson Date Planning** — Where the macro schedule is overridden by specific classroom dates
