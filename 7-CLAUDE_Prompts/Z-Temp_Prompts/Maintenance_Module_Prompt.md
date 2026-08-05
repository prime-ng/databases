# Maintenance Module Prompt

## Prompt:
I want to create a complete Mainitenance Management Module for the database and Images of my Application Prime-AI. Where we will keep Backup of all required files (Databse, Images, Vedios, PDF etc.) for a certain period. After that Pre-defined period, we can remove the old Backup or we can extend the period on request basis. High Level fuctionalities which I want to cover in the Module are as below.

I have created a DDL Schema to capture detail for Maintenance Module. Below are some Fuctionalities which needs to be covered in the Module:
- We can Schedule different maintenance plans for different Schools (Tenants)
- It should capture the detail of all the activities related to Maintenance (Backup & Restore)
- It should capture the information about all the Backups, that have been performed in the history.
- Information Related to the Backup are included but not limited to :
    - Backup File Storage Location (Path, File name, etc.)
    - File Info (Size, type etc.)
    - Scheduling (Started at, Completed at, Status etc.)
    - Who raise the Request and When
    - Tenant detail (Tenant Name, Code, DB Name etc.)
- It should capture the complete Log for all the activities of backup Module.
- It need to facilitate to Tennt that they can raise request to access Archived Database for a certain period
- Backup will be kept for a certain period but Tenant can demand (Paid Service) to extend the duration of keeping their data safe.
- We can extend the Backup End Date, If requested by Tenant.
- Include any other point which I may missed.

Now I want you to check the Maintenance Module DDL from "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/2-DDL_Tenant_Enhanced/Maintenance_DDL_v1.sql", evauate it and enhance it if required. Save the final DDL file as "/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Modules/Maintenance/Maintenance_DDL_v2.sql". Also create below 2 file and save into same folder:
- Data Disctory for the enhanced DDL - Explain each Field of every table, what is the use of it and wh it required.
- Process Flow - Generate a file to capture complete Process flow of Maintenance Module

## Responce:
Now let me examine the surrounding conventions — the central DB tables this module must reference, and an existing v2 DDL for format reference.

  Searched for 1 pattern, read 1 file, listed 3 directories, ran 5 shell commands

I have the full picture now. Let me record the evaluation findings and write the three files.

>> Write(Maintenance_DDL_v2.sql)

Let me verify the DDL structurally before writing the companion docs.

  Searched for 1 pattern, ran 2 shell commands

No local MySQL to parse against, so that check is structural only. Now the Data Dictionary — starting with the header and Layer 1.

>> Write(Maintenance_Data_Dictionary_v2.md)

>> Write(Maintenance_Process_Flow_v2.md)

All three files are in 1-DDL_Modules/Maintenance/.

Evaluation of v1

v1 would not have run. Four hard errors:
- mnt_tenant_archive_access_requests had a ; where a , belonged mid-CREATE TABLE
- Its UNIQUE KEY referenced tenant_id — a column that was commented out
- approved_by_user_id was BIGINT UNSIGNED while sys_users.id is INT UNSIGNED, so no FK was possible (and none was declared)
- requested_by_tenant_user_id was an orphan column with no target

Plus: created_by used ON DELETE CASCADE — deleting a staff member would have deleted their backup schedules. And it declared global_db, but every anchor it needs (sys_users, prm_tenant, bil_tenant_invoices) lives in prime_db; a backup catalogue also must not sit inside the databases it protects. Retargeted to prime_db.

Functionally, v1 covered roughly 20% of your requirement. Retention was entirely absent — no policy, no end date, no purge, no extension, which is the core of what you asked for. There was also no restore side, no activity log, no per-tenant detail (databases_json as a blob can't answer "did school X succeed on 12-Jul?"), no file catalogue, and no integrity data.

v2 — 3 tables → 20, in 6 layers

Config masters → scheduling → execution catalogue (run → item → file) → restore → retention/archive/purge → observability. The three-level catalogue is what makes per-school, per-file questions answerable at all.

retention_end_date on mnt_backup_run_items is your "Backup End Date". original_retention_end_date sits beside it, written once and never touched, so the original entitlement stays provable. A CHECK constraint makes it impossible for an "extension" to shorten retention. Extensions are quoted from a price book on the policy, invoiced through your existing bil_tenant_invoices, and applied per-item through a junction table that stores previous_end_date — so a refund reverses exactly, without guessing.

Beyond what you listed, the significant additions: pre-restore safety backup (mandatory before any overwrite, and the rollback source), legal hold, backup verification and test-restore drills, five purge safety gates, dual approval with no self-approval on destructive restores, incremental chain protection, offsite/3-2-1, encryption key references rather than keys, expiry warnings with a dedupe key, and daily per-tenant storage snapshots so GB-month billing uses the average rather than the peak.

Two things to flag

Prefix collision. 1-DDL_Modules/_Maintenance/ holds a different MNT module — physical asset/ticket/AMC maintenance, also mnt_, but in tenant_db. Different databases, so no hard collision, but I'd recommend renaming this one to bkp_. I kept mnt_ to stay aligned with module_list.md — your call.

Validation is structural only. No MySQL binary in this environment, so I verified 20 balanced CREATE TABLE statements, no duplicate constraint names, and every FK target resolving to a real table — but the DDL has not been parsed by a live server. Worth one mysql --execute against a scratch schema before you commit it.

✻ Crunched for 37m 7s

※ recap: Goal was rebuilding the Maintenance backup module schema; I delivered Maintenance_DDL_v2.sql (20 tables), the data dictionary, and the process flow in 1-DDL_Modules/Maintenance/. Next: run the DDL against a scratch MySQL schema to confirm it parses. (disable recaps in /config)

---------------------------------------------------------------------------------------------------------------------------------