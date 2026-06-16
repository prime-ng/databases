Library Module - Data Schema
============================

Master Tables (Static Setup)
----------------------------
-- Common defaults
-- Use InnoDB for FK support; utf8mb4 for full Unicode
-- SET sql_notes = 0; -- (optional) to suppress FK creation order warnings

CREATE TABLE book_languages (
  id     INT AUTO_INCREMENT PRIMARY KEY,
  language_name   VARCHAR(100) NOT NULL,
  UNIQUE KEY uk_language_name (language_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE category_subjects (
  id     INT AUTO_INCREMENT PRIMARY KEY,
  category_name   VARCHAR(150) NOT NULL,
  subcategory_name VARCHAR(150),
  dewey_no        VARCHAR(20),              -- Dewey/Class No (e.g., '530', '004.16')
  UNIQUE KEY uk_cat_sub (category_name, subcategory_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE book_publisher (
  id    INT AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(200) NOT NULL,
  city            VARCHAR(120),
  country         VARCHAR(120),
  contact         VARCHAR(120),
  email           VARCHAR(150),
  gstin           VARCHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE authors (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  author_name     VARCHAR(200) NOT NULL,
  country         VARCHAR(120),
  primary_genre   VARCHAR(120),
  notes           text DEFAULT NULL
  KEY idx_author_name (author_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE vendors (
  id       INT AUTO_INCREMENT PRIMARY KEY,
  name     VARCHAR(200) NOT NULL,
  contact_person  VARCHAR(120),
  phone           VARCHAR(50),
  email           VARCHAR(150),
  address         VARCHAR(300),
  gstin           VARCHAR(20),
  payment_terms   VARCHAR(120)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `cataloguing` (
  `accession_no` int(11) NOT NULL,
  `book_id` int(11) DEFAULT NULL,
  `copy_no` int(11) DEFAULT NULL,
  `shelf_id` int(11) DEFAULT NULL,
  `barcode_rfid` varchar(100) DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `source` varchar(50) DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL,
  `added_date` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE member_type (
  id      INT AUTO_INCREMENT PRIMARY KEY,
  type_name           VARCHAR(50) NOT NULL,     -- Student/Teacher/Staff/External
  max_books_allowed   INT NOT NULL DEFAULT 3,
  loan_period_days    INT NOT NULL DEFAULT 14,
  fine_per_day        DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  grace_period_days   INT NOT NULL DEFAULT 0,
  UNIQUE KEY uk_member_type (type_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

Fields not in current version
  type_code           VARCHAR(10) NOT NULL,     -- e.g., STU, STF
  max_renewals_allowed INT NOT NULL DEFAULT 2,
  reservation_limit   INT NOT NULL DEFAULT 3,
  can_borrow_digital  TINYINT(1) NOT NULL DEFAULT 1,
  digital_borrow_limit INT NOT NULL DEFAULT 2,
  status              ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',

-- Members (operational profile)
CREATE TABLE members (
  member_id       INT AUTO_INCREMENT PRIMARY KEY,
  member_type_id  INT NOT NULL,
  plan_id         INT NOT NULL,
  name            VARCHAR(200) NOT NULL,
  class_dept      VARCHAR(120),
  contact         VARCHAR(120),
  email           VARCHAR(150),
  address         VARCHAR(300),
  join_date       DATE NOT NULL,
  expiry_date     DATE NOT NULL,
  card_no         VARCHAR(50),
  status          ENUM('Active','Inactive','Suspended') DEFAULT 'Active',
  CONSTRAINT fk_member_type FOREIGN KEY (member_type_id) REFERENCES member_type_master(member_type_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_member_plan FOREIGN KEY (plan_id)        REFERENCES membership_plan_master(plan_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  KEY idx_member_name (name),
  KEY idx_member_expiry (expiry_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE library_locations (
  shelf_id        INT AUTO_INCREMENT PRIMARY KEY,
  block           VARCHAR(50),
  floor           VARCHAR(50),
  aisle           VARCHAR(50),
  rack            VARCHAR(50),
  shelf_no        VARCHAR(50),
  KEY idx_location (block, floor, aisle, rack, shelf_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE digital_resource (
  digital_id      		INT AUTO_INCREMENT PRIMARY KEY,
  title           		VARCHAR(200) NOT NULL,
  provider        		VARCHAR(150),
  access_url      		VARCHAR(500),
  license_type    		VARCHAR(100),
  Max_concurrent_user	INT,
  valid_upto      		DATE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Core Book (title-level) record
CREATE TABLE book_master (
  book_id         INT AUTO_INCREMENT PRIMARY KEY,
  isbn            VARCHAR(20),
  title           VARCHAR(300) NOT NULL,
  subtitle        VARCHAR(300),
  edition         VARCHAR(50),
  publication_year SMALLINT,
  pages           INT,
  category_id     INT,
  language_id     INT,
  publisher_id    INT,
  keywords        VARCHAR(500),
  CONSTRAINT fk_book_category  FOREIGN KEY (category_id) REFERENCES category_master(category_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_book_language  FOREIGN KEY (language_id) REFERENCES language_master(language_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_book_publisher FOREIGN KEY (publisher_id) REFERENCES publisher_master(publisher_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_book_series    FOREIGN KEY (series_id)   REFERENCES series_master(series_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  KEY idx_book_title (title),
  KEY idx_book_isbn (isbn)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Many-to-many: a book can have multiple authors
CREATE TABLE book_authors (
  book_id   INT NOT NULL,
  author_id INT NOT NULL,
  PRIMARY KEY (book_id, author_id),
  CONSTRAINT fk_ba_book   FOREIGN KEY (book_id)   REFERENCES book_master(book_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ba_author FOREIGN KEY (author_id) REFERENCES author_master(author_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


----------------- Removed ---------------------------------------

CREATE TABLE holiday_calendar (
  holiday_id      INT AUTO_INCREMENT PRIMARY KEY,
  date            DATE NOT NULL,
  reason          VARCHAR(200),
  is_half_day     TINYINT(1) NOT NULL DEFAULT 0,
  UNIQUE KEY uk_holiday_date (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE circulation_policy_master (
  policy_id           INT AUTO_INCREMENT PRIMARY KEY,
  member_type_id      INT NOT NULL,
  category_id         INT NOT NULL,
  max_loans           INT NOT NULL DEFAULT 3,
  loan_period_days    INT NOT NULL DEFAULT 14,
  renewals_allowed    INT NOT NULL DEFAULT 2,
  fine_per_day        DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  grace_days          INT NOT NULL DEFAULT 0,
  CONSTRAINT fk_circ_membertype
    FOREIGN KEY (member_type_id) REFERENCES member_type_master(member_type_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_circ_category
    FOREIGN KEY (category_id) REFERENCES category_master(category_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  UNIQUE KEY uk_circ_combo (member_type_id, category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE membership_plan_master (
  plan_id         INT AUTO_INCREMENT PRIMARY KEY,
  member_type_id  INT NOT NULL,
  validity_months INT NOT NULL DEFAULT 12,
  fee             DECIMAL(10,2) DEFAULT 0.00,
  deposit         DECIMAL(10,2) DEFAULT 0.00,
  benefits        VARCHAR(300),
  CONSTRAINT fk_plan_membertype
    FOREIGN KEY (member_type_id) REFERENCES member_type_master(member_type_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE series_master (
  series_id       INT AUTO_INCREMENT PRIMARY KEY,
  series_title    VARCHAR(200) NOT NULL,
  publisher_id    INT,
  CONSTRAINT fk_series_publisher
    FOREIGN KEY (publisher_id) REFERENCES publisher_master(publisher_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


----------------------------------------------------------------------------------------------------------------------------------------------------------------------

Transaction Tables (Dynamic Activity)
-------------------------------------

-- Requests/Ordering/Receiving
CREATE TABLE acquisition_requests (
  request_id          INT AUTO_INCREMENT PRIMARY KEY,
  requested_by_member_id INT,
  title              VARCHAR(300),
  author             VARCHAR(200),
  isbn               VARCHAR(20),
  format             ENUM('Book','Periodical') DEFAULT 'Book',
  reason             VARCHAR(300),
  priority           ENUM('Low','Medium','High') DEFAULT 'Medium',
  status             ENUM('Open','Approved','Ordered','Closed','Rejected') DEFAULT 'Open',
  requested_on       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ar_member FOREIGN KEY (requested_by_member_id) REFERENCES /* optionally */ members(member_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE purchase_orders (
  po_id          INT AUTO_INCREMENT PRIMARY KEY,
  vendor_id      INT NOT NULL,
  request_id     INT,
  order_date     DATE NOT NULL,
  expected_date  DATE,
  status         ENUM('Draft','Issued','Partially Received','Closed','Cancelled') DEFAULT 'Issued',
  CONSTRAINT fk_po_vendor  FOREIGN KEY (vendor_id)  REFERENCES vendor_master(vendor_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_po_request FOREIGN KEY (request_id) REFERENCES acquisition_requests(request_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE po_items (
  po_item_id     INT AUTO_INCREMENT PRIMARY KEY,
  po_id          INT NOT NULL,
  isbn_or_book_id VARCHAR(40),  -- keep flexible: ISBN at order time; later map to book_id
  title          VARCHAR(300),
  qty            INT NOT NULL,
  unit_price     DECIMAL(10,2) NOT NULL,
  tax_pct        DECIMAL(5,2) DEFAULT 0.00,
  CONSTRAINT fk_poi_po FOREIGN KEY (po_id) REFERENCES purchase_orders(po_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  KEY idx_poi_po (po_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE grns (
  grn_id         INT AUTO_INCREMENT PRIMARY KEY,
  po_id          INT NOT NULL,
  vendor_id      INT NOT NULL,
  receipt_date   DATE NOT NULL,
  invoice_no     VARCHAR(50),
  invoice_date   DATE,
  short_excess_note VARCHAR(300),
  CONSTRAINT fk_grn_po     FOREIGN KEY (po_id)     REFERENCES purchase_orders(po_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_grn_vendor FOREIGN KEY (vendor_id) REFERENCES vendor_master(vendor_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE grn_items (
  grn_item_id    INT AUTO_INCREMENT PRIMARY KEY,
  grn_id         INT NOT NULL,
  isbn_or_book_id VARCHAR(40),
  received_qty   INT NOT NULL,
  accepted_qty   INT NOT NULL,
  rejected_qty   INT NOT NULL DEFAULT 0,
  CONSTRAINT fk_gi_grn FOREIGN KEY (grn_id) REFERENCES grns(grn_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  KEY idx_gi_grn (grn_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Accessioning (physical copies) – created via Entry screen
CREATE TABLE accession_copies (
  accession_no    VARCHAR(40) PRIMARY KEY,       -- unique per physical copy
  book_id         INT NOT NULL,
  copy_no         INT NOT NULL,
  shelf_id        INT,
  barcode_rfid    VARCHAR(80),
  price           DECIMAL(10,2),
  source          ENUM('Purchase','Donation','Transfer') DEFAULT 'Purchase',
  status          ENUM('Available','Issued','Reserved','Damaged','Lost','In-Audit') DEFAULT 'Available',
  added_date      DATE NOT NULL DEFAULT (CURRENT_DATE),
  condition_grade ENUM('New','Good','Fair','Poor') DEFAULT 'Good',
  last_inventory_check_on DATE,
  notes           VARCHAR(300),
  CONSTRAINT fk_copy_book  FOREIGN KEY (book_id)  REFERENCES book_master(book_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_copy_shelf FOREIGN KEY (shelf_id) REFERENCES shelf_master(shelf_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  UNIQUE KEY uk_book_copy (book_id, copy_no),
  KEY idx_copy_status (status),
  KEY idx_copy_shelf (shelf_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE renewals (
  renewal_id      BIGINT AUTO_INCREMENT PRIMARY KEY,
  loan_id         BIGINT NOT NULL,
  old_due_date    DATE NOT NULL,
  new_due_date    DATE NOT NULL,
  renewal_count   INT NOT NULL DEFAULT 1,
  CONSTRAINT fk_ren_loan FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  KEY idx_ren_loan (loan_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE reservations (
  reservation_id  BIGINT AUTO_INCREMENT PRIMARY KEY,
  member_id       INT NOT NULL,
  book_id         INT NOT NULL,
  request_date    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expiry_date     DATE,
  status          ENUM('Queued','Ready','Picked','Cancelled') DEFAULT 'Queued',
  CONSTRAINT fk_res_member FOREIGN KEY (member_id) REFERENCES members(member_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_res_book   FOREIGN KEY (book_id)   REFERENCES book_master(book_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  KEY idx_res_member (member_id),
  KEY idx_res_book (book_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE fine_receipts (
  receipt_id      BIGINT AUTO_INCREMENT PRIMARY KEY,
  member_id       INT NOT NULL,
  loan_id         BIGINT,
  reason          ENUM('Overdue','Damaged','Lost') NOT NULL,
  amount          DECIMAL(10,2) NOT NULL,
  mode            ENUM('Cash','Card','UPI','Online') NOT NULL,
  receipt_date    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ref_no          VARCHAR(100),
  CONSTRAINT fk_fine_member FOREIGN KEY (member_id) REFERENCES members(member_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_fine_loan   FOREIGN KEY (loan_id)   REFERENCES loans(loan_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  KEY idx_fine_member (member_id),
  KEY idx_fine_date (receipt_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE damage_loss_reports (
  report_id       BIGINT AUTO_INCREMENT PRIMARY KEY,
  accession_no    VARCHAR(40) NOT NULL,
  report_type     ENUM('Damaged','Lost') NOT NULL,
  report_date     DATE NOT NULL,
  notes           VARCHAR(300),
  replacement_cost DECIMAL(10,2),
  action          ENUM('Repair','Replace','WriteOff') DEFAULT 'Repair',
  CONSTRAINT fk_dlr_copy FOREIGN KEY (accession_no) REFERENCES accession_copies(accession_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  KEY idx_dlr_copy (accession_no),
  KEY idx_dlr_date (report_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE stock_audits (
  audit_id        INT AUTO_INCREMENT PRIMARY KEY,
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  auditor         VARCHAR(150),
  remarks         VARCHAR(300)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE stock_audit_lines (
  audit_line_id   BIGINT AUTO_INCREMENT PRIMARY KEY,
  audit_id        INT NOT NULL,
  accession_no    VARCHAR(40) NOT NULL,
  system_qty      INT NOT NULL DEFAULT 1,
  physical_qty    INT NOT NULL DEFAULT 1,
  variance        INT NOT NULL DEFAULT 0,
  action          ENUM('None','Locate','WriteOff','Update') DEFAULT 'None',
  CONSTRAINT fk_sal_audit FOREIGN KEY (audit_id)     REFERENCES stock_audits(audit_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_sal_copy  FOREIGN KEY (accession_no) REFERENCES accession_copies(accession_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  KEY idx_sal_audit (audit_id),
  KEY idx_sal_copy (accession_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE vendor_invoices (
  invoice_id      INT AUTO_INCREMENT PRIMARY KEY,
  vendor_id       INT NOT NULL,
  po_id           INT,
  invoice_no	  VARCHAR(15),
  invoice_date    DATE NOT NULL,
  amount          DECIMAL(12,2) NOT NULL,
  tax_amount      DECIMAL(12,2) DEFAULT 0.00,
  paid_status     ENUM('Unpaid','Partial','Paid') DEFAULT 'Unpaid',
  CONSTRAINT fk_vi_vendor FOREIGN KEY (vendor_id) REFERENCES vendor_master(vendor_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_vi_po     FOREIGN KEY (po_id)     REFERENCES purchase_orders(po_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Digital usage
CREATE TABLE digital_access_logs (
  log_id         BIGINT AUTO_INCREMENT PRIMARY KEY,
  member_id      INT NOT NULL,
  digital_id     INT NOT NULL,
  access_datetime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  duration_mins  INT,
  CONSTRAINT fk_dal_member FOREIGN KEY (member_id)  REFERENCES members(member_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_dal_digital FOREIGN KEY (digital_id) REFERENCES digital_resource_master(digital_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  KEY idx_dal_member (member_id),
  KEY idx_dal_digital (digital_id),
  KEY idx_dal_time (access_datetime)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Feedback / ratings
CREATE TABLE feedback_ratings (
  feedback_id    BIGINT AUTO_INCREMENT PRIMARY KEY,
  member_id      INT NOT NULL,
  accession_no   VARCHAR(40),   -- optional: feedback on a specific copy
  book_id        INT,           -- or on title
  rating         TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comments       VARCHAR(500),
  feedback_on     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_fr_member FOREIGN KEY (member_id)    REFERENCES members(member_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_fr_copy   FOREIGN KEY (accession_no) REFERENCES accession_copies(accession_no)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_fr_book   FOREIGN KEY (book_id)      REFERENCES book_master(book_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  KEY idx_fr_book (book_id),
  KEY idx_fr_member (member_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;







CREATE TABLE membership_renewals (
  renewal_id      BIGINT AUTO_INCREMENT PRIMARY KEY,
  member_id       INT NOT NULL,
  old_expiry      DATE NOT NULL,
  new_expiry      DATE NOT NULL,
  fee             DECIMAL(10,2) DEFAULT 0.00,
  receipt_no      VARCHAR(100),
  renewed_on      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_mr_member FOREIGN KEY (member_id) REFERENCES members(member_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  KEY idx_mr_member (member_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Circulation
CREATE TABLE loans (
  loan_id         BIGINT AUTO_INCREMENT PRIMARY KEY,
  accession_no    VARCHAR(40) NOT NULL,
  member_id       INT NOT NULL,
  policy_id       INT,
  issue_date      DATE NOT NULL,
  due_date        DATE NOT NULL,
  return_date     DATE,
  condition_on_return ENUM('New','Good','Fair','Poor'),
  overdue_days    INT DEFAULT 0,
  fine_amount     DECIMAL(10,2) DEFAULT 0.00,
  waiver_amount   DECIMAL(10,2) DEFAULT 0.00,
  remarks         VARCHAR(300),
  CONSTRAINT fk_loan_copy   FOREIGN KEY (accession_no) REFERENCES accession_copies(accession_no)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_loan_member FOREIGN KEY (member_id)     REFERENCES members(member_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_loan_policy FOREIGN KEY (policy_id)     REFERENCES circulation_policy_master(policy_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  KEY idx_loan_member (member_id),
  KEY idx_loan_dates (issue_date, due_date),
  KEY idx_loan_copy (accession_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


----------------------------------------------------------------------------------------------------------------------------------------------------------------------


Notes & Best‑Practice Indexes
-----------------------------
Lookups & KPIs
--------------
members(expiry_date) → “Upcoming Membership Expiries” widget/report
loans(issue_date, due_date, return_date) → daily issuance/returns, overdue
reservations(status) → queue and ready‑to‑pick counts
accession_copies(status, shelf_id) → availability and shelf utilization
digital_access_logs(access_datetime) → trend charts

Data Integrity
--------------
book_authors as a junction ensures clean many‑to‑many mapping.
accession_copies created only through Accessioning screen but referenced by Loans, Audits, Damage/Loss.
Use ON DELETE RESTRICT for critical references to avoid accidental cascades.


