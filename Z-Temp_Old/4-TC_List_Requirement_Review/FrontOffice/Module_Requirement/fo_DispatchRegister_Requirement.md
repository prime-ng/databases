# Dispatch Register — Business Requirements

## What This Screen Does

The Dispatch Register tracks outgoing dispatches (documents sent via Hand, Post, Courier, Email, Fax). Each entry captures the addressee, dispatch mode, document type, reference number, and subject.

## When This Screen Is Used

- **Outgoing Document Logging**: Tracking all official documents sent from the school
- **Dispatch Tracking**: Reference numbers for sent correspondence

## Key Fields

- **dispatch_number** (string) — Auto-generated unique identifier
- **dispatch_date** (date) — When dispatched
- **dispatch_mode** (enum) — Hand, Post, Courier, Email, Fax, Other
- **document_type** (enum) — Letter, Notice, Circular, Report, Legal, Other
- **addressee_name** (string) — Who it was addressed to
- **reference_number** (string, nullable) — External reference
- **subject** (string) — Dispatch subject
- **remarks** (text, nullable)

## Requirements

- MUST display in Registers tab group as card-style list
- MUST authorize via `frontoffice.dispatch-register.*` policy gates
- MUST create entries via modal form
- MUST show dispatch mode + document type badges
- MUST support status toggle via Ajax
- MUST search across dispatch_number, reference_number, addressee, subject, mode, document_type
