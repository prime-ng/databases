# Screen Design Specification: Data Migration Jobs
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Track blue-green deployment and data migration jobs between environments (dev, staging, production). Backed by `tpt_data_migration_jobs`.

### 1.2 User Roles & Permissions
| Role | Create | View | Update | Delete | print | Export | Import |
|------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| PG Support   |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| School Admin |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✗    |  ✗    |
| Principal    |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✗    |  ✗    |
| Teacher      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Student      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Parents      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |

### 1.3 Data Context

Database Table: `tpt_data_migration_jobs`
├── id (BIGINT PRIMARY KEY)
├── job_name (VARCHAR)
├── migration_type (ENUM: BLUE_GREEN, BACKUP_RESTORE, DATA_SYNC, SCHEMA_UPGRADE, ARCHIVE)
├── source_environment (VARCHAR)
├── target_environment (VARCHAR)
├── status (ENUM: QUEUED, IN_PROGRESS, COMPLETED, FAILED, ROLLED_BACK)
├── total_records (BIGINT)
├── migrated_records (BIGINT)
├── failed_records (BIGINT)
├── started_timestamp (DATETIME, nullable)
├── completed_timestamp (DATETIME, nullable)
├── duration_seconds (INT, nullable)
├── error_message (TEXT, nullable)
├── rollback_available (BOOLEAN)
├── created_by (FK -> `hrm_employees.id`)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Migration Jobs Dashboard
**Route:** `/transport/migrations`

#### 2.1.1 Layout (Job Tracking)
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > DATA MIGRATION JOBS                                  │
├──────────────────────────────────────────────────────────────────┤
│ STATUS: [All ▼]  TYPE: [All ▼]  DATE: [Last 30 days ▼]        │
│ [+ Create Job] [View Logs] [Export] [Rollback]                 │
├──────────────────────────────────────────────────────────────────┤
│
│ ┌─ IN PROGRESS ────────────────────────────────────────┐
│ │ 🔄 BLUE_GREEN: Production Migration (Job-2025-042)
│ │ Source: Staging → Target: Production
│ │ Start: 2025-12-01 00:30 AM
│ │ Progress: 450,000 / 500,000 records (90%)
│ │ Estimated Time: 5 minutes remaining
│ │ [Monitor] [Cancel] [View Logs]
│ │
│ └───────────────────────────────────────────────────────┘
│
│ ┌─ COMPLETED ──────────────────────────────────────────┐
│ │ ✓ BLUE_GREEN: Dev to Staging (Job-2025-041)
│ │ Duration: 12 minutes 34 seconds
│ │ Records: 450,000 migrated successfully
│ │ Completed: 2025-11-30 11:45 PM
│ │ Rollback: Available (expires in 7 days)
│ │ [View Details] [Rollback] [Archive]
│ │
│ └───────────────────────────────────────────────────────┘
│
│ ┌─ FAILED ─────────────────────────────────────────────┐
│ │ ✗ BACKUP_RESTORE: Staging Recovery (Job-2025-040)
│ │ Error: Connection timeout
│ │ Status: FAILED (2025-11-28 10:15 AM)
│ │ [View Error Log] [Retry] [Cancel]
│ │
│ └───────────────────────────────────────────────────────┘
│
│ [View All Jobs] [Schedule Next Migration]
│
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Create Migration Job
#### 2.2.1 Job Configuration
```
┌────────────────────────────────────────────────┐
│ CREATE MIGRATION JOB                        [✕]│
├────────────────────────────────────────────────┤
│ Job Name *               [Prod Migration v2.5]│
│ Migration Type *         [BLUE_GREEN ▼]       │
│                          BLUE_GREEN / BACKUP_RESTORE
│                          DATA_SYNC / SCHEMA_UPGRADE
│
│ ENVIRONMENTS
│ Source Environment *     [Staging ▼]          │
│ Target Environment *     [Production ▼]       │
│
│ VALIDATION
│ Source Available: ✓
│ Target Available: ✓
│ Estimated Records: 500,000
│ Estimated Duration: 15–20 minutes
│
│ MIGRATION SCOPE
│ Entities to Migrate:
│ ☑ tpt_trips
│ ☑ tpt_vehicles
│ ☑ tpt_drivers
│ ☑ tpt_routes
│ ☑ ml_models
│
│ PRE-MIGRATION
│ ☑ Validate data integrity
│ ☑ Create backup
│ ☑ Notify stakeholders
│
│ POST-MIGRATION
│ ☑ Verify record counts
│ ☑ Run smoke tests
│ ☑ Enable rollback window
│
│ APPROVAL
│ Requested By: Admin User
│ Approved By: [Select ▼]
│
├────────────────────────────────────────────────┤
│ [Cancel]  [Validate]  [Submit for Approval]   │
└────────────────────────────────────────────────┘
```

### 2.3 Migration Progress Monitor
#### 2.3.1 Live Progress
```
┌────────────────────────────────────────────────────────┐
│ MIGRATION IN PROGRESS                               [✕]│
├────────────────────────────────────────────────────────┤
│ JOB: Production Migration v2.5 (Job-2025-042)
│ Status: IN_PROGRESS
│ Type: BLUE_GREEN (Staging → Production)
│ Started: 2025-12-01 00:30:15 AM
│
│ PROGRESS
│ ┌────────────────────────────────────────────┐
│ │████████████████░░░░░░░░░░░░░░░░░░░░░░░░░ │ 90%
│ └────────────────────────────────────────────┘
│ 450,000 of 500,000 records migrated
│ Failed: 0 | Skipped: 0
│
│ DETAILED PROGRESS (by entity)
│ ├─ tpt_trips: 95,000/100,000 (95%)
│ ├─ tpt_vehicles: 2,500/2,500 (100%) ✓
│ ├─ tpt_drivers: 125/125 (100%) ✓
│ ├─ tpt_routes: 50/50 (100%) ✓
│ └─ ml_models: 5/5 (100%) ✓
│
│ PERFORMANCE
│ Current Rate: 1,500 records/sec
│ Elapsed Time: 5 minutes 30 seconds
│ Estimated Remaining: 3 minutes 45 seconds
│ ETA Completion: 00:39:30 AM
│
│ SYSTEM HEALTH
│ Source DB CPU: 35% | Memory: 42%
│ Target DB CPU: 48% | Memory: 56%
│ Network: 95 Mbps
│
│ [Pause] [Resume] [Cancel] [View Logs]
│
└────────────────────────────────────────────────────────┘
```

### 2.4 Rollback Option
#### 2.4.1 Rollback Control
```
┌────────────────────────────────────────────────────┐
│ ROLLBACK MIGRATION                              [✕]│
├────────────────────────────────────────────────────┤
│ Job: Production Migration v2.5 (Job-2025-041)
│ Status: COMPLETED
│ Completed: 2025-11-30 11:45 PM
│ Records Migrated: 450,000
│
│ ROLLBACK AVAILABILITY
│ Status: AVAILABLE
│ Backup Created: 2025-11-30 00:30 AM
│ Expires In: 6 days 18 hours
│ Estimated Rollback Time: 8–12 minutes
│
│ PRE-ROLLBACK CHECKLIST
│ ☐ Confirm data integrity post-migration acceptable
│ ☐ Notify users (system will be unavailable)
│ ☐ Schedule rollback during maintenance window
│
│ CONFIRMATION
│ I understand that rolling back will:
│ • Restore production data to state at 2025-11-30 00:30 AM
│ • Discard any changes made after migration
│ • Take 8–12 minutes (system unavailable)
│ ☐ I confirm and understand
│
│ [Cancel]  [Initiate Rollback]
│
└────────────────────────────────────────────────────┘
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Migration Job
```json
POST /api/v1/transport/migrations
{
  "job_name": "Prod Migration v2.5",
  "migration_type": "BLUE_GREEN",
  "source_environment": "staging",
  "target_environment": "production",
  "total_records": 500000,
  "rollback_available": true,
  "created_by": 5
}

Response:
{
  "id": 42,
  "job_name": "Prod Migration v2.5",
  "status": "QUEUED",
  "total_records": 500000,
  "created_at": "2025-12-01T00:15:00Z"
}
```

### 3.2 Get Migration Jobs
```json
GET /api/v1/transport/migrations?status={status}&from_date={date}

Response:
{
  "data": [
    {
      "id": 42,
      "job_name": "Prod Migration v2.5",
      "migration_type": "BLUE_GREEN",
      "source_environment": "staging",
      "target_environment": "production",
      "status": "IN_PROGRESS",
      "total_records": 500000,
      "migrated_records": 450000,
      "failed_records": 0,
      "started_timestamp": "2025-12-01T00:30:15Z",
      "progress_percent": 90
    }
  ]
}
```

### 3.3 Monitor Job Progress
```json
GET /api/v1/transport/migrations/{id}/progress

Response:
{
  "id": 42,
  "status": "IN_PROGRESS",
  "progress_percent": 90,
  "migrated_records": 450000,
  "total_records": 500000,
  "failed_records": 0,
  "current_rate": 1500,
  "elapsed_seconds": 330,
  "estimated_remaining_seconds": 225,
  "entity_progress": [
    {
      "entity": "tpt_trips",
      "migrated": 95000,
      "total": 100000,
      "percent": 95
    }
  ]
}
```

### 3.4 Rollback Migration
```json
POST /api/v1/transport/migrations/{id}/rollback
{
  "confirmed": true
}

Response:
{
  "id": 42,
  "status": "ROLLED_BACK",
  "rollback_started": "2025-12-01T12:00:00Z",
  "rollback_completed": "2025-12-01T12:10:30Z"
}
```

---

## 4. USER WORKFLOWS

### 4.1 Plan & Execute Migration
```
1. Admin plans Prod migration (Staging → Production)
2. Clicks [+ Create Job]
3. Fills in source, target, entities to migrate
4. System validates environments are ready
5. Submits for approval
6. Approved by Super Admin
7. Job queued in migration scheduler
8. Migration executes automatically
```

### 4.2 Monitor Migration
```
1. Admin opens [View Logs] during migration
2. Watches real-time progress (90% complete)
3. Monitors system health (CPU, memory, network)
4. Sees entity-level progress (tpt_trips: 95%, etc.)
5. Estimated time remaining displayed
```

### 4.3 Rollback if Issues
```
1. Post-migration, issues discovered
2. Admin opens migration job
3. Clicks [Rollback]
4. Confirms rollback action
5. System restores from backup
6. Production data restored to pre-migration state
7. 8–12 minutes of downtime
```

---

## 5. VISUAL DESIGN GUIDELINES

- Color-code status: QUEUED (gray), IN_PROGRESS (blue), COMPLETED (green), FAILED (red), ROLLED_BACK (orange)
- Progress bar with percentage and record counts
- Real-time metrics (rate, ETA)
- Entity-level progress breakdown

---

## 6. ACCESSIBILITY & USABILITY

- Date/time pickers for filtering
- Dropdown for environment selection
- Progress bar accessible with ARIA attributes
- Keyboard shortcuts: Monitor [M], Logs [L], Cancel [C]

---

## 7. TESTING CHECKLIST

- [ ] Create migration job with all required fields
- [ ] Job status transitions (QUEUED → IN_PROGRESS → COMPLETED)
- [ ] Progress updates in real-time
- [ ] Record counts tracked correctly
- [ ] Failed records handled gracefully
- [ ] Rollback available after completion
- [ ] Rollback restores to pre-migration state
- [ ] Export job history to CSV

---

## 8. FUTURE ENHANCEMENTS

1. Incremental migrations (delta sync only)
2. Scheduled migrations (off-peak only)
3. Multi-environment failover (auto-redirect on failure)
4. Migration analytics (performance trends)
5. Data validation post-migration (automated checks)
6. Partition-level migrations (reduce downtime for large tables)

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
