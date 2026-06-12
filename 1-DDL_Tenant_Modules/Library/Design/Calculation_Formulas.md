# Library Module — Calculation Formulas & Processes
**Source DDL:** `Library_ddl_v6.sql`
**Purpose:** For every field across the 49 tables that is **not directly entered by a user** but must be **calculated/derived/cached** by the application, a trigger, an event, or a scheduled job — this document defines the formula, the calculation trigger point, and the concrete SQL/stored-procedure/view needed to populate it.

## Legend — Calculation Trigger Types

| Type | Meaning |
|------|---------|
| **DB Trigger** | Existing or proposed `AFTER INSERT/UPDATE` MySQL trigger — fires immediately, in-transaction |
| **DB Event** | Existing or proposed `CREATE EVENT` scheduled job (runs inside MySQL scheduler) |
| **App Real-time** | Calculated by the Laravel/API layer at the moment of the user action (synchronous) |
| **Scheduled Job** | Daily/weekly batch job (Laravel scheduler / cron) — typically for analytics tables |
| **On-Demand View** | Computed at query-time via a `VIEW` — no storage required |
| **AI/ML Service** | Computed by an external AI/ML pipeline and written back via API |

---

# 1. Sub-Menu 4 — ACQUISITION & CATALOGING

## 1.1 `lib_books_master`

### `is_available` (TINYINT, cached)
**Type:** DB Trigger
**Formula:**
```
is_available = 1  IF EXISTS at least one row in lib_book_copies
                     WHERE book_id = b.id
                       AND status = (SELECT id FROM lib_library_status_masters
                                       WHERE status_type='Book Status' AND code='Available')
                       AND is_active = 1
                ELSE 0
```
**Implementation — add to existing copy-status triggers** (`update_copy_status_on_issue`, `update_copy_status_on_return`) and a new trigger for direct `lib_book_copies.status` updates (lost/withdrawn/maintenance):

```sql
DELIMITER $$
CREATE TRIGGER `sync_book_availability_on_copy_change`
  AFTER UPDATE ON `lib_book_copies`
  FOR EACH ROW
  BEGIN
    DECLARE v_available_status SMALLINT UNSIGNED;
    IF NEW.status <> OLD.status OR NEW.is_active <> OLD.is_active THEN
      SELECT id INTO v_available_status
        FROM lib_library_status_masters
       WHERE status_type = 'Book Status' AND code = 'Available'
       LIMIT 1;

      UPDATE lib_books_master b
         SET b.is_available = (
               EXISTS (
                 SELECT 1 FROM lib_book_copies c
                  WHERE c.book_id = b.id
                    AND c.status = v_available_status
                    AND c.is_active = 1
                    AND c.deleted_at IS NULL
               )
             )
       WHERE b.id = NEW.book_id;
    END IF;
  END$$
DELIMITER ;
```
Also fire the same recalculation `AFTER INSERT ON lib_book_copies` (new copy added → may flip a book from unavailable to available):
```sql
DELIMITER $$
CREATE TRIGGER `sync_book_availability_on_copy_insert`
  AFTER INSERT ON `lib_book_copies`
  FOR EACH ROW
  BEGIN
    DECLARE v_available_status SMALLINT UNSIGNED;
    SELECT id INTO v_available_status
      FROM lib_library_status_masters
     WHERE status_type = 'Book Status' AND code = 'Available' LIMIT 1;

    UPDATE lib_books_master b
       SET b.is_available = (
             EXISTS (
               SELECT 1 FROM lib_book_copies c
                WHERE c.book_id = b.id
                  AND c.status = v_available_status
                  AND c.is_active = 1
                  AND c.deleted_at IS NULL
             )
           )
     WHERE b.id = NEW.book_id;
  END$$
DELIMITER ;
```

---

### `student_rating` & `rating_count` (DECIMAL(3,2), INT)
**Type:** DB Trigger (on `lib_book_reviews_ratings`)
**Formula:**
```
student_rating = AVG(rating)  WHERE book_id = b.id AND is_approved = 1 AND is_faculty = 0
rating_count   = COUNT(*)     WHERE book_id = b.id AND is_approved = 1
```
**SQL — Stored Procedure + Trigger:**
```sql
DELIMITER $$
CREATE PROCEDURE `recalc_book_rating`(IN p_book_id INT UNSIGNED)
BEGIN
  UPDATE lib_books_master b
     SET b.student_rating = (
            SELECT ROUND(AVG(rating), 2)
              FROM lib_book_reviews_ratings
             WHERE book_id = p_book_id
               AND is_approved = 1
               AND is_faculty = 0
               AND deleted_at IS NULL
         ),
         b.rating_count = (
            SELECT COUNT(*)
              FROM lib_book_reviews_ratings
             WHERE book_id = p_book_id
               AND is_approved = 1
               AND deleted_at IS NULL
         ),
         b.academic_rating = (
            SELECT ROUND(AVG(rating), 2)
              FROM lib_book_reviews_ratings
             WHERE book_id = p_book_id
               AND is_approved = 1
               AND is_faculty = 1
               AND deleted_at IS NULL
         )
   WHERE b.id = p_book_id;
END$$

CREATE TRIGGER `update_book_rating_on_review_change`
  AFTER UPDATE ON `lib_book_reviews_ratings`
  FOR EACH ROW
  BEGIN
    IF NEW.is_approved <> OLD.is_approved OR NEW.rating <> OLD.rating
       OR NEW.deleted_at <> OLD.deleted_at OR (NEW.deleted_at IS NULL) <> (OLD.deleted_at IS NULL) THEN
      CALL recalc_book_rating(NEW.book_id);
    END IF;
  END$$

CREATE TRIGGER `update_book_rating_on_review_insert`
  AFTER INSERT ON `lib_book_reviews_ratings`
  FOR EACH ROW
  BEGIN
    CALL recalc_book_rating(NEW.book_id);
  END$$
DELIMITER ;
```

---

### `popularity_rank` (MEDIUMINT, cached)
**Type:** Scheduled Job (Daily) — depends on `lib_book_popularity_trends`
**Formula:** Dense rank of books ordered by yesterday's `popularity_score` (descending).
```sql
-- Daily job, run after lib_book_popularity_trends is populated for the day
SET @rank := 0;
UPDATE lib_books_master b
INNER JOIN (
    SELECT book_id,
           (@rank := @rank + 1) AS rnk
      FROM lib_book_popularity_trends
     WHERE tracking_date = CURDATE() - INTERVAL 1 DAY
     ORDER BY popularity_score DESC
) ranked ON ranked.book_id = b.id
SET b.popularity_rank = ranked.rnk;
```

---

### `tags_json`, `ai_summary`, `key_concepts_json`, `lexile_level`, `reading_age_range`
**Type:** AI/ML Service
**Formula:** Generated by an external NLP/AI pipeline (e.g., on book creation/update of `summary` / `table_of_contents`).
**Process:**
1. On `INSERT`/`UPDATE` of `lib_books_master.summary` or `table_of_contents`, enqueue a background job (`lib_background_services` row: "Book AI Enrichment").
2. The job calls the AI service, receives `{tags: [...], ai_summary: "...", key_concepts: [...], lexile_level: "...", reading_age_range: "..."}`.
3. Job writes back:
```sql
UPDATE lib_books_master
   SET tags_json         = :tags_json,
       ai_summary         = :ai_summary,
       key_concepts_json  = :key_concepts_json,
       lexile_level       = :lexile_level,
       reading_age_range  = :reading_age_range
 WHERE id = :book_id;
```

---

### `curricular_relevance_score` (DECIMAL(5,2))
**Type:** Scheduled Job (Weekly) — depends on `lib_curricular_alignment`
**Formula:**
```
curricular_relevance_score = AVG(alignment_score)
                              FROM lib_curricular_alignment
                              WHERE book_id = b.id
```
```sql
UPDATE lib_books_master b
   SET b.curricular_relevance_score = COALESCE((
         SELECT ROUND(AVG(alignment_score), 2)
           FROM lib_curricular_alignment
          WHERE book_id = b.id
       ), 0.00);
```

---

## 1.2 `lib_book_purchases` (header)

### `bill_amt`, `bill_tax_amt`, `bill_net_amt`
**Type:** App Real-time + DB Trigger (safety net)
**Formula:**
```
bill_amt     = SUM(lib_book_purchases_items.book_amt)     WHERE book_purchase_id = p.id
bill_tax_amt = SUM(lib_book_purchases_items.book_tax_amt) WHERE book_purchase_id = p.id
bill_net_amt = SUM(lib_book_purchases_items.book_net_amt) WHERE book_purchase_id = p.id
```
**Recommended:** Calculate in the application when items are saved (single transaction). Safety-net trigger:
```sql
DELIMITER $$
CREATE PROCEDURE `recalc_purchase_totals`(IN p_purchase_id INT UNSIGNED)
BEGIN
  UPDATE lib_book_purchases p
     SET p.bill_amt     = (SELECT COALESCE(SUM(book_amt),0)     FROM lib_book_purchases_items WHERE book_purchase_id = p_purchase_id AND deleted_at IS NULL),
         p.bill_tax_amt = (SELECT COALESCE(SUM(book_tax_amt),0) FROM lib_book_purchases_items WHERE book_purchase_id = p_purchase_id AND deleted_at IS NULL),
         p.bill_net_amt = (SELECT COALESCE(SUM(book_net_amt),0) FROM lib_book_purchases_items WHERE book_purchase_id = p_purchase_id AND deleted_at IS NULL)
   WHERE p.id = p_purchase_id;
END$$

CREATE TRIGGER `recalc_purchase_totals_on_item_change`
  AFTER INSERT ON `lib_book_purchases_items`
  FOR EACH ROW
  BEGIN
    CALL recalc_purchase_totals(NEW.book_purchase_id);
  END$$

CREATE TRIGGER `recalc_purchase_totals_on_item_update`
  AFTER UPDATE ON `lib_book_purchases_items`
  FOR EACH ROW
  BEGIN
    CALL recalc_purchase_totals(NEW.book_purchase_id);
  END$$
DELIMITER ;
```

---

## 1.3 `lib_book_purchases_items`

### `book_amt`, `book_tax_amt`, `book_net_amt`
**Type:** App Real-time (computed before INSERT) + DB Trigger (safety net via `BEFORE INSERT/UPDATE`)
**Formula:**
```
book_amt     = book_price * book_quantity
book_tax_amt = ROUND(book_amt * book_tax_percent / 100, 2)
book_net_amt = book_amt + book_tax_amt
```
```sql
DELIMITER $$
CREATE TRIGGER `calc_purchase_item_amounts_insert`
  BEFORE INSERT ON `lib_book_purchases_items`
  FOR EACH ROW
  BEGIN
    SET NEW.book_amt     = NEW.book_price * NEW.book_quantity;
    SET NEW.book_tax_amt = ROUND(NEW.book_amt * NEW.book_tax_percent / 100, 2);
    SET NEW.book_net_amt = NEW.book_amt + NEW.book_tax_amt;
  END$$

CREATE TRIGGER `calc_purchase_item_amounts_update`
  BEFORE UPDATE ON `lib_book_purchases_items`
  FOR EACH ROW
  BEGIN
    SET NEW.book_amt     = NEW.book_price * NEW.book_quantity;
    SET NEW.book_tax_amt = ROUND(NEW.book_amt * NEW.book_tax_percent / 100, 2);
    SET NEW.book_net_amt = NEW.book_amt + NEW.book_tax_amt;
  END$$
DELIMITER ;
```

---

## 1.4 `lib_book_copies`

### `status` (FK → lib_library_status_masters)
**Type:** DB Trigger (already defined in DDL — `update_copy_status_on_issue`, `update_copy_status_on_return`)
**Formula:**
```
ON lib_transactions INSERT (status = 'Issued')   -> lib_book_copies.status = 'Issued'
ON lib_transactions UPDATE (status -> 'Returned') -> lib_book_copies.status = 'Available',
                                                      current_condition_id = return_condition_id
```
**Additional transitions (proposed App Real-time updates, not yet covered by triggers):**
```sql
-- Mark Lost (staff action, App Real-time)
UPDATE lib_book_copies
   SET status = (SELECT id FROM lib_library_status_masters WHERE status_type='Book Status' AND code='Lost'),
       is_lost = 1
 WHERE id = :copy_id;

-- Mark Withdrawn (staff action, App Real-time)
UPDATE lib_book_copies
   SET status = (SELECT id FROM lib_library_status_masters WHERE status_type='Book Status' AND code='Withdrawn'),
       is_withdrawn = 1,
       withdrawal_reason = :reason
 WHERE id = :copy_id;

-- Reserved (App Real-time, when a reservation is converted to "Available" pickup)
UPDATE lib_book_copies
   SET status = (SELECT id FROM lib_library_status_masters WHERE status_type='Book Status' AND code='Reserved')
 WHERE id = :copy_id;
```

---

## 1.5 `lib_digital_resources`

### `download_count`, `view_count` (cached aggregates)
**Type:** DB Trigger (on `lib_digital_access_transactions`)
**Formula:**
```
download_count = SUM(lib_digital_access_transactions.download_count) WHERE digital_resource_id = dr.id
view_count     = SUM(lib_digital_access_transactions.view_count)     WHERE digital_resource_id = dr.id
```
```sql
DELIMITER $$
CREATE PROCEDURE `recalc_digital_resource_counters`(IN p_resource_id INT UNSIGNED)
BEGIN
  UPDATE lib_digital_resources dr
     SET dr.download_count = (
           SELECT COALESCE(SUM(download_count),0) FROM lib_digital_access_transactions
            WHERE digital_resource_id = p_resource_id AND deleted_at IS NULL
         ),
         dr.view_count = (
           SELECT COALESCE(SUM(view_count),0) FROM lib_digital_access_transactions
            WHERE digital_resource_id = p_resource_id AND deleted_at IS NULL
         )
   WHERE dr.id = p_resource_id;
END$$

CREATE TRIGGER `sync_digRes_counters_on_access_update`
  AFTER UPDATE ON `lib_digital_access_transactions`
  FOR EACH ROW
  BEGIN
    IF NEW.download_count <> OLD.download_count OR NEW.view_count <> OLD.view_count THEN
      CALL recalc_digital_resource_counters(NEW.digital_resource_id);
    END IF;
  END$$
DELIMITER ;
```

### `status` (Available / License Consumed / License Expired)
**Type:** Scheduled Job (Daily) + App Real-time
**Formula:**
```
IF license_end_date IS NOT NULL AND license_end_date < CURDATE()
    THEN status = 'License Expired'
ELSE IF license_count IS NOT NULL
        AND (active concurrent access count >= license_count)
    THEN status = 'License Consumed'
ELSE status = 'Available'
```
```sql
-- Daily scheduled job
UPDATE lib_digital_resources dr
   SET dr.status = (SELECT id FROM lib_library_status_masters WHERE status_type='Digital Resource Status' AND code='License_Expired')
 WHERE dr.license_end_date IS NOT NULL
   AND dr.license_end_date < CURDATE();

-- App Real-time: when granting new access, check concurrent count first
UPDATE lib_digital_resources dr
   SET dr.status = (SELECT id FROM lib_library_status_masters WHERE status_type='Digital Resource Status' AND code='License_Consumed')
 WHERE dr.license_count IS NOT NULL
   AND dr.license_count <= (
        SELECT COUNT(*) FROM lib_digital_access_transactions t
         WHERE t.digital_resource_id = dr.id
           AND t.status = (SELECT id FROM lib_library_status_masters WHERE status_type='Digital Access Transaction Status' AND code='Active')
   );
```

---

# 2. Sub-Menu 5 — MEMBER & ACCESS MANAGEMENT

## 2.1 `lib_members`

### `total_books_borrowed` (lifetime counter)
**Type:** DB Trigger — **already implemented** as `update_member_borrowed_count` in DDL.
**Formula:**
```
ON lib_transactions INSERT (status = 'Issued')
  -> total_books_borrowed = total_books_borrowed + 1
  -> last_activity_date   = CURDATE()
```
(No additional SQL required — already present in Sub-Menu 11.)

---

### `last_activity_date`
**Type:** DB Trigger (extend coverage beyond issue)
**Formula:** Updated to `CURDATE()` on **any** member activity: issue, return, renewal, reservation, digital access, review, payment.
**Additional triggers needed (issue is already covered):**
```sql
DELIMITER $$
CREATE TRIGGER `update_member_activity_on_return`
  AFTER UPDATE ON `lib_transactions`
  FOR EACH ROW
  BEGIN
    DECLARE v_returned_status SMALLINT UNSIGNED;
    SELECT id INTO v_returned_status FROM lib_library_status_masters
     WHERE status_type='Transaction Status' AND code='Returned' LIMIT 1;
    IF NEW.status = v_returned_status AND OLD.status <> v_returned_status THEN
      UPDATE lib_members SET last_activity_date = CURDATE() WHERE id = NEW.member_id;
    END IF;
  END$$

CREATE TRIGGER `update_member_activity_on_reservation`
  AFTER INSERT ON `lib_reservations`
  FOR EACH ROW
  BEGIN
    UPDATE lib_members SET last_activity_date = CURDATE() WHERE id = NEW.member_id;
  END$$

CREATE TRIGGER `update_member_activity_on_digital_access`
  AFTER INSERT ON `lib_digital_access_transactions`
  FOR EACH ROW
  BEGIN
    UPDATE lib_members SET last_activity_date = CURDATE() WHERE id = NEW.member_id;
  END$$

CREATE TRIGGER `update_member_activity_on_payment`
  AFTER INSERT ON `lib_fine_payments`
  FOR EACH ROW
  BEGIN
    UPDATE lib_members m
    INNER JOIN lib_fines f ON f.id = NEW.fine_id
       SET m.last_activity_date = CURDATE()
     WHERE m.id = f.member_id;
  END$$
DELIMITER ;
```

---

### `total_fines_paid` & `outstanding_fines`
**Type:** DB Trigger (on `lib_fine_payments` and `lib_fines`)
**Formula:**
```
total_fines_paid  = SUM(lib_fine_payments.amount_paid)  for all fines belonging to member
outstanding_fines = SUM(lib_fines.amount - lib_fines.waived_amount)
                     - SUM(lib_fine_payments.amount_paid for those fines)
                     WHERE lib_fines.status IN ('Pending','Overdue')
```
```sql
DELIMITER $$
CREATE PROCEDURE `recalc_member_fines`(IN p_member_id INT UNSIGNED)
BEGIN
  UPDATE lib_members m
     SET m.total_fines_paid = (
            SELECT COALESCE(SUM(fp.amount_paid), 0)
              FROM lib_fine_payments fp
              INNER JOIN lib_fines f ON f.id = fp.fine_id
             WHERE f.member_id = p_member_id
               AND fp.deleted_at IS NULL
         ),
         m.outstanding_fines = (
            SELECT COALESCE(SUM(
                     f.amount - f.waived_amount
                     - COALESCE((SELECT SUM(fp2.amount_paid) FROM lib_fine_payments fp2
                                  WHERE fp2.fine_id = f.id AND fp2.deleted_at IS NULL), 0)
                   ), 0)
              FROM lib_fines f
              INNER JOIN lib_library_status_masters s ON s.id = f.status
             WHERE f.member_id = p_member_id
               AND s.status_type = 'Fine Status'
               AND s.code IN ('Pending','Overdue')
               AND f.deleted_at IS NULL
         )
   WHERE m.id = p_member_id;
END$$

CREATE TRIGGER `recalc_member_fines_on_fine_insert`
  AFTER INSERT ON `lib_fines`
  FOR EACH ROW
  BEGIN
    CALL recalc_member_fines(NEW.member_id);
  END$$

CREATE TRIGGER `recalc_member_fines_on_fine_update`
  AFTER UPDATE ON `lib_fines`
  FOR EACH ROW
  BEGIN
    CALL recalc_member_fines(NEW.member_id);
  END$$

CREATE TRIGGER `recalc_member_fines_on_payment`
  AFTER INSERT ON `lib_fine_payments`
  FOR EACH ROW
  BEGIN
    CALL recalc_member_fines((SELECT member_id FROM lib_fines WHERE id = NEW.fine_id));
  END$$
DELIMITER ;
```

---

### `reading_progress_ytd` (INT)
**Type:** DB Trigger (on `lib_transactions` return) + reset by Scheduled Job (yearly)
**Formula:**
```
reading_progress_ytd = COUNT(lib_transactions)
                        WHERE member_id = m.id
                          AND status = 'Returned'
                          AND YEAR(return_date) = YEAR(CURDATE())
```
```sql
DELIMITER $$
CREATE TRIGGER `increment_reading_progress_on_return`
  AFTER UPDATE ON `lib_transactions`
  FOR EACH ROW
  BEGIN
    DECLARE v_returned_status SMALLINT UNSIGNED;
    SELECT id INTO v_returned_status FROM lib_library_status_masters
     WHERE status_type='Transaction Status' AND code='Returned' LIMIT 1;
    IF NEW.status = v_returned_status AND OLD.status <> v_returned_status THEN
      UPDATE lib_members
         SET reading_progress_ytd = reading_progress_ytd + 1
       WHERE id = NEW.member_id;
    END IF;
  END$$
DELIMITER ;

-- Scheduled Job: run on Jan 1st every year to reset YTD counters
-- (e.g., via lib_background_services entry "Annual Reading Progress Reset")
UPDATE lib_members SET reading_progress_ytd = 0;
```

---

### `engagement_score`, `churn_risk_score`, `lifetime_value`, `member_segment`, `last_segment_calculation`
**Type:** Scheduled Job (Weekly) — driven by `lib_reading_behavior_analytics`, `lib_engagement_events`, `lib_transactions`, `lib_fines`
**Formulas:**

```
engagement_score (0-100) =
    LEAST(100,
        (events_last_30_days * 2)                       -- activity weight
      + (digital_access_last_30_days * 3)               -- digital engagement weight
      + (transactions_last_30_days * 5)                 -- borrowing weight
      + (reviews_written * 2)
    )

churn_risk_score (0-100) =
    100 - engagement_score
    + (CASE WHEN days_since_last_activity > 90 THEN 30
            WHEN days_since_last_activity > 60 THEN 15
            WHEN days_since_last_activity > 30 THEN 5
            ELSE 0 END)
    + (CASE WHEN outstanding_fines > 0 THEN 10 ELSE 0 END)
    -- clamp to [0,100]

lifetime_value =
    (total_books_borrowed * avg_book_cost_used_estimate)
  + total_fines_paid
  -- avg_book_cost_used_estimate sourced from AVG(lib_book_purchases_items.book_price)

member_segment =
    CASE
      WHEN engagement_score >= 70 AND lifetime_value >= 1000 THEN 'High-Value'
      WHEN churn_risk_score  >= 60                          THEN 'At-Risk'
      WHEN total_books_borrowed = 0                          THEN 'New'
      WHEN days_since_last_activity > 90                     THEN 'Inactive'
      ELSE 'Regular'
    END
```

**Stored Procedure (run weekly for all members):**
```sql
DELIMITER $$
CREATE PROCEDURE `calculate_member_segments`()
BEGIN
  -- Temp table of base metrics
  DROP TEMPORARY TABLE IF EXISTS tmp_member_metrics;
  CREATE TEMPORARY TABLE tmp_member_metrics AS
  SELECT
      m.id AS member_id,
      m.total_books_borrowed,
      m.total_fines_paid,
      m.outstanding_fines,
      DATEDIFF(CURDATE(), m.last_activity_date) AS days_since_last_activity,
      (SELECT COUNT(*) FROM lib_engagement_events e
        WHERE e.member_id = m.id AND e.created_at >= CURDATE() - INTERVAL 30 DAY) AS events_30d,
      (SELECT COUNT(*) FROM lib_digital_access_transactions d
        WHERE d.member_id = m.id AND d.access_start_at >= CURDATE() - INTERVAL 30 DAY) AS digital_30d,
      (SELECT COUNT(*) FROM lib_transactions t
        WHERE t.member_id = m.id AND t.issue_date >= CURDATE() - INTERVAL 30 DAY) AS tx_30d,
      (SELECT COUNT(*) FROM lib_book_reviews_ratings r
        WHERE r.member_id = m.id) AS reviews_count,
      (SELECT AVG(book_price) FROM lib_book_purchases_items) AS avg_book_cost
  FROM lib_members m;

  UPDATE lib_members m
  INNER JOIN tmp_member_metrics t ON t.member_id = m.id
  SET
    m.engagement_score = LEAST(100,
        (t.events_30d * 2) + (t.digital_30d * 3) + (t.tx_30d * 5) + (t.reviews_count * 2)
    ),
    m.churn_risk_score = GREATEST(0, LEAST(100,
        (100 - LEAST(100, (t.events_30d * 2) + (t.digital_30d * 3) + (t.tx_30d * 5) + (t.reviews_count * 2)))
        + CASE WHEN t.days_since_last_activity > 90 THEN 30
               WHEN t.days_since_last_activity > 60 THEN 15
               WHEN t.days_since_last_activity > 30 THEN 5
               ELSE 0 END
        + CASE WHEN t.outstanding_fines > 0 THEN 10 ELSE 0 END
    )),
    m.lifetime_value = (t.total_books_borrowed * COALESCE(t.avg_book_cost, 0)) + t.total_fines_paid,
    m.last_segment_calculation = NOW();

  -- Second pass: segment depends on the just-computed scores
  UPDATE lib_members m
  INNER JOIN tmp_member_metrics t ON t.member_id = m.id
  SET m.member_segment = CASE
        WHEN m.engagement_score >= 70 AND m.lifetime_value >= 1000 THEN 'High-Value'
        WHEN m.churn_risk_score  >= 60                              THEN 'At-Risk'
        WHEN t.total_books_borrowed = 0                             THEN 'New'
        WHEN t.days_since_last_activity > 90                        THEN 'Inactive'
        ELSE 'Regular'
      END;

  DROP TEMPORARY TABLE IF EXISTS tmp_member_metrics;
END$$
DELIMITER ;

-- Schedule (lib_background_services: "Member Segmentation - Weekly")
-- CREATE EVENT recalc_member_segments ON SCHEDULE EVERY 1 WEEK DO CALL calculate_member_segments();
```

---

# 3. Sub-Menu 6 — OPERATION MANAGEMENT

## 3.1 `lib_reservations`

### `queue_position` (SMALLINT)
**Type:** App Real-time (at INSERT)
**Formula:**
```
queue_position = (MAX(queue_position) for same book_id where status = 'Pending') + 1
                  (or 1 if no pending reservations exist for this book)
```
```sql
INSERT INTO lib_reservations (book_id, member_id, reservation_date, queue_position, status, ...)
SELECT
    :book_id, :member_id, NOW(),
    COALESCE((
        SELECT MAX(r.queue_position) + 1
          FROM lib_reservations r
         WHERE r.book_id = :book_id
           AND r.status = (SELECT id FROM lib_library_status_masters
                              WHERE status_type='Reservation Status' AND code='Pending')
    ), 1),
    (SELECT id FROM lib_library_status_masters WHERE status_type='Reservation Status' AND code='Pending'),
    ...;
```

**Re-sequencing on cancellation/fulfilment** — when a reservation moves out of `Pending` (Picked_Up / Cancelled / Expired), shift everyone behind it up by one:
```sql
DELIMITER $$
CREATE TRIGGER `resequence_reservation_queue`
  AFTER UPDATE ON `lib_reservations`
  FOR EACH ROW
  BEGIN
    DECLARE v_pending_status SMALLINT UNSIGNED;
    SELECT id INTO v_pending_status FROM lib_library_status_masters
     WHERE status_type='Reservation Status' AND code='Pending' LIMIT 1;

    IF OLD.status = v_pending_status AND NEW.status <> v_pending_status THEN
      UPDATE lib_reservations
         SET queue_position = queue_position - 1
       WHERE book_id = OLD.book_id
         AND status = v_pending_status
         AND queue_position > OLD.queue_position;
    END IF;
  END$$
DELIMITER ;
```

---

### `expected_available_date` (DATE)
**Type:** App Real-time (at INSERT) + recalculated by Scheduled Job (Daily) and on every `Returned` transaction
**Formula:**
```
expected_available_date =
    Nth earliest due_date among currently 'Issued' transactions for copies of this book,
    where N = queue_position
    (i.e., the copy expected to become free by the time this reservation reaches the front)
```
```sql
DELIMITER $$
CREATE PROCEDURE `recalc_reservation_expected_dates`(IN p_book_id INT UNSIGNED)
BEGIN
  -- Build ranked list of due dates for currently issued copies of this book
  DROP TEMPORARY TABLE IF EXISTS tmp_due_dates;
  CREATE TEMPORARY TABLE tmp_due_dates AS
  SELECT t.due_date,
         ROW_NUMBER() OVER (ORDER BY t.due_date ASC) AS rn
    FROM lib_transactions t
    INNER JOIN lib_book_copies c ON c.id = t.copy_id
   WHERE c.book_id = p_book_id
     AND t.status = (SELECT id FROM lib_library_status_masters
                        WHERE status_type='Transaction Status' AND code='Issued');

  UPDATE lib_reservations r
  LEFT JOIN tmp_due_dates d ON d.rn = r.queue_position
     SET r.expected_available_date = d.due_date
   WHERE r.book_id = p_book_id
     AND r.status = (SELECT id FROM lib_library_status_masters
                        WHERE status_type='Reservation Status' AND code='Pending');

  DROP TEMPORARY TABLE IF EXISTS tmp_due_dates;
END$$
DELIMITER ;

-- Trigger: recalc whenever a transaction is issued/returned (book availability changes)
CREATE TRIGGER `recalc_reservation_dates_on_tx_change`
  AFTER UPDATE ON `lib_transactions`
  FOR EACH ROW
  BEGIN
    CALL recalc_reservation_expected_dates(NEW.book_id);
  END$$
```

---

### `notification_sent`, `notification_sent_at` (FCFS notification on book return)
**Type:** DB Trigger (on `lib_transactions` return) + App Real-time (sends actual notification)
**Formula:** When a copy is returned and becomes `Available`, notify the **next pending reservation** (lowest `queue_position`) for that book, set `pickup_by_date = CURDATE() + grace days`, mark `notification_sent = 1`.
```sql
DELIMITER $$
CREATE TRIGGER `notify_next_reservation_on_return`
  AFTER UPDATE ON `lib_transactions`
  FOR EACH ROW
  BEGIN
    DECLARE v_returned_status SMALLINT UNSIGNED;
    DECLARE v_pending_status  SMALLINT UNSIGNED;
    DECLARE v_avail_resv_status SMALLINT UNSIGNED;
    DECLARE v_next_reservation_id INT UNSIGNED;

    SELECT id INTO v_returned_status FROM lib_library_status_masters WHERE status_type='Transaction Status' AND code='Returned' LIMIT 1;
    SELECT id INTO v_pending_status  FROM lib_library_status_masters WHERE status_type='Reservation Status' AND code='Pending' LIMIT 1;
    SELECT id INTO v_avail_resv_status FROM lib_library_status_masters WHERE status_type='Reservation Status' AND code='Available' LIMIT 1;

    IF NEW.status = v_returned_status AND OLD.status <> v_returned_status THEN
      SELECT r.id INTO v_next_reservation_id
        FROM lib_reservations r
       WHERE r.book_id = NEW.book_id
         AND r.status = v_pending_status
       ORDER BY r.queue_position ASC
       LIMIT 1;

      IF v_next_reservation_id IS NOT NULL THEN
        UPDATE lib_reservations
           SET status = v_avail_resv_status,
               notification_sent = 1,
               notification_sent_at = NOW(),
               pickup_by_date = CURDATE() + INTERVAL 3 DAY  -- configurable via lib_library_settings
         WHERE id = v_next_reservation_id;
        -- App layer: dispatch email/SMS/push notification to member here (async job)
      END IF;
    END IF;
  END$$
DELIMITER ;
```

**Reservation Expiry (Scheduled Job — Daily):** if member doesn't pick up by `pickup_by_date`, expire and notify next in queue.
```sql
UPDATE lib_reservations
   SET status = (SELECT id FROM lib_library_status_masters WHERE status_type='Reservation Status' AND code='Expired')
 WHERE status = (SELECT id FROM lib_library_status_masters WHERE status_type='Reservation Status' AND code='Available')
   AND pickup_by_date < CURDATE();
-- The resequence_reservation_queue + notify_next_reservation_on_return logic
-- (or an equivalent procedure) then promotes the next pending reservation.
```

---

## 3.2 `lib_transactions`

### `renewal_count` (INT)
**Type:** App Real-time (on renewal approval)
**Formula:**
```
renewal_count = renewal_count + 1   (capped at lib_membership_types.max_renewals)
due_date      = due_date + renewal_days_requested (or membership loan_period_days)
is_renewed    = 1
```
```sql
UPDATE lib_transactions t
INNER JOIN lib_reservations r ON r.transaction_id = t.id AND r.is_renewal_request = 1
INNER JOIN lib_members m ON m.id = t.member_id
INNER JOIN lib_membership_types mt ON mt.id = m.membership_type_id
   SET t.renewal_count = t.renewal_count + 1,
       t.is_renewed    = 1,
       t.due_date      = DATE_ADD(t.due_date, INTERVAL r.renewal_days_requested DAY)
 WHERE r.id = :reservation_id
   AND mt.renewal_allowed = 1
   AND t.renewal_count < mt.max_renewals;
```

---

### `status` (Issued → Overdue, automatic flag)
**Type:** Scheduled Job (Daily)
**Formula:**
```
status = 'Overdue'  WHERE status = 'Issued' AND due_date < CURDATE()
```
```sql
UPDATE lib_transactions
   SET status = (SELECT id FROM lib_library_status_masters WHERE status_type='Transaction Status' AND code='Overdue')
 WHERE status = (SELECT id FROM lib_library_status_masters WHERE status_type='Transaction Status' AND code='Issued')
   AND due_date < CURDATE();
```

---

## 3.3 `lib_digital_access_transactions`

### `download_count`, `is_downloaded`, `first_downloaded_at`, `last_downloaded_at`, `last_download_ip`, `last_download_device`, `last_download_user_agent`, `download_history_json`
**Type:** App Real-time — on every download event the API call updates this row
**Formula:**
```
download_count           = download_count + 1
is_downloaded             = 1
first_downloaded_at       = IF(first_downloaded_at IS NULL, NOW(), first_downloaded_at)
last_downloaded_at        = NOW()
last_download_ip          = :ip
last_download_device      = :device
last_download_user_agent  = :user_agent
download_history_json     = JSON_ARRAY_APPEND(COALESCE(download_history_json, JSON_ARRAY()), '$',
                                JSON_OBJECT('downloaded_at', NOW(), 'ip', :ip, 'device', :device, 'user_agent', :user_agent))
```
```sql
UPDATE lib_digital_access_transactions
   SET download_count          = download_count + 1,
       is_downloaded            = 1,
       first_downloaded_at      = COALESCE(first_downloaded_at, NOW()),
       last_downloaded_at       = NOW(),
       last_download_ip         = :ip,
       last_download_device     = :device,
       last_download_user_agent = :user_agent,
       download_history_json    = JSON_ARRAY_APPEND(
                                     COALESCE(download_history_json, JSON_ARRAY()),
                                     '$',
                                     JSON_OBJECT('downloaded_at', NOW(), 'ip', :ip, 'device', :device, 'user_agent', :user_agent)
                                   )
 WHERE id = :access_transaction_id;
```

---

### `view_count`, `total_view_duration_sec`, `last_view_ip`, `last_view_device`, `last_accessed_at`
**Type:** App Real-time — view increments on open, duration updated via heartbeat/session-close
**Formula:**
```
-- On open:
view_count        = view_count + 1
last_accessed_at  = NOW()
last_view_ip       = :ip
last_view_device   = :device

-- On session close (heartbeat):
total_view_duration_sec = total_view_duration_sec + :session_duration_seconds
last_accessed_at         = NOW()
```
```sql
-- On open
UPDATE lib_digital_access_transactions
   SET view_count = view_count + 1,
       last_accessed_at = NOW(),
       last_view_ip = :ip,
       last_view_device = :device
 WHERE id = :access_transaction_id;

-- On session close
UPDATE lib_digital_access_transactions
   SET total_view_duration_sec = total_view_duration_sec + :session_duration_seconds,
       last_accessed_at = NOW()
 WHERE id = :access_transaction_id;
```

---

### `status` (Active → Expired / Completed)
**Type:** Scheduled Job (Daily)
**Formula:**
```
status = 'Expired'  WHERE status = 'Active' AND access_expires_at IS NOT NULL AND access_expires_at < NOW()
```
```sql
UPDATE lib_digital_access_transactions
   SET status = (SELECT id FROM lib_library_status_masters WHERE status_type='Digital Access Transaction Status' AND code='Expired')
 WHERE status = (SELECT id FROM lib_library_status_masters WHERE status_type='Digital Access Transaction Status' AND code='Active')
   AND access_expires_at IS NOT NULL
   AND access_expires_at < NOW();
```
(`Revoked` is a manual staff action — App Real-time sets `status='Revoked'`, `revoked_by_id`, `revoked_at`, `revocation_reason`.)

---

## 3.4 `lib_fines`

### `amount`, `days_overdue`, `calculation_breakdown_json`, `fine_slab_config_id`
**Type:** DB Event (Daily) — **enhanced version of existing `auto_calculate_fines` event**
**Formula (slab-based, replacing flat `fine_rate_per_day`):**
```
days_overdue = DATEDIFF(CURDATE(), due_date)

For each fine_slab_details row matching:
   - fine_slab_config.membership_type_id = member's membership_type (or NULL = applies to all)
   - fine_slab_config.resource_type_id   = book's resource_type (or NULL = applies to all)
   - fine_slab_config.fine_type_id       = 'LateReturn'
   - fine_slab_config.is_active = 1
   - effective_from <= CURDATE() <= effective_to (or effective_to IS NULL)
   - slab.priority DESC (highest priority first)
   - days_overdue BETWEEN slab_details.from_day AND slab_details.to_day

amount = sum across overlapping day ranges of:
   slab_details.fine_rate  (if rate_type='Fixed')
     * (days in this range, per calculation_type: Per_Day/Per_Week/Per_Month/Per_Year/Per_Book)
   OR
   (slab_details.fine_rate / 100) * book_cost  (if rate_type='Percentage' and max_fine_cap='BookCost')

amount = LEAST(amount, max_fine_amt)  IF max_fine_cap = 'Fixed'
amount = LEAST(amount, book_cost)     IF max_fine_cap = 'BookCost'
-- max_fine_cap = 'Unlimited' -> no cap

calculation_breakdown_json = JSON_ARRAY of {from_day, to_day, days_in_range, rate, rate_type, calculation_type, sub_amount}
```

**Enhanced Event (replaces `auto_calculate_fines`):**
```sql
DELIMITER $$
CREATE EVENT `auto_calculate_fines_v2`
  ON SCHEDULE EVERY 1 DAY
  STARTS CURRENT_DATE
  DO
  BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_issued_status, v_pending_fine_status, v_late_fine_type SMALLINT UNSIGNED;
    DECLARE v_tx_id, v_member_id, v_membership_type_id, v_resource_type_id, v_book_id INT UNSIGNED;
    DECLARE v_due_date DATE;
    DECLARE v_days_overdue INT;
    DECLARE v_book_cost DECIMAL(10,2);
    DECLARE v_slab_config_id INT UNSIGNED;
    DECLARE v_total_fine DECIMAL(10,2);
    DECLARE v_breakdown JSON;

    DECLARE cur CURSOR FOR
      SELECT t.id, t.member_id, m.membership_type_id, b.resource_type_id, b.id,
             t.due_date, DATEDIFF(CURDATE(), t.due_date)
        FROM lib_transactions t
        INNER JOIN lib_members m ON t.member_id = m.id
        INNER JOIN lib_book_copies c ON t.copy_id = c.id
        INNER JOIN lib_books_master b ON c.book_id = b.id
       WHERE t.status = (SELECT id FROM lib_library_status_masters WHERE status_type='Transaction Status' AND code='Issued')
         AND t.due_date < CURDATE();
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    SELECT id INTO v_late_fine_type FROM lib_fine_type WHERE code='LateReturn' LIMIT 1;
    SELECT id INTO v_pending_fine_status FROM lib_library_status_masters
     WHERE status_type='Fine Status' AND code='Pending' LIMIT 1;

    OPEN cur;
    read_loop: LOOP
      FETCH cur INTO v_tx_id, v_member_id, v_membership_type_id, v_resource_type_id, v_book_id, v_due_date, v_days_overdue;
      IF done THEN LEAVE read_loop; END IF;

      -- Skip if a pending fine already exists for this transaction
      IF NOT EXISTS (SELECT 1 FROM lib_fines WHERE transaction_id = v_tx_id AND fine_type = v_late_fine_type AND status = v_pending_fine_status) THEN

        -- Find best matching slab config (highest priority, most specific)
        SELECT fsc.id INTO v_slab_config_id
          FROM lib_fine_slab_config fsc
         WHERE fsc.fine_type_id = v_late_fine_type
           AND fsc.is_active = 1
           AND (fsc.membership_type_id = v_membership_type_id OR fsc.membership_type_id IS NULL)
           AND (fsc.resource_type_id   = v_resource_type_id   OR fsc.resource_type_id IS NULL)
           AND fsc.effective_from <= CURDATE()
           AND (fsc.effective_to IS NULL OR fsc.effective_to >= CURDATE())
         ORDER BY fsc.priority DESC,
                  (fsc.membership_type_id IS NOT NULL) DESC,
                  (fsc.resource_type_id IS NOT NULL) DESC
         LIMIT 1;

        SET v_book_cost = (SELECT AVG(book_price) FROM lib_book_purchases_items WHERE book_id = v_book_id);

        IF v_slab_config_id IS NOT NULL THEN
          -- Sum fine across all overlapping slab-detail day ranges
          SELECT
            COALESCE(SUM(
              CASE
                WHEN sd.rate_type = 'Percentage' THEN ROUND((sd.fine_rate/100) * COALESCE(v_book_cost,0), 2)
                ELSE sd.fine_rate * (
                  LEAST(v_days_overdue, sd.to_day) - GREATEST(0, sd.from_day - 1)
                ) * CASE sd.calculation_type
                      WHEN 'Per_Day'   THEN 1
                      WHEN 'Per_Week'  THEN 1.0/7
                      WHEN 'Per_Month' THEN 1.0/30
                      WHEN 'Per_Year'  THEN 1.0/365
                      WHEN 'Per_Book'  THEN 0  -- handled as flat add-on below
                      ELSE 1 END
              END
            ), 0),
            JSON_ARRAYAGG(JSON_OBJECT(
              'from_day', sd.from_day, 'to_day', sd.to_day,
              'rate', sd.fine_rate, 'rate_type', sd.rate_type,
              'calculation_type', sd.calculation_type
            ))
          INTO v_total_fine, v_breakdown
          FROM lib_fine_slab_details sd
         WHERE sd.fine_slab_config_id = v_slab_config_id
           AND v_days_overdue >= sd.from_day;

          -- Apply cap
          SELECT
            CASE fsc.max_fine_cap
              WHEN 'Fixed'    THEN LEAST(v_total_fine, fsc.max_fine_amt)
              WHEN 'BookCost' THEN LEAST(v_total_fine, COALESCE(v_book_cost, v_total_fine))
              ELSE v_total_fine
            END
          INTO v_total_fine
          FROM lib_fine_slab_config fsc WHERE fsc.id = v_slab_config_id;

        ELSE
          -- Fallback: use lib_membership_types.fine_rate_per_day with grace_period_days
          SELECT mt.fine_rate_per_day * GREATEST(0, v_days_overdue - mt.grace_period_days)
            INTO v_total_fine
            FROM lib_membership_types mt WHERE mt.id = v_membership_type_id;
          SET v_breakdown = JSON_OBJECT('source', 'membership_type_default', 'fine_rate_per_day',
                              (SELECT fine_rate_per_day FROM lib_membership_types WHERE id = v_membership_type_id));
        END IF;

        IF v_total_fine > 0 THEN
          INSERT INTO lib_fines (transaction_id, member_id, fine_type, amount, days_overdue,
                                  calculated_from, calculated_to, fine_slab_config_id,
                                  calculation_breakdown_json, status)
          VALUES (v_tx_id, v_member_id, v_late_fine_type, v_total_fine, v_days_overdue,
                  v_due_date, CURDATE(), v_slab_config_id, v_breakdown, v_pending_fine_status);
        END IF;
      END IF;
    END LOOP;
    CLOSE cur;
  END$$
DELIMITER ;
```

---

### `status` (Pending → Paid / Overdue)
**Type:** DB Trigger (on `lib_fine_payments`) + Scheduled Job (Daily, Pending → Overdue)
**Formula:**
```
status = 'Paid'    WHEN SUM(lib_fine_payments.amount_paid) + waived_amount >= amount
status = 'Overdue' WHEN status = 'Pending' AND DATEDIFF(CURDATE(), created_at) > grace_period (e.g., 30 days unpaid)
```
```sql
DELIMITER $$
CREATE TRIGGER `update_fine_status_on_payment`
  AFTER INSERT ON `lib_fine_payments`
  FOR EACH ROW
  BEGIN
    DECLARE v_fine_amount, v_waived, v_paid_total DECIMAL(10,2);
    DECLARE v_paid_status SMALLINT UNSIGNED;

    SELECT amount, waived_amount INTO v_fine_amount, v_waived FROM lib_fines WHERE id = NEW.fine_id;
    SELECT COALESCE(SUM(amount_paid),0) INTO v_paid_total FROM lib_fine_payments WHERE fine_id = NEW.fine_id AND deleted_at IS NULL;
    SELECT id INTO v_paid_status FROM lib_library_status_masters WHERE status_type='Fine Status' AND code='Paid' LIMIT 1;

    IF (v_paid_total + v_waived) >= v_fine_amount THEN
      UPDATE lib_fines SET status = v_paid_status WHERE id = NEW.fine_id;
    END IF;
  END$$
DELIMITER ;

-- Daily scheduled job
UPDATE lib_fines
   SET status = (SELECT id FROM lib_library_status_masters WHERE status_type='Fine Status' AND code='Overdue')
 WHERE status = (SELECT id FROM lib_library_status_masters WHERE status_type='Fine Status' AND code='Pending')
   AND DATEDIFF(CURDATE(), created_at) > 30;
```

---

# 4. Sub-Menu 7 — AUDIT AND HISTORY

## 4.1 `lib_inventory_audit_details`

### `status` (Found / Missing / Misplaced / Damaged)
**Type:** App Real-time (at scan time)
**Formula:**
```
IF actual_location_id IS NULL                       -> 'Missing'
ELSE IF actual_location_id <> expected_location_id  -> 'Misplaced'
ELSE IF condition_id is a "damaged"-flagged condition (lib_book_conditions.code IN ('DAMAGED','POOR')) -> 'Damaged'
ELSE                                                 -> 'Found'
```
```sql
-- Computed by app at scan-time and inserted directly, e.g.:
INSERT INTO lib_inventory_audit_details
  (audit_id, copy_id, expected_location_id, actual_location_id, scanned_at, condition_id, status)
VALUES (
  :audit_id, :copy_id, :expected_location_id, :actual_location_id, NOW(), :condition_id,
  CASE
    WHEN :actual_location_id IS NULL THEN
      (SELECT id FROM lib_library_status_masters WHERE status_type='Inventory Audit Detail Status' AND code='Missing')
    WHEN :actual_location_id <> :expected_location_id THEN
      (SELECT id FROM lib_library_status_masters WHERE status_type='Inventory Audit Detail Status' AND code='Misplaced')
    WHEN (SELECT code FROM lib_book_conditions WHERE id = :condition_id) IN ('DAMAGED','POOR') THEN
      (SELECT id FROM lib_library_status_masters WHERE status_type='Inventory Audit Detail Status' AND code='Damaged')
    ELSE
      (SELECT id FROM lib_library_status_masters WHERE status_type='Inventory Audit Detail Status' AND code='Found')
  END
);
```

---

## 4.2 `lib_inventory_audit` (header)

### `total_scanned`, `total_expected`, `missing_copies`, `misplaced_copies`, `damaged_copies`
**Type:** DB Trigger (recalculated on each detail insert) + finalized when audit `status='Completed'`
**Formula:**
```
total_scanned    = COUNT(lib_inventory_audit_details) WHERE audit_id = a.id
total_expected   = COUNT(lib_book_copies) WHERE is_active=1 AND deleted_at IS NULL  (collection size at audit start)
missing_copies   = COUNT(details WHERE status = 'Missing')
misplaced_copies = COUNT(details WHERE status = 'Misplaced')
damaged_copies   = COUNT(details WHERE status = 'Damaged')
```
```sql
DELIMITER $$
CREATE PROCEDURE `recalc_inventory_audit_summary`(IN p_audit_id INT UNSIGNED)
BEGIN
  UPDATE lib_inventory_audit a
     SET a.total_scanned    = (SELECT COUNT(*) FROM lib_inventory_audit_details WHERE audit_id = p_audit_id),
         a.missing_copies   = (SELECT COUNT(*) FROM lib_inventory_audit_details d
                                  INNER JOIN lib_library_status_masters s ON s.id = d.status
                                 WHERE d.audit_id = p_audit_id AND s.code = 'Missing'),
         a.misplaced_copies = (SELECT COUNT(*) FROM lib_inventory_audit_details d
                                  INNER JOIN lib_library_status_masters s ON s.id = d.status
                                 WHERE d.audit_id = p_audit_id AND s.code = 'Misplaced'),
         a.damaged_copies   = (SELECT COUNT(*) FROM lib_inventory_audit_details d
                                  INNER JOIN lib_library_status_masters s ON s.id = d.status
                                 WHERE d.audit_id = p_audit_id AND s.code = 'Damaged')
   WHERE a.id = p_audit_id;
END$$

CREATE TRIGGER `recalc_audit_summary_on_detail_insert`
  AFTER INSERT ON `lib_inventory_audit_details`
  FOR EACH ROW
  BEGIN
    CALL recalc_inventory_audit_summary(NEW.audit_id);
  END$$
DELIMITER ;

-- total_expected: set once when audit is created (App Real-time)
UPDATE lib_inventory_audit
   SET total_expected = (SELECT COUNT(*) FROM lib_book_copies WHERE is_active = 1 AND deleted_at IS NULL)
 WHERE id = :audit_id;
```

**Side-effect (App Real-time, when audit is finalized `status='Completed'`):** Update `lib_book_copies.status` for any copy found `Missing` → `'Lost'`, and `Damaged` → triggers `is_damaged=1`, `current_condition_id` updated, plus a `lib_book_condition_jnt` history row (per existing DDL pattern).

---

# 5. Sub-Menu 8 — ADVANCED ANALYTICS & INSIGHTS

> All tables in this section are **fully derived** — populated exclusively by **Scheduled Jobs** (nightly/weekly batch processes, registered in `lib_background_services`). None of these fields are user-entered.

## 5.1 `lib_reading_behavior_analytics`
**Type:** Scheduled Job (Nightly) — one row per `(member_id, academic_year_id)`

| Field | Formula |
|---|---|
| `total_books_read` | `COUNT(lib_transactions)` WHERE `member_id=m.id AND status='Returned' AND issue_date BETWEEN academic_year.start_date AND end_date` |
| `total_pages_read` | `SUM(lib_books_master.page_count)` for those returned transactions (join `copy → book`) |
| `avg_reading_days_per_book` | `AVG(DATEDIFF(return_date, issue_date))` for returned transactions in the year |
| `preferred_genre_id` | `genre_id` with `MAX(COUNT(*))` from `lib_book_genre_jnt` joined to member's borrowed books |
| `preferred_category_id` | same logic via `lib_book_category_jnt` |
| `preferred_language` | `lib_books_master.language` (dropdown) with `MAX(COUNT(*))` among borrowed books |
| `avg_loan_completion_rate` | `(COUNT(returned ON TIME) / COUNT(total returned)) * 100`, where on-time = `return_date <= due_date` |
| `peak_borrowing_month` | `MONTH(issue_date)` with `MAX(COUNT(*))` |
| `peak_borrowing_day` | `DAYNAME(issue_date)` with `MAX(COUNT(*))` |
| `reading_consistency_score` | `100 - (STDDEV(days between consecutive issue_dates) / AVG(days between) * 100)`, clamped 0-100 |
| `genre_diversity_index` | Shannon diversity index: `-SUM(p_i * LN(p_i))` where `p_i` = proportion of books in genre *i* |
| `author_diversity_index` | same Shannon formula applied to `author_id` distribution |
| `digital_vs_physical_ratio` | `COUNT(digital access transactions) / NULLIF(COUNT(physical transactions),0)` |
| `renewal_frequency` | `AVG(lib_transactions.renewal_count)` for the member's transactions in the year |
| `reservation_frequency` | `COUNT(lib_reservations)` WHERE `member_id=m.id AND reservation_date` in the year |
| `reading_speed_estimate` | `total_pages_read / NULLIF(SUM(DATEDIFF(return_date, issue_date)), 0)` |
| `completion_rate_trend` | `current_month_completion_rate - previous_month_completion_rate` |
| `last_calculated_at` | `NOW()` |

**Stored Procedure:**
```sql
DELIMITER $$
CREATE PROCEDURE `calculate_reading_behavior_analytics`(IN p_academic_year_id INT UNSIGNED)
BEGIN
  DECLARE v_year_start DATE;
  DECLARE v_year_end   DATE;
  SELECT start_date, end_date INTO v_year_start, v_year_end FROM academic_years WHERE id = p_academic_year_id;

  -- Base per-member transaction stats
  DROP TEMPORARY TABLE IF EXISTS tmp_rba_base;
  CREATE TEMPORARY TABLE tmp_rba_base AS
  SELECT
      t.member_id,
      COUNT(*) AS total_books_read,
      SUM(b.page_count) AS total_pages_read,
      AVG(DATEDIFF(t.return_date, t.issue_date)) AS avg_reading_days_per_book,
      SUM(CASE WHEN t.return_date <= t.due_date THEN 1 ELSE 0 END) / COUNT(*) * 100 AS avg_loan_completion_rate,
      AVG(t.renewal_count) AS renewal_frequency,
      SUM(b.page_count) / NULLIF(SUM(DATEDIFF(t.return_date, t.issue_date)), 0) AS reading_speed_estimate
    FROM lib_transactions t
    INNER JOIN lib_book_copies c ON c.id = t.copy_id
    INNER JOIN lib_books_master b ON b.id = c.book_id
   WHERE t.status = (SELECT id FROM lib_library_status_masters WHERE status_type='Transaction Status' AND code='Returned')
     AND t.issue_date BETWEEN v_year_start AND v_year_end
   GROUP BY t.member_id;

  -- Preferred genre per member (mode)
  DROP TEMPORARY TABLE IF EXISTS tmp_rba_genre;
  CREATE TEMPORARY TABLE tmp_rba_genre AS
  SELECT member_id, genre_id FROM (
    SELECT t.member_id, bg.genre_id, COUNT(*) AS cnt,
           ROW_NUMBER() OVER (PARTITION BY t.member_id ORDER BY COUNT(*) DESC) AS rn
      FROM lib_transactions t
      INNER JOIN lib_book_copies c ON c.id = t.copy_id
      INNER JOIN lib_book_genre_jnt bg ON bg.book_id = c.book_id
     WHERE t.issue_date BETWEEN v_year_start AND v_year_end
     GROUP BY t.member_id, bg.genre_id
  ) ranked WHERE rn = 1;

  -- Genre diversity index (Shannon) per member
  DROP TEMPORARY TABLE IF EXISTS tmp_rba_diversity;
  CREATE TEMPORARY TABLE tmp_rba_diversity AS
  SELECT member_id, ROUND(-SUM(p * LN(p)), 2) AS genre_diversity_index
    FROM (
      SELECT t.member_id, bg.genre_id,
             COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY t.member_id) AS p
        FROM lib_transactions t
        INNER JOIN lib_book_copies c ON c.id = t.copy_id
        INNER JOIN lib_book_genre_jnt bg ON bg.book_id = c.book_id
       WHERE t.issue_date BETWEEN v_year_start AND v_year_end
       GROUP BY t.member_id, bg.genre_id
    ) genre_props
   GROUP BY member_id;

  -- Peak borrowing month/day per member
  DROP TEMPORARY TABLE IF EXISTS tmp_rba_peak;
  CREATE TEMPORARY TABLE tmp_rba_peak AS
  SELECT member_id, peak_month, peak_day FROM (
    SELECT t.member_id, MONTH(t.issue_date) AS peak_month, DAYNAME(t.issue_date) AS peak_day,
           ROW_NUMBER() OVER (PARTITION BY t.member_id ORDER BY COUNT(*) DESC) AS rn
      FROM lib_transactions t
     WHERE t.issue_date BETWEEN v_year_start AND v_year_end
     GROUP BY t.member_id, MONTH(t.issue_date), DAYNAME(t.issue_date)
  ) ranked WHERE rn = 1;

  -- Digital vs physical ratio per member
  DROP TEMPORARY TABLE IF EXISTS tmp_rba_digital;
  CREATE TEMPORARY TABLE tmp_rba_digital AS
  SELECT m.id AS member_id,
         COALESCE((SELECT COUNT(*) FROM lib_digital_access_transactions d
                    WHERE d.member_id = m.id AND d.access_start_at BETWEEN v_year_start AND v_year_end), 0)
         / NULLIF((SELECT COUNT(*) FROM lib_transactions t
                    WHERE t.member_id = m.id AND t.issue_date BETWEEN v_year_start AND v_year_end), 0)
         AS digital_vs_physical_ratio,
         (SELECT COUNT(*) FROM lib_reservations r
           WHERE r.member_id = m.id AND r.reservation_date BETWEEN v_year_start AND v_year_end) AS reservation_frequency
    FROM lib_members m;

  -- Upsert into lib_reading_behavior_analytics
  INSERT INTO lib_reading_behavior_analytics
    (member_id, academic_year_id, total_books_read, total_pages_read, avg_reading_days_per_book,
     preferred_genre_id, avg_loan_completion_rate, peak_borrowing_month, peak_borrowing_day,
     genre_diversity_index, digital_vs_physical_ratio, renewal_frequency, reservation_frequency,
     reading_speed_estimate, last_calculated_at)
  SELECT
     b.member_id, p_academic_year_id, b.total_books_read, b.total_pages_read, b.avg_reading_days_per_book,
     g.genre_id, b.avg_loan_completion_rate, pk.peak_month, pk.peak_day,
     div.genre_diversity_index, dig.digital_vs_physical_ratio, b.renewal_frequency, dig.reservation_frequency,
     b.reading_speed_estimate, NOW()
    FROM tmp_rba_base b
    LEFT JOIN tmp_rba_genre g ON g.member_id = b.member_id
    LEFT JOIN tmp_rba_diversity div ON div.member_id = b.member_id
    LEFT JOIN tmp_rba_peak pk ON pk.member_id = b.member_id
    LEFT JOIN tmp_rba_digital dig ON dig.member_id = b.member_id
  ON DUPLICATE KEY UPDATE
     total_books_read = VALUES(total_books_read),
     total_pages_read = VALUES(total_pages_read),
     avg_reading_days_per_book = VALUES(avg_reading_days_per_book),
     preferred_genre_id = VALUES(preferred_genre_id),
     avg_loan_completion_rate = VALUES(avg_loan_completion_rate),
     peak_borrowing_month = VALUES(peak_borrowing_month),
     peak_borrowing_day = VALUES(peak_borrowing_day),
     genre_diversity_index = VALUES(genre_diversity_index),
     digital_vs_physical_ratio = VALUES(digital_vs_physical_ratio),
     renewal_frequency = VALUES(renewal_frequency),
     reservation_frequency = VALUES(reservation_frequency),
     reading_speed_estimate = VALUES(reading_speed_estimate),
     last_calculated_at = NOW();

  -- completion_rate_trend: current vs previous month (computed in a follow-up pass)
  UPDATE lib_reading_behavior_analytics rba
  SET completion_rate_trend = rba.avg_loan_completion_rate - (
        SELECT AVG(CASE WHEN t.return_date <= t.due_date THEN 100 ELSE 0 END)
          FROM lib_transactions t
          INNER JOIN lib_book_copies c ON c.id = t.copy_id
         WHERE t.member_id = rba.member_id
           AND t.status = (SELECT id FROM lib_library_status_masters WHERE status_type='Transaction Status' AND code='Returned')
           AND t.issue_date BETWEEN DATE_SUB(CURDATE(), INTERVAL 2 MONTH) AND DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
      )
  WHERE rba.academic_year_id = p_academic_year_id;

  DROP TEMPORARY TABLE IF EXISTS tmp_rba_base, tmp_rba_genre, tmp_rba_diversity, tmp_rba_peak, tmp_rba_digital;
END$$
DELIMITER ;

-- Note: preferred_borrowing_time (Morning/Afternoon/Evening/Weekend), preferred_category_id and
-- author_diversity_index follow the same pattern as preferred_genre_id / genre_diversity_index above,
-- substituting lib_engagement_events.created_at (for time-of-day buckets), lib_book_category_jnt,
-- and lib_book_author_jnt respectively.

-- Schedule: lib_background_services "Reading Behavior Analytics - Nightly"
-- CREATE EVENT calc_reading_behavior ON SCHEDULE EVERY 1 DAY DO
--   CALL calculate_reading_behavior_analytics(
--     (SELECT id FROM academic_years WHERE CURDATE() BETWEEN start_date AND end_date LIMIT 1)
--   );
```

---

## 5.2 `lib_book_popularity_trends`
**Type:** Scheduled Job (Nightly) — one row per `(book_id, tracking_date=yesterday)`

| Field | Formula |
|---|---|
| `daily_requests` | `COUNT(lib_engagement_events)` WHERE `book_id=b.id AND event_type IN ('View_Details','Add_Reservation') AND DATE(created_at)=yesterday` |
| `daily_issues` | `COUNT(lib_transactions)` WHERE `book_id=b.id AND DATE(issue_date)=yesterday` |
| `daily_reservations` | `COUNT(lib_reservations)` WHERE `book_id=b.id AND DATE(reservation_date)=yesterday` |
| `daily_digital_views` | `COUNT(lib_digital_access_transactions)` WHERE `book_id=b.id AND access_type IN ('View_Online','Read_Online','Stream') AND DATE(access_start_at)=yesterday` |
| `daily_digital_downloads` | `COUNT(...)` WHERE `access_type='Download' AND DATE(access_start_at)=yesterday` |
| `popularity_score` | Weighted composite: `(daily_issues*5) + (daily_reservations*3) + (daily_requests*1) + (daily_digital_views*2) + (daily_digital_downloads*4)` |
| `trend_direction` | `'Rising'` if `popularity_score > previous_day_score * 1.1`; `'Falling'` if `< previous_day_score * 0.9`; else `'Stable'` |
| `velocity_score` | `popularity_score - previous_day_score` |
| `seasonality_factor` | `popularity_score / NULLIF(AVG(popularity_score over same weekday, last 8 weeks), 0)` |
| `peer_comparison_rank` | `RANK()` of `popularity_score` among books in the same primary category (via `lib_book_category_jnt`) |
| `shelf_turnover_rate` | `daily_issues / NULLIF(total_copies_for_book, 0)` |
| `waitlist_length` | `COUNT(lib_reservations)` WHERE `book_id=b.id AND status='Pending'` (current snapshot) |
| `avg_wait_days` | `AVG(DATEDIFF(picked_up_or_now, reservation_date))` for reservations of this book in last 90 days |
| `recommendation_weight` | `(popularity_score * 0.5) + (curricular_relevance_score * 0.3) + (student_rating * 10 * 0.2)` |

**Stored Procedure:**
```sql
DELIMITER $$
CREATE PROCEDURE `calculate_book_popularity_trends`()
BEGIN
  DECLARE v_yesterday DATE DEFAULT CURDATE() - INTERVAL 1 DAY;

  -- Step 1: insert/update raw daily counters
  INSERT INTO lib_book_popularity_trends
    (book_id, tracking_date, daily_requests, daily_issues, daily_reservations,
     daily_digital_views, daily_digital_downloads)
  SELECT
    b.id, v_yesterday,
    COALESCE((SELECT COUNT(*) FROM lib_engagement_events e
               WHERE e.book_id = b.id AND e.event_type IN ('View_Details','Add_Reservation')
                 AND DATE(e.created_at) = v_yesterday), 0),
    COALESCE((SELECT COUNT(*) FROM lib_transactions t
               INNER JOIN lib_book_copies c ON c.id = t.copy_id
              WHERE c.book_id = b.id AND DATE(t.issue_date) = v_yesterday), 0),
    COALESCE((SELECT COUNT(*) FROM lib_reservations r
              WHERE r.book_id = b.id AND DATE(r.reservation_date) = v_yesterday), 0),
    COALESCE((SELECT COUNT(*) FROM lib_digital_access_transactions d
              WHERE d.book_id = b.id AND d.access_type IN ('View_Online','Read_Online','Stream')
                AND DATE(d.access_start_at) = v_yesterday), 0),
    COALESCE((SELECT COUNT(*) FROM lib_digital_access_transactions d
              WHERE d.book_id = b.id AND d.access_type = 'Download'
                AND DATE(d.access_start_at) = v_yesterday), 0)
  FROM lib_books_master b
  ON DUPLICATE KEY UPDATE
    daily_requests = VALUES(daily_requests),
    daily_issues = VALUES(daily_issues),
    daily_reservations = VALUES(daily_reservations),
    daily_digital_views = VALUES(daily_digital_views),
    daily_digital_downloads = VALUES(daily_digital_downloads);

  -- Step 2: derived score fields (depend on Step 1 + previous day's row)
  UPDATE lib_book_popularity_trends pt
  LEFT JOIN lib_book_popularity_trends prev
         ON prev.book_id = pt.book_id AND prev.tracking_date = v_yesterday - INTERVAL 1 DAY
  LEFT JOIN (
        SELECT book_id, COUNT(*) AS total_copies FROM lib_book_copies
         WHERE is_active = 1 AND deleted_at IS NULL GROUP BY book_id
     ) copies ON copies.book_id = pt.book_id
  LEFT JOIN (
        SELECT book_id, COUNT(*) AS waitlist_length FROM lib_reservations
         WHERE status = (SELECT id FROM lib_library_status_masters WHERE status_type='Reservation Status' AND code='Pending')
         GROUP BY book_id
     ) wl ON wl.book_id = pt.book_id
  LEFT JOIN lib_books_master b ON b.id = pt.book_id
  SET
    pt.popularity_score = (pt.daily_issues*5) + (pt.daily_reservations*3) + (pt.daily_requests*1)
                           + (pt.daily_digital_views*2) + (pt.daily_digital_downloads*4),
    pt.velocity_score   = ((pt.daily_issues*5) + (pt.daily_reservations*3) + (pt.daily_requests*1)
                           + (pt.daily_digital_views*2) + (pt.daily_digital_downloads*4))
                           - COALESCE(prev.popularity_score, 0),
    pt.trend_direction  = CASE
                             WHEN COALESCE(prev.popularity_score,0) = 0 THEN 'Stable'
                             WHEN ((pt.daily_issues*5) + (pt.daily_reservations*3) + (pt.daily_requests*1)
                                   + (pt.daily_digital_views*2) + (pt.daily_digital_downloads*4)) > prev.popularity_score * 1.1 THEN 'Rising'
                             WHEN ((pt.daily_issues*5) + (pt.daily_reservations*3) + (pt.daily_requests*1)
                                   + (pt.daily_digital_views*2) + (pt.daily_digital_downloads*4)) < prev.popularity_score * 0.9 THEN 'Falling'
                             ELSE 'Stable'
                           END,
    pt.shelf_turnover_rate = pt.daily_issues / NULLIF(copies.total_copies, 0),
    pt.waitlist_length     = COALESCE(wl.waitlist_length, 0),
    pt.recommendation_weight = (((pt.daily_issues*5) + (pt.daily_reservations*3) + (pt.daily_requests*1)
                                 + (pt.daily_digital_views*2) + (pt.daily_digital_downloads*4)) * 0.5)
                              + (b.curricular_relevance_score * 0.3)
                              + (COALESCE(b.student_rating,0) * 10 * 0.2)
  WHERE pt.tracking_date = v_yesterday;

  -- Step 3: peer_comparison_rank (per category) and avg_wait_days
  UPDATE lib_book_popularity_trends pt
  INNER JOIN (
    SELECT pt2.book_id,
           RANK() OVER (PARTITION BY bc.category_id ORDER BY pt2.popularity_score DESC) AS rnk
      FROM lib_book_popularity_trends pt2
      INNER JOIN lib_book_category_jnt bc ON bc.book_id = pt2.book_id
     WHERE pt2.tracking_date = v_yesterday
  ) ranked ON ranked.book_id = pt.book_id
  SET pt.peer_comparison_rank = ranked.rnk
  WHERE pt.tracking_date = v_yesterday;

  UPDATE lib_book_popularity_trends pt
  SET pt.avg_wait_days = (
    SELECT AVG(DATEDIFF(COALESCE(r.notification_sent_at, NOW()), r.reservation_date))
      FROM lib_reservations r
     WHERE r.book_id = pt.book_id
       AND r.reservation_date >= CURDATE() - INTERVAL 90 DAY
  )
  WHERE pt.tracking_date = v_yesterday;

  -- Step 4: seasonality_factor (vs same weekday over last 8 weeks)
  UPDATE lib_book_popularity_trends pt
  SET pt.seasonality_factor = pt.popularity_score / NULLIF((
        SELECT AVG(pt2.popularity_score) FROM lib_book_popularity_trends pt2
         WHERE pt2.book_id = pt.book_id
           AND pt2.tracking_date BETWEEN v_yesterday - INTERVAL 56 DAY AND v_yesterday - INTERVAL 7 DAY
           AND DAYOFWEEK(pt2.tracking_date) = DAYOFWEEK(v_yesterday)
      ), 0)
  WHERE pt.tracking_date = v_yesterday;
END$$
DELIMITER ;

-- Schedule: lib_background_services "Book Popularity Trends - Nightly"
```

---

## 5.3 `lib_collection_health_metrics`
**Type:** Scheduled Job (Weekly) — one row per `(metric_date, category_id, genre_id)`, plus an "all" row where both are `NULL`

| Field | Formula |
|---|---|
| `total_titles` | `COUNT(DISTINCT lib_books_master.id)` for the category/genre (or all) |
| `total_copies` | `COUNT(lib_book_copies)` for those titles |
| `active_titles` | `COUNT(...)` WHERE `lib_books_master.is_active=1` |
| `inactive_titles` | `total_titles - active_titles` |
| `damaged_copies` | `COUNT(lib_book_copies)` WHERE `is_damaged=1` |
| `lost_copies` | `COUNT(...)` WHERE `is_lost=1` |
| `withdrawn_copies` | `COUNT(...)` WHERE `is_withdrawn=1` |
| `utilization_rate` | `(COUNT(copies currently Issued) / total_copies) * 100` |
| `turnover_rate` | `SUM(issues in last 12 months) / NULLIF(total_copies,0)` |
| `age_of_collection` | `AVG(YEAR(CURDATE()) - publication_year)` |
| `collection_diversity_score` | Shannon diversity index across genre distribution within scope |
| `relevance_score` | `AVG(curricular_relevance_score)` of titles in scope |
| `acquisition_effectiveness` | `(SUM(issues for titles purchased in last 12 months) / NULLIF(COUNT(titles purchased in last 12 months),0))` vs collection-wide average issues-per-title |
| `weeding_priority_score` | `100 - utilization_rate` weighted by `age_of_collection` (e.g., `(100-utilization_rate)*0.6 + LEAST(age_of_collection,20)/20*100*0.4`) |
| `budget_allocation_efficiency` | `SUM(issues) / NULLIF(SUM(lib_book_purchases_items.book_net_amt),0)` for the scope |
| `digital_penetration_rate` | `COUNT(titles with resource_type.is_digital=1) / NULLIF(total_titles,0) * 100` |
| `physical_vs_digital_ratio` | `COUNT(physical titles) / NULLIF(COUNT(digital titles),0)` |

**Stored Procedure (overall + per category/genre):**
```sql
DELIMITER $$
CREATE PROCEDURE `calculate_collection_health_metrics`()
BEGIN
  -- Overall (category_id=NULL, genre_id=NULL)
  INSERT INTO lib_collection_health_metrics
    (metric_date, category_id, genre_id, total_titles, total_copies, active_titles, inactive_titles,
     damaged_copies, lost_copies, withdrawn_copies, utilization_rate, turnover_rate, age_of_collection,
     digital_penetration_rate, physical_vs_digital_ratio)
  SELECT
    CURDATE(), NULL, NULL,
    (SELECT COUNT(*) FROM lib_books_master WHERE deleted_at IS NULL),
    (SELECT COUNT(*) FROM lib_book_copies WHERE deleted_at IS NULL),
    (SELECT COUNT(*) FROM lib_books_master WHERE is_active=1 AND deleted_at IS NULL),
    (SELECT COUNT(*) FROM lib_books_master WHERE is_active=0 AND deleted_at IS NULL),
    (SELECT COUNT(*) FROM lib_book_copies WHERE is_damaged=1 AND deleted_at IS NULL),
    (SELECT COUNT(*) FROM lib_book_copies WHERE is_lost=1 AND deleted_at IS NULL),
    (SELECT COUNT(*) FROM lib_book_copies WHERE is_withdrawn=1 AND deleted_at IS NULL),
    (SELECT COUNT(*) FROM lib_book_copies c
       INNER JOIN lib_library_status_masters s ON s.id = c.status
      WHERE s.code='Issued' AND c.deleted_at IS NULL) /
      NULLIF((SELECT COUNT(*) FROM lib_book_copies WHERE deleted_at IS NULL),0) * 100,
    (SELECT COUNT(*) FROM lib_transactions WHERE issue_date >= CURDATE() - INTERVAL 12 MONTH) /
      NULLIF((SELECT COUNT(*) FROM lib_book_copies WHERE deleted_at IS NULL),0),
    (SELECT AVG(YEAR(CURDATE()) - publication_year) FROM lib_books_master WHERE publication_year IS NOT NULL),
    (SELECT COUNT(*) FROM lib_books_master b
       INNER JOIN lib_resource_types rt ON rt.id = b.resource_type_id WHERE rt.is_digital=1) /
      NULLIF((SELECT COUNT(*) FROM lib_books_master),0) * 100,
    (SELECT COUNT(*) FROM lib_books_master b
       INNER JOIN lib_resource_types rt ON rt.id = b.resource_type_id WHERE rt.is_physical=1) /
      NULLIF((SELECT COUNT(*) FROM lib_books_master b
       INNER JOIN lib_resource_types rt ON rt.id = b.resource_type_id WHERE rt.is_digital=1),0);

  -- Per-category rows (repeat similarly with WHERE bc.category_id = c.id, GROUP BY c.id)
  INSERT INTO lib_collection_health_metrics
    (metric_date, category_id, genre_id, total_titles, total_copies, utilization_rate)
  SELECT
    CURDATE(), c.id, NULL,
    COUNT(DISTINCT b.id),
    COUNT(cp.id),
    SUM(CASE WHEN s.code='Issued' THEN 1 ELSE 0 END) / NULLIF(COUNT(cp.id),0) * 100
  FROM lib_categories c
  INNER JOIN lib_book_category_jnt bc ON bc.category_id = c.id
  INNER JOIN lib_books_master b ON b.id = bc.book_id
  LEFT JOIN lib_book_copies cp ON cp.book_id = b.id AND cp.deleted_at IS NULL
  LEFT JOIN lib_library_status_masters s ON s.id = cp.status
  GROUP BY c.id;

  -- collection_diversity_score, relevance_score, acquisition_effectiveness,
  -- weeding_priority_score, budget_allocation_efficiency: second pass, e.g.
  UPDATE lib_collection_health_metrics chm
  SET chm.relevance_score = (
        SELECT AVG(b.curricular_relevance_score)
          FROM lib_books_master b
          LEFT JOIN lib_book_category_jnt bc ON bc.book_id = b.id
         WHERE chm.category_id IS NULL OR bc.category_id = chm.category_id
      ),
      chm.weeding_priority_score = (100 - COALESCE(chm.utilization_rate,0)) * 0.6
                                    + LEAST(COALESCE(chm.age_of_collection,0), 20) / 20 * 100 * 0.4
  WHERE chm.metric_date = CURDATE();
END$$
DELIMITER ;

-- Schedule: lib_background_services "Collection Health Metrics - Weekly"
```

---

## 5.4 `lib_predictive_analytics`
**Type:** AI/ML Service (writes `predicted_value`, `confidence_score`, `model_version`, `features_used_json`, `insights`, `recommendations`) + DB/Scheduled Job for `accuracy_score`

### `predicted_value`, `confidence_score`, `model_version`, `features_used_json`, `insights`, `recommendations`
**Process:**
1. Nightly job exports feature vectors per `target_entity_type`/`target_entity_id` (e.g., for `Demand_Forecast` on a book: `last_3_months_issues`, `last_year_issues`, `popularity_score`, `seasonality_factor`, `curricular relevance`, `reservation waitlist length`, `genre trend`, etc. — see `lib_view_predictive_demand`).
2. Features sent to external ML model/service.
3. Model returns prediction; job inserts:
```sql
INSERT INTO lib_predictive_analytics
  (prediction_date, prediction_type, target_entity_type, target_entity_id,
   prediction_period_start, prediction_period_end, predicted_value, confidence_score,
   model_version, features_used_json, insights, recommendations)
VALUES
  (CURDATE(), 'Demand_Forecast', 'Book', :book_id,
   CURDATE(), CURDATE() + INTERVAL 3 MONTH, :predicted_value, :confidence_score,
   :model_version, :features_used_json, :insights, :recommendations);
```

### `accuracy_score`
**Type:** Scheduled Job (runs at the end of each `prediction_period_end`)
**Formula:**
```
actual_value  = real measured count over [prediction_period_start, prediction_period_end]
                 (e.g., for Demand_Forecast/Book: COUNT(lib_transactions) for that book in the period)
accuracy_score = 100 - ABS(predicted_value - actual_value) / NULLIF(actual_value,0) * 100
                 (clamped to [0,100]; 100 = perfect prediction)
```
```sql
UPDATE lib_predictive_analytics pa
   SET pa.actual_value = (
         SELECT COUNT(*) FROM lib_transactions t
           INNER JOIN lib_book_copies c ON c.id = t.copy_id
          WHERE c.book_id = pa.target_entity_id
            AND t.issue_date BETWEEN pa.prediction_period_start AND pa.prediction_period_end
       )
 WHERE pa.prediction_type = 'Demand_Forecast'
   AND pa.target_entity_type = 'Book'
   AND pa.prediction_period_end < CURDATE()
   AND pa.actual_value IS NULL;

UPDATE lib_predictive_analytics
   SET accuracy_score = GREATEST(0, LEAST(100,
         100 - (ABS(predicted_value - actual_value) / NULLIF(actual_value,0) * 100)
       ))
 WHERE actual_value IS NOT NULL AND accuracy_score IS NULL;
```

---

## 5.5 `lib_curricular_alignment`
**Type:** Scheduled Job (Weekly/Termly)

| Field | Formula |
|---|---|
| `student_usage_count` | `COUNT(lib_transactions)` WHERE `book_id=ca.book_id AND member.user_type='Student' AND member's class = ca.class_id AND issue_date in academic_year_id` |
| `exam_reference_count` | `COUNT` of references in exam-paper question bank (cross-module — from Exam module's question→resource mapping; if not yet linked, set via App Real-time when faculty tags an exam question with a library resource) |
| `assignment_citations` | `COUNT` of references in Assignment module submissions that cite this `book_id` (cross-module, App Real-time on citation save) |
| `alignment_score` | AI/ML or rule-based: `(student_usage_count normalized * 0.4) + (faculty_rating/5*100 * 0.3) + (exam_reference_count normalized * 0.15) + (assignment_citations normalized * 0.15)` |

```sql
DELIMITER $$
CREATE PROCEDURE `calculate_curricular_alignment`(IN p_academic_year_id INT UNSIGNED)
BEGIN
  UPDATE lib_curricular_alignment ca
     SET ca.student_usage_count = (
           SELECT COUNT(*) FROM lib_transactions t
             INNER JOIN lib_book_copies c ON c.id = t.copy_id
             INNER JOIN lib_members m ON m.id = t.member_id
             INNER JOIN sys_users u ON u.id = m.user_id
             -- cross-module: student's current class via sch_student_enrollments (or equivalent)
             INNER JOIN sch_student_enrollments se ON se.user_id = u.id AND se.academic_year_id = p_academic_year_id
            WHERE c.book_id = ca.book_id
              AND se.class_id = ca.class_id
              AND m.user_type = 'Student'
              AND t.issue_date BETWEEN (SELECT start_date FROM academic_years WHERE id = p_academic_year_id)
                                    AND (SELECT end_date FROM academic_years WHERE id = p_academic_year_id)
         )
   WHERE ca.academic_year_id = p_academic_year_id;

  -- alignment_score: normalize student_usage_count against the max for the same class+subject
  UPDATE lib_curricular_alignment ca
  INNER JOIN (
    SELECT class_id, subject_id, MAX(student_usage_count) AS max_usage,
           MAX(exam_reference_count) AS max_exam, MAX(assignment_citations) AS max_assign
      FROM lib_curricular_alignment
     WHERE academic_year_id = p_academic_year_id
     GROUP BY class_id, subject_id
  ) mx ON mx.class_id = ca.class_id AND mx.subject_id = ca.subject_id
  SET ca.alignment_score =
        (ca.student_usage_count / NULLIF(mx.max_usage,0) * 100 * 0.4)
      + (COALESCE(ca.faculty_rating,0) / 5 * 100 * 0.3)
      + (ca.exam_reference_count / NULLIF(mx.max_exam,0) * 100 * 0.15)
      + (ca.assignment_citations / NULLIF(mx.max_assign,0) * 100 * 0.15)
  WHERE ca.academic_year_id = p_academic_year_id;
END$$
DELIMITER ;

-- Schedule: lib_background_services "Curricular Alignment - Weekly"
```

---

## 5.6 `lib_engagement_events`
**Type:** App Real-time (write-only event log; no calculated columns — but feeds all the analytics above)
**Formula:** Every member interaction (search, view, reserve, download, review, etc.) is inserted directly by the app:
```sql
INSERT INTO lib_engagement_events
  (member_id, event_type, book_id, digital_resource_id, search_query, filters_used_json,
   session_id, device_type, browser, ip_address, location_id, time_spent_seconds, interaction_outcome)
VALUES
  (:member_id, :event_type, :book_id, :digital_resource_id, :search_query, :filters_used_json,
   :session_id, :device_type, :browser, :ip_address, :location_id, :time_spent_seconds, :interaction_outcome);
```
This table is the **primary input feed** for §5.1, §5.2 and member `engagement_score` in §2.1 — no field within this table itself is derived.

---

# 6. Sub-Menu 9 — NEW TABLES (NT-001 to NT-005)

## 6.1 `lib_book_reviews_ratings` (NT-001)
No calculated fields of its own — it is the **source table** driving `lib_books_master.student_rating`, `rating_count`, `academic_rating` (see §1.1). `is_approved` is a manual moderation action (App Real-time, not calculated).

## 6.2 `lib_wishlist` (NT-002)
No calculated fields — purely user-entered (`priority`, `notes`).
*Optional enhancement:* a nightly job could cross-reference `lib_wishlist` against `lib_books_master.is_available` to trigger "now available" notifications, but no DB field stores a calculated value.

## 6.3 `lib_digital_access_request_types` (NT-003), `lib_library_settings` (NT-004), `lib_background_services` (NT-005)
Pure configuration/master tables — no calculated fields.
- `lib_background_services.last_run_at` and `last_status` are updated by each scheduled job itself at the end of its run:
```sql
UPDATE lib_background_services
   SET last_run_at = NOW(), last_status = 'Success'
 WHERE service_name = :job_name;
```

---

# 7. Views Used as Calculation Sources (On-Demand)

These existing views (Sub-Menu 12 of the DDL) compute values **at query time** and do not require storage — they are listed here because their expressions double as the formula reference for several fields above:

| View | Calculated Expression | Relates To |
|---|---|---|
| `lib_view_member_360` | `days_since_last_activity = DATEDIFF(CURDATE(), m.last_activity_date)`<br>`activity_status = CASE ... 'New'/'Active'/'At Risk'/'Inactive'` | §2.1 `member_segment` (activity_status can feed segmentation) |
| `lib_view_collection_performance` | `demand_category = CASE COUNT(t.id) > 100/50/10 ...` | §5.3 collection health "relevance" |
| `lib_view_predictive_demand` | `acquisition_recommendation = CASE pa.predicted_value > 50/30/10 ...` | §5.4 `lib_predictive_analytics.recommendations` |
| `lib_view_overdue_books` | `days_overdue = DATEDIFF(CURDATE(), t.due_date)`<br>`estimated_fine = days_overdue * fine_rate_per_day` | §3.4 `lib_fines.amount` (simple fallback formula before slab-based calc) |
| `lib_view_most_issued_books` | `issue_count = COUNT(t.id)`, `avg_loan_days = AVG(DATEDIFF(return_date, issue_date))` | §5.2 `lib_book_popularity_trends` |

**Recommended new view** — `activity_status` from `lib_view_member_360` should be promoted into the `member_segment` calculation in §2.1 by including it as an input signal (e.g., `'Inactive'` activity_status → forces `'Inactive'` or `'At-Risk'` segment regardless of score).

---

# 8. Summary — Calculated Fields Index

| Table | Field(s) | Trigger Type | Section |
|---|---|---|---|
| `lib_books_master` | `is_available` | DB Trigger | §1.1 |
| `lib_books_master` | `student_rating`, `rating_count`, `academic_rating` | DB Trigger | §1.1 |
| `lib_books_master` | `popularity_rank` | Scheduled Job (Daily) | §1.1 |
| `lib_books_master` | `tags_json`, `ai_summary`, `key_concepts_json`, `lexile_level`, `reading_age_range` | AI/ML Service | §1.1 |
| `lib_books_master` | `curricular_relevance_score` | Scheduled Job (Weekly) | §1.1 |
| `lib_book_purchases` | `bill_amt`, `bill_tax_amt`, `bill_net_amt` | App Real-time + DB Trigger | §1.2 |
| `lib_book_purchases_items` | `book_amt`, `book_tax_amt`, `book_net_amt` | DB Trigger (BEFORE) | §1.3 |
| `lib_book_copies` | `status` | DB Trigger (existing) + App Real-time | §1.4 |
| `lib_digital_resources` | `download_count`, `view_count` | DB Trigger | §1.5 |
| `lib_digital_resources` | `status` | Scheduled Job (Daily) + App Real-time | §1.5 |
| `lib_members` | `total_books_borrowed`, `last_activity_date` | DB Trigger (existing + extended) | §2.1 |
| `lib_members` | `total_fines_paid`, `outstanding_fines` | DB Trigger | §2.1 |
| `lib_members` | `reading_progress_ytd` | DB Trigger + Scheduled Job (yearly reset) | §2.1 |
| `lib_members` | `engagement_score`, `churn_risk_score`, `lifetime_value`, `member_segment`, `last_segment_calculation` | Scheduled Job (Weekly) | §2.1 |
| `lib_reservations` | `queue_position` | App Real-time + DB Trigger (resequence) | §3.1 |
| `lib_reservations` | `expected_available_date` | DB Trigger + Scheduled Job | §3.1 |
| `lib_reservations` | `notification_sent`, `notification_sent_at`, `pickup_by_date`, `status` (Available/Expired) | DB Trigger + Scheduled Job (Daily) | §3.1 |
| `lib_transactions` | `renewal_count`, `is_renewed`, `due_date` (on renewal) | App Real-time | §3.2 |
| `lib_transactions` | `status` (→Overdue) | Scheduled Job (Daily) | §3.2 |
| `lib_digital_access_transactions` | `download_count`, `is_downloaded`, `*_downloaded_at`, `download_history_json`, etc. | App Real-time | §3.3 |
| `lib_digital_access_transactions` | `view_count`, `total_view_duration_sec`, `last_accessed_at`, etc. | App Real-time | §3.3 |
| `lib_digital_access_transactions` | `status` (→Expired) | Scheduled Job (Daily) | §3.3 |
| `lib_fines` | `amount`, `days_overdue`, `calculation_breakdown_json`, `fine_slab_config_id` | DB Event (Daily) | §3.4 |
| `lib_fines` | `status` (→Paid/Overdue) | DB Trigger + Scheduled Job (Daily) | §3.4 |
| `lib_inventory_audit_details` | `status` (Found/Missing/Misplaced/Damaged) | App Real-time | §4.1 |
| `lib_inventory_audit` | `total_scanned`, `total_expected`, `missing_copies`, `misplaced_copies`, `damaged_copies` | DB Trigger + App Real-time | §4.2 |
| `lib_reading_behavior_analytics` | All analytic columns | Scheduled Job (Nightly) | §5.1 |
| `lib_book_popularity_trends` | All analytic columns | Scheduled Job (Nightly) | §5.2 |
| `lib_collection_health_metrics` | All analytic columns | Scheduled Job (Weekly) | §5.3 |
| `lib_predictive_analytics` | `predicted_value`, `confidence_score`, etc. | AI/ML Service | §5.4 |
| `lib_predictive_analytics` | `actual_value`, `accuracy_score` | Scheduled Job (post-period) | §5.4 |
| `lib_curricular_alignment` | `student_usage_count`, `exam_reference_count`, `assignment_citations`, `alignment_score` | Scheduled Job (Weekly/Termly) | §5.5 |

---

# 9. Implementation Notes

1. **Order of deployment:** Existing DDL triggers (`update_member_borrowed_count`, `update_copy_status_on_issue`, `update_copy_status_on_return`, `auto_calculate_fines`) should be replaced/extended carefully — drop and recreate within a migration, since MySQL does not support `CREATE OR REPLACE TRIGGER`.
2. **`auto_calculate_fines` → `auto_calculate_fines_v2`:** The original event remains valid as a fallback when no `lib_fine_slab_config` row matches; the v2 event supersedes it. Drop the old event when v2 is deployed (`DROP EVENT auto_calculate_fines;`).
3. **Register every Scheduled Job** in `lib_background_services` (NT-005) so each run's `last_run_at`/`last_status` is auditable from the admin UI.
4. **All `JSON_ARRAYAGG` / `ROW_NUMBER() OVER (...)` usages require MySQL 8.0+** (already the platform baseline per DDL header).
5. **Cross-module dependencies** (marked in §5.5): `sch_student_enrollments`, Exam module question-bank, Assignment module citations — these tables/columns must exist in their respective modules before `calculate_curricular_alignment` can populate `exam_reference_count` / `assignment_citations`; until then, those two columns remain `0` (default).
