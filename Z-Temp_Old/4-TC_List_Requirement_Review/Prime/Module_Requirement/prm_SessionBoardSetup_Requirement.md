# Prime — Session & Board Setup (Combined Tab)

**Feature:** Session & Board Setup | **REQ-ID:** REQ-PRM-009 | **Priority:** P0 (MUST)

---

## 1. Description

The Session & Board Setup feature provides a combined tabbed interface for managing global reference data that is consumed by all school modules. It consolidates **Academic Sessions** and **Education Boards** into a single management view with separate tabs. Platform staff can create, view, edit, and manage academic sessions (with current-session flags) and education boards (CBSE, ICSE, State boards, etc.). Both entity types support search, status filtering, and separate pagination with URL fragments for tab-based navigation.

**Key Capabilities:**
- Combined tabbed interface: Academic Sessions tab and Board tab
- Academic session CRUD: name, short_name, start_date, end_date, is_current flag
- Board CRUD: name, short_name, is_active flag
- Search by name/short_name for both entity types
- Status filter (is_active) for both entity types
- Separate pagination per tab with query string preservation and URL fragments

---

## 2. Controller & Model

| Artifact | Path | Lines | Status |
|----------|------|:-----:|--------|
| Controller | `Modules/Prime/app/Http/Controllers/SessionBoardSetupController.php` | 111 | PARTIAL |
| Model (AcademicSession) | `Modules\Prime\Models\AcademicSession` | 103 | EXISTS |
| Model (Board) | `Modules\GlobalMaster\Models\Board` | 37 | EXISTS |
| View (index) | `prime::session-board-setup.index` | — | EXISTS |

**Note:** This controller implements only the `index()` method fully. All resource methods (`create`, `store`, `show`, `edit`, `update`, `destroy`) are stubs with only Gate checks — actual CRUD operations for academic sessions are handled by `AcademicSessionController` and for boards by `BoardController`.

---

## 3. Routes

| Method | URI | Action | Permission | Status |
|--------|-----|--------|------------|--------|
| GET | `/prime/session-board-setup` | `index` | `prime.session-board-setup.viewAny` | ✅ Gate check present |
| GET | `/prime/session-board-setup/create` | `create` | `prime.session-board-setup.create` | ✅ Gate check present (stub) |
| POST | `/prime/session-board-setup` | `store` | `prime.session-board-setup.create` | ✅ Gate check present (stub) |
| GET | `/prime/session-board-setup/{session_board_setup}` | `show` | `prime.session-board-setup.view` | ✅ Gate check present (stub) |
| GET | `/prime/session-board-setup/{session_board_setup}/edit` | `edit` | `prime.session-board-setup.update` | ✅ Gate check present (stub) |
| PUT | `/prime/session-board-setup/{session_board_setup}` | `update` | `prime.session-board-setup.update` | ✅ Gate check present (stub) |
| DELETE | `/prime/session-board-setup/{session_board_setup}` | `destroy` | `prime.session-board-setup.delete` | ✅ Gate check present (stub) |

---

## 4. Data Model

### 4.1 Academic Session (`glb_academic_sessions` — global_master database)

| Column | Type | Required | Default | Notes |
|--------|------|:--------:|:-------:|-------|
| `id` | INT UNSIGNED AUTO_INCREMENT | ✅ | — | Primary key |
| `short_name` | VARCHAR(10) | ✅ | — | UNIQUE; e.g. "2025-26" |
| `name` | VARCHAR(50) | ✅ | — | Full name; e.g. "April 2025 – March 2026" |
| `start_date` | DATE | ✅ | — | Session start |
| `end_date` | DATE | ✅ | — | Session end (must be >= start_date) |
| `is_current` | TINYINT(1) | ✅ | false (default) | Boolean; only one session can be current |
| `is_active` | TINYINT(1) | ✅ | 1 | — |
| `deleted_at` | TIMESTAMP | — | NULL | Soft delete |
| `created_at` | TIMESTAMP | — | — | — |
| `updated_at` | TIMESTAMP | — | — | — |

**Model Casts:** `start_date` (date), `end_date` (date), `is_current` (boolean)

### 4.2 Board (`glb_boards` — global_master database)

| Column | Type | Required | Default | Notes |
|--------|------|:--------:|:-------:|-------|
| `id` | INT UNSIGNED AUTO_INCREMENT | ✅ | — | Primary key |
| `short_name` | VARCHAR(10) | ✅ | — | UNIQUE; e.g. "CBSE", "ICSE" |
| `name` | VARCHAR(50) | ✅ | — | Full name; e.g. "Central Board of Secondary Education" |
| `is_active` | TINYINT(1) | ✅ | 1 | — |
| `deleted_at` | TIMESTAMP | — | NULL | Soft delete |
| `created_at` | TIMESTAMP | — | — | — |
| `updated_at` | TIMESTAMP | — | — | — |

**Model Casts:** `is_active` (boolean)
**Connection:** Both models use `global_master_mysql` connection.

---

## 5. Controller Implementation Details

### 5.1 `index(Request $request)`

- **Gate:** `Gate::authorize('prime.session-board-setup.viewAny')`
- **Academic Sessions Tab:**
  - Query: `AcademicSession::query()`
  - Search: Filters by `name`, `short_name` (LIKE %search%)
  - Status filter: `is_active` (0 or 1)
  - Order: `orderByDesc('start_date')`
  - Pagination: 10 per page, page name `academicsession_page`, fragment `#academicsession`
- **Boards Tab:**
  - Query: `Board::query()`
  - Search: Filters by `name`, `short_name` (LIKE %search%)
  - Status filter: `is_active` (0 or 1)
  - Order: `orderBy('name')`
  - Pagination: 4 per page, page name `academicboard_page`, fragment `#academicboard`
- **View:** `prime::session-board-setup.index` with `compact('academicSessions', 'boards')`

### 5.2 Stub Methods

| Method | Action |
|--------|--------|
| `create()` | Gate check only; returns `view('prime::create')` |
| `store($request)` | Gate check only; no-op body |
| `show($id)` | Gate check only; returns `view('prime::show')` |
| `edit($id)` | Gate check only; returns `view('prime::edit')` |
| `update($request, $id)` | Gate check only; no-op body |
| `destroy($id)` | Gate check only; no-op body |

---

## 6. Business Rules

| BR-ID | Rule | Verification |
|-------|------|:-----------:|
| BR-PRM-003 | Active academic session must exist before plan assignment | ✅ Session entity has `is_current` flag |
| BR-PRM-021 | Only one academic session may be current at a time | ✅ Logic exists in AcademicSessionController@toggleStatus and @store/@update |
| BR-PRM-023 | All state-changing operations must produce activity log entry | ✅ Logged via individual controllers |

---

## 7. Security Rules

| Rule | Implementation |
|------|---------------|
| Gate check on `viewAny` | ✅ `index()` |
| Gate check on `create` | ✅ `create()`, `store()` (stubs) |
| Gate check on `view` | ✅ `show()` (stub) |
| Gate check on `update` | ✅ `edit()`, `update()` (stubs) |
| Gate check on `delete` | ✅ `destroy()` (stub) |

---

## 8. Gaps & Known Issues

| # | Issue | Impact | Severity | Status |
|---|-------|--------|:--------:|:------:|
| 1 | All CRUD resource methods except `index()` are stubs — actual CRUD is in AcademicSessionController and BoardController | Architecture (by design) | — | ⬜ |
| 2 | Board pagination set to only 4 per page — may be too few for production | UX | P3 — Low | ⬜ |
| 3 | No feature tests exist for SessionBoardSetupController | Testing gap | P2 — Medium | ⬜ |

---

## 9. FRD References

| Reference | Source | Summary |
|-----------|--------|---------|
| REQ-PRM-009 | FRD §1.3 | Global Reference Data Management — boards, sessions, dropdowns, menus |
| BR-PRM-003 | FRD §1.4 | Active session required for plan assignment |
| BR-PRM-021 | FRD §1.4 | Exactly one current academic session |
| US-PRM-009 | FRD §8.1 | User story for reference data management |

---

## 10. Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| V1 | — | — | — |
| V2 | — | — | — |
