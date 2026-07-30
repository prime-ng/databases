# STP — Chat TC List

---

## 1. Module / Sub-Module
- **Module:** StudentPortal (STP)
- **Sub-Module:** Communication — Chat

---

## 2. FRD / BR Reference
- Not in STP FRD REQ list (supplementary feature)

---

## 3. Test Scenarios

| TC ID | Test Case | Preconditions | Test Steps | Expected Result | Status |
|-------|-----------|--------------|------------|----------------|--------|
| TC-STP-CHAT-001 | Verify chat page loads successfully | Authenticated student | 1) Login as student 2) Navigate to /chat | Page shell renders with chat container/wrapper; no server errors | ⬜ |
| TC-STP-CHAT-002 | Verify chat widget loads conversations via AJAX | Chat widget API is functional | 1) Login as student 2) Navigate to /chat 3) Observe network requests | AJAX requests fired to load conversations; data rendered in widget | ⬜ |
| TC-STP-CHAT-003 | Verify page is accessible to authenticated users | Authenticated student | 1) Login 2) Navigate to /chat | 200 OK response | ⬜ |
| TC-STP-CHAT-004 | Verify unauthenticated access is blocked | Not logged in | 1) Attempt to navigate to /chat without auth | Redirected to login page | ⬜ |
| TC-STP-CHAT-005 | Verify activity log entry created | Authenticated student | 1) Login 2) Navigate to /chat 3) Check activity log | "Student viewed the chat page" entry logged | ⬜ |
| TC-STP-CHAT-006 | Verify page renders without error when student profile incomplete | User has no student relation | 1) Login as user without student record 2) Navigate to /chat | 200 OK; activity log entry shows null student_id (graceful handling) | ⬜ |
| TC-STP-CHAT-007 | Verify chat widget error state on AJAX failure | Chat API endpoint down | 1) Login 2) Block chat API in dev tools 3) Navigate to /chat | Chat widget shows error/retry message; page shell still renders | ⬜ |

---

## 4. Test Data Requirements
- Authenticated student user
- Chat widget API functional with some test conversations
- User without student relation (edge case)

---

## 5. Test Environment
- **Browser:** Chrome / Firefox / Edge (latest)
- **Auth:** Authenticated student user
- **DB:** Tenant database (minimal — chat data via API)

---

## 6. Automation Scope
| TC ID | Automatable? | Notes |
|-------|-------------|-------|
| TC-STP-CHAT-001–006 | Yes | Pest HTTP tests for page load, auth, activity log |
| TC-STP-CHAT-007 | Partial | AJAX error state testing requires browser automation |

---

## 7. Pass / Fail Criteria
- **Pass:** All TC IDs pass; page loads; AJAX fired; auth enforced
- **Fail:** Server error; unauthenticated access; no AJAX request fired

---

## 8. Known Issues
| Issue | Description | Severity |
|-------|-------------|----------|
| GAP-STP-CHAT-01 | Chat widget source/framework undocumented | Low |
| GAP-STP-CHAT-02 | No FRD requirement assigned | Low |

---

## 9. Route Reference
| Method | URI | Name |
|--------|-----|------|
| GET | /chat | student-portal.chat |

---

## 10. Execution Status
| Total TCs | Passed | Failed | Blocked | Not Run |
|-----------|--------|--------|---------|---------|
| 7 | — | — | — | 7 |
