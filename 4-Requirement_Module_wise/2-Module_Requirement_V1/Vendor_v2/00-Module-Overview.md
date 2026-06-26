# Vendor Module — Business Requirements Overview

## Module Purpose

The Vendor Module enables a school to manage the complete lifecycle of its vendor relationships — from onboarding a supplier, signing and recording agreements, logging service consumption, generating invoices, and tracking payments to closing out contracts.

This module eliminates manual spreadsheet-based tracking by providing a structured, screen-wise digital workflow. It ensures accurate billing, timely payment processing, GST-compliant invoicing, and clear audit trails for every vendor transaction.

---

## Who Uses This Module

| Role | Primary Activities |
|------|-------------------|
| Admin / Principal | Vendor onboarding, agreement setup, status management |
| Finance Team | Invoice generation, payment recording, reconciliation |
| Finance Head / Accounts Manager | Dashboard monitoring, payment approvals, reporting |
| Purchase Department | Vendor item management, usage log entry |

---

## Module Screens (Tab-wise)

The entire Vendor module is accessible through a single multi-tab interface at: `/vendor/vendor`

| Tab | Screen | Purpose |
|-----|--------|---------|
| Dashboard | Vendor Dashboard | Real-time financial summary and alerts |
| Vendor | Vendor Master | Register and manage supplier records |
| Vendor Item | Vendor Item | Define goods and services catalogue |
| Vendor Agreement | Vendor Agreement | Record and manage contracts |
| Vendor Invoice | Vendor Invoice | Generate and manage invoices |
| Payment Details | Payment Details | Track and record vendor payments |
| Usage Log | Usage Log | Record actual consumption of services/products |

---

## Core Business Flow

```
Vendor Onboarding
       ↓
Define Vendor Items (Goods/Services Catalogue)
       ↓
Create Vendor Agreement (Contract with Billing Terms)
       ↓
Add Agreement Items (What is billed, at what rate, with what billing model)
       ↓
[For Per Unit / Hybrid billing] → Log Usage (Record actual consumption)
       ↓
Generate Invoice (System auto-calculates based on billing model + usage)
       ↓
Record Payment (Finance records payment made against invoice)
       ↓
Reconcile Payment (Finance confirms payment cleared in bank)
       ↓
Dashboard (Monitor outstanding, expiring agreements, payment health)
```

---

## Billing Models Explained Simply

The module supports three ways to calculate what is owed to a vendor:

**Fixed Billing**
The school pays a flat amount regardless of how much was used.
Example: ₹25,000/month for one bus route. Whether the bus makes 100 trips or 130 trips, the monthly charge is always ₹25,000.

**Per Unit Billing**
The school pays only for what it actually uses, multiplied by a rate.
Example: ₹35 per 20L water jar. If 200 jars are used, the charge is ₹7,000.

**Hybrid Billing**
A combination — the school pays a fixed base charge plus an extra amount for usage above a guaranteed minimum.
Example: ₹10,000 fixed + ₹50 per trip above 100 guaranteed trips. If 130 trips are made, extra charge = 30 × ₹50 = ₹1,500. Total = ₹11,500.

---

## Invoice Status Lifecycle

```
Invoice Generated → PENDING
       ↓ (partial payment recorded)
PARTIALLY PAID
       ↓ (remaining balance paid)
FULLY PAID
```

---

## Document Index

| File | Screen | Description |
|------|--------|-------------|
| [01-Vendor-Master.md](./01-Vendor-Master.md) | Vendor Master | Vendor registration, contact and bank details |
| [02-Vendor-Item.md](./02-Vendor-Item.md) | Vendor Item | Goods and services catalogue |
| [03-Vendor-Agreement.md](./03-Vendor-Agreement.md) | Vendor Agreement | Contract setup and agreement items with billing models |
| [04-Vendor-Invoice.md](./04-Vendor-Invoice.md) | Vendor Invoice | Invoice generation, payment recording, PDF and email |
| [05-Payment-Details.md](./05-Payment-Details.md) | Payment Details | Payment history, reconciliation, and payment management |
| [06-Usage-Log.md](./06-Usage-Log.md) | Usage Log | Actual service/product consumption tracking |
| [07-Vendor-Dashboard.md](./07-Vendor-Dashboard.md) | Vendor Dashboard | Financial summary, expiry alerts, and payment health |

---

## Key Dependencies Between Screens

- A **Vendor** must exist before an **Agreement** can be created
- A **Vendor Item** must exist before it can be added to an **Agreement**
- An **Agreement** with at least one active **Agreement Item** must exist before an **Invoice** can be generated
- For **Per Unit** or **Hybrid** billing, **Usage Logs** should be entered before invoice generation to ensure accurate billing
- A **Payment** can only be recorded against an existing **Invoice**
- The **Dashboard** aggregates data from all screens and shows real-time status

---

## Data Tables Reference

| Table | Description |
|-------|-------------|
| `vnd_vendors` | Vendor master — name, type, contact, bank, GST, PAN |
| `vnd_items` | Item master — code, name, type, category, unit, HSN/SAC |
| `vnd_agreements` | Agreement header — vendor, dates, billing cycle, status |
| `vnd_agreement_items_jnt` | Agreement items — item, billing model, rates, taxes |
| `vnd_invoices` | Generated invoices — amounts, dates, status, payments |
| `vnd_payments` | Payment records — amount, mode, reference, reconciliation |
| `vnd_usage_logs` | Usage entries — vendor, item, date, quantity consumed |
