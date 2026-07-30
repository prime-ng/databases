# Template Engine — Business Requirements

## What the Engine Does

The Template Engine is a backend service — it has no direct screen or user interface. Other modules call it when they need to generate a printed document (marksheet, student ID card, transport staff ID card, etc.). The engine finds the correct template, fills in the data, and returns the finished document as HTML or PDF.

The engine handles five core tasks: (1) finding which template to use based on the requesting class, (2) fetching data from registered data providers, (3) replacing every `{{placeholder}}` in the template with the actual value, (4) repeating table rows inside loop markers, and (5) converting the final HTML to PDF when requested.

---

## When the Engine Is Triggered

- **Marksheet Print** — When the Marksheet Generation module needs to print student marksheets
- **Student ID Card Print** — When the Student Profile module needs to print ID cards
- **Transport Staff ID Card Print** — When the Transport module needs to print staff ID cards
- **Any Future Document Print** — Any module that requests a document through the engine using a registered purpose code
- **Admin Preview** — When an administrator previews a template from the template detail screen
- **Test / Sandbox Call** — During development or testing, when a developer simulates a document generation call

---

## Who and What Triggers the Engine

- **Calling Modules (System-to-System)** — MarksheetGeneration, StudentProfile, Transport, and any other module that registers a purpose code
- **School Admin (via Preview)** — An administrator viewing a template preview from the Template Master detail screen
- **System Administrator** — Configures template assignments, data providers, and variable mappings in Template Master; the engine reads this configuration at processing time
- **Developer / Tester** — Makes test calls to the engine API with sample data

Authentication is handled at the controller/route layer (via middleware and Gate checks), not by the engine itself.

---

## How the Engine Works — Step by Step

### Step 1: Scope Resolution — Finding the Right Template

When a calling module requests a document, it provides a purpose code (e.g., MARKSHEET_PRINT) and the class details (e.g., Standard 10, Section A). The engine follows a priority chain to find the template:

1. **Exact Class Assignment** — Look for a template assignment that matches the exact class (standard + section). Only active templates with active assignments are eligible.
2. **Class Group Assignment** — (Specified in the FRD but not yet implemented) Look for a class group assignment that matches the requesting class's group.
3. **School-Wide Assignment** — Fall back to the school-wide default template for this purpose.
4. **No Assignment Found** — If none of the above yields a result, the engine raises a clear error indicating that no template is assigned.

If a template is found but is inactive (or its assignment is inactive), the engine skips it and continues to the next priority level.

### Step 2: Data Provider Integration

Certain purpose codes have a registered data provider that automatically fetches the required information from the database:

| Purpose Code | What the Provider Fetches |
|-------------|--------------------------|
| MARKSHEET_PRINT | Student marks, subject list, grades, exam details, class information |
| STUDENT_ID_CARD | Student photo, admission number, full name, class, roll number, blood group, date of birth, parent contact, address |
| TRANSPORT_STAFF_ID_CARD | Staff photo, staff name, employee code, designation, department, route details, emergency contact |

The engine calls the data provider first and gets a set of data. The calling module can also supply its own extra data. The engine merges both sources: for any key that appears in both, the calling module's value takes priority (the caller knows best).

### Step 3: Variable Substitution — Replacing Placeholders

After the template HTML is loaded and data is assembled, the engine walks through every `{{placeholder}}` marker in the HTML and replaces it with the actual value. Each placeholder is mapped to one of two types:

- **Automated Variables** — The engine looks up the configured database table and column, fetches the current value, and substitutes it. This is configured in Template Master by the administrator.
- **Manual Variables** — The value is provided directly by the calling module. No database lookup is needed.
- **No Value Found** — If the engine cannot find a value from any source, it uses the configured default value (or leaves the field blank if no default is set).

The output type determines how the value is rendered:

| Output Type | How It Is Rendered |
|-------------|-------------------|
| Text | The value is HTML-escaped before insertion (prevents XSS and display issues) |
| Rich HTML | The value is passed through as-is without escaping (for trusted, pre-formatted content) |
| Image | The value is rendered as an `<img>` HTML tag |

### Step 4: Loop Block Rendering — Repeating Rows

For tables and repeating sections (e.g., subject rows in a marksheet), the template HTML uses loop markers:

```
<!-- LOOP: subjects -->
<tr><td>{{subject_name}}</td><td>{{marks}}</td><td>{{grade}}</td></tr>
<!-- ENDLOOP -->
```

The engine identifies the content between `<!-- LOOP: name -->` and `<!-- ENDLOOP -->`, then repeats it once per item in the corresponding data array. Each repetition substitutes the placeholders with that item's values.

Legacy markers from older template versions are automatically translated to the new loop format:

| Legacy Marker | Translated To |
|--------------|--------------|
| `SUBJECT_TABLE_START` / `SUBJECT_TABLE_END` | LOOP subjects / ENDLOOP |
| `EXAM_COLUMNS_START` / `EXAM_COLUMNS_END` | LOOP exam_columns / ENDLOOP |
| `COSCHO_TABLE_START` / `COSCHO_TABLE_END` | LOOP coscho_rows / ENDLOOP |

This translation is automatic — administrators do not need to manually update old templates.

### Step 5: PDF Output

After the HTML is fully rendered (placeholders replaced, loops expanded), the engine can convert it to PDF. The calling module specifies:

- **Paper Size** — Defaults to A4 if not specified. Can be set to Letter, Legal, or other standard sizes.
- **Orientation** — Defaults to Portrait if not specified. Can be set to Landscape.

The engine returns the rendered content either as HTML (for browser preview) or as a PDF (for printing/download). The calling module decides which format to request.

### Step 6: Sample Preview

When an administrator views a template from the Template Master detail screen, they can click a preview button. The engine generates synthetic sample data based on the registered data provider's schema (field names and types, but not real school data). It then runs the full rendering pipeline with this sample data and returns the result for display in the browser.

The preview uses only fake, generated data — no real student, staff, or school information is used. If the template has no registered data provider, the preview shows the raw template with unresolved placeholders so the administrator can see the template structure.

---

## What the Engine Validates Before Processing

| Check | What Happens If It Fails |
|-------|--------------------------|
| Purpose code is valid and registered | Engine rejects with "Invalid purpose code" |
| Template exists and is active for the scope | Engine rejects with "No active template found for this purpose and class" |
| Required data is provided (caller data + provider data) | Engine substitutes blank or default for missing values (no hard failure) |
| Data provider (if registered) executes without error | Engine logs the error and continues with only caller-supplied data |
| Placeholder mapping is valid (automated variable table/column exists) | Engine substitutes blank for that placeholder and logs a warning |
| Output format is valid (html or pdf) | Engine rejects with "Invalid output format" |
| Paper size and orientation (for PDF) are valid | Engine defaults to A4 Portrait and continues |

---

## Business Rules and Conditions

### Rule BR-TE-001: Priority Chain Must Be Followed
The engine must always follow scope resolution in order: exact class → class group (future) → school-wide. It must never skip a level or select a lower-priority template when a higher-priority one exists.

### Rule BR-TE-002: Only Active Templates and Active Assignments
A template is eligible for selection only if both the template itself and its assignment are marked Active. If either is inactive, the engine treats it as if no template exists at that level and moves to the next priority level.

### Rule BR-TE-003: Caller Data Overrides Provider Data
When merging data from the data provider and the calling module, the calling module's values must always take precedence for any key that exists in both sources. The engine must never allow provider data to silently overwrite caller-supplied data.

### Rule BR-TE-004: Legacy Loop Markers Are Translated
Templates that use the old `SUBJECT_TABLE_START/END`, `EXAM_COLUMNS_START/END`, or `COSCHO_TABLE_START/END` markers must be automatically translated to the new `<!-- LOOP -->` / `<!-- ENDLOOP -->` format. No manual template update should be required.

### Rule BR-TE-005: Text Output Is HTML-Escaped
Any placeholder marked as type "Text" must have its value HTML-escaped before substitution. This prevents broken layout and security issues.

### Rule BR-TE-006: Preview Uses Synthetic Data Only
The preview feature must never use real school or student data. It must generate synthetic sample data based on the provider schema. If no provider is registered, it renders the template with unresolved placeholders visible.

### Rule BR-TE-007: PDF Defaults to A4 Portrait
If the calling module does not specify a paper size or orientation, the engine must default to A4 paper in Portrait orientation.

### Rule BR-TE-008: Missing Values Use Default or Blank
If a placeholder has no value from any source (provider, caller, or database), the engine must use the configured default value. If no default is configured, it must substitute an empty string (blank). It must never fail the entire request due to a missing value.

### Rule BR-TE-009: Provider Failure Does Not Block Rendering
If a data provider throws an error or returns no data, the engine must log the error and continue rendering using only the data supplied by the calling module. A provider failure must never cause the document generation to fail entirely.

### Rule BR-TE-010: Each Request Is Independent
Every document generation request is independent. The engine must not cache or reuse data from one request in another. Each request fetches fresh data from providers and the database.

### Rule BR-TE-011: Authentication Required for All Requests (Removed — engine has no auth logic; authentication is handled at controller/route layer)

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| BR-TE-001 | Follow scope resolution in order: exact class → class group → school-wide |
| BR-TE-002 | Only active templates with active assignments are eligible |
| BR-TE-003 | Calling module's data overrides provider data on conflict |
| BR-TE-004 | Legacy loop markers are auto-translated to new format |
| BR-TE-005 | Text output placeholders are HTML-escaped |
| BR-TE-006 | Preview uses synthetic data only, never real data |
| BR-TE-007 | PDF defaults to A4 Portrait when not specified |
| BR-TE-008 | Missing values use default or blank, never fail |
| BR-TE-009 | Provider failure is logged; rendering continues with caller data |
| BR-TE-010 | Every request is independent — no caching across requests |
| BR-TE-011 | (removed — authentication is at controller/route layer, not in engine) |

---

## Error Messages

| Scenario | Error Message |
|----------|--------------|
| Invalid or unknown purpose code | "The purpose code is invalid or not registered." |
| No template found for the given purpose and class | "No active template found for this purpose and class. Please assign a template in Template Master." |
| No template assignment exists at any scope level | "No template assignment found. Please assign a template for this purpose." |
| Template exists but is inactive | "The assigned template is inactive. Please activate it in Template Master." |
| Assignment exists but is inactive | "The template assignment is inactive. Please activate it in Template Master." |
| Invalid output format requested | "The output format is invalid. Please specify 'html' or 'pdf'." |
| Invalid paper size for PDF | "The paper size is invalid. Using default A4." |
| Invalid orientation for PDF | "The orientation is invalid. Using default Portrait." |
| Data provider execution failed | "The data provider encountered an error. Document rendered with available data." |
| Placeholder mapped to non-existent database column | "A placeholder reference could not be resolved. Check automated variable mappings in Template Master." |
| Unauthenticated request | "Authentication failed. Please provide valid credentials." |
| Template not found by ID (preview) | "Template not found." |
| Purpose code has no registered data provider (preview) | "No data provider is registered for this purpose. Preview will show unresolved placeholders." |

---

## Success Scenarios

- The Marksheet Generation module requests a marksheet for Standard 10, Section A. The engine finds an exact class assignment with an active template. The data provider fetches all student marks, subjects, and grades. The engine substitutes every `{{placeholder}}` in the template HTML, repeats subject rows inside the loop, and returns a fully rendered HTML document. The calling module converts it to PDF and sends it to the printer.

- The Student Profile module requests an ID card for student "Aarav Sharma" of Standard 5, Section B. No exact class assignment exists, and no class group assignment exists, so the engine falls back to the school-wide default template for STUDENT_ID_CARD. The data provider fetches the student's photo, admission number, name, class, and other details. The engine renders the HTML and returns it to the calling module.

- A School Admin opens a template in Template Master and clicks "Preview." The engine generates synthetic sample data — fake student name "John Doe", fake roll number "101", fake marks — and renders the template with this data. The admin sees a realistic preview in the browser with no real school data exposed.

- An administrator uploads an old template that uses `SUBJECT_TABLE_START` and `SUBJECT_TABLE_END` legacy markers. The engine automatically translates these to `<!-- LOOP: subjects -->` and `<!-- ENDLOOP -->`. The template renders correctly with all subject rows repeated.

---

## Failure Scenarios

- A calling module requests a marksheet for Standard 12, Section C, but no template is assigned at any level (exact class, class group, or school-wide). The engine returns "No active template found for this purpose and class. Please assign a template in Template Master."

- A calling module requests a document with an invalid output format "xls". The engine returns "The output format is invalid. Please specify 'html' or 'pdf'."

- The data provider for MARKSHEET_PRINT throws a database connection error. The engine logs the error internally, continues rendering with only the data supplied by the calling module (which may be minimal), and returns the partially rendered document with a warning message.

- An unauthenticated service tries to call the engine. The engine rejects the request with "Authentication failed. Please provide valid credentials."

- An administrator previews a template that has no registered data provider. The engine generates no synthetic data and shows the template with all `{{placeholder}}` markers still visible, along with the message "No data provider is registered for this purpose. Preview will show unresolved placeholders."

---

## Example Scenario

Sunrise International School uses the Template Engine to print marksheets for all classes.

The School Admin has configured the following in Template Master:

- **Purpose:** MARKSHEET_PRINT
- **Exact class assignment:** Standard 10, Section A → Template "Marksheet_v2" (Active)
- **School-wide default:** Template "Marksheet_Standard" (Active)

When the Marksheet Generation module triggers a print for Standard 10, Section A at the end of term:

1. The module sends a request to the engine with purpose code = MARKSHEET_PRINT, class = Standard 10 / Section A, and the student list as extra data.

2. The engine checks scope: it finds an exact class assignment for Standard 10 / Section A → Template "Marksheet_v2" is active. The assignment is active. The engine selects this template.

3. The engine calls the MARKSHEET_PRINT data provider. The provider fetches from the database: each student's marks per subject, subject names, grade for each subject, total marks, percentage, exam name, and class teacher name.

4. The engine merges the provider data with the calling module's extra data. For student names, both sources provide the same value — the calling module's value is used (both are identical in this case, so no conflict).

5. The engine loads Template "Marksheet_v2" HTML. It finds `{{student_name}}`, `{{class}}`, `{{exam_name}}`, `{{total_marks}}`, `{{percentage}}`, and `{{grade}}` placeholders. It also finds a `<!-- LOOP: subjects -->` block with `{{subject_name}}`, `{{marks}}`, `{{grade}}` inside.

6. The engine substitutes each placeholder with its value from the merged data. For the loop block, it repeats the subject row for each subject the student studied.

7. The engine returns the fully rendered HTML to the Marksheet Generation module. The module requests a PDF output with A4 Portrait. The engine converts the HTML to PDF and returns the PDF.

8. The school prints the marksheet for distribution to parents.

---

## Related Modules (Callers)

- **Template Master** — Where templates are created, edited, and assigned. The engine reads configuration from this module.
- **Marksheet Generation** — Calls the engine to print marksheets (purpose: MARKSHEET_PRINT)
- **Student Profile** — Calls the engine to print student ID cards (purpose: STUDENT_ID_CARD)
- **Transport** — Calls the engine to print transport staff ID cards (purpose: TRANSPORT_STAFF_ID_CARD)
- **Class Group Master** — (Future) Class group assignments will reference class groups defined in this module

---

## How Other Parts of the System Depend on the Engine

| Area | What It Needs From the Engine |
|------|------------------------------|
| **Marksheet Generation** | Rendered marksheet HTML/PDF with accurate student marks, grades, and subject data |
| **Student Profile** | Rendered ID card HTML/PDF with student photo, name, admission details, and class info |
| **Transport** | Rendered staff ID card HTML/PDF with staff photo, designation, department, and route details |
| **Template Master** | Template assignment data (which templates are active, which assignments exist) for scope resolution |
| **Template Master (Preview)** | Rendered preview HTML using synthetic sample data so admins can verify template appearance |
| **Any Future Module** | A standardised way to generate printed documents without building custom printing logic |
