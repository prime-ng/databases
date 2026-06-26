# Transfer Certificates — Business Requirements

## What This Screen Does

The Transfer Certificates (TC) screen manages the issuance of official school leaving certificates. A Transfer Certificate is a legal document that records a student's departure from the school — including dates attended, class left, reason for leaving, and conduct.

The screen shows a TC list (within the Promotions & Alumni tab group) with status, student details, issue date, and action buttons. Each TC has a show/detail page and a PDF generation action. TCs require fee clearance before issuance.

---

## When This Screen Is Used

- Student withdraws from school: Admin issues a TC as part of the exit process
- Alumni requests a duplicate TC: Admin re-issues a previously generated TC
- Student transfers to another school: TC is required as part of the transfer process
- Admin needs to verify TC details or view previously issued TCs

---

## Key Fields at a Glance

**Student**
The student for whom the TC is being issued.

**Issue Date**
The date the TC was generated.

**Last Class Attended**
The class and section the student was in when they left.

**Session Attended**
The academic sessions the student was enrolled in.

**Reason for Leaving**
The stated reason (e.g., "Family relocation", "Transfer to another school", "Graduation").

**Conduct / Remarks**
A note on the student's conduct and any additional remarks.

**Fee Clearance Status**
Whether all dues have been cleared. TC cannot be issued until fees are cleared.

**Status**
Draft — being prepared, not yet issued.
Issued — TC has been finalized and PDF generated.
Cancelled — TC was voided.

---

## Business Rules and Conditions

**Fee Clearance Required**
The system checks the StudentFee module to verify that all fees are cleared. If dues exist, the TC cannot be issued.

**Unique TC Number**
Each TC has a unique auto-generated number (e.g., "TC-2027-0001").

**PDF Generation**
The TC PDF is generated via DomPDF with a verification QR code. The QR code links to a verification page where any school can verify the TC's authenticity.

**Duplicate Prevention**
A student can only have one active TC. If a new TC is needed, the previous one must be cancelled.

**Soft Delete**
TCs can be soft-deleted.

---

## Workflow Steps

**Creating a TC for a Withdrawn Student**
After a withdrawal is processed, admin can navigate to the TC tab and create a TC for the withdrawn student.

**Creating a TC Manually**
Admin clicks "Add TC", searches for the student, enters the last class, reason, and conduct remarks. The system auto-fills the session dates.

**Checking Fee Clearance**
Admin clicks "Check Fees" before issuing. If fees are not cleared, the system shows dues and blocks issuance.

**Issuing a TC**
Admin clicks "Issue TC". The TC number is generated, status becomes Issued, and the PDF is ready for download.

**Downloading TC PDF**
Admin clicks "Download PDF" on the TC show page. The PDF downloads with all TC details and a verification QR code.

**Cancelling a TC**
Admin clicks "Cancel TC" if it was issued in error. The status changes to Cancelled.

---

## Example Scenario

A Class X student is relocating to another city. The school processes a withdrawal. Admin creates a TC:
- Student: Aadil Saurabh Baral
- Last Class: X - A
- Session: 2026-27
- Reason: "Family relocation to Bangalore"
- Conduct: "Good"

Admin checks fee clearance → all cleared. Issues the TC. The PDF downloads with TC number "TC-2027-0042" and a QR code. The parent receives a copy, and the new school can verify the TC by scanning the QR code.

---

## Related Screens

- **Withdrawals** — TC is typically created after a withdrawal is processed
- **Enrollment** — TC documents the student's departure (complement to enrollment)
- **Alumni** — Graduating students may request TCs
- **StudentFee** — Fee clearance check is a cross-module dependency
