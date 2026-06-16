-- 1. Master Event Table
-- Represents the overall PTM event (e.g., "Term 1 Parent Teacher Meet 2026")
CREATE TABLE ptm_events (
    ptm_event_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL, -- Name of the PTM event
    academic_year VARCHAR(10) NOT NULL, -- e.g., "2025-2026"
    description TEXT,
    is_active BOOLEAN DEFAULT true -- To enable/disable booking globally
);

-- 2. Batch Templates
-- Defines the "shape" of a schedule created by a teacher.
CREATE TABLE ptm_batches (
    batch_id SERIAL PRIMARY KEY,
    teacher_id INT NOT NULL, -- Owner of the batch
    batch_name VARCHAR(100), -- e.g., "Morning Slot - 15 mins"
    slot_duration_minutes INT NOT NULL, -- Duration of each meeting
    max_participants_per_slot INT DEFAULT 1, -- 1 for private, >1 for group sessions
    buffer_minutes INT DEFAULT 0, -- Gap between two meetings
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Batch Slot Templates
-- The specific time offsets for a batch (e.g., 09:00, 09:15, 09:30)
CREATE TABLE ptm_batch_slot_definitions (
    slot_def_id SERIAL PRIMARY KEY,
    batch_id INT REFERENCES ptm_batches(batch_id) ON DELETE CASCADE,
    start_offset_time TIME NOT NULL, -- The time the slot starts
    end_offset_time TIME NOT NULL, -- The time the slot ends
    is_break BOOLEAN DEFAULT false -- If true, this is a tea/lunch break and not bookable
);

-- 4. Schedule Assignments (The Bridge)
-- This applies a Batch to a specific Class and Date.
CREATE TABLE ptm_assignments (
    assignment_id SERIAL PRIMARY KEY,
    ptm_event_id INT REFERENCES ptm_events(ptm_event_id),
    batch_id INT REFERENCES ptm_batches(batch_id),
    class_section_id INT NOT NULL, -- The specific Grade+Section (e.g., 10-A)
    scheduled_date DATE NOT NULL, -- The specific day this class has its PTM
    meeting_mode VARCHAR(50), -- e.g., "In-Person", "Zoom", "Teams"
    room_or_link TEXT, -- Physical room number or virtual meeting URL
    
    -- Constraint: A teacher cannot be assigned to two classes on the same date/time
    -- This logic is usually handled via a Trigger or Application logic due to time overlaps.
    UNIQUE(ptm_event_id, class_section_id, scheduled_date)
);

-- 5. Actual Bookable Slots
-- These are generated automatically when an assignment is created.
CREATE TABLE ptm_slots (
    slot_id SERIAL PRIMARY KEY,
    assignment_id INT REFERENCES ptm_assignments(assignment_id) ON DELETE CASCADE,
    teacher_id INT NOT NULL, -- Redundant but useful for quick queries
    slot_start TIMESTAMP NOT NULL, -- Actual Date + Time (e.g., 2026-05-10 09:00:00)
    slot_end TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'AVAILABLE', -- AVAILABLE, BOOKED, BLOCKED, COMPLETED
    student_id INT DEFAULT NULL, -- Linked student if status is 'BOOKED'
    parent_comments TEXT, -- Notes provided by parent during booking
    
    -- Ensure a student doesn't book the same slot twice in the same assignment
    CONSTRAINT unique_student_booking UNIQUE (assignment_id, student_id)
);
