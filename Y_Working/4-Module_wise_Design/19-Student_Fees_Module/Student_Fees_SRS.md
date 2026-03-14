# Software Requirements Specification (SRS)
-------------------------------------------

For: Student Fee Management Module (School ERP)
Version 1.0
Document Control
Role	Description
Project:	School ERP System Enhancement
Module:	Student Fee Management
Prepared by:	Business Analyst GPT
Date:	2024-2025
Target Audience:	AI for DDL/Design, Development Team, QA Team, Project Stakeholders
1.0 Introduction
1.1 Purpose
The purpose of this document is to provide a detailed specification for the design and development of the Student Fee Management Module. This module aims to automate and streamline all financial transactions between the institution and students/parents, from fee structure setup to payment collection, receipt generation, and financial reporting . It is designed to reduce manual effort, minimize errors, and provide real-time financial visibility .

1.2 Scope
The module will handle the entire fee lifecycle:

Configuration: Defining fee heads, groups, structures, and fine rules.

Assignment: Applying fees to students based on class, category, and custom attributes.

Assessment: Calculating due amounts, applying concessions, and generating invoices.

Collection: Accepting payments via multiple modes and integrating with payment gateways .

Delinquency Management: Tracking late payments, calculating fines, and managing name removal/re-admission.

Reporting & Analytics: Providing financial summaries, outstanding reports, and predictive insights .

2.0 Functional Requirements
The module is grouped into the following key functional areas:

2.1 Fee Setup & Configuration (Masters)
This section is used by Administrators and Accounts Staff to define the building blocks of the fee structure.

2.1.1 Fee Head Management

Description: Define the core components of a fee.

Details: Users can create, edit, and deactivate fee heads.

Attributes:

Fee Head Name: (e.g., Tuition, Transport, Hostel, Library, Sports, Examination, Activity Fee, Caution Money).

Fee Head Code: A unique alphanumeric identifier.

Description: (Optional) Details about the fee head.

Tax Applicability: A flag to indicate if tax (e.g., GST) is applicable.

Tax %: (Conditional) The percentage of tax to be applied.

Account Head: Mapping to the institution"s Chart of Accounts for integration with accounting/ERP systems .

Refundable: (Yes/No) To distinguish between one-time payments (like Caution Money) and recurring fees.

Frequency: (One-time, Monthly, Quarterly, Yearly).

2.1.2 Fee Group Management

Description: Combine multiple fee heads into logical groups for easier assignment .

Details: Admins can create groups like "Academic Fees" (Tuition + Library + Exam) or "Transport Fees" (Transport + Fuel Surcharge).

Attributes:

Group Name

Description

Assigned Fee Heads: A list of fee heads belonging to this group, with the ability to mark each head as Optional or Mandatory for the student.

2.1.3 Class-Wise Fee Structure Definition

Description: Define the specific amounts for fee heads/groups for each academic class and session.

Details: The system must allow setting amounts based on student attributes .

Functionality:

Select Academic Year, Class, and Student Category (e.g., General, OBC, Board - CBSE/ICSE/State) .

Assign Fee Groups or individual Fee Heads to the class.

Enter the Amount for each fee head.

Define Installment Schedules (e.g., 25% by April 10th, 25% by July 10th, 25% by Sep 10th, 25% by Dec 10th). The system should allow defining due dates and the percentage/amount due per installment.

Conditional Logic: Provide an interface to define rules.

*Example: "IF number of siblings in school >= 2, THEN apply 10% discount on Tuition Fee for all."*

*Example: "IF Board == 'ICSE', THEN Library Fee = 1500, ELSE Library Fee = 1000."*

2.1.4 Fine Setup (Masters)

Description: Define rules for late payment penalties.

Details: Create multiple fine categories that can be attached to fee groups or specific installments.

Attributes:

Fine Name: (e.g., "Late Tuition Fine").

Applicable On: Link to a specific fee head or group.

Fine Calculation Method: Define complex, tiered rules.

From Day 1 to Day 10: 10% of due amount (capped at Rs. 25).

From Day 11 to Day 30: 20% of due amount (capped at Rs. 50).

From Day 31 to Day 60: 30% of due amount (capped at Rs. 100).

On Day 61: Action = "Mark for Name Removal".

Grace Period: Number of days after due date before fine is applied (e.g., 5 days).

Maximum Fine: Cap on the total fine amount.

2.2 Fee Assignment & Student Fee Details
This section is used by Administrators and Accounts Staff to apply the configured fees to students.

2.2.1 Mass Fee Assignment & Preview

Description: Automatically assign fees to an entire batch of students.

Details: After defining the fee structure, the admin selects the target batch (e.g., "All Class 10 Students"). The system calculates and shows a Preview of Fee Breakdown for a sample student before finalizing the assignment. This preview must show the breakup by head, concession calculations, and installment dates. Upon confirmation, the system auto-assigns the fee structure to all students in that batch .

2.2.2 Individual Fee Adjustment

Description: Override or adjust fees for a specific student.

Details: The accounts staff can search for a student and view their assigned fee details.

Functionality:

Validate student-class mapping.

Allow the student to select/deselect optional fee heads (e.g., opting out of hostel fees).

Apply prorated amounts for mid-session admissions (e.g., charging only 50% of the term fees if a student joins in the middle) .

2.2.3 Concession & Scholarship Management

Description: A structured workflow for applying discounts .

Details:

Define Concession Types: (Sibling Concession, Merit Scholarship, Staff Concession, Financial Aid).

Set Concession Value: Percentage or fixed amount.

Approval Workflow: The request for concession (e.g., raised by a parent or clerk) is sent for approval to the principal or designated authority.

Approval History: The system must maintain a complete log of who requested, who approved, and when.

2.3 Fee Collection & Payment Processing
This section is used by Accounts Staff (onsite) and Parents/Students (online).

2.3.1 Payment Gateway Integration

Description: Seamless integration with online payment providers .

Details: The system must integrate with popular gateways like Razorpay, Paytm, CCAvenue.

Functionality:

Parents can log in to their parent portal, view the due amount, and pay online.

The system must handle payment success/failure callbacks.

Auto-reconciliation: Online payments must be automatically matched to the correct student invoice and marked as "Paid" .

2.3.2 On-Site Payment Processing (Counter)

Description: Handling payments made in cash, cheque, or UPI at the school counter.

Functionality:

Staff can search for a student by name, class, or admission number.

The screen displays the student's outstanding fees and applicable fines (calculated automatically based on due dates).

Staff selects the payment mode (Cash / UPI / Cheque / DD / Bank Transfer).

For cheques/DDs, capture Cheque Number, Bank Name, and Date.

Enter the amount being paid.

The system generates a unique receipt number.

2.3.3 Receipt Generation

Description: Provide a formal receipt for every transaction.

Details: After payment, a receipt is generated instantly. It must include: Receipt Number, Student Details, Date, Amount paid (in words and figures), Fee Heads covered, Payment Mode, and Transaction ID (if online). It should be printable and downloadable as PDF.

2.3.4 Name Removal & Re-Admission Workflow

Description: Handling extreme delinquency cases as per the defined rules (e.g., 60+ days late).

Workflow:

Automated Flag: On day 61 of non-payment, the system automatically marks the student's status as "Fee-Defaulter - Name Removed" .
Notification: An alert is sent to the admin and parents.
Re-Admission Process:
Parent/Student approaches the admin.
Admin initiates the "Re-Admission" process in the system.
The system calculates the total due, including all pending fees + accrued fines + a pre-defined "Re-Admission Fine" .
Upon payment of this total amount, the system automatically:
Generates a receipt.
Re-activates the student's name in the class roll.
Updates the student's status from "Removed" to "Active".
2.4 Communication & Notifications
Automated triggers based on fee events.

2.4.1 Invoice & Reminder System

Description: Proactive communication to parents.

Details:

Invoice Generation: Generate and send fee invoices via email/SMS at the start of each term/installment.

Due Date Reminders: Automated reminders sent 7 days, 3 days, and 1 day before the due date.

Overdue Alerts: Send alerts on the day after the due date, informing of the applicable fine.

Payment Confirmation: Send SMS/email with the receipt link immediately upon successful payment .

2.4.2 Escalation Workflow

Description: Internal notifications for staff.

Details: If a payment is missed beyond a certain period (e.g., 30 days), the system sends an alert to the class teacher. If missed beyond 45 days, it escalates to the accounts head and principal.

2.5 Reports & Analytics
For use by Administrators, Accountants, and Principals to gain financial insights .

2.5.1 Operational Reports

Fee Collection Summary: Daily, weekly, monthly collection reports by cashier, by class, and by fee head.

Outstanding Report: A real-time list of all students with pending dues, filtered by class, age of debt, and amount.

Fee Concession Report: A report showing total concessions/scholarships given, categorized by type.

Installer-wise Collection Report: Track collection progress against each defined installment.

2.5.2 Analytical Reports

Default Risk Prediction: Using historical data, the system should flag students who show a pattern of late payments, predicting a potential default .

Trend Analysis: Identify patterns in fee collection, such as which months see the highest late payments, helping the administration plan reminders better.

2.6 Integration Touchpoints
The Fee Module does not operate in isolation. It must integrate with:

Student Information System (SIS): To fetch student demographics, class, category, and admission date. To push back defaulter status .

Transport Module: To automatically fetch and apply transport fees based on the student's route and stop assignment.

Hostel Module: To apply hostel rent and mess charges, including calculations for partial months or room changes .

Accounting/ERP System: To push summarized financial data (e.g., total collection per fee head) to the main chart of accounts .

Learning Management System (LMS)/Portal: To restrict access to online learning materials if the student is flagged as a defaulter.

3.0 Non-Functional Requirements
Security: Role-based access control (RBAC) is mandatory. Accountants should not see HR data. Parents should only see their own children's data . All financial transactions must be logged in an audit trail .

Performance: The system should be able to calculate dues and generate fee structures for a batch of 500 students in under 10 seconds.

Scalability: The database design should support up to 10,000 students and 100,000 transactions annually without performance degradation.

Usability: The fee counter interface should be optimized for speed, with keyboard shortcuts and minimal clicks for a transaction.
