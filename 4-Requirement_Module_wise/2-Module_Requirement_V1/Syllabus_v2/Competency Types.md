# Competency Types Master — Business Requirements

## What This Screen Does

The Competency Types screen is a high-level master configuration interface. It acts as the ultimate categorisation dictionary for all educational outcomes and skills tracked by the school.

Instead of throwing hundreds of granular skills into one massive, unmanageable list, this screen allows schools to group them into broad, distinct pedagogical categories, such as Cognitive Knowledge, Practical Skills, or Behavioral Attitudes. This is the absolute first step in aligning a school's digital system with national mandates like the National Education Policy or National Curriculum Framework.

---

## When This Screen Is Used

- Initial Setup configured by administrators before any syllabus or skill mapping begins
- Policy Adaptation when the government introduces a new educational mandate like tracking Financial Literacy or 21st Century Skills as distinct domains
- Report Configuration when setting up the legends and categories for Radar Charts or Performance Audits

---

## Key Fields at a Glance

**Identity and Definition**
A Unique Code acts as a standardized system identifier, such as KNOWLEDGE, SKILL, or ATTITUDE. Because this code is heavily relied upon by backend reporting tools, it must be unique and is usually locked once it is in use. The Display Name provides a human-readable label displayed in dropdowns across the system, while a detailed Description explains exactly what this broad category encapsulates.

**State Management**
A Status Toggle acts as an active or inactive switch. If marked as inactive, this Competency Type will no longer appear as an option when users are creating new specific skills, keeping the dropdowns clean without deleting historical data.

---

## Business Rules and Conditions

**Foundational Dependency**
This screen acts as the parent category for all individual competencies. The system enforces a strict dependency rule preventing the deletion of a Competency Type if there are individual skills currently linked to it. The system must prevent deletion and instead encourage administrators to deactivate it.

**Uniqueness and Data Cleanliness**
The unique code must not be duplicated. The system should automatically format user input, such as converting text to uppercase and replacing spaces, before saving to ensure data cleanliness and consistency for reporting.

**Analytics Roll-up**
When the Coverage Audit report is generated, the system dynamically groups all granular outcomes under these Types. If a type exists here but has zero topics mapped to it downstream in the syllabus, the reports will flag it as a Deficient Domain, alerting the Principal that an entire category of learning is being ignored.

---

## Workflow Steps

**Adding a New Competency Type**
The Administrator navigates to the Competency Types screen. They click Add New Type and enter the Name as "Socio-Emotional Learning". They enter the Code as "SEL_DOMAIN" and provide a Description explaining that it tracks emotional intelligence and empathy. Upon saving the record, the "Socio-Emotional Learning" type instantly becomes available as a category when teachers or HODs are defining new specific skills.

---

## Example Scenario

An International Baccalaureate school uses the system. The IB framework requires tracking specific "Learner Profiles" like Inquirers, Thinkers, and Risk-takers. 

The school administrator uses the Competency Types screen to create a new broad category called "IB Learner Profile". Following this, they go to the Competencies screen and create the specific traits, linking them to this new category. At the end of the term, the Principal can generate a specialized report filtered exclusively by the "IB Learner Profile" category. This instantly generates the official, compliant tracking documentation required for external audits without manual data sorting.

---

## Related Screens

- **Competencies** — The child screen where granular skills are created and linked to these broad types
- **Coverage Audit Report** — Uses these types to generate high-level pie charts and radar graphs showing syllabus distribution
