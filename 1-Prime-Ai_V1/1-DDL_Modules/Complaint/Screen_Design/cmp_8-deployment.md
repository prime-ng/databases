# Complaint Management Module - Deployment & Runbook (Deliverable H)

## 1. Deployment Checklist

### 1.1 Pre-Deployment
- [ ] **Database**: Backup `tenant_db`. Run `cmp_complaint_management_v2.0.sql`.
- [ ] **Environment**: Set `AI_SERVICE_API_KEY` in `.env` for Sentiment Analysis.
- [ ] **Storage**: Run `php artisan storage:link` to ensure evidence files are accessible.

### 1.2 Configuration
- [ ] **SLA Matrix**: Admin must log in and configure "Level 1" to "Level 5" roles for "Transport" and "Academic" categories.
- [ ] **Queues**: Start Supervisor for `sla_escalation_queue` (Priority High).

### 1.3 Monitoring
- [ ] **Health Check**: Endpoint `/api/health/complaints` should return 200 OK.
- [ ] **Logs**: Watch `laravel.log` for "SLA Job Failed" errors.

---

## 2. Disaster Recovery
- **Scenario**: AI Service Outage.
- **Impact**: Sentiment scores missing.
- **Failover**: System defaults to Manual Review. Queue jobs retry automatically after 1 hour.
- **Recovery**: Once API is up, run `php artisan complaints:reprocess-ai` to backfill scores.

## 3. Rollback Plan
1.  **Revert Code**: Checkout previous git tag.
2.  **Revert DB**: Restore `cmp_` tables from backup.
    *   *Warning*: Any tickets created during the failed window will be lost unless manually exported first.
