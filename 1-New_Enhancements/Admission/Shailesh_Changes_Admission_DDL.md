# DDL Change Report — Admission Entrance Test Question Paper

**Project:** `prime_ai`  
**Database:** Tenant Schema (PostgreSQL)  
**Scope:** DDL Changes Only

---

## 1. Summary of DDL Changes

| # | Action | Table | Object / Columns Added | Migration File |
|---|---|---|---|---|
| 1 | `CREATE TABLE` | `adm_entrance_test_questions` | New junction table with primary key, foreign keys, unique constraint, and indexes | `database/migrations/tenant/2026_09_26_120000_create_adm_entrance_test_questions_table.php` |
| 2 | `ALTER TABLE` | `adm_entrance_tests` | 13 paper configuration columns, foreign key `fk_adm_et_diff_config`, index `idx_adm_et_diff_config` | `database/migrations/tenant/2026_06_16_083604_create_adm_entrance_tests_table.php` |
| 3 | `ALTER TABLE` | `qns_questions_bank` | `for_admission` column | `database/migrations/tenant/2026_06_15_151318_create_qns_questions_bank_table.php` |

---

## 2. Table: `adm_entrance_test_questions` (NEW TABLE)

```sql
CREATE TABLE adm_entrance_test_questions (
    id                BIGSERIAL    NOT NULL,
    ordinal           INTEGER      NOT NULL DEFAULT 0,
    marks_override    NUMERIC(6,2) NULL,
    is_active         BOOLEAN      NOT NULL DEFAULT TRUE,
    entrance_test_id  BIGINT       NOT NULL,
    question_id       INTEGER      NOT NULL,
    created_at        TIMESTAMP    NULL,
    updated_at        TIMESTAMP    NULL,
    deleted_at        TIMESTAMP    NULL,

    CONSTRAINT adm_entrance_test_questions_pkey PRIMARY KEY (id),

    CONSTRAINT fk_adm_etq_test
        FOREIGN KEY (entrance_test_id)
        REFERENCES adm_entrance_tests (id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_adm_etq_question
        FOREIGN KEY (question_id)
        REFERENCES qns_questions_bank (id)
        ON DELETE CASCADE,

    CONSTRAINT uq_adm_etq_test_question
        UNIQUE (entrance_test_id, question_id)
);

CREATE INDEX idx_adm_etq_question     ON adm_entrance_test_questions (question_id);
CREATE INDEX idx_adm_etq_test_ordinal ON adm_entrance_test_questions (entrance_test_id, ordinal);
```

### Column Specifications

| Column | Data Type | Nullable | Default | Constraints / References |
|---|---|---|---|---|
| `id` | `BIGSERIAL` | `NOT NULL` | Auto increment | `PRIMARY KEY` |
| `ordinal` | `INTEGER` | `NOT NULL` | `0` | Order of question in paper |
| `marks_override` | `NUMERIC(6,2)` | `NULL` | `NULL` | Paper-specific marks override |
| `is_active` | `BOOLEAN` | `NOT NULL` | `TRUE` | Active status flag |
| `entrance_test_id` | `BIGINT` | `NOT NULL` | — | `FOREIGN KEY` → `adm_entrance_tests(id)` `ON DELETE CASCADE` |
| `question_id` | `INTEGER` | `NOT NULL` | — | `FOREIGN KEY` → `qns_questions_bank(id)` `ON DELETE CASCADE` |
| `created_at` | `TIMESTAMP` | `NULL` | `NULL` | Record creation timestamp |
| `updated_at` | `TIMESTAMP` | `NULL` | `NULL` | Record update timestamp |
| `deleted_at` | `TIMESTAMP` | `NULL` | `NULL` | Soft delete timestamp |

---

## 3. Table: `adm_entrance_tests` (ALTER TABLE)

```sql
ALTER TABLE adm_entrance_tests
    ADD COLUMN duration_minutes         SMALLINT     NULL,
    ADD COLUMN total_marks              NUMERIC(8,2) NOT NULL DEFAULT 0.00,
    ADD COLUMN total_questions          INTEGER      NOT NULL DEFAULT 0,
    ADD COLUMN passing_percentage       NUMERIC(5,2) NOT NULL DEFAULT 33.00,
    ADD COLUMN negative_marks           NUMERIC(4,2) NOT NULL DEFAULT 0.00,
    ADD COLUMN is_randomized            BOOLEAN      NOT NULL DEFAULT FALSE,
    ADD COLUMN question_marks_shown     BOOLEAN      NOT NULL DEFAULT FALSE,
    ADD COLUMN timer_enforced           BOOLEAN      NOT NULL DEFAULT TRUE,
    ADD COLUMN show_correct_answer      BOOLEAN      NOT NULL DEFAULT FALSE,
    ADD COLUMN show_explanation         BOOLEAN      NOT NULL DEFAULT FALSE,
    ADD COLUMN ignore_difficulty_config BOOLEAN      NOT NULL DEFAULT FALSE,
    ADD COLUMN only_unused_questions    BOOLEAN      NOT NULL DEFAULT FALSE,
    ADD COLUMN difficulty_config_id     INTEGER      NULL;

ALTER TABLE adm_entrance_tests
    ADD CONSTRAINT fk_adm_et_diff_config
        FOREIGN KEY (difficulty_config_id)
        REFERENCES lms_difficulty_distribution_configs (id)
        ON DELETE SET NULL;

CREATE INDEX idx_adm_et_diff_config ON adm_entrance_tests (difficulty_config_id);
```

### Column Specifications

| Column | Data Type | Nullable | Default | Constraints / References |
|---|---|---|---|---|
| `duration_minutes` | `SMALLINT` | `NULL` | `NULL` | Test duration in minutes |
| `total_marks` | `NUMERIC(8,2)` | `NOT NULL` | `0.00` | Derived total marks on the paper |
| `total_questions` | `INTEGER` | `NOT NULL` | `0` | Declared total question limit |
| `passing_percentage` | `NUMERIC(5,2)` | `NOT NULL` | `33.00` | Minimum pass percentage |
| `negative_marks` | `NUMERIC(4,2)` | `NOT NULL` | `0.00` | Negative marks per incorrect answer |
| `is_randomized` | `BOOLEAN` | `NOT NULL` | `FALSE` | Shuffle question order |
| `question_marks_shown` | `BOOLEAN` | `NOT NULL` | `FALSE` | Display question marks to candidate |
| `timer_enforced` | `BOOLEAN` | `NOT NULL` | `TRUE` | Enforce test countdown |
| `show_correct_answer` | `BOOLEAN` | `NOT NULL` | `FALSE` | Reveal correct answers post-test |
| `show_explanation` | `BOOLEAN` | `NOT NULL` | `FALSE` | Reveal explanations post-test |
| `ignore_difficulty_config` | `BOOLEAN` | `NOT NULL` | `FALSE` | Ignore difficulty validation |
| `only_unused_questions` | `BOOLEAN` | `NOT NULL` | `FALSE` | Use only unassigned questions |
| `difficulty_config_id` | `INTEGER` | `NULL` | `NULL` | `FOREIGN KEY` → `lms_difficulty_distribution_configs(id)` `ON DELETE SET NULL` |

---

## 4. Table: `qns_questions_bank` (ALTER TABLE)

```sql
ALTER TABLE qns_questions_bank
    ADD COLUMN for_admission BOOLEAN NOT NULL DEFAULT FALSE;
```

### Column Specifications

| Column | Data Type | Nullable | Default | Description |
|---|---|---|---|---|
| `for_admission` | `BOOLEAN` | `NOT NULL` | `FALSE` | Authorizes question for Admission Entrance Tests |

---

## 5. Rollback DDL

```sql
-- 1. Drop junction table
DROP TABLE IF EXISTS adm_entrance_test_questions;

-- 2. Revert columns and constraints on adm_entrance_tests
ALTER TABLE adm_entrance_tests
    DROP CONSTRAINT IF EXISTS fk_adm_et_diff_config,
    DROP COLUMN IF EXISTS duration_minutes,
    DROP COLUMN IF EXISTS total_marks,
    DROP COLUMN IF EXISTS total_questions,
    DROP COLUMN IF EXISTS passing_percentage,
    DROP COLUMN IF EXISTS negative_marks,
    DROP COLUMN IF EXISTS is_randomized,
    DROP COLUMN IF EXISTS question_marks_shown,
    DROP COLUMN IF EXISTS timer_enforced,
    DROP COLUMN IF EXISTS show_correct_answer,
    DROP COLUMN IF EXISTS show_explanation,
    DROP COLUMN IF EXISTS ignore_difficulty_config,
    DROP COLUMN IF EXISTS only_unused_questions,
    DROP COLUMN IF EXISTS difficulty_config_id;

-- 3. Revert column on qns_questions_bank
ALTER TABLE qns_questions_bank
    DROP COLUMN IF EXISTS for_admission;
```
