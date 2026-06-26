# Resource Matrix Report — Business Requirements

## What This Screen Does

The Resource Matrix is an operational auditing report that cross-references the theoretical syllabus with physical and digital assets. It helps the school ensure that every planned lesson actually has the necessary study materials, like PDFs and Videos, and assessment materials, like Question Banks, attached to it before the term begins.

It acts as a quality assurance tool, preventing situations where a teacher arrives in class only to realize the smartboard video for that topic hasn't been uploaded yet or students have no homework assigned.

---

## When This Screen Is Used

- Summer Break Preparation used by Heads of Departments before the academic year starts to verify that teachers have uploaded all required study materials to the system
- Digital Content Audits used by the IT or Content team to identify missing PDFs, broken video links, or empty question banks
- Flipped Classroom Planning used to ensure that students have pre-reading materials available before a topic is scheduled to be taught

---

## Key Fields and Columns in the Report

**Topic Context**
Columns for Class, Subject, Lesson Name, and Topic Name identify exactly where the resources should be attached.

**Dynamic Resource Counters**
The Video Count displays the total number of video links attached to the topic. The Document Count displays the total number of PDF or Word documents attached. The URL Count displays the total number of external web links attached. The Question Bank Count displays the total number of assessable questions currently tagged to this specific topic in the central Question Bank.

**Status and Health Indicator**
A Status Badge provides a system-calculated health indicator, categorizing the topic as Resource Rich in Green, Adequate in Yellow, or Deficient in Red.

---

## Business Rules and Conditions

**Deep Document Parsing**
To generate this report efficiently, the system must deeply scan the resource attachments stored against both Lessons and Topics. It must categorize the attachments into videos, documents, and links, count the occurrences of each type, and output them to the grid columns to provide a clear summary without requiring manual checking.

**Deficiency Logic based on Assessability**
The report's Health Indicator must be intelligent. It checks whether a topic is marked as Assessable in the master setup. If an assessable topic has a Question Bank Count of zero, the Resource Matrix flags this topic as critically deficient due to missing questions. However, if a topic is explicitly marked as non-assessable, such as an introductory welcome topic, a zero Question Bank Count is perfectly acceptable and does not trigger a deficiency warning.

**Aggregate Roll-up**
The user must be able to view this matrix at the broad Lesson level. The system will sum up the Video, Document, and Question counts of all child topics to give an overall health score for the entire chapter.

---

## Workflow Steps

**Auditing Missing Content**
The Science HOD opens the Resource Matrix report during the summer break. They filter the report for Class 9 Physics. The matrix loads, showing that Chapter 1 has 5 Videos, 2 PDFs, and 50 Questions, earning a Green Resource Rich status badge. However, Chapter 3 has 0 Videos, 0 PDFs, and only 2 Questions, causing the status badge to flash Red for Deficient. The HOD clicks the Export Missing Resources List button. They email this generated list to the Physics department, mandating them to upload content and questions for Chapter 3 before the school reopens.

---

## Example Scenario

A school mandates a modern Flipped Classroom model, where students must watch a conceptual video at home before coming to physical class to discuss it. 

To ensure this model doesn't fail, the Academic Coordinator uses the Resource Matrix. They apply a custom filter to show all topics where the Video Count is zero. The system instantly generates a list of 40 topics across various subjects that lack video content. The Coordinator exports this list and tasks the IT multimedia team to source, record, and upload videos for these exact 40 topics, guaranteeing the Flipped Classroom model operates smoothly.

---

## Related Screens

- **Topics Master and Lessons Master** — The source screens where the resources are actually uploaded and stored
- **Question Bank Module** — The source module queried to calculate the Question Bank Count
