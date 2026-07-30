# ParentPortal — Complaints (TC List)

## 1. Feature Overview

| Attribute | Details |
|-----------|---------|
| Feature | Complaints / Grievances |
| Module | ParentPortal (PPT) + Complaint Module |
| Priority | P1 |
| Type | Write (Form submission) |
| Test Strategy | Functional + Validation + AJAX + Security |

## 2. Test Environment

| Parameter | Value |
|-----------|-------|
| Base URL | `{tenant_url}/parent-portal/complaint` |
| Auth Required | Yes (Parent role) |
| Child Context | Active child must be selected |
| Database | Tenant database with cmp_complaints and cmp_complaint_categories tables |
| Precondition | Complaint module must be active for the tenant |

## 3. Test Case Matrix

### 3.1 UI / Screen Navigation

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-CMP-001 | Verify Complaint list page loads | 1. Login as Parent<br>2. Navigate to Complaints | Complaint index page renders with list (or empty state) | ⬜ | ◌ |
| TC-PPT-CMP-002 | Verify empty state when no complaints exist | 1. Login as Parent with no complaints<br>2. Navigate to Complaints | Empty state message shown; no errors | ⬜ | ◌ |
| TC-PPT-CMP-003 | Verify "New Complaint" button navigates to create form | 1. On complaint index<br>2. Click New Complaint | Navigated to complaint create form | ⬜ | ◌ |
| TC-PPT-CMP-004 | Verify create form loads with parent categories | 1. Navigate to create form<br>2. Examine category dropdown | Only parent categories (parent_id = null) shown | ⬜ | ◌ |
| TC-PPT-CMP-005 | Verify selecting a category loads subcategories via AJAX | 1. Select a parent category<br>2. Wait for AJAX | Subcategory dropdown populated with children of selected category | ⬜ | ◌ |
| TC-PPT-CMP-006 | Verify category metadata loaded via AJAX | 1. Select a category<br>2. Check console/network | getCategoryMeta endpoint called; severity/priority populated | ⬜ | ◌ |
| TC-PPT-CMP-007 | Verify complaint detail page renders | 1. Submit a complaint<br>2. Click to view detail | Shows ticket number, title, category, status, description, date | ⬜ | ◌ |
| TC-PPT-CMP-008 | Verify anonymous checkbox visible on create form | 1. Navigate to create form | Anonymous checkbox present | ⬜ | ◌ |

### 3.2 Create Complaint (Validation)

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-CMP-009 | Submit valid complaint with all fields | 1. Fill all fields<br>2. Submit | Complaint created; redirected to index with success + ticket number | ⬜ | ◌ |
| TC-PPT-CMP-010 | Submit with category_id empty | 1. Leave category blank<br>2. Submit | Validation error for category_id | ⬜ | ◌ |
| TC-PPT-CMP-011 | Submit with invalid category_id | 1. Enter non-existent category_id<br>2. Submit | Validation error: category not found | ⬜ | ◌ |
| TC-PPT-CMP-012 | Submit with title empty | 1. Leave title blank<br>2. Submit | Validation error for title | ⬜ | ◌ |
| TC-PPT-CMP-013 | Submit with title exceeding 200 characters | 1. Enter 201-char title<br>2. Submit | Validation error: title too long | ⬜ | ◌ |
| TC-PPT-CMP-014 | Submit with title at exactly 200 characters boundary | 1. Enter exactly 200 chars<br>2. Submit | Validation passes; complaint created | ⬜ | ◌ |
| TC-PPT-CMP-015 | Submit with valid subcategory | 1. Select subcategory<br>2. Submit | Complaint created with subcategory | ⬜ | ◌ |
| TC-PPT-CMP-016 | Submit with description null | 1. Leave description blank<br>2. Submit | Complaint created (description nullable) | ⬜ | ◌ |
| TC-PPT-CMP-017 | Submit with location_details exceeding 255 chars | 1. Enter 256-char location<br>2. Submit | Validation error: location_details too long | ⬜ | ◌ |
| TC-PPT-CMP-018 | Submit with invalid incident_date format | 1. Enter non-date value<br>2. Submit | Validation error: invalid date | ⬜ | ◌ |
| TC-PPT-CMP-019 | Submit with valid incident_date | 1. Enter valid date<br>2. Submit | Complaint created with incident_date | ⬜ | ◌ |
| TC-PPT-CMP-020 | Submit as anonymous | 1. Check anonymous box<br>2. Submit all valid fields | Complaint created; complainant_user_id = null; name/contact hidden | ⬜ | ◌ |
| TC-PPT-CMP-021 | Submit without anonymous | 1. Uncheck anonymous<br>2. Submit | Complaint created; complainant_user_id = auth user id | ⬜ | ◌ |

### 3.3 Ticket Number Generation

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-CMP-022 | Verify ticket number format | 1. Submit complaint<br>2. Check ticket_no in response | Format: CMP-YYYY-000001 | ⬜ | ◌ |
| TC-PPT-CMP-023 | Verify ticket number increments | 1. Submit two complaints<br>2. Compare | Second ticket has next sequence | ⬜ | ◌ |
| TC-PPT-CMP-024 | Verify ticket number uniqueness | 1. Create multiple complaints<br>2. Check for duplicates | All ticket numbers unique | ⬜ | ◌ |

### 3.4 AJAX Endpoints

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-CMP-025 | Get subcategories for category with children | 1. Call GET /complaint/ajax/subcategories/{categoryId}<br>2. Check response | JSON array of child categories with id and name | ⬜ | ◌ |
| TC-PPT-CMP-026 | Get subcategories for leaf category | 1. Call for category with no children<br>2. Check response | Empty array | ⬜ | ◌ |
| TC-PPT-CMP-027 | Get subcategories for invalid category ID | 1. Call with non-existent ID<br>2. Check response | 404 (Model binding) | ⬜ | ◌ |
| TC-PPT-CMP-028 | Get category meta for valid category | 1. Call GET /complaint/ajax/subcategory-meta/{categoryId}<br>2. Check response | JSON with severity_level_id and priority_score_id | ⬜ | ◌ |
| TC-PPT-CMP-029 | Get category meta — verify only active subcategories returned | 1. Create active + inactive subcategories<br>2. Call endpoint | Only active (is_active = 1) subcategories returned | ⬜ | ◌ |

### 3.5 View Complaints (List + Detail)

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-CMP-030 | Verify parent sees own complaints in list | 1. Submit complaint as Parent A<br>2. View complaint list as Parent A | Complaint visible in list | ⬜ | ◌ |
| TC-PPT-CMP-031 | Verify parent does NOT see other parents' complaints | 1. Submit complaint as Parent A<br>2. Login as Parent B<br>3. View complaint list | Parent A's complaint not visible | ⬜ | ◌ |
| TC-PPT-CMP-032 | Verify complaint detail shows all available info | 1. Click on complaint<br>2. Verify all fields rendered | ticket_no, title, description, category, subcategory, status, severity, priority, date shown | ⬜ | ◌ |
| TC-PPT-CMP-033 | Verify complaint detail shows status label resolved from sys_dropdown_table | 1. Submit complaint<br>2. View detail | Status label (e.g., "Open") resolved from dropdown | ⬜ | ◌ |
| TC-PPT-CMP-034 | Verify complaint detail shows category/subcategory names | 1. Create with category + subcategory<br>2. View detail | Category name and subcategory name displayed | ⬜ | ◌ |

### 3.6 Security Tests

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-CMP-035 | Access complaints page without auth | 1. Logout<br>2. Navigate to complaints index | Redirected to login | ⬜ | ◌ |
| TC-PPT-CMP-036 | POST without CSRF token | 1. Submit form with missing CSRF | 419 CSRF mismatch | ⬜ | ◌ |
| TC-PPT-CMP-037 | Access another parent's complaint by ID | 1. Get ID of Parent A's complaint<br>2. Access as Parent B | 404 (filtered by query scope) | ⬜ | ◌ |
| TC-PPT-CMP-038 | Verify target fields nulled on create (SEC-PPT-004) | 1. Submit complaint<br>2. Check DB | target_table_name, target_selected_id, target_name, target_code all NULL | ⬜ | ◌ |

### 3.7 Audit Logging

| TC ID | Test Case | Steps | Expected Result | Status | CR |
|-------|-----------|-------|-----------------|--------|----|
| TC-PPT-CMP-039 | Verify audit log on view complaint index | 1. Access complaint index<br>2. Check sys_activity_logs | "Viewed" event logged | ⬜ | ◌ |
| TC-PPT-CMP-040 | Verify audit log on create form view | 1. Access create form<br>2. Check logs | "Viewed" event for complaint form | ⬜ | ◌ |
| TC-PPT-CMP-041 | Verify audit log on complaint submission | 1. Submit valid complaint<br>2. Check logs | "Submitted" event with complaint_id and ticket_no | ⬜ | ◌ |
| TC-PPT-CMP-042 | Verify audit log on complaint detail view | 1. View complaint detail<br>2. Check logs | "Viewed" event with complaint_id | ⬜ | ◌ |
| TC-PPT-CMP-043 | Verify audit log on AJAX subcategory fetch | 1. Select category<br>2. Check logs | "Fetched complaint subcategories" event | ⬜ | ◌ |
| TC-PPT-CMP-044 | Verify audit log on AJAX category meta fetch | 1. Select category<br>2. Check logs | "Fetched complaint category metadata" event | ⬜ | ◌ |

## 4. API Contract (AJAX Responses)

### Get Subcategories — Success (200)
```json
{
    "subcategories": [
        { "id": 5, "name": "Bullying" },
        { "id": 6, "name": "Harassment" }
    ]
}
```

### Get Category Meta — Success (200)
```json
{
    "severity_level_id": 12,
    "priority_score_id": 8
}
```

## 5. Test Data Setup

| Entity | Required Records |
|--------|-----------------|
| ComplaintCategory | At least 3 parent categories, each with 2-3 child subcategories |
| Complaint | At least 2 complaints created by the test parent |
| sys_dropdown_table | Records for cmp_complaints.complainant_type_id (Parent, Anonymous), cmp_complaints.status_id (Open) |
| Student | At least 2 students linked to the test parent |

## 6. Database Assertions

| Assertion | Query / Check |
|-----------|--------------|
| Complaint created | `SELECT * FROM cmp_complaints WHERE ticket_no = ?` |
| Anonymous complaint | `complainant_user_id IS NULL`, `is_anonymous = 1` |
| Parent complaint | `complainant_user_id = {auth_user_id}`, `is_anonymous = 0` |
| Status = Open | `status_id` resolves to value 'Open' in sys_dropdown_table |
| Target fields null | `target_table_name IS NULL`, `target_selected_id IS NULL` |
| Ticket number unique | No duplicate ticket_no across all records |

## 7. Browser / Device Compatibility

| Platform | Support |
|----------|---------|
| Chrome (Desktop) | ✅ |
| Firefox (Desktop) | ✅ |
| Chrome (Android) | ✅ |
| Safari (iOS) | ✅ |
| PWA mode | ✅ |

## 8. Known Issues

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | No validation ensuring subcategory belongs to selected parent category | Medium | ⬜ |
| 2 | Broad query scope may leak complaints if target fields are ever populated | Medium | ⬜ |
| 3 | Target fields nulled intentionally — no direct student-complaint linkage | Medium | ⬜ |
| 4 | FRD does not document this feature | Low | ⬜ |
| 5 | No notification when complaint status changes | Low | ⬜ |

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/parent-portal/complaint` | `complaint.index` | `index` |
| GET | `/parent-portal/complaint/create` | `complaint.create` | `create` |
| POST | `/parent-portal/complaint` | `complaint.store` | `store` |
| GET | `/parent-portal/complaint/{complaint}` | `complaint.show` | `show` |
| GET | `/parent-portal/complaint/ajax/subcategories/{category}` | `complaint.subCategories` | `getCategories` |
| GET | `/parent-portal/complaint/ajax/subcategory-meta/{category}` | `complaint.categoryMeta` | `getCategoryMeta` |

## 10. Execution Status

| TC Count | Automated | Manual | Pass | Fail | Blocked | Not Run |
|----------|-----------|--------|------|------|---------|---------|
| 44 | 0 | 0 | 0 | 0 | 0 | 44 |
