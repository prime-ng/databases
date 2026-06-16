# Student Fee Management (SFM)

## SCREEN 1 — Fee Head Master

Screen Purpose
 - Define and manage all types of fee heads used in the school.

User Roles
 - Admin
 - Accounts Head

Layout Structure
Section A — Fee Head List (Grid)
| Column	            |    Type	            |    Notes
|-----------------------|-----------------------|-----------------------|
| Fee Head Code	        |    Text	            |    Unique
| Fee Head Name	        |    Text	            |    Display name
| Recurring	            |    Toggle	            |    Yes / No
| Taxable	            |    Toggle	            |    GST
| Refundable	        |    Toggle	            |    Yes / No
| Status	            |    Badge	            |    Active / Inactive
| Actions	            |    Buttons	        |    Edit / Disable


Section B — Fee Head Form (Drawer / Modal)

Fields
  - Fee Head Code (Text, Required)
  - Fee Head Name (Text, Required)
  - Is Recurring? (Toggle)
  - Recurrence Type (Dropdown – shown if recurring)
  - Is Taxable? (Toggle)
  - Is Refundable? (Toggle)
  - Display Order (Number)
  - Active (Toggle)

Buttons
  - Save
  - Cancel


SCREEN 2 — Fee Structure Setup

Purpose
  - Define class-wise and category-wise fee structures per academic year.

User Roles
  - Admin
  - Finance Manager

Layout
Section A — Filters
  - Academic Year (Dropdown)
  - Class (Dropdown)
  - Category (Optional Dropdown)

Section B — Fee Structure Grid
| Column	            |    Type	            |    Notes
|-----------------------|-----------------------|-----------------------|
| Fee Head	            |    Text	            |    Display name
| Total Amount	        |    Currency	        |    Total fee
| Payment Cycle	        |    Badge	            |    One-time / Installment
| Locked	            |    Yes / No	        |    Locked
| Actions	            |    Buttons	        |    Edit / Lock

Section C — Fee Structure Form

Fields
  - Academic Year (Dropdown, Required)
  - Class (Dropdown, Required)
  - Category (Dropdown, Optional)
  - Fee Head (Dropdown, Required)
  - Total Amount (Currency, Required)
  - Payment Cycle (Dropdown)
  - Lock Structure (Checkbox)

Buttons
  - Save
  - Save & Add Installments


SCREEN 3 — Fee Installment Planner

Purpose
  - Break fee into installments with due dates.

User Roles
  - Accounts Head

Layout
Section A — Fee Structure Summary
  - Academic Year
  - Class
  - Fee Head
  - Total Amount

Section B — Installment Grid
| Column	            |    Type	            |    Notes
|-----------------------|-----------------------|-----------------------|
| Seq	                |    Number	            |    Sequence number
| Installment Name	    |    Text	            |    Display name
| Due Date	            |    Date	            |    Due date
| Amount	            |    Currency	        |    Amount
| Actions	            |    Buttons	        |    Edit
1	Q1	10-Apr	₹4500	Edit
2	Q2	10-Jul	₹4500	Edit
Section C — Installment Form

Fields

Installment Name (Text)

Due Date (Date Picker)

Amount (Currency)

Sequence No (Number)

Buttons

Add Installment

Save

SCREEN 4 — Fine Policy Configuration
Screen ID

SFM-04

Purpose

Define late fee policies.

User Roles

Admin

Principal

Layout
Section A — Policy List
Policy Name	Grace Days	Removal After	Status	Actions
Section B — Policy Form

Fields

Policy Name (Text, Required)

Grace Days (Number)

Removal After Days (Number)

Description (Textarea)

Active (Toggle)

SCREEN 5 — Fine Slab Rules
Screen ID

SFM-05

Purpose

Configure slab-based fine rules.

User Roles

Admin

Layout
Section A — Policy Selector

Fine Policy (Dropdown)

Section B — Slab Grid
From Day	To Day	Mode	%	₹/Day	Action
Section C — Slab Form

Fields

From Day (Number)

To Day (Number)

Fine Mode (Dropdown)

Percent Value (Shown conditionally)

Amount Per Day (Shown conditionally)

Action Code (Dropdown)

SCREEN 6 — Student Fee Assignment
Screen ID

SFM-06

Purpose

Assign fee structures to students.

User Roles

Admission Office

Accounts

Layout
Section A — Student Selector

Student Search (Autocomplete)

Class (Readonly)

Section B — Assigned Fee Grid
Fee Head	Amount	Concession	Effective From	Actions
Section C — Assignment Form

Fields

Fee Structure (Dropdown)

Concession Type (Dropdown)

Concession Value (Conditional)

Effective From (Date)

Effective To (Date)

SCREEN 7 — Fee Demand Generation
Screen ID

SFM-07

Purpose

Generate installment-wise fee demand.

User Roles

Accounts

System Scheduler

Layout
Section A — Filters

Academic Year

Class

Student (Optional)

Section B — Actions

Generate Demand

Preview Demand

SCREEN 8 — Fee Collection / Payment
Screen ID

SFM-08

Purpose

Collect student fee payments.

User Roles

Fee Clerk

Parent (Portal)

Layout
Section A — Student Summary

Student Name

Class

Total Due

Fine Due

Section B — Outstanding Grid
Installment	Due	Paid	Balance
Section C — Payment Form

Fields

Payment Mode (Dropdown)

Amount Paid (Currency)

Reference No (Conditional)

Payment Date (Date)

Buttons

Pay

Generate Receipt

SCREEN 9 — Fee Receipt Viewer
Screen ID

SFM-09

Purpose

View & print fee receipts.

User Roles

Accounts

Parent

Auditor

Layout
Section A — Receipt Search

Student

Date Range

Receipt No

Section B — Receipt Viewer

Receipt No

Date

Amount

Download PDF

Cancel Receipt (Role-based)

SCREEN 10 — Student Fee Status Monitor
Screen ID

SFM-10

Purpose

Monitor overdue / removed students.

User Roles

Principal

Admin

Layout
Section A — Filters

Class

Status

Overdue Days

Section B — Status Grid
Student	Status	Overdue Days	Outstanding	Actions
Ravi	REMOVED	63	₹12,000	Re-Admit
SCREEN 11 — Re-Admission & Fine Clearance
Screen ID

SFM-11

Purpose

Handle re-admission after removal.

User Roles

Admin

Accounts

Layout
Section A — Student Summary

Removal Reason

Outstanding Amount

Re-Admission Fine

Section B — Payment Form

Payment Mode

Amount

Reference No

Buttons

Collect & Reactivate

SCREEN 12 — Fee Analytics Dashboard
Screen ID

SFM-12

Purpose

Decision-making dashboard.

User Roles

Management

Principal

Layout
Widgets

Total Collection (KPI)

Outstanding Amount

Defaulter Count

Fine Collected

Charts

Monthly Collection Trend

Class-wise Outstanding

Fine Dependency Index