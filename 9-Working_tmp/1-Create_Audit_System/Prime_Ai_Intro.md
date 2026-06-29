# Prime-AI — Platform Overview
==============================

## 0. Executive Summary
-----------------------
**Prime-AI is a multi-tenant SaaS Academic Intelligence Platform for Indian K-12 schools.** It is positioned deliberately *against* the conventional school ERP: instead of merely recording and reporting *what happened*, Prime-AI's mission is to help school leadership **take the right decision at the right time** by converting day-to-day operational and academic data into **actionable insights**.

The product unifies three domains that the market usually sells separately — **ERP** (administration), **LMS** (learning & assessment), and **LXP** (learning experience & recommendations) — into a single platform. It is operated as **SaaS** by a central "Prime Team" that onboards and serves many schools (tenants), each with isolated data.

Technically it is a **modular monolith** on PHP 8.2 / Laravel 12 / MySQL 8, using `stancl/tenancy` for tenant isolation and `nwidart/laravel-modules` for module boundaries. Data is organised into a **3-layer database model** (Prime → Global → Tenant) that mirrors the commercial model: platform operations, shared masters, and per-school data.

**Maturity at a glance:** Core operations and academics are largely delivered (13 modules at 100%), the intelligence and assessment layers are maturing (7 modules at 80–95%), and the student/parent-facing experience remains the principal gap (StudentPortal, Library pending).

**Why it matters (one line):**
> *Prime-AI moves schools from **reporting the past** to **deciding the future**, while letting the Prime Team run it as scalable SaaS across many schools.*

---

## 1. What Prime-AI Is

Prime-AI is **not a conventional school ERP** — it is an **Academic Intelligence Platform**. Where a typical ERP records and reports *what happened*, Prime-AI's stated purpose is to help schools **decide what to do next**, by providing detailed data insights and decision support.

It is delivered as a **multi-tenant SaaS** product — one platform serving many schools (tenants) from shared infrastructure, while keeping each school's data isolated.

---

## 2. Product Scope — Three Pillars

Prime-AI combines three product domains that are usually sold separately:

| Pillar | Meaning | Business Value |
|--------|---------|----------------|
| **ERP** | Administrative backbone — fees, transport, school setup, complaints, vendors | Runs day-to-day school operations |
| **LMS** | Learning Management — exams, quizzes, homework, syllabus delivery | Manages teaching & assessment |
| **LXP** | Learning Experience — recommendations, personalised academic guidance | Drives the "intelligence" / insight layer |

---

## 3. Who It Serves (Stakeholders)

- **Prime Team** — the SaaS operator; onboards and manages schools, billing, and platform configuration.
- **Schools (Tenants)** — the paying customers; administrators, principals, and management.
- **Teachers** — assessment, homework, syllabus, classroom intelligence.
- **Students / Parents** — the StudentPortal experience (currently pending).

---

## 4. Architecture at a Glance (3-Layer Data Model)

The platform's tenancy is built on **three database layers**, which directly mirror the business model:

| Layer | Database | Owned By | Holds | Tables | Prefix |
|-------|----------|----------|-------|--------|--------|
| **Prime** | `prime_db` | Prime Team | Tenant management, billing, system config | 27 | `prm_*`, `bil_*`, `sys_*` |
| **Global** | `global_db` | Shared | Common masters — city, state, board, academic session, menus, language | 12 | `glb_*` |
| **Tenant** | `tenant_db` | Each School | All operational & academic data | 368 | `tt_*`, `std_*`, `fin_*`, `exm_*`… |

**Key design intent (from the architect):**
- In **production**, the tenant layer consumes global masters via **database views** — common reference data is *controlled centrally but used everywhere*.
- In the **dev environment**, schemas are deliberately split **per module** for easier enhancement and team comprehension.

### Table Prefix Conventions
```
sys-System   glb-Global   prm-Prime   bil-Billing   sch-SchoolSetup   tt-Timetable
std-Student  slb-Syllabus qns-Questions rec-Recommendation bok-Books cmp-Complaint
ntf-Notification tpt-Transport vnd-Vendor hpc-HPC fin-Fees exm-Exam quz-Quiz
beh-Behaviour hos-Hostel mes-Mess acc-Accounting   _jnt-Junction/bridge suffix
```

---

## 5. Module Capability Matrix (with Maturity %)

**29 modules total** — 5 central (Prime-team facing) + 24 tenant (school-facing).

### 5.1 Central Modules (Prime Team)

| # | Module | Domain | Capability | Maturity |
|---|--------|--------|------------|----------|
| 1 | **Prime** | Platform | Tenant (school) lifecycle & management | 100% |
| 2 | **GlobalMaster** | Reference | Shared masters across all schools | 100% |
| 3 | **SystemConfig** | Platform | System-wide configuration | 100% |
| 4 | **Billing** | Commercial | Subscription / billing for tenants | 100% |
| 5 | **Documentation** | Platform | Internal documentation | 100% |

### 5.2 Tenant Modules — Operations

| # | Module | Domain | Capability | Maturity |
|---|--------|--------|------------|----------|
| 6 | **SchoolSetup** | Operations | School, class, section, structure setup | 100% |
| 7 | **SmartTimetable** | Operations | Timetable generation & scheduling | 100% |
| 8 | **Transport** | Operations | Routes, vehicles, transport mgmt | 100% |
| 9 | **StudentProfile** | Operations | Student master & profile | 100% |
| 10 | **Vendor** | Operations | Vendor management | 100% |
| 11 | **Complaint** | Operations | Complaint / grievance tracking | 100% |
| 12 | **Notification** | Operations | Alerts & notifications | 100% |
| 13 | **Scheduler** | Operations | Job / event scheduling | 100% |
| 14 | **Dashboard** | Insight | Data insights & dashboards | 100% |

### 5.3 Tenant Modules — Academics / LMS

| # | Module | Domain | Capability | Maturity |
|---|--------|--------|------------|----------|
| 15 | **Syllabus** | Academics | Syllabus structure & delivery | 100% |
| 16 | **SyllabusBooks** | Academics | Books mapped to syllabus | 100% |
| 17 | **QuestionBank** | Academics | Question repository & statistics | 100% |
| 18 | **LmsExam** | Assessment | Exam lifecycle | 80–95% |
| 19 | **LmsQuiz** | Assessment | Quizzes | 80–95% |
| 20 | **LmsHomework** | Assessment | Homework | 80–95% |
| 21 | **LmsQuests** | Assessment | Quests / gamified learning | 80–95% |
| 22 | **Hpc** | Assessment | Holistic Progress Card | 80–95% |

### 5.4 Tenant Modules — Finance & Intelligence

| # | Module | Domain | Capability | Maturity |
|---|--------|--------|------------|----------|
| 23 | **StudentFee** | Finance | Fee structure & collection | 80–95% |
| 24 | **Payment** | Finance | Payment processing | 100% |
| 25 | **Recommendation** | Intelligence | Personalised academic recommendations | 80–95% |

### 5.5 Pending / In-Progress

| # | Module | Domain | Capability | Maturity |
|---|--------|--------|------------|----------|
| 26 | **StudentPortal** | Experience | Student / parent-facing portal | Pending |
| 27 | **Library** | Operations | Library management | Pending |

> *Modules 28–29 reserved — the platform is documented as a 29-module target; the two pending modules above plus ongoing initiatives (e.g. Marksheet Generation / MSG) round out the roadmap.*

### 5.6 Maturity Summary

| Maturity Band | Count | Modules |
|---------------|-------|---------|
| ✅ **100% (Delivered)** | 18 | All Central (5) + Operations (9) + Syllabus, SyllabusBooks, QuestionBank, Payment |
| 🟡 **80–95% (Maturing)** | 7 | LmsExam, LmsQuiz, LmsHomework, LmsQuests, Hpc, StudentFee, Recommendation |
| 🔴 **Pending** | 2 | StudentPortal, Library |

---

## 6. Technology Foundation

| Concern | Choice |
|---------|--------|
| Language / Framework | PHP 8.2+ · Laravel 12.0 |
| Database | MySQL 8.x |
| Multi-tenancy | `stancl/tenancy` v3.9 |
| Modularity | `nwidart/laravel-modules` v12.0 |
| Architecture style | Modular monolith |
| Security | 195+ authorization policies; tenancy & module rules enforced via an "AI Brain" knowledge base |

---

## 7. Strategic Read (BA Summary)

**Strengths**
- Clear differentiation — *intelligence/decision-support*, not commodity ERP.
- Operational and academic foundations are largely built (18 modules at 100%).
- Tenancy architecture (3-layer + views) is commercially aligned and scalable.

**Watch areas / Roadmap priorities**
1. **Student/Parent experience gap** — StudentPortal is pending, yet it is the primary touchpoint that converts back-office data into *parent-visible value*.
2. **Assessment layer completion** — the LMS suite (Exam, Quiz, Homework, Quests, HPC) sits at 80–95%; closing this unlocks the academic-intelligence value loop.
3. **Finance hardening** — StudentFee at 80–95% is revenue-critical for schools.
4. **Library** — a recognised gap, lower strategic urgency than the above.

**Core value proposition**
> *Prime-AI consolidates a school's administrative, learning, and experience data into a single multi-tenant platform, then layers intelligence on top — so schools move from **reporting the past** to **deciding the future**, while the Prime Team operates it as scalable SaaS across many schools.*

---

*Document maintained under `9-Working_tmp/1-Create_Audit_System/`. Maturity bands sourced from the project module-status classification; refine per the latest gap-analysis findings.*
