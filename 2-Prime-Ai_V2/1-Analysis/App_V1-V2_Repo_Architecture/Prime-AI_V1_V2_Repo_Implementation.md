# Prime-AI V1/V2 Repository Separation & Release Management

**Implementation guide · GitHub · Laravel · Web App · Mobile App · 50+ modules**

## Purpose

This document defines the implementation plan for separating the stable Prime-AI demo version from ongoing development, while retaining controlled promotion of tested features and bug fixes between the two repositories.

The objective is not simply to create another Git repository. It is to establish a release-management process that protects the stable application, prevents accidental changes, reduces cross-module regressions, and allows the team to continue development without interruption.

## 1. Final architecture and decisions

Use **two independent repositories with restricted release access, controlled code promotion, and mandatory integration testing**.

### Repository 1 — `prime_ai`

**Purpose:** Development / V2.

- The owner and all four team members work here.
- Developers use individual feature and bug-fix branches.
- The Senior Developer reviews and merges pull requests.
- Integration and regression tests are required before a change is considered release-ready.

### Repository 2 — `prime-ai-release`

**Purpose:** Stable / released versions.

- Access: owner and Senior Developer only.
- The current demo-ready version becomes V1.
- Approved changes enter through a controlled promotion process.
- Each release receives a version tag.
- This repository becomes the authoritative source for released Web, API and Mobile App code, or the source of record for the components it contains.

### Decisions to keep fixed

| Area | Decision |
|---|---|
| Existing repository | Continue as the Development Repository |
| New repository | Create a separate, restricted Release Repository |
| Initial V1 snapshot | Exact commit currently approved for demo |
| Normal development | Existing developer-branch and PR workflow, strengthened with integration gates |
| V2 to V1 | Promote only selected, tested changes |
| V1 bug fixes | Fix in the Release Repository, test, then forward-port to Development |
| Database | Separate demo, development and integration databases |
| Release authority | Owner approves releases; Senior Developer manages technical promotion |
| Tester | Independently validates module functionality and cross-module regression |

**Important:** The two repositories protect against accidental Git changes by developers who lack Release Repository access. They do not, by themselves, protect the running demo from database changes, deployment mistakes, or broken code deliberately promoted by an authorized person. The remaining steps address those risks.

## 2. Before starting: establish the rules

Do not start by renaming branches, deleting old branches, or moving code. First record the current state and establish a recoverable baseline.

### Step 1 — Confirm the repository and milestone

Open the existing Prime-AI repository on GitHub.

Record:

- Repository URL and visibility (private/public).
- Current default branch, expected to be `main`.
- Latest commit that represents the demo-ready application.
- All active developer branches and open pull requests.
- Current Laravel version, PHP version, database connections, and environment configuration.
- Existing deployment location and database used for the demo.

On your Mac, open Terminal and navigate to the existing project:

```bash
cd /path/to/prime_ai
```

Check the current branch and working tree:

```bash
git status
git branch --show-current
git branch -a
git log -10 --oneline --decorate
git remote -v
```

If `git status` shows uncommitted work, **do not reset, discard or overwrite it**. Save or commit the work on the appropriate development branch before continuing.

Fetch the latest remote information:

```bash
git fetch --all --prune
```

Check the latest `main` commit:

```bash
git log -1 origin/main --oneline
```

If the default branch is not named `main`, substitute the actual branch name throughout this guide.

### Step 2 — Freeze the chosen V1 milestone

Choose the exact commit that has been verified as suitable for the demo.

Record its full commit hash:

```bash
git rev-parse origin/main
```

Use the output only if `origin/main` is the approved demo-ready commit. Otherwise, identify the correct approved commit first.

Create a tag on that exact commit:

```bash
git tag -a v1.0.0 <COMMIT_HASH> -m "Prime-AI V1.0.0 Demo Baseline"
git push origin v1.0.0
```

Replace `<COMMIT_HASH>` with the actual hash. Do not type the angle brackets.

This tag records the milestone; it does not create a separate repository or protect the deployed application by itself.

**Do not tag a version as `v1.0.0` until the exact code, database state, configuration, and demo smoke tests have been verified.** If the milestone has not yet been validated, complete the backup and verification steps first.

### Step 3 — Back up the application

Create a backup before repository separation.

At minimum, preserve:

1. A Git bundle containing the repository's reachable Git history.
2. A database dump of the demo database.
3. Any tenant databases needed by the demo.
4. The `.env` configuration, stored securely outside Git.
5. Uploaded files, documents, images, and other required storage assets.
6. A list of currently installed dependencies and deployment settings.

Create a Git bundle from the local repository:

```bash
git bundle create ../prime-ai-pre-split.bundle --all
git bundle verify ../prime-ai-pre-split.bundle
```

This backs up Git history and references included in the bundle, not database contents, uncommitted files, ignored files, or uploaded assets.

For MySQL, a typical logical backup command is:

```bash
mysqldump -u YOUR_DB_USER -p \
  --single-transaction \
  --routines --triggers --events \
  YOUR_DEMO_DATABASE > ../prime-ai-demo-v1.sql
```

Replace the placeholders with the correct database credentials and database name. For a multi-database demo, back up each required database separately. Validate that the backup can be restored before relying on it.

Keep backup files out of your Git repository and store them securely.

### Step 4 — Record the baseline

Create a short release record:

| Field | Example |
|---|---|
| Product | Prime-AI |
| Release | V1.0.0 |
| Source repository | Existing `prime_ai` repository |
| Source commit | Actual full commit hash |
| Release tag | `v1.0.0` |
| Demo database backup | Backup filename and date |
| Demo test status | Pass / Fail |
| Approved by | Owner |
| Release date | Actual release date |

This record will help trace regressions to a particular release.

## 3. Create the new Release Repository

### Step 5 — Create `prime-ai-release`

On GitHub:

1. Open the GitHub account or organization that owns Prime-AI.
2. Click **New repository**.
3. Enter the repository name: `prime-ai-release`.
4. Select **Private**.
5. Do not initialize it with a README, `.gitignore`, or licence. The existing project history will be pushed.
6. Create the repository.

**Do not use GitHub's Fork option.** The goal is an independently managed release repository, not a fork with an upstream permission relationship.

### Step 6 — Grant access only to the required people

Configure access to the Release Repository:

| Person | Required access |
|---|---|
| Owner | Repository owner |
| Senior Developer | Write access |
| Other developers | No access |
| Tester | No access initially |

The tester can test a deployed release candidate without repository write access.

If the existing repository belongs to a personal GitHub account, its private-repository collaborators may have write access rather than a read-only collaborator role. An organization offers more granular roles if required.

**GitHub Free limitation:** GitHub's current documentation lists branch protection for private repositories on Pro, Team and Enterprise plans; Free supports protected branches for public repositories. Do not make proprietary code public just to obtain branch protection. Verify the current plan and documentation before relying on any feature.

The separate private repository prevents developers without access from pushing to V1. If server-enforced PR reviews and blocking direct pushes are required, plan for an eligible GitHub plan and configure the appropriate branch protection. Until then, access restrictions and the operating procedure in this guide are essential.

### Step 7 — Push only the V1 baseline into the new repository

Do this from the existing local clone after confirming the baseline tag and a clean working state.

Inspect remotes:

```bash
git remote -v
```

Keep the existing remote unchanged. Add the new repository under a separate remote name:

```bash
git remote add release https://github.com/YOUR_ACCOUNT/prime-ai-release.git
```

Replace `YOUR_ACCOUNT` with the actual GitHub username or organization.

Fetch and verify the new remote:

```bash
git fetch release
git remote -v
```

Push only the approved V1 tag's commit to the new repository's `main` branch:

```bash
git push release v1.0.0:refs/heads/main
git push release v1.0.0
```

The first command publishes the tagged commit as the Release Repository's `main` branch. The second publishes the tag.

Verify the result:

```bash
git ls-remote release
git ls-remote --tags release
```

Open `prime-ai-release` on GitHub and confirm:

- `main` contains the V1.0.0 baseline.
- The `v1.0.0` tag exists.
- The commit hash matches the approved baseline.
- No V2 feature branches have been published to the Release Repository.

The two repositories now share their historical baseline but can develop independently.

## 4. Establish the development workflow

### Step 8 — Keep the existing repository as the Development Repository

For the initial implementation, keep the existing repository, current `main` branch, developer branches, and open PRs intact.

Do not rename `main` immediately. First get the new Release Repository working and verify that all developers can continue normal work.

After that, introduce an `integration` branch in the Development Repository:

```bash
git switch main
git pull --ff-only origin main
git switch -c integration
git push -u origin integration
```

Only do this after confirming that the working tree is clean and local `main` is aligned with the intended remote baseline.

For the initial transition, `main` remains the V2 development integration branch. The new `integration` branch becomes the place where a batch of changes is assembled and tested before being merged back into `main`.

### Step 9 — Adopt standard branch naming

| Work type | Branch pattern | Example |
|---|---|---|
| New feature | `feature/<module>-<description>` | `feature/timetable-teacher-availability` |
| Bug fix | `bugfix/<module>-<description>` | `bugfix/attendance-monthly-report` |
| Integration candidate | `integration` | `integration` |
| V1 fix | `bugfix/v1-<description>` | `bugfix/v1-fee-receipt` |
| V1 promotion | `promote/v1-<description>` | `promote/v1-timetable` |

Use lowercase names and hyphens. Include a ticket or task reference where available.

### Step 10 — Developer workflow

Each developer should:

1. Start from the latest V2 `main`.
2. Create a feature or bug-fix branch.
3. Make changes limited to a clearly defined feature.
4. Add or update automated tests.
5. Test the feature locally.
6. Commit logically related changes separately.
7. Open a PR into `integration`, not directly into `main`.
8. Document the modules, APIs, database tables, migrations and shared components affected.

Example:

```bash
git fetch origin
git switch main
git pull --ff-only origin main
git switch -c feature/timetable-teacher-availability
```

After implementation and local testing:

```bash
git add .
git commit -m "Timetable: add teacher availability constraint"
git push -u origin feature/timetable-teacher-availability
```

Then open a GitHub PR with:

- Base branch: `integration`
- Compare branch: `feature/timetable-teacher-availability`

If the branch has become outdated, update it carefully and resolve conflicts rather than overwriting shared history.

Keep each PR focused. A single PR should not mix an unrelated Timetable enhancement, Accounting refactoring, and global CSS changes unless those changes are genuinely required by the same feature.

### Step 11 — Senior Developer's responsibilities

The Senior Developer should review each PR for:

- Correctness and code quality.
- Module boundaries and shared-code changes.
- Database migrations and rollback implications.
- Permissions, authentication and tenant isolation.
- API contracts and mobile/web compatibility.
- Automated tests and regression risk.
- Logging, error handling and configuration changes.

The Senior Developer should return incomplete PRs rather than merging them merely because the developer says the feature works.

Once a PR is accepted, merge it into `integration`. This means it is a **candidate for integration testing**, not that it has passed.

## 5. Establish the integration and regression-testing gate

This is the most important process improvement for the team and the 50+ modules.

### Step 12 — Define the integration testing workflow

```text
Developer feature branch
          |
          v
     PR into integration
          |
          v
   Senior Developer review
          |
          v
   Automated checks / tests
          |
          v
   Tester validates the build
          |
          v
  Cross-module regression tests
          |
     +----+----+
     |         |
    FAIL      PASS
     |         |
     v         v
  Fix PR    Integration approved
                |
                v
         PR integration -> main
                |
                v
          V2 development
```

A PR merged into `integration` is a **candidate for integration testing**, not a passed change.

The tester should test the combined build, not merely the feature in isolation.

### Step 13 — Require an impact analysis for every PR

Use this template in the PR description:

```markdown
## Prime-AI Change Impact Assessment

**Task / PR Reference:**

**Developer:**

**Primary Module:**

**Change Type:** Feature / Bug Fix / Refactoring / Database Change

### Impact Assessment

- [ ] Primary module identified
- [ ] Other affected modules identified
- [ ] Shared services/components checked
- [ ] Database tables and migrations listed
- [ ] API endpoints and contracts checked
- [ ] Permissions and roles checked
- [ ] Web/mobile compatibility checked
- [ ] Tenant isolation checked
- [ ] Automated tests added or updated
- [ ] Existing functionality regression risks documented

**Primary module:**

**Potentially affected modules:**

**Database changes:**

**API changes:**

**Shared components changed:**

**Test cases to execute:**

**Known limitations / dependencies:**

**Developer test result:**

**Senior Developer review:**

**Tester result:**

**Final status:** PASS / FAIL / BLOCKED
```

### Step 14 — Build a module dependency matrix

Maintain a document mapping which modules depend on which other modules.

Start with important shared dependencies:

- Authentication and users.
- Roles and permissions.
- Academic sessions, classes and sections.
- Students and teachers.
- Common notifications.
- Shared APIs and services.
- Finance and fee-related services.
- Timetable and Attendance.
- LMS and student/teacher relationships.

For example, a Timetable change may require regression tests for Attendance, Teacher, Academic and LMS, depending on the actual change.

Do not assume every Timetable change affects all these modules. Use the impact assessment and dependency matrix to determine test scope.

### Step 15 — Define regression test levels

| Test level | Responsible person | Minimum purpose |
|---|---|---|
| Developer test | Feature developer | Verify the changed functionality |
| Module regression | Module owner / tester | Verify existing functionality in that module |
| Integration regression | Tester | Verify affected dependent modules |
| Release acceptance | Owner + tester | Verify the release candidate and demo-critical workflows |

Initially, there is no need to automate every test across all 50+ modules. Start with the highest-risk shared workflows, then gradually expand the automated regression suite.

### Step 16 — Promote the tested integration build into V2 `main`

After the integration batch passes:

1. Open a PR from `integration` into `main`.
2. Include the PRs and features covered by the test run.
3. Record tester results and known limitations.
4. Obtain the Senior Developer's approval.
5. Merge the PR.
6. Run a smoke test against the resulting V2 `main` commit.

If the integration batch fails, fix the relevant feature branch or create a dedicated fix branch, then repeat the tests.

Do not promote an untested batch into V2 `main` merely to keep development moving. Independent work can continue in feature branches while the integration issue is resolved.

### Step 17 — Configure GitHub automation

Add GitHub Actions checks for:

- PHP syntax validation.
- Composer dependency validation.
- Laravel application boot and configuration tests.
- Automated unit and feature tests.
- Migration checks against a disposable test database.
- Static analysis or coding standards, if already configured.

Run these checks on PRs targeting `integration` and `main`.

Do not run destructive commands such as `php artisan migrate:fresh` against the demo database. Use an isolated test database for CI.

GitHub Actions can run these checks on GitHub Free, subject to applicable usage limits. For private repositories, branch-protection enforcement depends on the plan and repository configuration.

## 6. Protect V1 from normal development

### Step 18 — Establish the Release Repository operating rules

The new repository has its own `main` branch. Treat it as the current approved release line.

1. Never use the Release Repository for ordinary development.
2. Never push V2's complete `main` branch over the Release Repository's `main`.
3. Never use `git push --force` against the release branch.
4. Never delete release tags to conceal a release mistake.
5. Never merge an entire V2 development history into the Release Repository.
6. Introduce changes through a promotion branch and a PR.
7. Test the promotion candidate before merging.
8. Keep the demo deployment tied to an approved release, not an arbitrary development commit.

If the private repository is on GitHub Free, these rules are operational safeguards rather than all being enforceable server-side. For enforced branch restrictions, upgrade to an eligible plan and configure the required branch-protection rules.

### Step 19 — Create a release candidate branch for every promotion

When a feature is approved for V1, the Senior Developer creates a promotion branch from the current Release Repository `main`.

Example:

```text
promote/v1-timetable-enhancement
```

The branch should contain only the commits required for that feature and its dependencies.

After testing, the Senior Developer opens a PR into the Release Repository's `main`. The owner reviews and approves the release decision.

The release branch is not a place to experiment. If the candidate fails, fix the promotion branch or discard it and prepare a corrected candidate.

## 7. Promote a selected V2 feature into the Release Repository

This is the key procedure for adding a new feature to V1 without importing unrelated development changes.

### Step 20 — Confirm release eligibility

Before promotion, confirm that:

- The feature is complete in V2.
- Its PR has been merged into V2 `main`.
- Developer tests passed.
- Module regression tests passed.
- Cross-module impact tests passed.
- Required migrations, configuration and assets are identified.
- The feature does not depend on unapproved V2 work.
- The owner has decided that the feature belongs in the demo/release version.

A feature can be tested and complete without being suitable for V1. Release approval is a separate decision.

### Step 21 — Identify the exact commits

In the Development Repository, identify the commits implementing the feature:

```bash
git log --oneline origin/main
```

Record the relevant commit hashes.

Prefer a small set of commits representing one complete feature. If the feature requires multiple commits, identify all of them and their order.

Do not cherry-pick a commit that depends on an unapproved refactor or a database migration absent from the Release Repository.

**Critical rule:** If a feature cannot be cleanly separated from unrelated V2 changes, do not force a selective promotion. First isolate the feature or prepare a dedicated, reviewed backport.

### Step 22 — Create the promotion branch from the Release Repository

Use a clean working tree and fetch both repositories:

```bash
git fetch origin
git fetch release
```

Create a promotion branch based on the Release Repository's current `main`:

```bash
git switch --create promote/v1-timetable-enhancement release/main
```

This creates the branch from `release/main`, not from the Development Repository's `main`.

Cherry-pick the selected commits in dependency order:

```bash
git cherry-pick <COMMIT_HASH_1>
git cherry-pick <COMMIT_HASH_2>
```

Replace placeholders with actual commit hashes. If the feature consists of one commit, cherry-pick only that commit.

Cherry-picking creates new commits in the target branch; it does not merge all of V2 into V1.

### Step 23 — Resolve conflicts safely

If Git reports a conflict:

```bash
git status
```

Resolve the conflict carefully, review the resulting diff, and run relevant tests.

If you cannot confidently resolve the conflict:

```bash
git cherry-pick --abort
```

Stop and investigate the dependency rather than forcing the merge.

After resolving and testing:

```bash
git status
git diff release/main...HEAD
```

Review the changed files and ensure only the intended feature and necessary dependencies are included.

### Step 24 — Push the promotion branch

```bash
git push -u release promote/v1-timetable-enhancement
```

Open a PR on GitHub:

- Base repository: `prime-ai-release`
- Base branch: `main`
- Compare branch: `promote/v1-timetable-enhancement`

The PR should include:

- Feature description and source V2 commit hashes.
- List of files changed.
- Database migration and rollback notes.
- Impacted modules and regression results.
- Release decision and intended version.

### Step 25 — Test the promotion candidate

Deploy the promotion branch to a **separate release-candidate environment**. Do not test it directly on the live demo environment.

Run:

1. Migration checks against a cloned or disposable database.
2. Feature-specific tests.
3. Module regression tests.
4. Cross-module regression tests.
5. Demo-critical smoke tests.
6. Web/API/mobile compatibility checks, as applicable.

If any test fails, reject the candidate and correct it before release.

### Step 26 — Merge and tag the release

After the candidate passes:

1. The owner approves the promotion.
2. The Senior Developer merges the promotion PR.
3. Verify the final Release Repository commit.
4. Create the next release tag.
5. Deploy the approved release to the demo environment.
6. Perform post-deployment smoke tests.

For example, if the previous release was `v1.0.0` and the feature is a backward-compatible feature addition, you might use `v1.1.0`. A bug fix might use `v1.0.1`. Choose the version based on actual release scope.

Tag the exact approved commit:

```bash
git switch main
git pull --ff-only release main
git tag -a v1.1.0 <APPROVED_COMMIT_HASH> -m "Prime-AI V1.1.0"
git push release v1.1.0
```

Use the actual final commit hash. Do not move an existing release tag to another commit. If a release is defective, issue a new corrected version.

## 8. Fix a bug discovered in V1

The direction of the workflow reverses when a bug is found in the stable demo.

### Step 27 — Create the hotfix from the Release Repository

Do not start the fix from current V2 `main`, because it may contain unrelated or incompatible changes.

Fetch the Release Repository:

```bash
git fetch release
```

Create a hotfix branch:

```bash
git switch --create bugfix/v1-fee-receipt release/main
```

Fix the issue, add or update tests, and commit:

```bash
git add .
git commit -m "Finance: fix fee receipt calculation"
git push -u release bugfix/v1-fee-receipt
```

Open a PR into `prime-ai-release` `main`.

### Step 28 — Test and release the V1 hotfix

The tester should verify:

- The reported bug is fixed.
- Related workflows still work.
- No other demo-critical workflow has regressed.
- Any database migration is safe.
- The release can be deployed and rolled back safely.

After approval, merge the PR, tag a patch release such as `v1.0.1`, and deploy it only after normal release checks pass.

### Step 29 — Forward-port the fix into V2

The same bug fix should normally be carried into V2 so the defect does not reappear in future releases.

Identify the hotfix commit:

```bash
git log release/main --oneline
```

Create a new fix branch from the current Development Repository `main`:

```bash
git fetch origin
git switch --create bugfix/finance-fee-receipt origin/main
git cherry-pick <V1_HOTFIX_COMMIT_HASH>
```

Resolve conflicts, run developer and regression tests, and open a PR into the Development Repository's `integration` branch.

After testing, merge it through the usual integration workflow.

If V2 has substantially changed the affected code, do not blindly cherry-pick. Apply the same logical fix to the current V2 implementation, test it, and document the relationship between the two fixes.

## 9. Separate the V1 and V2 environments and databases

Repository separation alone is not sufficient. Prime-AI uses Laravel and multiple databases, so database isolation is essential.

### Step 30 — Establish separate environments

#### V1 — Demo / Release

- Release code: `prime-ai-release`
- Application environment: `demo`
- Demo database: separate V1 database
- Tenant databases: separate V1 demo tenant databases
- Uploaded files: separate or explicitly versioned storage

#### V2 — Development

- Code: existing `prime_ai` repository
- Application environment: `development`
- Development database: separate V2 database
- Tenant databases: separate V2 development tenant databases
- Uploaded files: development storage

#### Integration / Release Candidate

- Code: integration build or promotion branch
- Database: dedicated integration database
- Tenant databases: dedicated test tenants
- Data: synthetic or appropriately sanitized test data

For the database architecture, separation must include the relevant `prime_master`, `global_master` and school-specific tenant databases. Do not assume that using different Laravel `.env` files automatically isolates every database connection.

### Step 31 — Verify Laravel configuration

Review the database configuration in `config/database.php`, relevant environment variables, tenant connection logic, queue workers, scheduled jobs, file storage and cache configuration.

Ensure the demo application points exclusively to its intended databases and supporting services.

For example, a deployed demo might use:

```dotenv
APP_ENV=production
APP_DEBUG=false
```

These are example settings, not a replacement for the actual configuration.

Never commit credentials, `.env` files, production database dumps or private keys into either repository. Keep V1 and V2 environment configuration separate.

### Step 32 — Control database migrations

Every feature promotion involving schema changes must include a migration review.

Before releasing a migration:

1. Identify the tables and columns changed.
2. Check whether the feature's PHP code and migration are being promoted together.
3. Verify foreign keys, indexes, data types and existing data compatibility.
4. Test the migration on a restored test database.
5. Document any required backfill or data conversion.
6. Define a recovery plan.

Do not use `migrate:fresh` or `db:wipe` on the demo database.

Prefer backward-compatible schema changes where possible. If a V2 feature depends on several migrations or shared refactoring, promote the complete dependency set or defer the feature until it can be safely separated.

A database rollback is not always safe because data may already have been transformed or deleted. Keep verified backups and test restoration procedures.

## 10. Protect and deploy released Web, API and Mobile App versions

### Step 33 — Keep a release manifest

For each release, record the exact code and database state.

| Component | V1.1.0 release record |
|---|---|
| Web application | Git release tag and commit |
| API | Tag/commit if separately versioned |
| Mobile application | App build/version and source commit |
| Database | Schema/migration version |
| Configuration | Versioned configuration template |
| Test results | Regression run reference |
| Deployment | Date and target environment |

If Web, API and Mobile live in the same repository, a common release tag can identify the source snapshot, but record the exact deployed build of each component as well.

If the mobile application has a separate repository, it needs its own controlled release process and source tag. A Git tag in the Web repository does not automatically version a separate mobile repository.

### Step 34 — Establish a release acceptance checklist

Before any release reaches the demo:

- [ ] Feature or fix approved for release.
- [ ] Required commits and dependencies identified.
- [ ] Database migrations reviewed and tested.
- [ ] Unit and feature tests pass.
- [ ] Module regression passes.
- [ ] Cross-module regression passes.
- [ ] Demo-critical workflows pass.
- [ ] API and mobile compatibility verified where relevant.
- [ ] Release database backup verified.
- [ ] Deployment and recovery plan documented.
- [ ] Exact release tag created.
- [ ] Post-deployment smoke test passes.

A failed mandatory check means the release is not approved.

## 11. Configure access and branch protection

### Step 35 — Decide whether GitHub Free is sufficient

For this situation, retain private repositories and upgrade the Release Repository to an eligible plan if GitHub must enforce PR-based releases.

GitHub's documentation distinguishes between branch protection available on Free for public repositories and private-repository protection available on paid plans. Verify the current plan and official documentation before relying on a feature.

With eligible protection, configure the Release Repository's `main` branch to require:

- Pull requests before merging.
- At least one approval.
- Passing automated status checks.
- No force pushes.
- No branch deletion.
- No bypass of required protections where supported.

Keep administrative access limited to the owner. The Senior Developer should have the minimum role necessary to manage promotion PRs and release operations.

If you stay on GitHub Free with private repositories, access restrictions still prevent the other developers from accessing the Release Repository. However, the owner and Senior Developer must follow the controlled promotion process because required server-enforced branch protections may not be available on that plan.

## 12. Recovery plan if a release breaks the demo

### Step 36 — Stop and assess

If a deployment introduces a regression:

1. Stop further deployments.
2. Record the failing release tag and commit.
3. Identify whether the failure is in code, configuration, database schema, or data.
4. Notify the Senior Developer and tester.
5. Decide whether to roll back the application, apply a hotfix, or restore data.

### Step 37 — Roll back to the last known-good release

Identify the last verified release tag, for example:

```text
v1.0.1
```

Redeploy that exact application version using the established deployment procedure.

Do not force-reset the Release Repository's `main` or rewrite its release history simply to roll back a deployment. The previous tag remains the record of the previous release.

If the release introduced a database migration, determine whether the old code is compatible with the new schema. Do not automatically reverse the migration or restore a database backup without assessing the data impact.

After recovery, create a corrected release with a new version tag and document the incident.

## 13. Implementation checklist

Use this checklist to track the transition.

### Preparation

- [ ] Inspect current repository, branches and open PRs.
- [ ] Identify the exact demo-ready commit.
- [ ] Back up Git history, databases and uploaded files.
- [ ] Record and verify the V1 baseline.

### Repository separation

- [ ] Create private `prime-ai-release` repository.
- [ ] Grant access only to the owner and Senior Developer.
- [ ] Push the approved V1 commit and `v1.0.0` tag.
- [ ] Verify the new repository's commit and tag.

### Development workflow

- [ ] Keep the existing development repository intact.
- [ ] Create the `integration` branch.
- [ ] Direct new feature PRs into `integration`.
- [ ] Introduce impact assessment and module ownership.
- [ ] Define module and cross-module regression tests.

### Release controls

- [ ] Choose branch-protection plan/settings.
- [ ] Create the promotion PR template.
- [ ] Test V2-to-V1 selective promotion in a candidate environment.
- [ ] Test V1 hotfix and forward-port procedure.
- [ ] Configure separate demo, development and integration databases.

### Operational readiness

- [ ] Document Web/API/Mobile release versioning.
- [ ] Define release acceptance checklist.
- [ ] Test recovery to a known-good release.
- [ ] Confirm V1 demo works after separation.

## 14. Final operating rules for the team

Publish these rules internally and follow them consistently.

1. **Development Repository:** All normal feature development and routine V2 bug fixes happen here.
2. **Integration:** Features must pass agreed integration and regression checks before entering V2 `main`.
3. **Release Repository:** Only the owner and Senior Developer have access.
4. **Promotion:** No entire-branch merges or blind repository copies from V2 to V1. Promote only reviewed, tested changes and their required dependencies.
5. **Release approval:** A successful developer test alone is not sufficient.
6. **Hotfixes:** V1 bugs are fixed against released code, tested, released, and then forward-ported to V2.
7. **Databases:** V1, V2 and integration environments never share writable application databases.
8. **Versioning:** Every approved release receives a unique, immutable tag.
9. **Rollback:** Preserve the previous release and a verified recovery path.
10. **No exceptions by convenience:** If a feature cannot be safely isolated, delay its promotion rather than risking the demo.

## 15. Recommended implementation order

Perform these steps in order:

1. Back up and freeze the current demo-ready commit.
2. Create `prime-ai-release` and verify the V1 snapshot.
3. Restrict access and configure release controls.
4. Establish the V2 integration workflow.
5. Separate the demo and development databases.
6. Trial a small, low-risk feature promotion.
7. Trial a V1 hotfix and forward-port.
8. Adopt the workflow for all future releases.

## Success criterion

The team must be able to continue developing V2 normally while the demo remains untouched unless the owner explicitly authorizes a tested release.

The two-repository architecture creates that separation; the integration gate, release checklist, access controls and database isolation make the separation operationally reliable.
