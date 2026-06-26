-- =====================================================
-- Test Runner Database Schema (SQLite)
-- Location: tests/Browser/reports/test_runs.db
-- Purpose: Store automated Dusk test run history & results
-- Created: June 11, 2026
-- =====================================================

-- Enable WAL mode for better concurrent read performance
PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

-- -----------------------------------------------------
-- Table: test_runs
-- One row per test execution (each "Run" button click)
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS test_runs (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id      TEXT    NOT NULL UNIQUE,              -- YYYYMMDD_HHmmss_uniqid
    module      TEXT    NOT NULL,                     -- module folder name (e.g., SyllabusBooks)
    timestamp   TEXT    NOT NULL,                     -- human-readable datetime
    exit_code   INTEGER DEFAULT 0,                    -- 0 = success, >0 = failure
    total       INTEGER DEFAULT 0,                    -- total test case count
    passed      INTEGER DEFAULT 0,
    skipped     INTEGER DEFAULT 0,
    failures    INTEGER DEFAULT 0,
    assertions  INTEGER DEFAULT 0,
    duration    TEXT    DEFAULT '',                    -- e.g., "734.42s"
    paths_json  TEXT    DEFAULT '[]',                  -- JSON array of file paths run
    raw_output  TEXT    DEFAULT '',                    -- full terminal output
    created_at  TEXT    DEFAULT (datetime('now','localtime'))
);

-- -----------------------------------------------------
-- Table: test_run_results
-- One row per individual test case within a run
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS test_run_results (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id    TEXT NOT NULL,                           -- FK → test_runs.run_id
    test_name TEXT NOT NULL,                           -- test method name
    status    TEXT NOT NULL CHECK(status IN ('passed','failed','skipped')),
    FOREIGN KEY (run_id) REFERENCES test_runs(run_id) ON DELETE CASCADE
);

-- -----------------------------------------------------
-- Indexes for fast lookups
-- -----------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_run_id    ON test_runs(run_id);
CREATE INDEX IF NOT EXISTS idx_module    ON test_runs(module);
CREATE INDEX IF NOT EXISTS idx_timestamp ON test_runs(timestamp);
CREATE INDEX IF NOT EXISTS idx_results_run ON test_run_results(run_id);
