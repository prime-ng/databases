# Document Checklist — Business Requirements

## What This Screen Does

The Document Checklist screen allows the admin to define the set of documents that applicants must upload or submit as part of their application. Each document entry specifies whether it is mandatory or optional, which class it applies to, and which admission cycle it belongs to.

This screen shows a table of all defined documents with their class, cycle, and mandatory status. A form panel on the side allows adding or editing document entries inline.

---

## When This Screen Is Used

- After creating an admission cycle: Admin defines what documents are required
- Per-class variation: Different classes may need different documents (e.g., birth certificate for Class I, mark sheets for higher classes)
- Admin needs to update document requirements mid-cycle

---

## Key Fields at a Glance

**Document Name**
The name of the document (e.g., "Birth Certificate", "Aadhaar Card", "Previous Report Card").

**Is Mandatory**
Toggle to mark the document as mandatory or optional. Mandatory documents must be uploaded before the application can be submitted.

**Class**
The class this document requirement applies to. Can be set to "All Classes" or a specific class.

**Cycle**
The admission cycle this document belongs to.

**Status**
Enable/disable toggle to temporarily hide a document from the application form.

---

## Business Rules and Conditions

**Cycle-Scoped**
All document checklists belong to a specific admission cycle. They do not carry over between cycles.

**Per-Class or Global**
A document can be defined for "All Classes" or a specific class. If defined for a specific class, it only appears in the application form for that class.

**Mandatory Validation**
During application submission, all mandatory documents must be uploaded. The system validates this before allowing the application to move past the Draft stage.

**Soft Delete**
Documents can be soft-deleted. Restoring a deleted document re-associates it with its cycle and class.

---

## Workflow Steps

**Adding a Document**
Admin clicks "Add Document", selects the class, enters the document name, toggles mandatory/optional, and submits.

**Editing a Document**
Admin clicks the Edit icon on any row. The form populates with the document's data. Changes are saved inline.

**Toggling Mandatory**
Admin toggles the mandatory switch on any document to change its requirement status.

**Deleting a Document**
Admin clicks Delete. A confirmation dialog appears. On confirm, the document is soft-deleted.

---

## Example Scenario

For the 2027-28 admission cycle, the admin defines these documents:
- Birth Certificate (Mandatory — Class I, II)
- Aadhaar Card (Mandatory — All Classes)
- Previous Report Card (Mandatory — Class II and above)
- Transfer Certificate (Mandatory — Class II and above)
- Passport Photo (Mandatory — All Classes)
- Caste Certificate (Optional — All Classes)

When a parent applies for Class I, they must upload Birth Certificate, Aadhaar Card, and Passport Photo. The Caste Certificate is optional.

---

## Related Screens

- **Admission Cycles** — Checklists are scoped to a cycle
- **Enquiry Pipeline** — Applications validate against document checklist
- **Application Show** — Document upload status is displayed per applicant
