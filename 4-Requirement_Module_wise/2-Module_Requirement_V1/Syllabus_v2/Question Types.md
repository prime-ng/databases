# Question Types Master — Business Requirements

## What This Screen Does

The Question Types screen defines the foundational mechanical formats or structures of questions that can be added to the system's Question Bank, such as Multiple Choice, Fill in the Blanks, Long Answer, or File Upload. 

This is arguably the most critical configuration table for the Assessment Engine. It acts as the command center that tells the user interface how to display a question to a student, and tells the backend engine whether a specific question can be auto-graded by algorithms or if it requires manual checking by a human teacher.

---

## When This Screen Is Used

- System Initialization primarily during system setup by the software provider or top-level Admin to define standard testing formats
- New Assessment Modalities when the school wants to introduce a completely new assessment format like adding Coding Snippet, Audio Transcription, or Match the Following as supported question types

---

## Key Fields at a Glance

**Identity and Definition**
A System Code acts as the strict identifier, such as MCQ_SINGLE or LONG_ANSWER. This code is often linked directly to the software's code to trigger specific visual layouts. A Display Name provides the human-readable name for teachers, like 'Multiple Choice (Single Answer)' or 'Descriptive Essay'.

**Core Behavioral Settings**
A Requires Options Toggle dictates that if enabled, the system will forcibly display option input fields when creating the question. If disabled, it provides a text area or file upload zone instead. An Auto-Gradable Toggle dictates that if enabled, the system's algorithm can automatically check the student's submitted answer against the stored correct answer and award marks instantly. If disabled, the question is flagged and routed to a teacher's pending evaluations dashboard for manual marking.

**Control and Governance**
A System Lock Toggle acts as a safeguard. If enabled, this indicates a core architectural type required by the software. It absolutely cannot be edited, deactivated, or deleted by the school admin, preventing them from breaking the Question Bank interface.

---

## Business Rules and Conditions

**Visual Rendering Dependency**
The System Code and the Requires Options toggle dictate the visual layout. If a teacher selects a Multiple Choice type, the interface reads the toggle and displays checkbox inputs. If they select a Long Answer type, the interface provides a rich-text editor. 

**Auto-Grading Strict Enforcement**
If a Question Type is marked as Auto-Gradable, the system must enforce that the teacher provides a definitive correct answer when creating a question of this type. The system will block saving an auto-gradable question without an answer key. Conversely, if it is not Auto-Gradable, the correct answer field becomes an optional evaluation rubric intended only as a reference for the evaluating teacher.

**System Data Integrity**
Records that are locked by the System Lock toggle must trigger an immediate error if a school administrator attempts to alter their core settings or delete them. Only the software provider can alter these core types.

---

## Workflow Steps

**Adding a New Question Format**
The Admin navigates to Question Types to support a new language curriculum. They click Add Question Type and set the Name to "Audio Transcription". They disable the Requires Options toggle since students will type what they hear into a blank box. They disable the Auto-Gradable toggle because a teacher needs to listen to the audio and read the text to grade nuances properly. They leave the System Lock disabled since this is a custom school addition. They submit the form, and teachers can now select "Audio Transcription" when adding questions to the bank.

---

## Example Scenario

During a sudden school closure, the administration decides to conduct online subjective exams. The Admin verifies that the Long Answer question type exists. 

Because Long Answer is configured with Requires Options disabled and Auto-Gradable disabled, when students log into the exam portal, they are presented with a blank text box to type their essays instead of radio buttons. Furthermore, when the 2-hour exam concludes, the students do not get an instant result. Instead, the system automatically batches these specific questions and routes them into the English teacher's Pending Manual Evaluations queue. The results are only published after the teacher manually inputs the marks.

---

## Related Screens

- **Question Type Specificity** — Links these broad Question Types to specific cognitive goals
- **Question Bank Module** — This master configuration populates the primary dropdown when teachers create new questions
