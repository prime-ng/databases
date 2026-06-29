# Complete Audit — CommonChat (COM) — 2026-06-29   (Mode X: A+B+C+G + scoped D)

**Module:** CommonChat | **Code:** COM | **Live table prefix:** `cht_` | **App dir:** `Modules/CommonChat`
**Auditor:** Technical Auditor (read-only) | **Baseline FRD:** `COM_FRD_Complete_2026-06-29.md` (22 REQ / 40 BR / 5 RPT)
**Scope confirm:** This is the *CommonChat* in-app chat module (`cht_`). It is NOT the non-existent `com_` broadcast module — verified: no `Modules/Communication`, no `com_*` migration. CODE=COM, PREFIX=`cht_` is the intentional pairing.

---

## Executive Summary
CommonChat is a substantially-built module (9 tables, 15 controllers, a 559-LOC `ChatService`, 4 policies, 5 FormRequests, 19 views, 1 scheduled command, 0 tests) with a clean tenancy/authorization backbone on the web path. However it carries **one P0 deploy blocker** (`cht_permission_config` declares two FKs to `sys_roles`, a table that has **no create migration anywhere** → `tenants:migrate` fails with errno 150/1824) and a cluster of P1 defects: chat **attachments are served from the public disk with no membership check** (confidential files world-readable by URL), the **retention-purge command is scheduled in central context** so it never runs per-tenant, the **moderation/admin-delete path is broken by hardcoded role slugs** (`super-admin`/`principal`), the **message column is VARCHAR(2000) while validation allows 5,000 chars** (insert failure / truncation), **reply integrity is unenforced** (reply-to-reply and cross-conversation replies are possible), and **PII is logged on every user search**. Notification (REQ-COM-012) and moderation-audit writes (REQ-COM-019) are entirely absent.
**Overall health: 38/100 — CAPPED at 40 (one P0 present). DEPLOY: NO-GO.**

## Audit Mode(s) Run
Mode X = A (12-layer) + B (FRD gap) + C (BR enforcement) + G (deploy gate) + module-scoped D (systemic patterns). One unified report; each defect coded once.

## Health Score
Weighted layer index ≈ 64 raw, **capped at 40** by the P0 migration blocker (MIG-COM-001). A single deploy blocker means "not healthy", per the rubric.

## Deploy Gate Verdict — **NO-GO**
Blocking items:
1. **MIG-COM-001 (P0)** — FK to non-existent `sys_roles` migration → tenant migration fails; the module's tables cannot be created on a fresh tenant.
2. **SEC-COM-001 (P1, deploy-sensitive)** — confidential attachments publicly accessible by URL (no auth/membership gate).
Both must be resolved before any tenant user testing.

---

## P0 Findings

### [MIG-COM-001] P0 — `cht_permission_config` FK targets `sys_roles`, which has no create migration (tenant migration fails)
- **Location:** `database/migrations/tenant/2026_06_16_100703_create_cht_permission_config_table.php:32` and `:36`
- **Evidence:**
```php
$table->foreign('permission_for_role_id','fk_..._permission_for_role_id')->references('id')->on('sys_roles')->onDelete('cascade');
// ...
$table->foreign('allowed_whom_to_connect_with','fk_..._allowed_whom_to_connect_with')->references('id')->on('sys_roles')->onDelete('cascade');
```
  Verification: `ls database/migrations/tenant/*create_sys_roles_table.php` → **0 files**; `ls database/migrations/*create_sys_roles*` (central) → **0 files**. (`sys_users` tenant migration *does* exist: `2026_06_15_145405_create_sys_users_table.php`, so the `sys_users` FKs are fine.)
- **Why it's a risk:** MySQL cannot create a FK to a table that does not exist → `tenants:migrate` aborts with errno 150/1824 when it reaches `cht_permission_config`. The whole CommonChat schema (and any later migrations) fail to provision on a new tenant. Deploy blocker.
- **Fix:** This is the platform-wide Layer-2.5 systemic gap (17+ tenant FKs already target the missing `sys_roles`). Either add a `create_sys_roles_table` tenant migration ordered before `cht_permission_config`, or, if roles live centrally, drop the DB-level FK and keep an index + application-level integrity (cross-DB FK is impossible in MySQL). Module-local action: do not rely on the DB FK to `sys_roles`.
- **Confidence:** High
- **Systemic?:** Yes — Layer 2.5 / platform `sys_roles`-missing pattern. CommonChat adds 2 more FKs to the count.

---

## P1 Findings

### [SEC-COM-001] P1 — Chat attachments served from public disk with no membership/auth gate
- **Location:** `app/Http/Controllers/ChatAjaxController.php:479` (store), `:506`, `:508` (serve)
- **Evidence:**
```php
$path = $file->store("chat-attachments/{$tenantId}/".now()->format('Y/m/d'), 'public');   // public disk
// ...
'url'          => $isImage ? Storage::disk('public')->url($attachment->file_path) : null,
'download_url' => Storage::disk('public')->url($attachment->file_path),
```
- **Why it's a risk:** Files on the `public` disk are reachable at a static `/storage/...` URL by **anyone**, with no authentication and no conversation-membership check. This directly violates NFR-COM-006 / REQ-COM-007 acceptance ("a non-participant hitting the file URL directly → access refused") and BR-COM-023's confidentiality intent. Although the path is segmented by `tenant()->id`, the URL is guessable/shareable and bypasses tenancy + the participant gate. Confidential, possibly child-safety-sensitive, attachments leak.
- **Fix:** Store on a private disk and serve through an authenticated controller route that authorizes `view` on the parent conversation (membership check), e.g. a signed/streamed `messages/{id}/attachment` endpoint. Use `tenant_asset()`/private storage, never `disk('public')->url()`.
- **Confidence:** High
- **Systemic?:** Layer 6.4 (tenant file routing) + Layer 5 (IDOR on file URL).

### [JOB-COM-001] P1 — Retention purge scheduled in central context; never runs per-tenant
- **Location:** `app/Providers/CommonChatServiceProvider.php:80-83`; command `app/Console/Commands/PurgeOldChatMessages.php`
- **Evidence:**
```php
$schedule->command('chat:purge-old-messages')->daily();   // central scheduler, no tenants:run wrapper
```
  The command body (`ChatSettings::first()` / `ChatMessage::...->forceDelete()`) touches tenant-only `cht_*` tables but has no `tenancy()->initialize()` / `$tenant->run()` and takes no `--tenant`. No `withoutOverlapping()`/`onOneServer()`.
- **Why it's a risk:** The daily run executes once in **central** context where `cht_settings`/`cht_messages` do not exist → it errors or reads the wrong DB and silently no-ops. REQ-COM-020 (BR-COM-039) message-retention purge is effectively **non-functional** in production; retention is never enforced.
- **Fix:** Schedule via `tenants:run chat:purge-old-messages` (or loop tenants and `$tenant->run()`), and add `withoutOverlapping()->onOneServer()`. Confirm Horizon/queue connection if dispatched.
- **Confidence:** High
- **Systemic?:** Layer 10.2 (same class as Hostel `hst:escalate-complaints` central-schedule defect).

### [BUG-COM-001] P1 — Moderation / admin-delete broken by hardcoded role slugs (role-name chaos)
- **Location:** `app/Services/ChatService.php:365`
- **Evidence:**
```php
$isAdmin = $user->hasAnyRole(['super-admin', 'principal']);   // hyphenated slugs, hardcoded
```
- **Why it's a risk:** The controller authorizes moderation via the policy permission `tenant.chat.moderate` (`ChatModerationController::destroy:62`, `ChatMessagePolicy::delete:41`), but the **service** re-checks with a *different* identifier scheme: literal roles `super-admin`/`principal`. A user who legitimately holds `tenant.chat.moderate` but a different role (e.g. `vice_principal`, or a role named `super_admin` with an underscore) passes the controller gate and then hits `throw "You can only delete your own messages."` inside the service. Admin moderation (REQ-COM-018, BR-COM-032) fails for most moderators. The module uses **three** inconsistent role conventions: display names in the seeder ("Super Admin", "School Admin"), `short_name` in `canInitiateDm` (`super_admin`, `principal`, `vice_principal`), and hyphen slugs here (`super-admin`).
- **Fix:** Remove the service's hardcoded role check; rely on the already-authorized policy decision (pass an `$isModerator` flag from the controller, or re-check `$user->can('tenant.chat.moderate')`). Standardise on one role identifier across seeder/service/policy (GAP-COM-005).
- **Confidence:** High
- **Systemic?:** D24 permission/role-name chaos.

### [BUG-COM-002] P1 — Group max-member off-by-one rejects the configured maximum
- **Location:** `app/Services/ChatService.php:224`
- **Evidence:**
```php
if (count($memberIds) >= $maxMembers) {
    throw new \InvalidArgumentException("A group cannot have more than {$maxMembers} members.");
}
```
- **Why it's a risk:** `$memberIds` excludes the creator, and the guard fires at `>= $maxMembers`, so the largest creatable group is `maxMembers - 1` additional + creator = `maxMembers` total only when the creator is double-counted — in practice it blocks at one below the school limit and the error text is also misleading. Violates BR-COM-010 (`cannot exceed` the configured max, hard cap 500). GAP-COM-008 confirmed live.
- **Fix:** Compare total membership (`count($memberIds) + 1 > $maxMembers`) and align the message.
- **Confidence:** High

### [DAT-COM-001] P1 — Message column VARCHAR(2000) but validation allows 5,000 chars
- **Location:** `database/migrations/tenant/2026_06_16_100707_create_cht_messages_table.php:16` vs `app/Http/Requests/StoreMessageRequest.php:17` and `app/Http/Controllers/ChatAjaxController.php:155`
- **Evidence:**
```php
$table->string('body', 2000)->nullable();          // migration: 2000
'body' => ['nullable','string','max:5000'],          // FormRequest + AJAX: 5000
```
  FRD BR-COM-016 and `ChatService` comment both state the limit is 5,000.
- **Why it's a risk:** A message of 2,001–5,000 chars passes validation, then on insert MySQL truncates it (non-strict) or throws SQLSTATE 22001 "Data too long for column 'body'" (strict mode) → 500 / lost content. Three-way mismatch (DDL/migration vs FormRequest vs BR).
- **Fix:** Make the column and the rule agree — either widen to `VARCHAR(5000)`/`TEXT` (recommended, matches BR-COM-016) or lower the validation `max` to 2000 and update the FRD.
- **Confidence:** High
- **Systemic?:** Layer 2.2 three-way reconcile gap.

### [VAL-COM-001] P1 — Reply integrity unenforced: reply-to-reply AND cross-conversation replies allowed
- **Location:** `app/Services/ChatService.php:290-297` (sendMessage); `app/Http/Requests/StoreMessageRequest.php:18`; `app/Http/Controllers/ChatAjaxController.php:156`
- **Evidence:** `parent_message_id` is validated only as `exists:cht_messages,id` — there is no check that the parent is top-level (`parent_message_id IS NULL`) nor that it belongs to the **same conversation**:
```php
'parent_message_id' => ['nullable','integer','exists:cht_messages,id'],   // any message in any conversation
```
- **Why it's a risk:** (a) BR-COM-019 reply-depth cap (one level) is not enforced — reply-to-reply is possible (GAP-COM-002). (b) **BR-COM-018 is violated**: a reply can point at a message in a *different* conversation, and `parentMessage->body` preview is then surfaced (`ChatAjaxController:121`) — a content-leak/data-integrity hole across conversations.
- **Fix:** In `sendMessage` (and/or the FormRequest), load the parent and reject if `parent.conversation_id !== $conversation->id` or `parent.parent_message_id !== null`.
- **Confidence:** High

### [BUG-COM-003] P1 — PII logged on every user search (`Log::debug` of user identity)
- **Location:** `app/Http/Controllers/ChatController.php:210, 218, 227`
- **Evidence:**
```php
\Illuminate\Support\Facades\Log::debug('searchUsers', ['auth_id'=>auth()->id(), 'auth_role_name'=>..., ...]);
\Illuminate\Support\Facades\Log::debug('dm_check', ['recipient_id'=>$user->id,'recipient_name'=>$user->name, ...]);
```
- **Why it's a risk:** Every user-search request writes user ids, names and roles to the log (per-recipient, in a loop) — PII spam and a privacy concern in a multi-tenant child-data system. Explicitly the pattern flagged in the audit playbook (Layer 4.2) for this exact file.
- **Fix:** Remove the debug logging (it is left-over development instrumentation), or gate behind `if (config('app.debug'))` with PII redacted.
- **Confidence:** High

### [BUG-COM-004] P1 — Moderation/audit trail not written (REQ-COM-019 has no data source)
- **Location:** `app/Services/ChatService.php:363-377` (deleteMessage)
- **Evidence:** `deleteMessage` sets `is_deleted / body=null / deleted_by` only; no write to `sys_activity_logs`, no SHA-256 body hash.
- **Why it's a risk:** REQ-COM-019 / BR-COM-037 / BR-COM-038 (immutable audit, hash-only body for admin deletes) and RPT-COM-004/005 have **no backing data**. The Activity Log screen is empty. GAP-COM-003.
- **Fix:** On admin delete and group-lifecycle events, write a `sys_activity_logs` entry (actor, action, subject, timestamp; SHA-256 of original body for deletes). Note the per-tenant `cht_messages` writes already use `activityLog()` in `ChatPermissionConfigController` — reuse that helper.
- **Confidence:** High

### [BUG-COM-005] P1 — Notification integration entirely absent (REQ-COM-012)
- **Location:** `app/Services/ChatService.php` (sendMessage — no dispatch); `app/Providers/EventServiceProvider.php:14` (`$listen = []`)
- **Evidence:** No NTF dispatch, event, or listener anywhere; only `unread_count` increments.
- **Why it's a risk:** REQ-COM-012 (BR-COM-024/028: new-message/@mention in-app notification with privacy + graceful degradation) is NOT STARTED. GAP-COM-004.
- **Fix:** Dispatch a queued notification on send (honour `cht_personalization_settings` + mute), with a try/catch fallback to unread-count-only.
- **Confidence:** High

### [BUG-COM-006] P1 — Seeder ↔ service role-identifier mismatch breaks permission resolution
- **Location:** `database/seeders/ChatPermissionConfigSeeder.php:21-45` vs `app/Services/ChatService.php:35-77`
- **Evidence:** Seeder keys role-pairs on display names `['Super Admin','School Admin','Teacher','Student','Parent']`; `canInitiateDm` branches on `short_name` `['super_admin','principal','vice_principal','teacher','staff','accountant','librarian','student','parent']`. "School Admin" has no `short_name` branch; `principal`/`vice_principal` are never seeded; `staff/accountant/librarian` have no seeded rows.
- **Why it's a risk:** The role-pair matrix (`checkPermissionConfig`) and the hardcoded fallback (`canInitiateDm`) disagree on who roles are, so permission resolution (REQ-COM-002/017, BR-COM-006/007) is inconsistent and role-dependent. GAP-COM-005.
- **Fix:** Pick one identifier (recommend `short_name`) and use it consistently in seeder, service, and `deleteMessage`. Seed `principal`/`vice_principal`/staff variants.
- **Confidence:** High

---

## P2 Findings

### [DATA-COM-002] P2 — `cht_messages.message_type` ENUM has an invalid default `'text'`
- **Location:** `2026_06_16_100707_create_cht_messages_table.php:17`
- **Evidence:** `$table->enum('message_type',['Attachment','System','Text'])->default('text');` — default `'text'` is not a member of the (capitalised) ENUM.
- **Why it's a risk:** In strict mode MySQL rejects the invalid default / coerces to `''`. Runtime inserts are safe because `ChatService::sendMessage:280` always writes a capitalised value via `match`, but the schema default is invalid. GAP-COM-006.
- **Fix:** `->default('Text')`. Confidence: High.

### [SEC-COM-002] P2 — `is_deactivated_by_admin` not enforced in send/receive path
- **Location:** model `app/Models/ChatPersonalizationSettings.php:22` (fillable); no guard in `ChatService::sendMessage` / `ChatMessagePolicy`.
- **Evidence:** Column exists and is checked nowhere in the message pipeline. (Web update `ChatPersonalizationController::update:40-46` correctly whitelists only the 5 preference fields, so a user cannot self-clear the flag via the web path — but a deactivated user is never actually blocked from sending/receiving.)
- **Why it's a risk:** REQ-COM-022 / BR-COM-040 (block deactivated users) is unenforced. GAP-COM-010.
- **Fix:** Add a guard in `sendMessage` (and read/list) that refuses when the sender's `is_deactivated_by_admin` is true. Confidence: High.

### [VAL-COM-002] P2 — Permission-config uniqueness (BR-COM-036) not validated at the request layer
- **Location:** `app/Http/Controllers/ChatPermissionConfigController.php:39-54` (store) and `:108-123` (update)
- **Evidence:** No `unique` rule on `(permission_for_role_id, permission_for_user_id, allowed_whom_to_connect_with)`; relies solely on the DB unique index `uq_cht_permission_config_role_user`.
- **Why it's a risk:** A duplicate rule yields an unhandled `QueryException` (500) instead of the graceful "creation refused" required by REQ-COM-017 / BR-COM-036.
- **Fix:** Add a `Rule::unique(...)->where(...)` (ignoring soft-deleted/the current id on update). Confidence: High.

### [SEC-COM-003] P2 — AJAX controller bypasses the Policy layer (inconsistent authorization surface)
- **Location:** `app/Http/Controllers/ChatAjaxController.php` (all actions)
- **Evidence:** Web controllers use `Gate::authorize('view'|'message'|'create'|'moderate', ...)`; the AJAX controller uses only `abort_unless(auth()->check(),401)` + participant `firstOrFail()` for IDOR. It never calls the `tenant.chat.*` permission gates.
- **Why it's a risk:** The two front-ends apply different authorization. IDOR is mostly covered by the participant lookup, but capability gates (e.g. `tenant.chat.message`, announcement post-restriction) and `is_deactivated_by_admin` are not consulted on the AJAX path → a user lacking `tenant.chat.message` can still send via `/chat/ajax/...`. Announcement post-restriction IS only in `ChatConversationPolicy::message` (not re-checked in `ChatService::sendMessage`), so the AJAX send path does not enforce "only admins post in Announcements" (REQ-COM-005 / BR-COM-014).
- **Fix:** Route AJAX sends through the same policy gate (or move the announcement/role checks into `ChatService::sendMessage`). Confidence: High.

### [PERF-COM-001] P2 — Message search uses `LIKE %term%` with no FULLTEXT index
- **Location:** `app/Http/Controllers/ChatMessageController.php:121-135`
- **Evidence:** `->where('body','like',"%{$query}%")` over `cht_messages`.
- **Why it's a risk:** Leading-wildcard LIKE cannot use an index; full scan on the highest-growth table as volume rises (GAP-COM-012). The membership gate + 50-row cap limit blast radius today.
- **Fix:** Add a FULLTEXT index and `MATCH ... AGAINST`, or external search. Confidence: Medium.

### [SCH-COM-001] P2 — D29: three raw ENUMs instead of `sys_dropdown` FK
- **Location:** `cht_conversations.conversation_type` (:17), `cht_participants.role` (:16), `cht_messages.message_type` (:17)
- **Why it's a risk:** Platform convention (D29) is dropdown-FK, not ENUM; ENUMs require migrations to evolve. These three are small/code-gated, so lower priority — but they count against D29. Confidence: High.

### [TEST-COM-001] P2 — Zero automated tests
- **Location:** `Modules/CommonChat/tests/` (empty)
- **Why it's a risk:** No coverage on DM-uniqueness, permission resolution, receipt fan-out, retention purge, reply integrity — exactly the areas with defects above. GAP-COM-001.
- **Fix:** Pest feature tests for the P0/P1 paths. Confidence: High.

---

## P3 Findings
- **[DEAD-COM-001] P3** — `app/Http/Controllers/CommonChatController.php` is an untouched scaffold: `store/update/destroy` empty (`:29,:50,:55`), `create/edit/show` return views (`commonchat::create/edit/show`) that do not exist. It is wired to `routes/api.php` `apiResource commonchats` and that group (`RouteServiceProvider::mapApiRoutes`) has **no tenancy middleware** (only `api`). It's a dead, broken stub — remove the controller + route, or implement. GAP-COM-011. (The real mobile API in `routes/mobile_api.php` IS correctly tenant-scoped — see below.)
- **P3** — `$request->all()` passed to `ChatService` at `ChatAjaxController:197,363`, `Mobile/MobileChatController:149`, `Mobile/MobileChatMessageController:100`. Currently safe because the service rebuilds explicit attribute arrays (no privilege field reaches a model `create`), but it is the D25 pattern — prefer `$request->validated()`.
- **P3** — `is_deactivated_by_admin` is in `ChatPersonalizationSettings::$fillable` (mass-assignable). Safe today (web update whitelists), but a latent privilege field — guard it or remove from fillable.
- **P3** — `cht_permission_config` and `cht_personalization_settings` use `$table->increments('id')` (INT signed PK) — platform Layer-2.3 norm; prefer `id()`.
- **P3** — `{!! config('commonchat.name') !!}` in `resources/views/index.blade.php:4` (scaffold view; config value, not user input — safe).

---

## Layer Health Summary
| Layer | Status | Key finding |
|------|--------|-------------|
| 1 DDL Schema | Amber | Invalid ENUM default (DATA-COM-002); 3 ENUMs (SCH-COM-001); INT PKs |
| 2 Migration↔Model↔DDL | **Red** | P0 `sys_roles` FK (MIG-COM-001); body 2000 vs 5000 (DAT-COM-001) |
| 3 Model & ORM | Green | Casts/fillable correct; relationships sound |
| 4 Code Quality | Amber | PII Log::debug (BUG-COM-003); dead scaffold (DEAD-COM-001) |
| 5 Authorization | Amber | Web policies good; moderation role-slug bug (BUG-COM-001); AJAX bypasses gates (SEC-COM-003) |
| 6 Multi-Tenancy | Amber | Web + mobile tenancy correct; public-disk attachments break isolation/auth (SEC-COM-001); api stub group no tenancy |
| 7 Validation/Mass-assign | Amber | Reply integrity unenforced (VAL-COM-001); uniqueness not validated (VAL-COM-002); FormRequests authorize() are real (not D30) |
| 8 Data Integrity/Tx | Amber | Good transactions in send/markRead/createDm/createGroup; body truncation; cross-conversation reply |
| 9 Performance | Amber | LIKE search (PERF-COM-001); paginated lists + eager loads otherwise healthy |
| 10 Queue/Job | **Red** | Purge scheduled centrally, non-functional per-tenant (JOB-COM-001) |
| 11 Frontend | Green | `{!! nl2br(e($body)) !!}` correctly escapes (good pattern); CSRF via forms |
| 12 Deployment | **Red** | P0 migration blocker; public attachment exposure |

## STEP 1 Reading-Discipline Output — three-way reconcile (DDL ↔ migration ↔ model)
| Item | DDL/Migration | Model | Reconcile |
|------|---------------|-------|-----------|
| `cht_messages.body` | migration VARCHAR(2000) | fillable `body`; rules max:5000 | **MISMATCH → DAT-COM-001** |
| `cht_messages.message_type` | ENUM(...) default `'text'` | cast `string`; service writes capitalised | invalid default → DATA-COM-002 |
| `cht_conversations.dm_pair_hash` | VIRTUAL generated col + UNIQUE (raw DDL, line 50) | not in fillable (correct) | **Correct D36 pattern** (generated col actually emitted; never written by code) — good |
| `cht_conversations` CHECK (name-by-type) | present (line 54) | enforced | OK (MySQL 8.0.16+) |
| `cht_permission_config` FKs → `sys_roles` | constrained (lines 32,36) | — | **`sys_roles` migration absent → MIG-COM-001 (P0)** |
| `cht_message_receipts` | has `created_at/updated_at`, no `created_by/deleted_at` | matches | OK (append/update-read_at only) |
| Snapshot correction | module-knowledge said attachment MIME/size "not enforced" | live `ChatAjaxController:167-194` **does** enforce MIME allow-list + per-setting size, and `storeAttachment:481` **does** create `cht_attachments` | snapshot stale on the AJAX path; the *web* `StoreMessageRequest` path still hardcodes `max:10240` and the service does not persist attachments (only AJAX/mobile do) |

## FRD Gap Summary (Mode B) — REQ → status
| REQ | Status | Note (finding) |
|-----|--------|----------------|
| 001 Dashboard | DONE | paginated 20, pinned-first, excludes left/archived |
| 002 Direct msg | DONE | one-DM-per-pair via generated hash + pre-check |
| 003 Group | PARTIAL | off-by-one (BUG-COM-002) |
| 004 Membership mgmt | PARTIAL | no system messages (GAP-COM-009) |
| 005 Announcement | PARTIAL | post-restriction only in policy, not service → AJAX bypass (SEC-COM-003) |
| 006 Composer/reply | PARTIAL | reply integrity unenforced (VAL-COM-001) |
| 007 Attachments | PARTIAL (AJAX/mobile) | public-disk exposure (SEC-COM-001); web path incomplete |
| 008 Receipts | DONE | fan-out batch insert in tx |
| 009 Unread/mark-read | DONE | single tx; atomic increment |
| 010 Search | DONE | LIKE only (PERF-COM-001) |
| 011 Mute/pin/archive | DONE | pin cap 5 enforced |
| 012 Notifications | NOT STARTED | BUG-COM-005 |
| 013 Presence | DONE | upsert heartbeat |
| 014 Soft-delete | PARTIAL | works, but moderation broken (BUG-COM-001); no audit (BUG-COM-004) |
| 015 Personalisation | DONE | lazy create from defaults |
| 016 School config | DONE | singleton firstOrFail; max 500 validated |
| 017 Permission config | DONE | full CRUD; uniqueness not validated (VAL-COM-002); role-name mismatch (BUG-COM-006) |
| 018 Moderation console | PARTIAL | view ok; delete broken (BUG-COM-001) |
| 019 Audit log | NOT STARTED | BUG-COM-004 |
| 020 Retention purge | PARTIAL | command exists but scheduled centrally (JOB-COM-001) |
| 021 Mobile API | DONE | tenant-scoped + sanctum (verified `routes/api.php:26-52`) |
| 022 Access revocation | PARTIAL | not enforced (SEC-COM-002) |

## Business-Rule Enforcement (Mode C)
| BR | Type | Location | Status | Link |
|----|------|----------|--------|------|
| 004 one DM per pair | Concurrency | generated `dm_pair_hash` UNIQUE + `createDm` pre-check | ENFORCED | — |
| 005 no self DM | Validation | `canInitiateDm:22` | ENFORCED | — |
| 006/007 permission resolution | Permission | `checkPermissionConfig` | PARTIAL | BUG-COM-006 |
| 008 min 3 members | Validation | `createGroup:220` | ENFORCED | — |
| 009 name-by-type | Validation | DB CHECK (conversations:54) | ENFORCED | — |
| 010 max members | Validation | `createGroup:224` | PARTIAL (off-by-one) | BUG-COM-002 |
| 011 creator removal | Workflow | `removeParticipant:429` | ENFORCED | — |
| 012 last-admin auto-promote | Workflow | `leaveGroup:463` | ENFORCED | — |
| 013 both active | Validation | `canInitiateDm:26` (recipient only; initiator not re-checked) | PARTIAL | minor |
| 014 announcement post | Permission | `ChatConversationPolicy::message:48` only | PARTIAL | SEC-COM-003 (AJAX bypass) |
| 015 plain text/XSS | Validation | view escapes via `e()` | ENFORCED (output) | no server-side strip, but escaped on render |
| 016 max 5000 | Validation | rules max:5000 | ENFORCED at request, **broken at DB** | DAT-COM-001 |
| 017 body-or-attachment | Validation | `StoreMessageRequest::withValidator` | ENFORCED | — |
| 018 reply same conversation | Validation | — | **MISSING** | VAL-COM-001 |
| 019 reply depth 1 | Validation | — | **MISSING** | VAL-COM-001 |
| 020 no send to archived | Workflow | `sendMessage:266` | ENFORCED | — |
| 021/022 attachment type/size | Validation | `ChatAjaxController:167-194` (AJAX); web path hardcoded | PARTIAL | SEC-COM-001 |
| 024 unread only non-muted | Workflow | `sendMessage:321` `isMuted()` | ENFORCED | — |
| 025 receipt fan-out | Workflow | `sendMessage:305-328` | ENFORCED | — |
| 028 mark-read in one tx | Concurrency | `markAsRead:348` | ENFORCED | — |
| 032 sender/moderator delete | Permission | `deleteMessage:365` | PARTIAL (role-slug bug) | BUG-COM-001 |
| 033/034 singleton + cap 500 | Validation | `ChatSettings::firstOrFail` + rules max:500 | ENFORCED | — |
| 036 permission rule unique | Validation | DB index only | PARTIAL | VAL-COM-002 |
| 037/038 audit immutable + hash | Workflow | — | **MISSING** | BUG-COM-004 |
| 039 retention purge | Workflow | command exists, mis-scheduled | PARTIAL | JOB-COM-001 |
| 040 deactivation block | Permission | — | **MISSING** | SEC-COM-002 |

## Systemic-Pattern Scorecard (Mode D, scoped)
| Pattern | Present? | Count / note |
|---------|----------|--------------|
| Layer 2.5 cross-DB/missing FK target | **YES (P0)** | 2 FKs → missing `sys_roles` (MIG-COM-001) |
| D17 fillable vs columns | No | fillable matches migrations |
| D24 permission-prefix/role-name chaos | **YES** | 3 role conventions (BUG-COM-001/006); gate prefix `tenant.` is consistent (good) |
| D25 `$request->all()` into models | Partial | 4 sites, all filtered by service (P3) |
| D29 ENUM in migrations | **YES** | 3 ENUMs (SCH-COM-001) |
| D30 FormRequest `authorize(){return true;}` | **No** | All 5 FormRequests delegate to policies (`->can(...)`) — better than platform norm |
| D36 generated column degraded | No | `dm_pair_hash` correctly emitted as VIRTUAL + UNIQUE |
| Layer 6.2 `initialize()` w/o `end()` | No | none in module |
| Layer 10.1 job tenancy/retry | **YES** | scheduled command lacks per-tenant wrap + retry (JOB-COM-001) |
| TEN-RTG (module-subscription mw) | n/a | web RSP carries full tenancy stack |
| SEC-RTG seeder-routes-unauth | No | seeders not route-exposed in this module |

## vs Platform Baseline
- **Better than norm:** FormRequest `authorize()` are real policy delegations (platform: 437/485 return bare `true`). No `initialize()` leak. Generated column done right (platform: only 1 of ~19 correct). Tenancy stack present on web + mobile.
- **At/that norm:** Adds 2 FKs to the `sys_roles`-missing P0 (platform 17+). 3 ENUMs (platform ~476). INT PKs (platform 428/658).
- **Worse / module-specific:** Public-disk attachment exposure; centrally-scheduled tenant purge; triple role-naming inconsistency; body length DDL/validation mismatch; zero tests.

## Recommended Fix Order
1. **MIG-COM-001 (P0)** — resolve the `sys_roles` FK so tenant migration runs (platform decision: provide `sys_roles` tenant migration or drop the DB FK). *Unblocks deployment.*
2. **SEC-COM-001 (P1)** — move attachments to a private disk + authenticated, membership-gated serve route.
3. **JOB-COM-001 (P1)** — schedule purge via `tenants:run` + `withoutOverlapping/onOneServer`.
4. **BUG-COM-001 + BUG-COM-006 (P1)** — unify role identifiers; fix moderation delete.
5. **DAT-COM-001 (P1)** — align `body` column width with the 5000-char rule.
6. **VAL-COM-001 (P1)** — enforce reply same-conversation + depth-1.
7. **BUG-COM-003 (P1)** — remove PII `Log::debug`.
8. **BUG-COM-004 / BUG-COM-005 (P1)** — implement audit writes + NTF dispatch.
9. P2s: DATA-COM-002, SEC-COM-002/003, VAL-COM-002, PERF-COM-001, TEST-COM-001.
10. P3 hygiene: remove dead `CommonChatController`/`commonchats` route; `validated()` over `all()`.

## Next Steps
```
Audit complete — Health 40/100 (capped: P0 present).  DEPLOY: NO-GO.
1. Fix P0 + schema gaps   → act as DB Architect (sys_roles FK, body width, enum default)
2. Fix P1 code defects    → act as Developer (attachments, purge schedule, moderation, reply integrity, logging)
3. Completeness score     → act as Status_Analyzer
4. Test coverage          → act as Testing Architect (GAP-COM-001)
5. Platform sweep (sys_roles FK)  → re-run Mode D
```
