# Fee Structures — Business Requirements

## What This Screen Does

The Fee Structures screen configures hostel fee rates for different accommodation types. Room rent, mess charges, electricity, laundry, and security deposit amounts are defined per room type, meal plan, and academic session with effective dates. These rates are used when generating fee demands for hostel students.

---

## When This Screen Is Used

- At the start of the academic year to set hostel fee rates
- When room rent or mess charges are revised
- To configure different rates for different room types
- To set up session-specific fee structures

---

## Key Fields

- **Name** — Fee structure name (e.g., "2026-27 Boys Hostel Fees")
- **Academic Session** — Which session this applies to
- **Hostel** — Which hostel (optional, can be global)
- **Room Type** — Which room type (optional, can be global)
- **Meal Plan** — Vegetarian / Non-Vegetarian / Mess Only / No Mess
- **Room Rent** — Monthly room rent amount
- **Mess Charge** — Monthly mess charge
- **Electricity Charge** — Monthly electricity (fixed or based on usage)
- **Laundry Charge** — Monthly laundry charge
- **Security Deposit** — One-time refundable deposit
- **Other Charges** — Any additional charges (JSON)
- **Effective From** — Start date
- **Effective To** — End date (nullable)
- **Status** — Active / Inactive

---

## Business Rules

- Fee structures are session-specific (different rates each year)
- Rates can be defined per hostel, per room type, or as a global default
- More specific rates override general ones (hostel+room type > room type only > global)
- Only one active fee structure per combination at a time
- Changing rates mid-session creates a new structure (old one remains for historical billing)
- Security deposit is one-time, all other charges are periodic

---

## Related Screens

- **Room Types** (Tab 02) — Fee rates configured per room type
- **Fee Demands** (Tab 39) — Fee structures used to generate demands
- **Hostels** (Tab 05) — Fee rates can be per hostel
