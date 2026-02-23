



#### 2. Migration Naming Convention

Use descriptive names:
	✅ add_phone_to_users_table
	✅ remove_old_status_column
	❌ alter_users_table
	❌ update_table

#### 3. Git Safety Rules
  - Never commit migration files with .bk extension
  - Never commit renamed migration files
  - Never commit deleted migration files
  - Never commit moved migration files

#### 4. Migration Management

For production deployments:
  ✅ Use php artisan migrate
  ✅ Use php artisan migrate --path=database/migrations/2023_01_01_000000_create_users_table.php
  ❌ Never manually edit production database
  ❌ Never run raw SQL on production

#### 5. Rollback Safety

Before rolling back:
  ✅ Check migration dependencies
  ✅ Test rollback in development
  ✅ Verify data integrity
  ❌ Never rollback without testing
  ❌ Never rollback critical migrations

#### 6. Branching Strategy

All migration changes must go through:
	- Feature Branch → Develop → Staging → Production

#### 7. Review Process

All migration PRs must be reviewed by:
	✅ Senior Developer
	✅ Tech Lead
	✅ QA (if applicable)

#### 8. Consequences of Violation

Violating this policy may result in:
	❌ Data loss
	❌ Production downtime
	❌ Team conflicts
	❌ Codebase instability

#### 9. Exception Handling

Exceptions require:
	✅ Documented approval
	✅ Risk assessment
	✅ Emergency rollback plan

#### 10. Documentation

All migration changes must be documented in:
	✅ Migration file comments
	✅ Changelog
	✅ PR description

#### 11. Testing Requirements

Before merging:
	✅ Run php artisan migrate
	✅ Run php artisan migrate:rollback
	✅ Verify no data loss
	✅ Verify all constraints work

#### 12. Database Backup

Before any migration:
	✅ Create database backup
	✅ Verify backup integrity
	✅ Test restore procedure

#### 13. Migration Cleanup

After migration is stable:
	✅ Keep migration file (immutability rule)
	✅ Remove old SQL scripts
	✅ Update documentation

#### 14. Team Responsibility

Every developer must:
	✅ Follow this policy strictly
	✅ Review others' migration PRs
	✅ Report violations immediately
✅ Participate in migration planning

#### 15. Continuous Improvement

This policy will be reviewed:
	✅ Quarterly
	✅ As needed
	✅ When new tools become available

#### 16. Tools & Automation

Use tools to enforce policy:
	✅ Git hooks for migration naming
	✅ CI/CD checks for migration validation
	✅ Automated rollback testing

#### 17. Migration Types

Allowed:
	✅ Create tables
	✅ Add columns
	✅ Modify columns
	✅ Add indexes
	✅ Add foreign keys

Not allowed:
	❌ Delete tables (without replacement)
	❌ Rename tables (without migration)
	❌ Remove columns (without replacement)
	❌ Modify primary keys

#### 18. Migration History

Maintain clean migration history:

✅ No duplicate timestamps
✅ No skipped timestamps
✅ No reordered migrations

#### 19. Migration Naming Examples

Good:
	php artisan make:migration add_phone_to_users_table
	php artisan make:migration create_posts_table
	php artisan make:migration alter_users_add_avatar_column

Bad:
	php artisan make:migration alter_table
	php artisan make:migration update_users
	php artisan make:migration new_migration

#### 20. Migration Review Checklist

Before merging:
	✅ Migration name follows convention
	✅ No duplicate timestamps
	✅ No skipped timestamps
	✅ All dependencies documented
	✅ Rollback tested
	✅ Data integrity verified
	✅ Production impact assessed
	✅ Backup created
	✅ Documentation updated
	✅ Code reviewed
	✅ CI/CD checks passed

#### 21. Migration Recovery

If migration fails:
	✅ Fix migration file
	✅ Re-run migration
	✅ Verify success
	✅ Update documentation

If rollback needed:
	✅ Test rollback first
	✅ Verify data integrity
	✅ Document rollback reason
	✅ Update migration history

#### 22. Migration Governance Team

Responsible for:
	✅ Policy enforcement
	✅ Training
	✅ Auditing
	✅ Improvement

#### 23. Policy Enforcement

Violations will be handled through:
	✅ Warning
	✅ Retraining
	✅ Performance review
	✅ Disciplinary action (severe cases)

#### 24. Policy Review Schedule

This policy will be reviewed:
	✅ Every 6 months
	✅ After major incidents
	✅ When new tools are adopted

#### 25. Policy Acknowledgment

All developers must:
	✅ Read this policy
	✅ Understand its implications
	✅ Adhere to it strictly
	✅ Sign acknowledgment form

#### 26. Policy Updates

All updates must include:
	✅ Version number
	✅ Date
	✅ Changes made
	✅ Rationale
	✅ Effective date

#### 27. Policy Scope

This policy applies to:
	✅ All Laravel projects
	✅ All developers
	✅ All environments
	✅ All migration files

#### 28. Policy Purpose

To ensure:
	✅ Database stability
	✅ Data integrity
	✅ Smooth deployments
	✅ Codebase maintainability
	✅ Team collaboration

#### 29. Policy Enforcement Contact

For questions or violations:
	✅ Tech Lead
	✅ Engineering Manager
	✅ Database Administrator

#### 30. Policy Acknowledgment Form

I, [Developer Name], acknowledge that I have read, understood, and agree to comply with the PrimeGurukul Database Migration Governance & Git Safety Protocol.


Signature: ____________________

Date: ____________________
