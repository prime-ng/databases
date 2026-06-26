# Enquiry Pipeline — Business Requirements

## What This Screen Does

The Enquiry Pipeline page is the CRM (Customer Relationship Management) hub for the admission module. It combines two core functions in a single tabbed interface:

1. **Enquiries Tab** — Raw lead capture. Front desk staff or counselors log inbound enquiries from parents (walk-in, phone, website, referral). Each enquiry records the prospective student's name, class sought, contact details, lead source, and status (New → Contacted → Callback → Interested → Converted → Duplicate → Not_Interested).

2. **Applications Tab** — The formal application pipeline. Each application goes through a Finite State Machine (FSM): Draft → Submitted → Under_Review → Verified → Shortlisted → Selected → Rejected. Applications are created from scratch or converted from enquiries.

---

## When This Screen Is Used

- Daily: Front desk logs new walk-in or phone enquiries
- Daily: Counselors update enquiry status after follow-ups
- Application window: Parents submit applications (online or manual)
- Review stage: Admin verifies documents and shortlists applicants
- Pre-test: Admin selects applicants for entrance tests

---

## Key Enquiry Fields at a Glance

**Student Name**
The prospective student's full name.

**Class Sought**
The class the parent is enquiring about.

**Parent / Guardian Name**
The parent or guardian's name.

**Contact Mobile & Email**
Primary contact details.

**Lead Source**
How the enquiry came in: Walk-in, Phone, Website, Referral, Social Media, Campaign, Other.

**Status**
New → Contacted → Callback → Interested → Converted → Duplicate → Not_Interested.

**Assigned Counselor**
The staff member responsible for follow-up.

**Enquiry No**
Auto-generated unique identifier (e.g., "ENQ-2027-0001").

---

## Key Application Fields at a Glance

**Full Name**
The applicant's full legal name.

**Application No**
Auto-generated unique identifier (e.g., "APP-2027-0001").

**Class Applied**
The class the student is applying for.

**Cycle**
The admission cycle this application belongs to.

**Status (FSM)**
Draft → Submitted → Under_Review → Verified → Shortlisted → Selected → Rejected.

**Quota Type**
The quota category the applicant applied under.

**Counselor**
The staff member handling this application.

**Documents Status**
Percentage of required documents uploaded and verified.

---

## Business Rules and Conditions

**Duplicate Detection**
When creating an enquiry, the system checks for existing enquiries with the same mobile number or email. If found, the enquiry is flagged as potential duplicate.

**Enquiry → Application Conversion**
A Converted enquiry can be one-click converted into a Draft application, carrying forward the student name, class, and contact details.

**Application FSM Rules**
- Draft → Submitted: Applicant or admin submits the application.
- Submitted → Under_Review: Admin begins the document verification process.
- Under_Review → Verified: All documents verified, applicant becomes eligible.
- Verified → Shortlisted: Admin marks as shortlisted for testing/interview.
- Shortlisted → Selected: After merit list, applicant is selected.
- Any status → Rejected: Application can be rejected at any stage with a reason.

**Document Verification**
The application show page displays a document checklist with upload status (Pending/Uploaded/Verified/Rejected) for each required document.

**Soft Delete**
Both enquiries and applications can be soft-deleted.

---

## Workflow Steps

**Logging an Enquiry**
Admin clicks "Add Enquiry" (or navigates to Enquiries tab in the pipeline page), enters the student name, class, parent details, contact, source, and submits. The enquiry is assigned an auto-generated number.

**Following Up on an Enquiry**
On the enquiry show page, admin can view the follow-up timeline and add new follow-ups (notes, next follow-up date). Each follow-up is timestamped and linked to the counselor.

**Converting an Enquiry to Application**
Admin clicks "Convert to Application" on an enquiry with status "Interested" or "Converted". The system creates a Draft application with pre-filled details.

**Creating an Application**
Admin clicks "Add Application" (or navigate to Applications tab), fills in the full application form, selects the class, cycle, and quota, and submits as Draft.

**Advancing Application Status**
Admin uses the FSM action buttons (Submit, Verify, Shortlist, Select, Reject) on the application show page. Each action moves the application through the pipeline.

**Viewing Application Stages**
Admin clicks "View Stages" to see the application's full status history with timestamps.

---

## Example Scenario

A parent walks into the school and enquires about Class I admission. The front desk logs an enquiry:
- Student: Aarav Patel
- Class: I
- Parent: Mr. Rajesh Patel
- Mobile: 9876543210
- Source: Walk-in
- Status: New

The counselor calls the parent the next day and updates status to Contacted. The parent expresses interest → status becomes Interested. The counselor converts the enquiry to an application. The parent submits the required documents online → status becomes Submitted. Admin verifies documents → Under_Review → Verified. After review, admin Shortlists → Shortlisted. After entrance test and merit list → Selected.

---

## Related Screens

- **Admission Cycles** — All enquiries and applications are scoped to a cycle
- **Entrance Tests** — Shortlisted applicants are candidates for entrance tests
- **Merit Lists** — Selected applicants appear in merit lists
- **Allotments** — Selected applicants proceed to seat allotment
- **Dashboard** — Enquiry and application counts feed into funnel KPIs
- **Document Checklist** — Required documents are defined per cycle/class
