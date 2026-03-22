# Student Fee Management

## 1. MASTER CONFIGURATION SCREENS

### 1.1 Fee Head Master Screen
Screen Name - Fee Head Master

Purpose / Usability
  - Define types of fees charged by the school
  - Forms the foundation of all fee calculations
  - Must be configured before any fee structure

Who Uses
  - School Admin
  - Accounts Head

Key UI Elements
  - Fee Head Code
  - Fee Head Name
  - Recurring? (Yes/No)
  - Recurrence Type
  - Taxable?
  - Refundable?
  - Display Order
  - Active Toggle

Tables - sfm_fee_heads (INSERT / UPDATE)

---

## 2. Fee Structure & Installments

### 2.1 Fee Structure Master Screen
Screen Name - Fee Structure Master

Purpose / Usability
  - Define class-wise / category-wise fees
  - Locks fee for an academic year
  - Prevents mid-session manipulation

Who Uses
  - Admin
  - Finance Manager

Key UI Inputs
  - Academic Year
  - Class
  - Category (optional)
  - Fee Head
  - Total Amount
  - Payment Cycle
  - Lock Structure (checkbox)

Tables - sfm_fee_structures (INSERT / UPDATE)

---

### 2.2 Fee Installment Configuration Screen

Screen Name - Fee Installment Planner

Purpose / Usability
  - Break fee into installments
  - Define due dates (used for fine calculation)
  - Auto-generate fee demands

Who Uses
  - Accounts Head

Key UI Inputs
  - Installment Name (Q1 / April / Term 1)
  - Due Date
  - Amount
  - Sequence Order

Tables - sfm_fee_installments (INSERT / UPDATE)

---

## 3. FINE & PENALTY ENGINE

### 3.1 Fine Policy Master Screen
Screen Name - Fine Policy Master

Purpose / Usability
  - Define school-level fine rules
  - Centralized policy applied system-wide

Who Uses
  - Admin
  - Principal (approval)

Key UI Inputs
  - Policy Name
  - Grace Days
  - Removal After Days
  - Description

Tables - sfm_fine_policies (INSERT / UPDATE)

### 3.2 Fine Slab Rule Screen
Screen Name - Fine Slab Rule

Purpose / Usability
  - Configure slab-based fines
  - Supports % OR fixed OR max-of-both logic

Who Uses
  - Admin
  - Accounts Head

Key UI Inputs
  - From Day
  - To Day
  - Fine Mode
  - % Value
  - Amount per Day
  - Action (Remove Student)

Tables - sfm_fine_slabs (INSERT / UPDATE)

## 4. STUDENT FEE ASSIGNMENT

### 4.1 Student Fee Mapping Screen
Screen Name - Student Fee Assignment

Purpose / Usability
  - Assign fees to students at:
    - Admission
    - Promotion
    - Re-admission
  - Apply concessions

Who Uses
  - Admission Office
  - Accounts

Key UI Inputs
  - Student
  - Fee Structure
  - Concession Type
  - Concession Value
  - Effective From / To

Tables - sfm_student_fee_map (INSERT / UPDATE)

---

## 5. FEE DEMAND & LEDGER (SYSTEM DRIVEN)

### 5.1 Fee Demand Generation Screen
Screen Name - Generate Fee Demand

Purpose / Usability
  - Generate installment-wise demands
  - Usually system-triggered

Who Uses
  - System (Scheduler)
  - Accounts (Manual Trigger)

Key UI Actions
  - Select Academic Year
  - Select Class / Student
  - Generate Demand

Tables - sfm_student_fee_ledger (INSERT (DEMAND))

---

## 6. FEE PAYMENT & COLLECTION

### 6.1 Fee Collection Screen
Screen Name - Fee Collection / Payment

Purpose / Usability
  - Collect fees (online / offline)
  - Auto-adjust dues
  - Trigger receipt generation

Who Uses
  - Fee Clerk
  - Parent (Online Portal)

Key UI Inputs
  - Student
  - Outstanding Amount
  - Payment Mode
  - Amount Paid
  - Reference No

Tables 
 - sfm_fee_payments (INSERT)
 - sfm_student_fee_ledger (INSERT (PAYMENT))

### 6.2 Fee Receipt Screen
Screen Name - Fee Receipt Viewer

Purpose / Usability
  - View / Print receipts
  - Audit & compliance

Who Uses
  - Accounts
  - Parent
  - Auditor

Tables - sfm_fee_receipts (INSERT / VIEW)

---

## 7. FINE CALCULATION & STATUS CHANGE

### 7.1 Fine Calculation Job (No UI)
Type
  - System Job (Nightly / Daily)

Purpose
  - Apply fine slabs
  - Update ledger
  - Trigger status change

Table 
  - sfm_student_fee_ledger (FINE)
  - sfm_student_fee_status_history
---

## 8. STUDENT REMOVAL & READMISSION

### 8.1 Student Fee Status Screen
Screen Name - Student Fee Status Monitor

Purpose / Usability
  - View overdue / removed students
  - Control re-admission

Who Uses
  - Principal
  - Admin

Tables 
  - sfm_student_fee_status_history
  - sfm_student_fee_snapshot

### 8.2 Re-Admission Fee Screen
Screen Name - Re-Admission & Fine Clearance

Purpose / Usability
  - Collect re-admission fine
  - Reactivate student

Tables 
  - sfm_fee_payments
  - sfm_student_fee_ledger
  - sfm_student_fee_status_history

---

## 9. REPORTS & ANALYTICS

### 9.1 Fee Dashboard Screen
Screen Name - Fee Analytics Dashboard

Purpose / Usability
  - Management decision-making
  - AI-powered insights

Tables Used (Read-Only)
  - sfm_student_fee_snapshot
  - sfm_student_fee_ledger

---

## END-TO-END PROCESS FLOW (TEXTUAL)

Fee Head Setup
   ↓
Fee Structure Setup
   ↓
Installment Planning
   ↓
Student Fee Assignment
   ↓
Fee Demand Generation
   ↓
Due Date Crossed
   ↓
Fine Calculation (Auto)
   ↓
Payment Received
   ↓
Ledger Updated
   ↓
Receipt Generated
   ↓
Snapshot Updated
   ↓
Reports & AI Analytics



