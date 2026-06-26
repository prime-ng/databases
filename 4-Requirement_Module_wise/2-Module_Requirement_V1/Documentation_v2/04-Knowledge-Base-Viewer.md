# Business Requirements Document (BRD)
## Module: Documentation
### Sub-Module: Public / Client Facing
### Screen: Knowledge Base Viewer (`main-doc`)

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Knowledge Base Viewer** is the frontend application where end-users actually read the documentation. It features a modern, 3-column layout (Sidebar, Content, Article List) and supports a Dark/Light mode toggle.

### 1.2 Why is this necessary? (Business Justification)
- **Self-Service Support:** A highly intuitive, easily navigable help center reduces support tickets drastically. The 3-column design prevents users from getting lost in deep folders.

---

## 2. Document Scope
- **In-Scope:** The 3-column interactive layout, category accordion logic, AJAX/Base64 content swapping, and theme toggle.
- **Out-of-Scope:** Admin editing.

---

## 3. User Personas
1. **End User (Client/Developer/Public):** Browses the documentation to find answers.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: 3-Column Interactive Layout
The UI is divided into 3 responsive columns:
1. **Column 1 (Left - Categories):** A sticky sidebar displaying the category tree. Categories with children have an accordion toggle (chevron). Clicking a category filters Column 3.
2. **Column 2 (Center - Content Viewer):** Displays the currently selected article. Shows the Title, Publish Date, Author, and the rendered HTML body. If no article is selected, it shows an "Empty State".
3. **Column 3 (Right - Article List):** Displays a list of clickable Article Cards (Title + Excerpt) belonging to the selected category.

### FR-02: Client-Side Content Swapping
- **System Behavior:** When a user clicks an Article Card in Column 3, JavaScript intercepts the click, reads the `data-article-content` attribute (which is Base64 encoded to preserve HTML), decodes it, and injects it into Column 2 without a page reload.

### FR-03: Dark/Light Mode Theme Toggle
- **System Behavior:** A floating button in the bottom corner allows the user to toggle the CSS theme of the documentation between Light Mode (Sun Icon) and Dark Mode (Moon Icon) for reading comfort.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Reading Without Reloads
**As a** User,
**I want to** click through different articles rapidly,
**So that** I don't have to wait for the whole page to refresh every time I switch topics.

**Acceptance Criteria:**
- **Given** I am looking at a list of articles in the right column, **When** I click an article card, **Then** JS decodes the base64 payload and instantly updates the center reading pane.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** `doc_categories`, `doc_articles`.
- **Outgoing Dependencies:** N/A (Frontend display).
