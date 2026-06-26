# Subscription Views — Requirements

## What It Does
Provides read-only view of tenant subscription and plan assignment data within the Billing module. Displays subscription details, pricing information, billing schedule, and module assignments. Supports AJAX-loaded detail panels and bulk PDF/ZIP download of subscription summaries. The actual subscription plan assignment and pricing management lives in the Prime module — Billing module provides the viewing and reporting layer.

## Business Rules

**Read-Only Scope**
- Billing module does NOT create or modify subscription plans or tenant assignments
- All subscription data is read from Prime module models: `TenantPlan`, `TenantPlanRate`, `TenantPlanBillingSchedule`, `TenantPlanModule`
- Write operations (plan assignment, rate changes, schedule modifications) happen in the Prime module

**Subscription Data Source**
- `tenantPlan` status filter: only active plans are shown
- `start_date` range filter available
- Data is paginated at 10 records per page

**PDF Download**
- Subscription PDFs are generated via DomPDF using a dedicated print view
- Multiple subscriptions can be downloaded as a single ZIP archive
- ZIP is generated synchronously (potential timeout risk for large batches)

## Filter System

The Subscription tab uses `buildSubscriptionQuery()` with:

| Parameter | Behavior |
|---|---|
| `status` | Filters by `TenantPlan.status`. Supports multiple value formats: `1`/`'ACTIVE'`/`'active'` all map to active. `0`/`'INACTIVE'`/`'inactive'` map to inactive. Uses `whereHas('tenantPlan')`. |
| `date_range` | Filters `TenantPlanRate.start_date BETWEEN start AND end` |

Default query: `TenantPlanRate::query()` with no initial filters. Paginated at 10 per page.

## CRUD Operations

**List Subscription Data**
- Route: `GET /billing/billing-management?type=subscription_data`
- Shows paginated table with: tenant name, plan name, start date, end date, billing cycle, status, Actions
- Filter by: tenant, plan, date range, status

**Subscription Detail Panel (AJAX)**
- Route: `GET /billing/subscription-details?id=`
- Returns JSON `{html: string}` with subscription metadata
- Shows: plan name, start/end dates, billing cycle, status, assigned modules

**Pricing Detail Panel (AJAX)**
- Route: `GET /billing/pricing-details?id=`
- Returns JSON `{html: string}` with pricing information
- Shows: plan rate, billing cycle rate, discount percentages, tax configuration

**Billing Schedule Panel (AJAX)**
- Route: `GET /billing/billing-details?id=`
- Returns JSON `{html: string}` with billing schedule entries
- Shows: scheduled dates, amounts, invoice generation status, generated invoice references

**Module Details Panel (AJAX)**
- Route: `GET /billing/module-details?id=&type=subscription|invoice`
- `type=subscription`: loads modules from `TenantPlanModule`
- `type=invoice`: loads modules from `BillOrgInvoicingModulesJnt`

**Subscription PDF/ZIP Download**
- Route: `POST /billing/subscription` with `ids[]`
- For each ID: DomPDF from subscription PDF view → add to ZipArchive → return ZIP
- Print view: `GET /billing/billing-management/print/data?type=subscription_data`

## Permissions

| Operation | Permission Key |
|---|---|
| View subscription tab | `prime.subscription.viewAny` |
| View subscription details | `prime.subscription.view` |
| Download subscription PDF | `prime.subscription.create` |
