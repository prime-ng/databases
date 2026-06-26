# Business Requirements Document (BRD)
## Module: Payment
### Feature: Payment Gateway Configuration

---

## 1. Executive Summary
The Payment Module handles financial transactions across the school system (e.g., fee collection, uniform purchases). To process online payments, the system requires configured **Payment Gateways** (such as Razorpay, PayU, Stripe).

## 2. Business Motive & Rules
- **Multi-Gateway Support:** The school may use Razorpay for primary fees and another gateway as a backup.
- **Environment Isolation:** Gateways must support `test` and `live` modes.
- **Priority Routing:** If multiple active gateways exist, the system should route payments through the gateway with the highest `priority` (1 being highest).

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Payment Gateway Master (`PaymentGateway`)
- Managed by `PaymentGatewayController.php`.
- **Fields:**
  - `name`: Display name (e.g., "Razorpay India").
  - `code`: Unique system code.
  - `driver`: The underlying API driver (e.g., `razorpay`).
  - `credentials`: JSON object containing API keys and secrets.
  - `extra_config`: JSON for additional settings like `{"mode": "test"}`.
  - `priority`: Integer dictating the default gateway.
  - `is_active`: Boolean toggle.
- **Soft Delete Protocol:** Deleting a gateway marks it as inactive and moves it to trash. It can be restored via `restore()` or permanently deleted via `forceDelete()`.
- **Activity Logging:** Every creation, update (showing old vs new values), toggle, and deletion must be logged using the `activityLog()` helper.

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Configuring Razorpay
**As a** System Admin,
**I want to** add Razorpay credentials to the system,
**So that** parents can pay school fees online using UPI, Credit Cards, or Netbanking.

**Acceptance Criteria:**
- **Given** I am on the Payment Gateway creation page, **When** I select the "Razorpay" driver and enter the API keys in `test` mode, **Then** the credentials are saved as JSON, the priority is set to 1, and the system logs the "Stored" activity.
