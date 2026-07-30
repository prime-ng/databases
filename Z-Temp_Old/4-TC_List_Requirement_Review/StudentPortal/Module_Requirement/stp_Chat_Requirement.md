# STP — Chat Requirement Document

---

## 1. Module / Sub-Module
- **Module:** StudentPortal (STP)
- **Sub-Module:** Communication — Chat
- **Table Prefix:** stp_ (no STP-owned tables; chat data via AJAX)

---

## 2. FRD Reference
| ID | Description | Priority |
|----|------------|----------|
| — | Not in STP FRD REQ list (supplementary communication feature) | P2 |

---

## 3. Feature Description
A chat interface page for student communication. The page shell renders via the server, but all conversation data is loaded asynchronously via AJAX by the front-end chat widget.

---

## 4. User Stories / Use Cases
- **As a** student, **I want to** access a chat interface **so that** I can communicate with teachers or support staff.
- **As a** student, **I want to** see my conversations loaded dynamically **so that** I always have the latest messages.

---

## 5. Business Rules (BR)
| BR ID | Rule | Type | Enforcement |
|-------|------|------|-------------|
| BR-STP-001 | Data must belong to authenticated user | Permission | Controller uses `auth()->user()` for activity log only |

---

## 6. Validations & Edge Cases
| Scenario | Input / Action | Expected Behaviour |
|----------|---------------|-------------------|
| Chat page loads successfully | Navigate to /chat | Page shell renders with chat widget container; AJAX loads conversations |
| AJAX fails | Network error | Chat widget shows error state (handled by front-end) |
| No conversations | User has no chats | Empty state within chat widget (handled by front-end) |

---

## 7. Route Details
| Method | Route | Name | Controller Method |
|--------|-------|------|-------------------|
| GET | /chat | student-portal.chat | StudentChatController@index |

---

## 8. Data / Entity Reference

### A. Controller
- **Class:** `Modules\StudentPortal\Http\Controllers\StudentChatController`
- **Method:** `index()`
- **Behaviour:** Logs activity, returns `view('studentportal::chat.index')`
- **No data loaded server-side** — all conversation data is loaded via AJAX from front-end chat widget

### B. Chat Widget
- **Type:** Front-end component (likely JavaScript/Vue/livewire widget)
- **Data source:** Communicated via API endpoints (not defined in StudentPortal web routes — likely external or in a dedicated chat module)

---

## 9. Dependencies (Cross-Module)
| Module | Dependency | Type |
|--------|-----------|------|
| Chat (external widget) | AJAX API endpoints for conversation data | Read/Write (via front-end) |

---

## 10. Integration / API
- Server renders the page shell only
- All conversation CRUD operations handled client-side via AJAX by the chat widget
- ActivityLog entry created on page view

---

## 11. Security & Permissions
| Check | Implementation |
|-------|---------------|
| Authentication | Standard `auth` + `verified` middleware |
| Page access | Controller does not check any specific permission beyond auth |
| Data security | Dependent on the front-end chat widget's API authentication |

---

## 12. Assumptions & Constraints
- Chat widget is a separate front-end component with its own API endpoints
- StudentPortal web controllers do not own or serve any chat data
- Chat widget loading errors are handled client-side
- Activity logging is the only server-side operation performed

---

## 13. Known Issues / Gaps
| ID | Issue | Severity | Status |
|----|-------|----------|--------|
| GAP-STP-CHAT-01 | Chat widget source/framework not documented in controllers | Low | Open |
| GAP-STP-CHAT-02 | No FRD requirement assigned to this feature | Low | Open |
| GAP-STP-CHAT-03 | No server-side validation or rate limiting on chat actions | Medium | Open |

---

## 14. Future Enhancements
| ID | Suggestion | Priority |
|----|-----------|----------|
| ENH-STP-CHAT-01 | Add chat history persistence and search | P3 |
| ENH-STP-CHAT-02 | Add read receipts and typing indicators | P3 |
| ENH-STP-CHAT-03 | Integrate with notification system for new messages | P2 |

---

## 15. V1/V2 Status
- **V1:** —
- **V2:** —
- **Status:** ✅ Implemented (page shell)
- **CR:** ◌

---

## 16. Revision History
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 23-07-2026 | OpenCode | Initial requirement document |
