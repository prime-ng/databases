# Lib Account Entry Configs — Business Requirements

## What This Screen Does
Manages accounting integration mappings for library financial events. Each configuration maps a library fine type (optionally scoped to a specific fine slab config) to the correct Accounting Module ledger and account group. This enables the library's financial transactions (fine payments, waivers) to be automatically posted to the correct general ledger accounts in the accounting module.

---

## When This Screen Is Used
- Initial setup of library-accounting integration during deployment.
- Mapping a fine type (e.g., "Late Return Fine", "Lost Book Penalty") to a specific accounting ledger.
- Setting up fine-slab-specific accounting rules (e.g., different ledgers for different fine slabs).
- Deactivating a mapping when a fine type is no longer in use or needs a temporary pause.
- Reviewing all accounting mappings for audit or reconciliation purposes.

## Default Data Load
- Index: Paginated list of all account entry configurations showing name, fine type, slab config, account group, ledger, and active status.
- Create: Blank form with fields for name, fine type, slab config (optional), account group, ledger, and active toggle.
- Edit: Pre-populated form with existing configuration data.
- Show: Read-only display of configuration details.

---

## Key Fields at a Glance

### Table Schema (from `lib_account_entry_configs`)
| Column | Source Table | Notes |
|--------|-------------|-------|
| `name` | Manual input | Unique display name for the config entry |
| `fine_type_id` | `lib_fine_type` | Which fine type this entry config applies to (e.g., LateReturn, LostBook) |
| `fine_slab_config_id` | `lib_fine_slab_config` | Which specific slab config — NULL means applies to all slabs of this fine type |
| `account_group_id` | `acc_account_groups` | Accounting module — the account group for this fine entry |
| `ledger_id` | `acc_ledgers` | Accounting module — the specific ledger to post fine entries to |
| `is_active` | TINYINT(1) | DEFAULT 1, boolean — Soft on/off toggle |

---

## Business Rules and Conditions
1. **Name Uniqueness:** Each account entry config must have a unique `name` (enforced by `UNIQUE KEY uq_lib_aec_name`).
2. **Fine Type Required:** Every config must be linked to a valid fine type (e.g., LateReturn, LostBook). This is mandatory.
3. **Slab Config Applicability:**
   - `fine_slab_config_id` = NULL → This account entry config applies to **ALL fine slab configs** of the given fine type.
   - `fine_slab_config_id` = specific → This config applies **ONLY** to fines generated from that specific slab config.
   - More specific (with slab config) takes priority over a general NULL entry when both match.
4. **Accounting Linkage Required:** Both `account_group_id` and `ledger_id` are mandatory — a fine cannot be posted to accounts without both being defined.
5. **Duplicate Prevention:** The combination of `fine_type_id` + `fine_slab_config_id` + `account_group_id` + `ledger_id` must be unique — no two configs can have the same four-field combination (enforced by composite UNIQUE KEY).
6. **Active/Inactive:** Inactive configurations are skipped by the accounting event dispatcher; no journal entries are generated for inactive configs.
7. **Soft Delete:** Deleting an entry config soft-deletes it (`deleted_at` set to current timestamp). A soft-deleted config must not be used for any new accounting entries.
8. **Restore:** Bringing back a deleted entry config reactivates the mapping.
9. **Usage Trigger (Lookup Logic):** This config is looked up automatically when:
   - A fine payment is recorded in `lib_fine_payments`.
   - A fine is waived.
   - In both cases, the system identifies the fine type + slab config of the fine, finds the matching account entry config, and posts the entry to the corresponding ledger.
   - Lookup priority: Step 1 finds config where `fine_type_id` matches AND (`fine_slab_config_id` = fine's slab OR is NULL) AND `is_active = 1` AND `deleted_at IS NULL`. Step 2 prefers the specific (non-NULL slab) over the general one.

---

## Workflow Steps
1. Admin navigates to Library Account Entry Configurations.
2. Admin views the list of all fine-type-to-account mappings.
3. Admin clicks "Add Config" to create a new mapping.
4. Admin enters a unique name, selects the fine type, optionally selects a specific slab config, selects the account group and ledger from the Accounting module, and sets active status.
5. System validates uniqueness of name and the four-field combination.
6. Admin can edit mappings to reassign ledgers or account groups.
7. Admin can toggle active status to temporarily stop/pause a mapping.
8. Admin can soft-delete a mapping when the fine type is retired.

---

## Example Scenario
**Setting up Late Return fine accounting:**
1. Admin creates an entry config: name = "Late Return - Standard Slab", fine_type = `LateReturn`, slab_config = "Standard Late Fee", account_group = "Library Fines Revenue", ledger = "4100-LIB-FINES".
2. When a member pays a late return fine, the system finds this config by matching the fine's fine_type_id and slab_config_id.
3. A journal entry is created: Credit ledger `4100-LIB-FINES`, Debit accounts receivable.
4. Admin creates a second, more general config with slab_config = NULL for the same fine type as a fallback.
5. Later, Admin changes the ledger to `4105-LIB-FINES-NEW` and deactivates the old mapping.

---

## Related Screens
- **Fine Types** — Defines the fine categories referenced by `fine_type_id`.
- **Fine Slab Config** — Optional slab-specific scoping via `fine_slab_config_id`.
- **Accounting Module (Account Groups)** — Provides `account_group_id` reference.
- **Accounting Module (Ledgers)** — Provides `ledger_id` reference.
- **Library Fines & Payments** — The consumer that triggers accounting entry lookup.

---

## Requirements
(technical: controller, model, validation, activityLog, policy)

- **Controller:** `LibAccountEntryConfigController` — Standard CRUD. Index lists all mappings. No special AJAX endpoints beyond toggleStatus.
- **Model:** `LibAccountEntryConfig` — table `lib_account_entry_configs`, fillable: `name`, `fine_type_id`, `fine_slab_config_id`, `account_group_id`, `ledger_id`, `is_active`. Relationships: `fineType()` belongsTo `LibFineType`, `fineSlabConfig()` belongsTo `LibFineSlabConfig`.
- **Validation (FormRequest):** `name` => required|string|max:255|unique:lib_account_entry_configs,name; `fine_type_id` => required|exists:lib_fine_type,id; `fine_slab_config_id` => nullable|exists:lib_fine_slab_configs,id; `account_group_id` => required|exists:acc_account_groups,id; `ledger_id` => required|exists:acc_ledgers,id; `is_active` => boolean.
- **ActivityLog:** Must call `activityLog()` after create, update, delete, restore, forceDelete.
- **Policy:** Gate string `tenant.lib-account-entry-configs.*` mapped to `LibAccountEntryConfigPolicy`.
- **Permissionslist entry:** `'lib-account-entry-configs' => $crud`

---

## Who Can Access This Screen
- Users with `tenant.lib-account-entry-configs.viewAny` — list page and tab visibility.
- Users with `tenant.lib-account-entry-configs.create` — add button and store.
- Users with `tenant.lib-account-entry-configs.view` — show/details page.
- Users with `tenant.lib-account-entry-configs.update` — edit, update, toggle status.
- Users with `tenant.lib-account-entry-configs.delete` — soft delete.
- Users with `tenant.lib-account-entry-configs.restore` — trash view and restore.
- Users with `tenant.lib-account-entry-configs.forceDelete` — permanent delete.

---

## How This Screen Works — Logic Flow (Non-Technical)
1. User opens the Account Entry Configurations page.
2. The system loads all fine-type-to-account mappings and displays them in a table.
3. Each row shows the config name, fine type, optional slab config, account group, ledger, and a status toggle.
4. The user can add a new mapping by clicking "Add Config." They enter a unique name, select the fine type, optionally scope it to a specific slab config, and select the target account group and ledger.
5. The system checks that the name is unique and no other mapping has the same four-field combination.
6. After saving, the mapping is active. When a fine payment is recorded or a fine is waived, the system automatically looks up this mapping and posts the accounting entry.
7. If a fine type needs a different ledger for different slabs, the user creates multiple configs with slab-specific scoping.
8. If a mapping is no longer needed, the user toggles it inactive or deletes it.

---

## Validate Before Save
1. `name` is required, must be a string ≤255 characters, and must be unique.
2. `fine_type_id` is required and must reference an existing fine type.
3. `fine_slab_config_id` is optional; if provided, must reference an existing slab config.
4. `account_group_id` is required and must reference an existing account group in the Accounting module.
5. `ledger_id` is required and must reference an existing ledger in the Accounting module.
6. `is_active` is a boolean flag.
7. Update validation excludes the current record from the unique `name` check.
8. The four-field combination `(fine_type_id, fine_slab_config_id, account_group_id, ledger_id)` must be unique.

---

## Error Handling and Validation Messages
| Condition | Message |
|-----------|---------|
| Name missing | "The name field is required." |
| Name duplicate | "The name has already been taken." |
| Name too long | "The name must not be greater than 255 characters." |
| Fine type missing | "The fine type field is required." |
| Invalid fine type | "The selected fine type is invalid." |
| Invalid slab config | "The selected fine slab config is invalid." |
| Account group missing | "The account group field is required." |
| Invalid account group | "The selected account group is invalid." |
| Ledger missing | "The ledger field is required." |
| Invalid ledger | "The selected ledger is invalid." |

---

## Success Scenarios
1. **Create:** Valid mapping saved. Redirect to list with "Account Entry Config created successfully."
2. **Update:** Modified mapping saved. Redirect to list with "Account Entry Config updated successfully."
3. **Toggle Status:** AJAX toggles `is_active`. Returns `{success: true, is_active: bool}`.
4. **Soft Delete:** Record soft-deleted. Success message displayed.
5. **Restore:** Record restored. Success message displayed.
6. **Force Delete:** Record permanently removed. Success message.

---

## Failure Scenarios
1. **Create with duplicate name:** Validation fails, "The name has already been taken."
2. **Create with missing fine type:** "The fine type field is required."
3. **Create with duplicate four-field combination:** Composite unique constraint violation at DB level.
4. **Force delete non-existent record:** `findOrFail` throws 404.
5. **Edit with name changed to another existing value:** Unique validation fails.

---

## Dependencies module and tables
| Dependency | Type | Details |
|-----------|------|---------|
| `lib_account_entry_configs` | Table | Primary table for this feature |
| `lib_fine_type` | Table | FK reference for `fine_type_id` |
| `lib_fine_slab_configs` | Table | FK reference for `fine_slab_config_id` (nullable) |
| `acc_account_groups` | Table (Accounting module) | FK reference for `account_group_id` |
| `acc_ledgers` | Table (Accounting module) | FK reference for `ledger_id` |
| `lib-account-entry-configs` | Permission | CRUD permissions defined in `permissionslist.php` |
| `LibAccountEntryConfigPolicy` | Policy | Authorization policy mapped to `tenant.lib-account-entry-configs.*` |
