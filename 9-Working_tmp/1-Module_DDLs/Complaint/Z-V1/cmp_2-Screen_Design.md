# Complaint Module - Screen Design Document

## 1. Overview
**Objective:** To design a user-centric, responsive interface for the Complaint & Grievance Management Module that ensures ease of submission for parents/students while providing powerful tracking and resolution tools for the administration.

**Scope:**
- **Admin Portal (Web):** For Principal, Admin, Managers.
- **Staff Portal (Web/Mobile):** For Teachers, Transport Staff.
- **Parent/Student App (Mobile):** For complaint submission and tracking.

---

## 2. Data Context
Data flows from the frontend forms directly to `cmp_complaints` and associated tables.

- **Submission:** Frontend Form -> API `POST /complaints` -> `cmp_complaints`
- **Updates:** Action Log UI -> API `POST /complaints/{id}/actions` -> `cmp_complaint_actions`
- **Analytics:** `cmp_ai_insights` feeds the "Risk Score" badges on the UI.

---

## 3. Screen Layouts

### A. Web Application (Admin/Staff)
**Layout:** Sidebar Navigation + Top Header + Main Content Area.
- **Header:** Notification Bell (SLA Alerts), User Profile, Quick Add Button.
- **Sidebar:** Dashboard, My Tickets, Transport Complaints, Reports, Settings.
- **Content:**
    - **List View:** Datatable with filters (Status, Category, Severity).
    - **Detail View:** 3-Column Layout.
        - *Left:* Ticket Info (Meta data, Complainant).
        - *Middle:* Conversation/Action Timeline (Chat interface style).
        - *Right:* Actions Panel (Assign, Resolve, Escalate) + Attachments.

### B. Mobile App (Parent/Student)
**Layout:** Bottom Tab Navigation (Home, File Complaint, My Activity, Profile).
- **Home:** Widget showing "Active Complaints" status.
- **File Complaint:** Wizard-based form (Step 1: Category -> Step 2: Details -> Step 3: Attachments).
- **Detail View:** Card layout showing Status timeline and "Chat with Admin" feature.

---

## 4. Data Models (Field Level)

| Field Label | UI Component | DB Column | Validation |
| :--- | :--- | :--- | :--- |
| **Category** | Dropdown (Icon grid on mobile) | `category` | Required |
| **Severity** | Toggle Button / Badge | `severity_level` | Required (Default: Med) |
| **Transport?** | Checkbox | `is_transport_related` | Boolean |
| **Route No** | Searchable Dropdown | `route_id` | Required if Transport=Yes |
| **Title** | Text Input (Single line) | `title` | Max 200 chars |
| **Description** | Rich Text Editor / Textarea | `description` | Required |
| **Attachments** | File Uploader (Drag & Drop) | `cmp_attachments` | Max 5MB, img/pdf/vid |
| **Anonymous** | Toggle Switch | `is_anonymous` | Boolean |

---

## 5. User Workflows

### Workflow 1: Filing a Safety Complaint (Parent)
1. **Login** to Mobile App.
2. Tap **"Report Incident"**.
3. Select Category: **"Transport/Safety"**.
4. Form auto-expands Transport fields (Vehicle/Route). Parent selects "Bus 12".
5. Enters Description: "Driver was speeding."
6. Uploads Photo/Video (Optional).
7. Submits.
8. **System:** Auto-creates ticket, assigns to Transport Manager, sends Notification.

### Workflow 2: Resolving a Complaint (Admin)
1. Admin gets Email/Push Alert.
2. Clicks link to open **Ticket Detail View**.
3. Reviews Description and AI Risk Score.
4. Posts a **"Private Note"** asking for Driver Log.
5. Changes Status to **"In-Progress"**.
6. Actions -> **"Resolve"** -> Selects "Driver Warned".
7. System notifies Parent.

---

## 6. Visual Design Guidelines

- **Color Palette:**
    - Primary: `#2563EB` (Royal Blue) - Buttons, Links.
    - Danger/Critical: `#DC2626` (Red) - High Severity, SLA Breach.
    - Success: `#10B981` (Emerald) - Resolved, On Track.
    - Warning: `#F59E0B` (Amber) - Medium Severity, Approaching SLA.
    - Background: `#F3F4F6` (Light Gray) - App Background.

- **Typography:**
    - Font Family: 'Inter' or 'Roboto'.
    - Headings: Bold, Dark Slate (`#1F2937`).
    - Body: Regular, Gray (`#4B5563`).

- **Components:**
    - **Cards:** White background, slight shadow (`box-shadow: 0 1px 3px rgba(0,0,0,0.1)`), rounded corners (`8px`).
    - **Badges:** Pill-shaped, colored background with darker text.

---

## 7. Accessibility (WCAG 2.1)

- **Contrast:** Ensure text contrast ratio of at least 4.5:1.
- **Keyboard Nav:** All forms and buttons navigable via Tab key.
- **Screen Readers:** ARIA labels on all icons (e.g., specific specific `aria-label="Upload Attachment"` instead of just icon).
- **Focus States:** Clearly visible outlines on focused inputs.
- **Error Handling:** Validation errors announced immediately to screen readers.

---

## 8. Testing Checklists

### Unit Testing
- [ ] Ticket creation saves to DB.
- [ ] SLA calculator returns correct hours based on Config.
- [ ] AI Sentiment service returns valid score.

### Integration Testing
- [ ] notification triggers email/push.
- [ ] File upload stores to AWS S3/Local and links to DB.
- [ ] Transport Route dropdown populates from `tpt_route` table.

### UAT (User Acceptance Testing)
- [ ] Parent can file complaint in < 2 minutes.
- [ ] Admin receives notification within 1 minute.
- [ ] Mobile view renders correctly on iPhone/Android.

---

## 9. Future Enhancements
- **Chatbot Integration:** AI chatbot to answer "What is the status of my ticket?"
- **Voice-to-Text:** Allow parents to record audio complaints that are auto-transcribed.
- **Public Grievance Portal:** For non-parents (neighbors/public) to report school bus driving issues.

---

## 10. Technical Constraints
- **Browser:** Support Chrome, Firefox, Safari, Edge (Last 2 versions).
- **Mobile:** iOS 14+, Android 8+.
- **Network:** Must handle offline submission (queue locally and sync when online).
- **Scalability:** Horizontal scaling for Attachment storage (separate File Server/CDN).
