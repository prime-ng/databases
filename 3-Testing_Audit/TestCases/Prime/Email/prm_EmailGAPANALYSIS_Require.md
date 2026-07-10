# prm_Email — Gap Analysis

**Feature:** Prime (PRM) Email debug/preview (tableless action screen)
**Test file:** `prm_Email_TestCas.php` · 16 methods · single suite (no V1/V2)

---

## 1. Manual TC ↔ Dusk Method Mapping

### Config
| Manual | Dusk method | Coverage |
|--------|-------------|----------|
| MT-01 | `test_email_01_routes_gates_controller_and_policy_configuration_are_correct` | Full |
| MT-01 (view) | `test_email_02_email_preview_view_source_is_present` | Full |

### Action
| Manual | Dusk method | Coverage |
|--------|-------------|----------|
| MT-02 | `test_email_10…` + `test_email_11…` | Full |
| MT-03 (response) | `test_email_12_send_test_email_route_returns_email_sent` | Full |
| MT-03 (actual send) | `test_email_14_send_test_email_source_dispatches_login_mail` | Partial (source-level; Dusk cannot Mail::fake) |
| MT-04 | `test_email_13_send_test_email_is_registered_as_get_verb` | Full |

### Authorization
| Manual | Dusk method | Coverage |
|--------|-------------|----------|
| MT-05 | `test_email_50_test_email_is_gated_by_view_any` | Full (gate+source) |
| MT-06 | `test_email_51_send_test_email_is_gated_by_create` | Full (gate+source) |
| MT-05/06 (policy) | `test_email_52_policy_methods_map_to_gate_abilities` | Full |
| MT-07 | `test_email_53_guest_is_redirected_from_test_email` | Full |
| MT-08 | `test_email_54_guest_is_redirected_from_send_test_email` | Full |

### Security (SEC-PRM-002)
| Manual | Dusk method | Coverage |
|--------|-------------|----------|
| MT-09 | `test_email_90_debug_routes_have_environment_guard_present` | Full |
| MT-10 | `test_email_91_send_test_email_uses_hardcoded_recipient` | Full |
| MT-04/GET-CSRF | `test_email_92_send_route_is_side_effecting_get_without_csrf` | Full |
| MT-11 | `test_email_93_preview_does_not_reflect_injected_query_input` | Full |

---

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Config | 2 | 2 | 0 | 0 | 100% |
| Action (Positive) | 5 | 4 | 1 | 0 | 100% |
| Authorization (Negative) | 5 | 5 | 0 | 0 | 100% |
| Security | 4 | 4 | 0 | 0 | 100% |
| **Total** | **16** | **15** | **1** | **0** | **100%** |

- Negative: **100%** ✅ · Positive: **~93%** (1 partial = mail-send side-effect) ✅ · Dependency: N/A (tableless, no FK) · Tenancy: N/A (central, no tenant scope).

### Partial-coverage list
| Item | Limitation |
|------|-----------|
| MT-03 actual mail dispatch | Dusk drives a real browser and cannot install `Mail::fake()`; the send is proven by asserting the controller source (`Mail::to()->send(new LoginMail(...))`) + the `"Email Sent"` HTTP response. A dedicated PHPUnit feature test with `Mail::fake()->assertSent(LoginMail::class)` would raise this to Full. |

---

## 3. Coverage-Score (by requirement Source)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR` → BC-BIZ) | 5 | 5 | 100% |
| State-Machine (`Screen-SM`) | 0 | 0 | n/a (no lifecycle) |
| Validation (`Screen-VR`) | 0 | 0 | n/a (parameterless GET) |
| Integration (`Screen-IP`) | 0 | 0 | n/a |
| Permissions (`Screen-PM` → BC-AUTH) | 5 | 5 | 100% |
| Security (`Screen-SEC`) | 4 | 4 | 100% |

Every `Source`-tagged BC has ≥1 TC. No requirement item has 0 coverage.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compare | Finding |
|---|-------|---------|---------|
| 2 | Route registration | Blade/audit vs `routes/web.php` + Providers | Routes ARE registered — but only under env guard (local/staging/testing). Audit "no env guard" **REFUTED**. → SEC-PRM-002 downgraded. |
| 3 | Gate vs Policy | `Gate::authorize('prime.email.*')` vs `PrimeEmailPolicy` | Both gates map to real policy methods (viewAny/create) — OK. |
| 3b | Policy user type | `PrimeEmailPolicy::viewAny(Modules\Prime\Models\User $user)` vs central `App\Models\User` guard | **Candidate DEV-PRM-EMAIL-002**: policy hints a different User class than the central auth user; a non-super-admin request may TypeError on `Gate::authorize`. Super-admin is unaffected (Gate::before bypass). *Verify in source at runtime — not asserted destructively.* |
| 8/9 | Validation / messages | requirement vs FormRequest | N/A — no FormRequest (parameterless GET). |
| 10 | Permissions | requirement matrix vs Policy + gates | `prime.email.viewAny` (preview), `prime.email.create` (send) — exact, no missing gate. |
| — | Side-effect verb | REST expectation vs route verb | `send-test-email` is GET but sends mail → BC-SEC-03 smell (DEV-PRM-EMAIL-001 territory). |
| — | Hardcoded data | requirement vs controller | Recipient hardcoded `primegurukul@yopmail.com` → DEV-PRM-EMAIL-001. |

Checks 1, 4, 5, 6, 7, 11 are **N/A** for a tableless action screen (no ENUM/fillable/casts/service/state-machine/FK).

---

## 5. Defect Register (feature-local)

| ID | Sev | Description | Proving test | Status |
|----|-----|-------------|--------------|--------|
| SEC-PRM-002 | P1→P2 | Debug email routes exposed in non-prod envs (incl. staging). Audit "no env guard/production" **refuted** by routes/web.php:99. | `test_email_90` | Documented |
| DEV-PRM-EMAIL-001 | P2 | `sendTestEmail()` sends real mail to hardcoded `primegurukul@yopmail.com`; recipient not request-controlled; side-effecting GET. | `test_email_91`, `test_email_92` | Documented |
| DEV-PRM-EMAIL-002 | P3 | Policy type-hint `Modules\Prime\Models\User` differs from central `App\Models\User` — potential TypeError for non-super-admin. | (cross-ref) | Verify in source |

---

## 6. Legend
- **Full** — behaviour/assertion fully exercised by the method.
- **Partial** — proven indirectly (source-level) due to a documented harness limitation.
- **Gap** — no coverage (none here).
- **N/A** — not applicable to this screen type (tableless action).
