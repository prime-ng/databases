# Business Requirements Document (BRD)
## Module: Notification
### Feature: Architecture, Channels & Providers

---

## 1. Executive Summary
The Notification module is an enterprise-grade messaging engine built to handle Omni-channel communication (Email, SMS, WhatsApp, In-App, Push). This specific document outlines the foundational architecture: **Channels** and **Providers**.

## 2. Business Motive & Rules
- **Omni-Channel Support:** The system must abstract communication methods. A "Notification" doesn't care if it's SMS or Email; the engine routes it.
- **Provider Fallbacks:** If Twilio (Provider A) fails, the system must fallback to MSG91 (Provider B) seamlessly.
- **Cost & Limits Control:** SMS and WhatsApp cost money. The engine must track `cost_per_unit`, `daily_limit`, and `rate_limit_per_minute` to prevent overspending and API throttling.

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Channel Master (`ntf_channel_master`)
- Define base communication channels (EMAIL, SMS, WHATSAPP, IN_APP, PUSH).
- Define `channel_type` (IMMEDIATE, BULK, TRANSACTIONAL).
- Enforce strict delivery limits: `rate_limit_per_minute`, `daily_limit`, `monthly_limit`.
- Define `cost_per_unit` for budget tracking.
- Set a `fallback_channel_id` (e.g., if WhatsApp fails, fallback to SMS).

### FR-02: Provider Master (`ntf_provider_master`)
- Map third-party services to Channels (e.g., Channel = SMS, Provider = Twilio).
- Store API endpoints, encrypted API keys (`api_key_encrypted`), and sender identities (`from_address`).
- Define provider sequence using `provider_type` (PRIMARY, SECONDARY, BACKUP) to dictate fallback routing logic.

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Provider Fallback Config
**As a** System Admin,
**I want to** configure a Secondary provider for SMS,
**So that** if the Primary SMS API gateway is down, messages are still delivered.

**Acceptance Criteria:**
- **Given** I am on the Provider Master configuration, **When** I add MSG91 as SECONDARY to the SMS channel, **Then** the delivery engine will try MSG91 automatically if Twilio (PRIMARY) returns a 5xx error.
