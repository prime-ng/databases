# Complete Data Dictionary for Library Module (v2 — aligned to Library_ddl_v6.sql)

## Overview
This data dictionary documents all tables, fields, relationships, and business purposes for the Library Module (v6) in the Prime-AI Multi-Tenant ERP/LMS/LXP system. It reflects the comprehensive fixes (F-001 to F-045) and new tables (NT-001 to NT-005) introduced in v6, replacing the earlier v1 data dictionary which was based on a pre-v6 schema.

---

## Sub-Menu 1: BOOK MASTERS

### Table Name: lib_resource_types
**Purpose:** Classification of resource formats (physical books, e-books, PDFs, audio books, etc.) to handle different media types appropriately.

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each resource type
|code             |Business code (e.g., 'PHY_BOOK', 'EBOOK')
|name             |Display name (e.g., 'Physical Book', 'E-Book')
|is_physical      |Whether this is a physical resource
|is_digital       |Whether this is a digital resource
|is_audio_books   |Whether this resource type represents audio books
|is_borrowable    |Whether resources of this type can be borrowed
|is_active        |Whether this resource type is currently active
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp


### Table Name: lib_categories
**Purpose:** Hierarchical classification of books/resources (e.g., Fiction → Science Fiction → Space Opera). Supports multi-level categorization. Parent-child grouping is used for showing categories under their parent category.

|Field Name          |Description
|---------------------|-----------------------------------------------------------------
|id                   |Unique identifier for each category
|parent_category_id   |Self-reference (FK to lib_categories.id) for hierarchical categories
|code                 |Business code (e.g., 'FIC', 'SCI_FI')
|name                 |Display name (e.g., 'Fiction', 'Science Fiction')
|description          |Detailed description of the category
|level                |Depth in hierarchy (1 = top level)
|display_order        |Order for display in dropdowns
|is_active            |Whether this category is currently active
|created_at           |Record creation timestamp
|updated_at           |Last update timestamp
|deleted_at           |Soft delete timestamp


### Table Name: lib_genres
**Purpose:** Tags for literary genres that can be applied across categories for flexible searching and recommendations.

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each genre
|code             |Business code (e.g., 'SF', 'MYSTERY')
|name             |Display name (e.g., 'Science Fiction', 'Mystery')
|description      |Description of the genre
|is_active        |Whether this genre is currently active
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp


### Table Name: lib_book_conditions
**Purpose:** Standardized condition states for physical books to track wear and tear, damage, and usability.

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each condition
|code             |Business code (e.g., 'NEW', 'DAMAGED')
|name             |Display name (e.g., 'New', 'Damaged')
|description      |Detailed description of the condition
|is_borrowable    |Whether books in this condition can be issued
|is_active        |Whether this condition is currently active
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp


### Table Name: lib_publishers
**Purpose:** Master list of publishers for books and resources.

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each publisher
|code             |Business code for the publisher
|name             |Full name of the publishing company
|address          |Physical/registered address
|contact          |Primary contact person
|email            |Contact email address
|phone            |Contact phone number
|website          |Publisher's website URL
|is_active        |Whether this publisher is currently active
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp


### Table Name: lib_authors  *(NEW in v6)*
**Purpose:** Master list of authors for books and resources.

|Field Name          |Description
|---------------------|-----------------------------------------------------------------
|id                   |Unique identifier for each author
|short_name           |Short identifier or pen name for the author
|author_name          |Full name of the author
|country_id           |FK to glb_countries.id — country of the author
|primary_genre_id     |FK to lib_genres.id — primary genre preference of the author
|notes                |Additional notes about the author
|is_active            |Whether this author record is active
|created_at           |Record creation timestamp
|updated_at           |Last update timestamp
|deleted_at           |Soft delete timestamp


### Table Name: lib_keywords  *(NEW in v6)*
**Purpose:** Searchable keywords that can be applied across books for flexible discovery and filtering.

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each keyword
|code             |Business code for the keyword
|name             |Keyword text
|is_active        |Whether this keyword is currently active
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp


---

## Sub-Menu 2: LOCATION MASTERS

### Table Name: lib_location_master  *(NEW in v6)*
**Purpose:** Holds all available options for Zone, Floor, Aisle, Shelf, and Rack. Each row represents a single location element referenced by lib_shelf_locations.

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each location element
|code             |Business code (e.g., 'A1-S1-R1')
|name             |Display name (e.g., 'Aisle 1', 'Shelf 1')
|description      |Detailed description of the location
|location_type    |Type of location element: 'Zone', 'Floor', 'Aisle', 'Shelf', 'Rack' (renamed from `type` to avoid reserved word)
|building_id      |FK to sch_buildings.id
|is_active        |Whether this location element is currently active
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp

**Conditions:**
- An aisle is the open passage/walkway between rows of shelving units.
- A shelf is a flat, horizontal surface used for storing/displaying items.
- A rack is a framework (bars/hooks) used for storing/displaying items.
- A floor is the lower surface of a room.
- A zone is an area/section having a particular characteristic, purpose, or restriction.


### Table Name: lib_shelf_locations
**Purpose:** Physical location mapping for books in the library, enabling efficient shelving and retrieval. Combines references to building, zone, floor, aisle, rack, and shelf (each resolved via lib_location_master).

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each shelf location
|code             |Business code (e.g., 'A1-S1-R1')
|building_id      |FK to sch_buildings.id
|zone_id          |FK to lib_location_master.id — zone or section
|floor_id         |FK to lib_location_master.id — floor/level in the building
|aisle_id         |FK to lib_location_master.id — aisle identifier (1 aisle can have multiple racks; 1 rack can have multiple shelves)
|rack_id          |FK to lib_location_master.id — rack identifier
|shelf_id         |FK to lib_location_master.id — shelf identifier within aisle
|description      |Additional location details
|is_active        |Whether this location is currently active
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp


---

## Sub-Menu 3: LIBRARY CONFIGURATION

### Table Name: lib_fine_type  *(NEW in v6)*
**Purpose:** Master list of fine types applicable in the library (late return, lost book, damaged book, processing fee, etc.).

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each fine type
|code             |Code for the fine type (e.g., 'LateReturn', 'LostBook', 'DamagedBook', 'ProcessingFee')
|name             |Name of the fine type (e.g., 'Late Book Return Fine', 'Lost Book Fine')
|description      |Description of the fine type
|is_active        |Whether this fine type is currently active
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp


### Table Name: lib_fine_slab_config  *(NEW in v6)*
**Purpose:** Parent configuration table defining fine slabs — rules for how fines are calculated, capped, and applied, scoped by membership type, resource type, and fine type, with effective date ranges and priority.

|Field Name          |Description
|----------------------|-----------------------------------------------------------------
|id                   |Unique identifier for each fine slab configuration
|name                 |Name of the fine slab
|membership_type_id   |FK to lib_membership_types.id (NULL = applies to all membership types)
|resource_type_id     |FK to lib_resource_types.id (NULL = applies to all resource types)
|fine_type_id         |FK to lib_fine_type.id
|max_fine_cap         |Type of cap applied to the fine: 'Fixed', 'BookCost', or 'Unlimited'
|max_fine_amt         |Maximum fine amount when max_fine_cap = 'Fixed'
|fine_amt_calc_type   |How the fine amount is calculated: 'Fixed', 'Percentage', or 'BookCost'
|effective_from       |Date from which this slab is effective
|effective_to         |Date until which this slab is effective (NULL = effective indefinitely)
|priority             |Priority for slab evaluation (higher priority slabs are evaluated first)
|is_active            |Whether this slab configuration is currently active
|created_at           |Record creation timestamp
|updated_at           |Last update timestamp
|deleted_at           |Soft delete timestamp


### Table Name: lib_fine_slab_details  *(NEW in v6)*
**Purpose:** Child table of lib_fine_slab_config defining the day-range based fine rates and calculation frequency for each slab.

|Field Name          |Description
|----------------------|-----------------------------------------------------------------
|id                   |Unique identifier for each fine slab detail row
|fine_slab_config_id  |FK to lib_fine_slab_config.id (cascades on delete)
|from_day             |Start of the day range (>= 0) for this fine rate
|to_day               |End of the day range (>= from_day) for this fine rate
|fine_rate            |Fine rate amount for this day range
|rate_type            |Whether fine_rate is a 'Fixed' amount or a 'Percentage'
|calculation_type     |Frequency basis for the fine: 'Per_Day', 'Per_Week', 'Per_Month', 'Per_Year', 'Per_Book'
|created_at           |Record creation timestamp
|updated_at           |Last update timestamp
|deleted_at           |Soft delete timestamp


### Table Name: lib_account_entry_config  *(NEW in v6)*
**Purpose:** Maps library fine types (and optionally specific fine slab configs) to accounting ledgers/account groups, so that fine collections post to the correct accounting entries.

|Field Name          |Description
|----------------------|-----------------------------------------------------------------
|id                   |Unique identifier for each account entry configuration
|name                 |Name of the configuration entry
|fine_type_id         |FK to lib_fine_type.id (e.g., Late Return, Lost Book, Damaged Book, Processing Fee)
|fine_slab_config_id  |FK to lib_fine_slab_config.id (NULL = applies to all slabs)
|account_group_id     |FK to acc_account_groups.id
|ledger_id            |FK to acc_ledgers.id
|is_active            |Whether this configuration is currently active
|created_at           |Record creation timestamp
|updated_at           |Last update timestamp
|deleted_at           |Soft delete timestamp


### Table Name: lib_library_status_masters  *(NEW in v6)*
**Purpose:** Generic master for dynamic status codes used across the Library module (Book, Member, Transaction, Reservation, Fine, Inventory Audit, Digital Resource and Digital Access Transaction statuses), allowing new statuses to be added without code changes.

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each status row
|status_type      |Category of status: 'Book Status', 'Member Status', 'Transaction Status', 'Reservation Status', 'Fine Status', 'Inventory Audit Status', 'Inventory Audit Detail Status', 'Digital Resource Status', 'Digital Access Transaction Status'
|code             |Status code (e.g., 'Available', 'Issued', 'Pending')
|name             |Display name of the status (e.g., 'Available', 'Issued', 'Pending')
|is_system        |Whether this status is a system status that cannot be deleted/edited
|is_active        |Whether this status is currently active
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp

**Seed mapping (status_type → consuming table → seeded codes):**
- Book Status → lib_book_copies → Available, Issued, Reserved, Under_Maintenance, Lost, Withdrawn
- Digital Resource Status → lib_digital_resources → Available, License_Consumed, License_Expired
- Member Status → lib_members → Active, Expired, Suspended, Deactivated
- Transaction Status → lib_transactions → Issued, Returned, Overdue, Lost
- Reservation Status → lib_reservations → Pending, Available, Picked_Up, Cancelled, Expired
- Digital Access Transaction Status → lib_digital_access_transactions / lib_digital_access_requests → Active, Expired, Revoked, Completed (also Pending, Approved, Rejected, Withdrawn for requests)
- Fine Status → lib_fines → Pending, Paid, Waived, Overdue
- Inventory Audit Status → lib_inventory_audit → In_Progress, Completed, Cancelled
- Inventory Audit Detail Status → lib_inventory_audit_details → Found, Missing, Misplaced, Damaged


---

## Sub-Menu 4: ACQUISITION & CATALOGING

### Table Name: lib_books_master
**Purpose:** Central repository for all bibliographic information about books and resources. This is the title-level master record, including catalog data, AI-derived analytics, and curricular metadata.

|Field Name                  |Description
|------------------------------|-----------------------------------------------------------------
|id                           |Unique identifier for each book title
|title                        |Main title of the book
|subtitle                     |Subtitle if applicable
|edition                      |Edition information (e.g., '2nd', 'Revised')
|isbn                         |International Standard Book Number (unique)
|issn                         |International Standard Serial Number (for journals)
|doi                          |Digital Object Identifier
|publication_year             |Year of publication
|publisher_id                 |FK to lib_publishers.id
|language                     |FK to sys_dropdown_table.id — primary language of the resource (data must be seeded in sys_dropdown_table)
|page_count                   |Total number of pages (must be > 0)
|summary                      |Brief summary/abstract
|cover_image_media_id         |FK to sys_media.id — cover image (NULL allowed; set NULL on media delete)
|table_of_contents            |Structured table of contents
|resource_type_id             |FK to lib_resource_types.id
|is_reference_only            |Whether the book cannot be borrowed (in-library use only)
|lexile_level                 |Reading difficulty level (e.g., 'Level 3')
|reading_age_range            |Recommended reading age range (e.g., '8-12 years')
|awards_json                  |JSON list of awards won by the book
|series_name                  |Series name if the book is part of a series
|series_position              |Position of the book within the series
|popularity_rank              |Popularity rank (MEDIUMINT, allows ranks beyond 255)
|academic_rating              |Rating by faculty
|student_rating               |Average student rating
|rating_count                 |Number of ratings received
|curricular_relevance_score   |Curricular relevance score
|tags_json                    |JSON of auto-generated tags from AI analysis
|ai_summary                   |AI-generated summary
|key_concepts_json            |JSON of key concepts extracted from the book
|is_available                 |Whether the book is currently available (cached flag, updated by triggers/application logic)
|is_active                    |Whether this title is currently active
|created_at                   |Record creation timestamp
|updated_at                   |Last update timestamp
|deleted_at                   |Soft delete timestamp

**Conditions:**
- If `is_reference_only` = 1, the book cannot be borrowed (in-library use only).
- Show book status from field `is_available` in Book Master.
- Create data in `sys_dropdown_table` for `language` values.


### Table Name: lib_book_author_jnt
**Purpose:** Junction table linking books with their authors (many-to-many), supporting display order and primary author designation.

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each book-author assignment
|book_id          |FK to lib_books_master.id (cascades on delete)
|author_id        |FK to lib_authors.id (cascades on delete)
|author_order     |Display order of authors (1 = first)
|is_primary       |Whether this is the primary author
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp


### Table Name: lib_book_category_jnt
**Purpose:** Junction table linking books with their categories (many-to-many).

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each book-category assignment
|book_id          |FK to lib_books_master.id (cascades on delete)
|category_id      |FK to lib_categories.id (cascades on delete)
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp


### Table Name: lib_book_genre_jnt
**Purpose:** Junction table linking books with their genres (many-to-many) for flexible tagging and filtering.

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each book-genre assignment
|book_id          |FK to lib_books_master.id (cascades on delete)
|genre_id         |FK to lib_genres.id (cascades on delete)
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp


### Table Name: lib_book_subject_jnt  *(NEW in v6)*
**Purpose:** Junction table linking books with class-subject combinations (many-to-many), supporting curriculum-aligned cataloging.

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each book-class-subject assignment
|book_id          |FK to lib_books_master.id (cascades on delete)
|class_id         |FK to sch_classes.id (cascades on delete)
|subject_id       |FK to sch_subjects.id (cascades on delete)
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp


### Table Name: lib_book_keyword_jnt  *(NEW in v6)*
**Purpose:** Junction table linking books with their keywords (many-to-many) for flexible discovery and filtering.

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each book-keyword assignment
|book_id          |FK to lib_books_master.id (cascades on delete)
|keyword_id       |FK to lib_keywords.id (cascades on delete)
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp


### Table Name: lib_book_purchases  *(NEW in v6)*
**Purpose:** Header record for a book purchase bill from a vendor, capturing invoice-level totals. Line-level details (book/copy/digital resource specifics) are in lib_book_purchases_items.

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each purchase bill
|vendor_id        |FK to vnd_vendors.id — supplier/vendor (restrict on delete)
|bill_no          |Vendor invoice number
|bill_date        |Date when the purchase bill was raised
|bill_amt         |Total cost of all copies on the bill
|bill_tax_amt     |Total tax amount on the bill
|bill_net_amt     |Total cost including tax
|notes            |Any note related to the purchase
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp

**Condition:** Check `resource_type_id` (on the related purchase item) in lib_resource_types to determine and display whether the item is physical or digital.


### Table Name: lib_book_purchases_items  *(NEW in v6)*
**Purpose:** Line items for a book purchase, including pricing, tax, quantity, and links to the resulting book copy or digital resource once created.

|Field Name              |Description
|--------------------------|-----------------------------------------------------------------
|id                       |Unique identifier for each purchase line item
|book_purchase_id         |FK to lib_book_purchases.id (cascades on delete)
|book_id                  |FK to lib_books_master.id (restrict on delete)
|resource_type_id         |FK to lib_resource_types.id (restrict on delete)
|book_copy_id             |FK to lib_book_copies.id — set after the physical copy is created (set NULL on delete)
|digital_resource_id      |FK to lib_digital_resources.id — set after the digital resource is created (set NULL on delete)
|book_price               |Purchase cost per unit
|book_quantity            |Number of copies purchased
|book_amt                 |Total cost (price × quantity)
|book_tax_head            |Tax head/category applied
|book_tax_percent         |Tax percentage applied on the book
|book_tax_amt             |Tax amount for this line item
|book_net_amt             |Total cost including tax for this line item
|created_at               |Record creation timestamp
|updated_at               |Last update timestamp
|deleted_at               |Soft delete timestamp

**Condition:** Check `resource_type_id` in lib_resource_types and showcase on screen whether the item is physical or digital.


### Table Name: lib_book_copies
**Purpose:** Item-level tracking of each physical copy of a book, including identifiers, location, condition, and circulation status.

|Field Name              |Description
|--------------------------|-----------------------------------------------------------------
|id                       |Unique identifier for each physical copy
|book_id                  |FK to lib_books_master.id
|accession_number         |Institution's unique accession number
|barcode                  |Scannable barcode for circulation
|rfid_tag                 |RFID tag identifier if used
|shelf_location_id        |FK to lib_shelf_locations.id — current physical location
|current_condition_id     |FK to lib_book_conditions.id — current condition of the copy
|book_purchase_id         |FK to lib_book_purchases.id — purchase this copy originated from
|is_lost                  |Whether the copy is reported lost; cannot be issued
|is_damaged               |Whether the copy is damaged
|is_withdrawn             |Whether the copy is withdrawn from the collection
|withdrawal_reason        |Reason for withdrawal
|status                   |FK to lib_library_status_masters.id (Book Status: Available, Issued, Reserved, Under_Maintenance, Lost, Withdrawn)
|notes                    |Additional notes about this copy
|is_active                |Whether this copy is currently active
|created_at               |Record creation timestamp
|updated_at               |Last update timestamp
|deleted_at               |Soft delete timestamp


### Table Name: lib_book_condition_jnt
**Purpose:** Historical condition log per book copy for tracking wear and damage over time.

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each condition log entry
|date             |Date when the condition was assessed
|book_id          |FK to lib_books_master.id (cascades on delete)
|book_copy_id     |FK to lib_book_copies.id (cascades on delete)
|condition_id     |FK to lib_book_conditions.id (cascades on delete)
|note             |Additional notes about this condition assessment
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp


### Table Name: lib_digital_resources
**Purpose:** Manages digital assets (e-books, PDFs, audio/video files, etc.) including storage, usage tracking, licensing, and access controls.

|Field Name              |Description
|--------------------------|-----------------------------------------------------------------
|id                       |Unique identifier for each digital resource
|book_id                  |FK to lib_books_master.id
|file_name                |Original file name
|file_media_id            |FK to sys_media.id — stored file (set NULL on media delete)
|file_path                |Storage path or URL
|file_size_bytes          |Size of the file in bytes (BIGINT, supports large files)
|mime_type                |MIME type (e.g., 'application/pdf')
|file_format              |Format (e.g., 'PDF', 'EPUB', 'MP3')
|can_student_download     |Whether students can download this resource
|can_teacher_download     |Whether teachers can download this resource
|can_staff_download       |Whether other staff can download this resource
|download_count           |Number of times downloaded
|view_count                |Number of times viewed online
|license_key              |License identifier if applicable
|license_type             |Type of license (e.g., 'Single User', 'Concurrent', 'Site')
|license_start_date       |License validity start date
|license_end_date         |License validity end date
|license_count            |Number of concurrent licenses; NULL = unlimited
|status                   |FK to lib_library_status_masters.id (Digital Resource Status: Available, License Consumed, License Expired)
|is_active                |Whether this resource is currently active
|created_at               |Record creation timestamp
|updated_at               |Last update timestamp
|deleted_at               |Soft delete timestamp

**Conditions:**
- If `license_count` IS NOT NULL, then concurrent access is limited to `license_count`.
- If `license_count` IS NULL, access is unlimited.


### Table Name: lib_digital_access_request_types  *(NEW in v6)*
**Purpose:** Master list of digital access request types (download, online view, stream, offline, extended license), referenced by lib_digital_access_requests.

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each request type
|code             |Business code (e.g., 'Download', 'View_Online', 'Stream', 'Offline', 'Extended')
|name             |Display name of the request type
|description      |Description of the request type
|is_active        |Whether this request type is currently active
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp


### Table Name: lib_digital_resource_tags
**Purpose:** Searchable tags for digital resources to enhance discovery and categorization.

|Field Name              |Description
|--------------------------|-----------------------------------------------------------------
|id                       |Unique identifier for each tag assignment
|digital_resource_id      |FK to lib_digital_resources.id (cascades on delete)
|tag_name                 |Tag text (e.g., 'interactive', 'video-lecture')
|created_at               |Record creation timestamp
|updated_at               |Last update timestamp
|deleted_at               |Soft delete timestamp


---

## Sub-Menu 5: MEMBER & ACCESS MANAGEMENT

### Table Name: lib_membership_types
**Purpose:** Defines different types of library memberships with their associated privileges and rules. Controls borrowing limits, loan periods, renewal rules, fine rates, and digital access entitlements.

|Field Name                          |Description
|--------------------------------------|-----------------------------------------------------------------
|id                                   |Unique identifier for each membership type
|code                                 |Business code (e.g., 'STD_STUDENT', 'PREMIUM_STAFF')
|name                                 |Display name (e.g., 'Standard Student', 'Premium Staff')
|max_books_allowed                   |Maximum number of books a member can borrow simultaneously (> 0)
|loan_period_days                    |Standard loan duration in days (> 0)
|renewal_allowed                     |Whether members can renew books
|max_renewals                        |Maximum number of times a book can be renewed
|fine_rate_per_day                   |Daily fine amount for late returns (>= 0)
|grace_period_days                   |Days after due date before fines start accruing
|priority_level                      |Priority for reservations (higher = better priority)
|digital_access_days                 |Number of days digital resource access is provided
|can_restricted_members_view_list    |If 0, restricted members cannot view the Book List
|is_active                           |Whether this membership type is currently available
|created_at                          |Record creation timestamp
|updated_at                          |Last update timestamp
|deleted_at                          |Soft delete timestamp

**Conditions:**
- When a student requests a book, check `max_books_allowed`. If limit reached, show "Reached Limit".
- When issuing a book, check `max_books_allowed`. If limit reached, show "Reached Limit".
- Check whether the user is a Member. If not, show "You are not Authorized to issue Book".
- If `can_restricted_members_view_list` is 0, restricted members cannot see the Book List.


### Table Name: lib_members
**Purpose:** Library-specific member profiles linked to the main user table, including circulation summary, status, and rich reading-behavior analytics fields.

|Field Name                          |Description
|--------------------------------------|-----------------------------------------------------------------
|id                                   |Unique identifier for the library member
|user_id                              |FK to sys_users.id (unique — one library profile per user)
|membership_type_id                  |FK to lib_membership_types.id
|user_type                           |Type of user: 'Student', 'Teacher', 'Staff'
|membership_number                   |Unique library membership number
|library_card_barcode                |Barcode on the physical library card
|registration_date                   |Date of membership registration
|expiry_date                         |Membership expiry date
|is_auto_renew                       |Whether the membership auto-renews
|last_activity_date                  |Last library activity date
|total_books_borrowed                |Lifetime total books borrowed
|total_fines_paid                    |Lifetime fines paid
|outstanding_fines                   |Current unpaid fines (>= 0, NOT NULL)
|status                               |FK to lib_library_status_masters.id (Member Status: Active, Expired, Suspended, Deactivated)
|suspension_reason                   |Reason if membership is suspended
|notes                                |Additional notes
|reading_level                       |Reading level: 'Beginner', 'Intermediate', 'Advanced', 'Expert'
|preferred_notification_channel      |Preferred channel for notifications: 'Email', 'SMS', 'Push', 'InApp'
|member_segment                      |Behavioral segment label (e.g., High-Value, At-Risk, Inactive, New)
|last_segment_calculation            |Timestamp when member_segment was last calculated
|engagement_score                    |Engagement score (0-100 scale)
|churn_risk_score                    |Churn risk score (0-100 scale)
|lifetime_value                      |Estimated lifetime value of the member
|preferred_language                  |Member's preferred language (default 'English')
|reading_goal_annual                 |Annual reading goal (number of books)
|reading_progress_ytd                |Reading progress year-to-date (number of books)
|is_active                           |Whether this member record is active
|created_at                          |Record creation timestamp
|updated_at                          |Last update timestamp
|deleted_at                          |Soft delete timestamp


### Table Name: lib_digital_resource_access_restrictions  *(NEW in v6)*
**Purpose:** Defines access restrictions on digital resources based on role, designation, department, or individual user. At least one restriction dimension must be specified per row.

|Field Name              |Description
|--------------------------|-----------------------------------------------------------------
|id                       |Unique identifier for each restriction rule
|digital_resource_id      |FK to lib_digital_resources.id (cascades on delete)
|role_id                  |FK to sys_roles.id (NULL = not restricted by role)
|designation_id           |FK to sys_designations.id (NULL = not restricted by designation)
|department_id            |FK to sys_departments.id (NULL = not restricted by department)
|user_id                  |FK to sys_users.id (NULL = not restricted by individual user)
|is_active                |Whether this restriction rule is currently active
|created_at               |Record creation timestamp
|updated_at               |Last update timestamp
|deleted_at               |Soft delete timestamp

**Condition:** At least one of `role_id`, `designation_id`, `department_id`, or `user_id` must be non-null (enforced via CHECK constraint `chk_drar_at_least_one`).


---

## Sub-Menu 6: OPERATION MANAGEMENT

### Table Name: lib_reservations
**Purpose:** Manages holds, reservations, and renewal requests for books, including queue position tracking and renewal approval workflow.

|Field Name                  |Description
|------------------------------|-----------------------------------------------------------------
|id                           |Unique identifier for each reservation
|book_id                      |FK to lib_books_master.id
|member_id                    |FK to lib_members.id
|reservation_date             |Date and time of the reservation
|expected_available_date      |Estimated date when the book will be available
|queue_position               |Position in the reservation queue
|notification_sent            |Whether an availability notification was sent
|notification_sent_at         |When the notification was sent
|pickup_by_date               |Date by which the member must pick up the book
|transaction_id               |FK to lib_transactions.id — the issue transaction created against this reservation request
|status                       |FK to lib_library_status_masters.id (Reservation Status: Pending, Available, Picked_Up, Cancelled, Expired)
|cancellation_reason          |Reason if the reservation was cancelled
|is_renewal_request           |Whether this row represents a renewal request rather than a new reservation
|renewal_days_requested        |Number of days requested for renewal
|renewal_approved             |Whether the renewal request has been approved
|renewal_approved_at          |When the renewal request was approved
|renewal_approved_by_id       |FK to sys_users.id — who approved the renewal
|created_at                   |Record creation timestamp
|updated_at                   |Last update timestamp
|deleted_at                   |Soft delete timestamp

**Conditions:**
- A member can request a Renewal; the renewal request is approved by the Library Incharge.
- A member can also withdraw a Renewal/Reservation request.
- When raising a Renewal Request, check `renewal_allowed` in lib_membership_types — only allowed if `renewal_allowed` = 1.
- When raising a Renewal Request, check `max_renewals` in lib_membership_types, then check `renewal_count` in lib_transactions.
- When raising a Renewal Request, check `max_books_allowed` in lib_membership_types.


### Table Name: lib_transactions
**Purpose:** Core circulation table tracking all book issues and returns — the most active table in the library system.

|Field Name              |Description
|--------------------------|-----------------------------------------------------------------
|id                       |Unique identifier for each circulation transaction
|book_id                  |FK to lib_books_master.id
|copy_id                  |FK to lib_book_copies.id
|member_id                |FK to lib_members.id
|issue_date               |Date and time when the book was issued
|due_date                 |Expected return date
|return_date              |Actual return date (NULL if not yet returned)
|issued_by_id             |FK to sys_users.id — who issued the book
|received_by_id           |FK to sys_users.id — who received the return
|issue_condition_id       |FK to lib_book_conditions.id — condition at issue
|return_condition_id      |FK to lib_book_conditions.id — condition at return
|is_renewed               |Whether this transaction has been renewed
|renewal_count            |Number of times this transaction has been renewed
|status                   |FK to lib_library_status_masters.id (Transaction Status: Issued, Returned, Overdue, Lost)
|notes                    |Additional notes
|created_at               |Record creation timestamp
|updated_at               |Last update timestamp
|deleted_at               |Soft delete timestamp

**Conditions:**
- On Issue: check `max_books_allowed` in lib_membership_types; if the limit is exceeded, the member cannot issue more books.
- On Return: check pending requests in lib_reservations for the returned book; notify members by queue position (FCFS — First Come First Serve). Example: if 3 members requested on 10th May and 1 member requested on 12th May, notify all 3 from 10th May first, issue to whoever collects first; on the next availability, notify the remaining 2 from 10th May, then finally the 12th May member.
- On Renewal: check `renewal_allowed` and `max_renewals` in lib_membership_types and `renewal_count` in lib_transactions; if the member has reached the limit, they cannot renew.
- On Return: compare book condition at issue vs. return; charge a fine if the condition has degraded.
- On Return: check `grace_period_days` before applying a late fine.


### Table Name: lib_digital_access_requests
**Purpose:** Member-initiated requests for access to digital resources (download, online view, stream, etc.), reviewed and approved/rejected by library staff.

|Field Name              |Description
|--------------------------|-----------------------------------------------------------------
|id                       |Unique identifier for each digital access request
|request_type             |FK to lib_digital_access_request_types.id
|member_id                |FK to lib_members.id (restrict on delete)
|book_id                  |FK to lib_books_master.id (restrict on delete)
|digital_resource_id      |FK to lib_digital_resources.id (set NULL on delete)
|reason                   |Reason/justification for the request
|status                   |FK to lib_library_status_masters.id (Digital Access Request Status: Pending, Approved, Rejected, Withdrawn)
|reviewed_by_id           |FK to sys_users.id — who reviewed the request (set NULL on delete)
|reviewed_at              |When the request was reviewed
|notes                    |Additional notes
|is_active                |Whether this request record is active
|created_at               |Record creation timestamp
|updated_at               |Last update timestamp
|deleted_at               |Soft delete timestamp

**Conditions:**
- A member can request digital access; it is reviewed and approved by the Library Incharge.
- A member can also withdraw the request.
- Check `renewal_allowed`, `max_renewals`, and `max_books_allowed` in lib_membership_types as applicable.


### Table Name: lib_digital_access_transactions  *(NEW in v6)*
**Purpose:** Tracks each granted digital access window for a member — including view/download activity, device/IP tracking, and revocation — for licensing enforcement and analytics.

|Field Name                  |Description
|------------------------------|-----------------------------------------------------------------
|id                           |Unique identifier for each digital access transaction
|member_id                    |FK to lib_members.id (restrict on delete)
|book_id                      |FK to lib_books_master.id (restrict on delete)
|digital_resource_id          |FK to lib_digital_resources.id (restrict on delete)
|access_request_id            |FK to lib_digital_access_requests.id (NULL if directly granted without a request; set NULL on delete)
|access_type                  |Type of access: 'View_Online', 'Download', 'Stream', 'Read_Online'
|access_start_at              |Date/time the access window started
|access_expires_at            |Date/time the access window expires (NULL = no expiry / permanent)
|last_accessed_at             |Date/time of the last access
|is_downloaded                |Whether the resource has been downloaded at least once
|download_count               |Number of times downloaded
|first_downloaded_at          |Date/time of the first download
|last_downloaded_at           |Date/time of the most recent download
|last_download_ip             |IP address of the most recent download
|last_download_device         |Device type of the most recent download: 'Desktop', 'Mobile', 'Tablet', 'Kiosk', 'Other'
|last_download_user_agent     |User agent string of the most recent download
|download_history_json        |JSON array of download events: [{downloaded_at, ip, device, user_agent}, ...]
|view_count                    |Number of times viewed online
|total_view_duration_sec      |Total time spent viewing online, in seconds
|last_view_ip                 |IP address of the most recent online view
|last_view_device             |Device type of the most recent online view
|granted_by_id                |FK to sys_users.id — who granted the access (set NULL on delete)
|revoked_by_id                |FK to sys_users.id — who revoked the access (set NULL on delete)
|revoked_at                   |Date/time the access was revoked
|revocation_reason            |Reason for revocation
|status                       |FK to lib_library_status_masters.id (Digital Access Transaction Status: Active, Expired, Revoked, Completed)
|notes                        |Additional notes
|created_at                   |Record creation timestamp
|updated_at                   |Last update timestamp
|deleted_at                   |Soft delete timestamp

**Conditions:**
- One row is created per granted access window; a new row is created on re-request after expiry.
- `download_count` increments on every download event; `download_history_json` appends a new object per event.
- `view_count` increments when a member opens the resource online without downloading.
- `total_view_duration_sec` is updated by the application on session close (heartbeat approach).
- Status transitions: Active → Expired (scheduled job when `access_expires_at` < NOW()); Active → Revoked (manual staff action); Active → Completed (member explicitly closes, or license consumed).


### Table Name: lib_fines
**Purpose:** Tracks all fines generated for late returns, lost books, or damages, including waiver tracking and a JSON breakdown of the calculation.

|Field Name                  |Description
|------------------------------|-----------------------------------------------------------------
|id                           |Unique identifier for each fine
|transaction_id               |FK to lib_transactions.id
|member_id                    |FK to lib_members.id
|fine_type                    |FK to lib_fine_type.id
|amount                       |Fine amount (>= 0)
|days_overdue                 |Number of days overdue (for late returns)
|calculated_from              |Start date for fine calculation
|calculated_to                |End date for fine calculation
|fine_slab_config_id          |FK to lib_fine_slab_config.id — slab configuration used for this fine
|calculation_breakdown_json   |JSON breakdown of how the fine amount was calculated
|waived_amount                |Amount waived (>= 0)
|waived_by_id                 |FK to sys_users.id — who waived the fine
|waived_reason                |Reason for waiving
|waived_at                    |When the fine was waived
|status                       |FK to lib_library_status_masters.id (Fine Status: Pending, Paid, Waived, Overdue)
|notes                        |Additional notes
|created_at                   |Record creation timestamp
|updated_at                   |Last update timestamp
|deleted_at                   |Soft delete timestamp


### Table Name: lib_fine_payments
**Purpose:** Records all payments made against fines with receipt tracking.

|Field Name              |Description
|--------------------------|-----------------------------------------------------------------
|id                       |Unique identifier for each payment
|fine_id                  |FK to lib_fines.id
|amount_paid              |Amount paid (> 0)
|payment_method           |Payment method: 'Cash', 'Card', 'Online', 'Waiver'
|payment_reference        |External reference (e.g., transaction ID)
|payment_date             |Date and time of payment
|received_by_id           |FK to sys_users.id — who received the payment
|receipt_number           |Generated receipt number (unique)
|notes                    |Additional notes
|created_at               |Record creation timestamp
|updated_at               |Last update timestamp
|deleted_at               |Soft delete timestamp


---

## Sub-Menu 7: AUDIT AND HISTORY

### Table Name: lib_transaction_history
**Purpose:** Audit trail for all circulation transactions, tracking the type of action and before/after values over time.

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each history record
|transaction_id   |FK to lib_transactions.id
|action_type      |Type of action: 'issued', 'returned', 'renewed', 'marked_lost', 'condition_updated'
|old_value_json   |Previous values as JSON
|new_value_json   |New values as JSON
|performed_by_id  |FK to sys_users.id — who performed the action
|performed_at     |When the action was performed
|notes            |Additional notes
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp


### Table Name: lib_inventory_audit
**Purpose:** Tracks physical inventory audit sessions for stock verification — header record summarizing scan results.

|Field Name          |Description
|----------------------|-----------------------------------------------------------------
|id                   |Unique identifier for each audit session
|audit_date           |Date of the audit
|performed_by_id      |FK to sys_users.id — who performed the audit
|total_scanned        |Total copies scanned during the audit
|total_expected       |Total copies expected in the collection
|missing_copies       |Number of copies not found
|misplaced_copies     |Number of copies found in the wrong location
|damaged_copies       |Number of copies found damaged
|status               |FK to lib_library_status_masters.id (Inventory Audit Status: In_Progress, Completed, Cancelled)
|completed_at         |When the audit was completed
|notes                |Additional notes
|created_at           |Record creation timestamp
|updated_at           |Last update timestamp
|deleted_at           |Soft delete timestamp


### Table Name: lib_inventory_audit_details
**Purpose:** Line items for each copy scanned during an inventory audit, comparing expected vs. actual location and observed condition.

|Field Name              |Description
|--------------------------|-----------------------------------------------------------------
|id                       |Unique identifier for each audit detail row
|audit_id                 |FK to lib_inventory_audit.id (cascades on delete)
|copy_id                  |FK to lib_book_copies.id
|expected_location_id     |FK to lib_shelf_locations.id — where the copy should be
|actual_location_id       |FK to lib_shelf_locations.id — where the copy was found
|scanned_at               |When this copy was scanned
|condition_id             |FK to lib_book_conditions.id — observed condition during the audit
|status                   |FK to lib_library_status_masters.id (Inventory Audit Detail Status: Found, Missing, Misplaced, Damaged)
|notes                    |Additional notes
|created_at               |Record creation timestamp
|updated_at               |Last update timestamp
|deleted_at               |Soft delete timestamp


---

## Sub-Menu 8: ADVANCED ANALYTICS & INSIGHTS

### Table Name: lib_reading_behavior_analytics  *(NEW in v6)*
**Purpose:** Per-member, per-academic-year aggregated reading behavior metrics used for personalization, recommendations, and the Member 360 view.

|Field Name                      |Description
|----------------------------------|-----------------------------------------------------------------
|id                               |Unique identifier for each analytics record
|member_id                        |FK to lib_members.id
|academic_year_id                 |FK to academic_years.id
|total_books_read                 |Total number of books read in the academic year
|total_pages_read                 |Total pages read in the academic year
|avg_reading_days_per_book        |Average number of days taken to read a book
|preferred_genre_id               |FK to lib_genres.id — the member's preferred genre
|preferred_category_id            |FK to lib_categories.id — the member's preferred category
|preferred_language               |The member's preferred reading language
|avg_loan_completion_rate         |Percentage of books returned on time
|peak_borrowing_month             |Month in which the member borrows most frequently
|peak_borrowing_day               |Day of week the member borrows most frequently
|reading_consistency_score        |0-100 score based on borrowing regularity
|genre_diversity_index            |Shannon diversity index for genres read
|author_diversity_index           |Diversity index across authors read
|preferred_borrowing_time         |Time of day/week the member prefers to borrow: 'Morning', 'Afternoon', 'Evening', 'Weekend'
|digital_vs_physical_ratio        |Ratio of digital to physical resource usage
|renewal_frequency                |Average number of renewals per book
|reservation_frequency            |Number of reservations made
|reading_speed_estimate           |Estimated reading speed in pages per day
|completion_rate_trend            |Month-over-month trend in loan completion rate
|last_calculated_at               |When this record was last (re)calculated
|created_at                       |Record creation timestamp
|updated_at                       |Last update timestamp


### Table Name: lib_book_popularity_trends  *(NEW in v6)*
**Purpose:** Daily time-series of demand and popularity signals per book, used for trend detection, recommendations, and shelf planning.

|Field Name                  |Description
|------------------------------|-----------------------------------------------------------------
|id                           |Unique identifier for each daily trend record
|book_id                      |FK to lib_books_master.id
|tracking_date                |Date of the tracked metrics
|daily_requests               |Number of requests for the book on this date
|daily_issues                 |Number of issues of the book on this date
|daily_reservations           |Number of reservations made for the book on this date
|daily_digital_views          |Number of digital views of the book on this date
|daily_digital_downloads      |Number of digital downloads of the book on this date
|popularity_score             |Weighted composite popularity score
|trend_direction               |Direction of popularity trend: 'Rising', 'Falling', 'Stable'
|velocity_score               |Rate of change of popularity
|seasonality_factor           |Seasonal adjustment factor applied to demand
|peer_comparison_rank         |Rank of this book among similar books
|shelf_turnover_rate          |How often the book moves off the shelf
|waitlist_length              |Current length of the reservation waitlist
|avg_wait_days                |Average wait time (days) for the book
|recommendation_weight        |Weight assigned to this book by the recommendation engine
|created_at                   |Record creation timestamp
|updated_at                   |Last update timestamp


### Table Name: lib_collection_health_metrics  *(NEW in v6)*
**Purpose:** Periodic, optionally category/genre-scoped, metrics describing the overall health and utilization of the library collection.

|Field Name                      |Description
|----------------------------------|-----------------------------------------------------------------
|id                               |Unique identifier for each metrics snapshot
|metric_date                      |Date of the metrics snapshot
|category_id                      |FK to lib_categories.id (NULL = all categories; set NULL on delete)
|genre_id                         |FK to lib_genres.id (NULL = all genres; set NULL on delete)
|total_titles                     |Total number of titles in scope
|total_copies                     |Total number of physical copies in scope
|active_titles                    |Number of active titles
|inactive_titles                  |Number of inactive titles
|damaged_copies                   |Number of damaged copies
|lost_copies                      |Number of lost copies
|withdrawn_copies                 |Number of withdrawn copies
|utilization_rate                 |Percentage of the collection currently in circulation
|turnover_rate                    |Average issues per copy
|age_of_collection                |Average age of the collection in years
|collection_diversity_score       |Diversity score based on genre/category distribution
|relevance_score                  |How well the collection matches current demand
|acquisition_effectiveness        |ROI measure on recent acquisitions
|weeding_priority_score           |Priority score for removal/replacement of titles
|budget_allocation_efficiency     |Efficiency measure of budget allocation
|digital_penetration_rate         |Proportion of the collection that is digital
|physical_vs_digital_ratio        |Ratio of physical to digital holdings
|created_at                       |Record creation timestamp
|updated_at                       |Last update timestamp


### Table Name: lib_predictive_analytics  *(NEW in v6)*
**Purpose:** Stores model-generated predictions (demand forecasts, churn risk, resource optimization, acquisition recommendations, seasonal patterns, budget projections) along with confidence and accuracy tracking.

|Field Name              |Description
|--------------------------|-----------------------------------------------------------------
|id                       |Unique identifier for each prediction record
|prediction_date          |Date the prediction was generated
|prediction_type          |Type of prediction: 'Demand_Forecast', 'Member_Churn', 'Resource_Optimization', 'Acquisition_Recommendation', 'Seasonal_Pattern', 'Budget_Projection'
|target_entity_type       |Type of entity the prediction targets: 'Book', 'Category', 'Genre', 'Member', 'Department', 'All'
|target_entity_id         |ID of the target entity (NULL for entity_type = 'All')
|prediction_period_start  |Start date of the period the prediction covers
|prediction_period_end    |End date of the period the prediction covers
|predicted_value          |The predicted numeric value
|confidence_score         |0-100 confidence level of the prediction
|actual_value             |Actual observed value, once known (for accuracy tracking)
|accuracy_score           |Accuracy of the prediction vs. actual value
|model_version            |Version identifier of the model used
|features_used_json       |JSON of features used in generating the prediction
|insights                 |Human-readable insights derived from the prediction
|recommendations          |Human-readable recommendations derived from the prediction
|is_active                |Whether this prediction record is active
|created_at               |Record creation timestamp
|updated_at               |Last update timestamp
|deleted_at               |Soft delete timestamp


### Table Name: lib_curricular_alignment  *(NEW in v6)*
**Purpose:** Maps books to class/subject/academic-year combinations with alignment scoring, faculty endorsement, and usage tracking, to support curriculum-integrated collection planning.

|Field Name              |Description
|--------------------------|-----------------------------------------------------------------
|id                       |Unique identifier for each curricular alignment record
|academic_year_id         |FK to academic_years.id
|class_id                 |FK to sch_classes.id
|subject_id               |FK to sch_subjects.id
|book_id                  |FK to lib_books_master.id
|alignment_score          |How well the book aligns with the curriculum
|recommended_by_faculty   |Whether faculty have recommended this book
|faculty_rating           |1-5 rating from faculty
|student_usage_count      |Number of times students have used this book for this class/subject
|exam_reference_count     |Number of times the book has been referenced in exams
|assignment_citations     |Number of times the book has been cited in assignments
|curriculum_unit          |Curriculum unit this book supports
|term_recommended         |Term in which the book is recommended: 'Term1', 'Term2', 'Term3', 'All'
|priority_level           |Priority of the book for this curriculum: 'Essential', 'Recommended', 'Supplementary', 'Optional'
|notes                    |Additional notes
|created_at               |Record creation timestamp
|updated_at               |Last update timestamp


### Table Name: lib_engagement_events  *(NEW in v6)*
**Purpose:** Event-level log of member interactions with the library system (search, browse, reservations, digital access, reviews, etc.) used to drive analytics and personalization.

|Field Name              |Description
|--------------------------|-----------------------------------------------------------------
|id                       |Unique identifier for each engagement event
|member_id                |FK to lib_members.id
|event_type               |Type of event: 'Search','Browse','View_Details','Add_Reservation','Cancel_Reservation','Renew_Online','Digital_View','Digital_Download','Read_Online','Share_Resource','Add_Review','Rate_Book','Save_To_Wishlist','Request_Purchase','Ask_Librarian','Attend_Event'
|book_id                  |FK to lib_books_master.id (if applicable to this event)
|digital_resource_id      |FK to lib_digital_resources.id (if applicable to this event)
|search_query             |Search query text (for Search events)
|filters_used_json        |JSON of filters applied (for Search/Browse events)
|session_id               |Session identifier for grouping related events
|device_type              |Device used: 'Desktop', 'Mobile', 'Tablet', 'Kiosk'
|browser                  |Browser used for the event
|ip_address               |IP address of the event
|location_id              |Physical location ID, if the event occurred in the library
|time_spent_seconds       |Time spent on this interaction, in seconds
|interaction_outcome      |Outcome/result of the interaction
|created_at               |Record creation timestamp


---

## Sub-Menu 9: NEW TABLES (NT-001 to NT-005)

### Table Name: lib_book_reviews_ratings  *(NEW in v6 — NT-001)*
**Purpose:** Stores individual member ratings and reviews of books, with moderation workflow. lib_books_master.student_rating is populated from aggregates of this table.

|Field Name          |Description
|----------------------|-----------------------------------------------------------------
|id                   |Unique identifier for each review/rating
|book_id              |FK to lib_books_master.id (cascades on delete)
|member_id            |FK to lib_members.id (cascades on delete)
|transaction_id       |FK to lib_transactions.id — the transaction that led to this review (set NULL on delete)
|rating               |Star rating from 1 to 5
|review_text          |Free-text review content
|is_faculty           |Whether the reviewer is a faculty member
|is_approved          |Moderation flag — whether the review is approved for display
|approved_by_id       |FK to sys_users.id — who approved the review (set NULL on delete)
|approved_at          |When the review was approved
|is_active            |Whether this review record is active
|created_at           |Record creation timestamp
|updated_at           |Last update timestamp
|deleted_at           |Soft delete timestamp


### Table Name: lib_wishlist  *(NEW in v6 — NT-002)*
**Purpose:** Personal reading wishlist per member for future borrowing or purchase requests; linked to the Save_To_Wishlist engagement event type.

|Field Name      |Description
|-----------------|-----------------------------------------------------------------
|id               |Unique identifier for each wishlist entry
|member_id        |FK to lib_members.id (cascades on delete)
|book_id          |FK to lib_books_master.id (cascades on delete)
|notes            |Optional notes about why the book was wishlisted
|priority         |Priority of this wishlist entry
|is_active        |Whether this wishlist entry is active
|created_at       |Record creation timestamp
|updated_at       |Last update timestamp
|deleted_at       |Soft delete timestamp


### Table Name: lib_digital_access_request_types  *(NEW in v6 — NT-003)*
**Purpose:** See entry under Sub-Menu 4 (defined there to satisfy the FK dependency from lib_digital_access_requests).


### Table Name: lib_library_settings  *(NEW in v6 — NT-004)*
**Purpose:** Module-level key-value configuration for the Library module, with optional per-academic-year overrides of global defaults.

|Field Name          |Description
|----------------------|-----------------------------------------------------------------
|id                   |Unique identifier for each setting entry
|academic_year_id     |FK to academic_years.id (NULL = global default; non-null = year-specific override; cascades on delete)
|setting_key          |Configuration key name
|setting_value        |Configuration value (stored as text)
|value_type           |Data type of the value: 'string', 'integer', 'decimal', 'boolean', 'json'
|description          |Description of what this setting controls
|is_active            |Whether this setting is currently active
|created_at           |Record creation timestamp
|updated_at           |Last update timestamp
|deleted_at           |Soft delete timestamp


### Table Name: lib_background_services  *(NEW in v6 — NT-005)*
**Purpose:** Registry of background/scheduled services for the Library module (e.g., book condition update jobs), with run status tracking.

|Field Name          |Description
|----------------------|-----------------------------------------------------------------
|id                   |Unique identifier for each background service
|service_name         |Name of the background service (unique)
|service_url          |URL endpoint for the service, if applicable
|service_interval     |Interval between runs, in minutes (default 1440 = daily)
|last_run_at          |Timestamp of the last run
|last_status          |Status of the last run: 'Success', 'Failed', 'Running', 'Pending'
|is_active            |Whether this service is currently active
|created_at           |Record creation timestamp
|updated_at           |Last update timestamp
|deleted_at           |Soft delete timestamp


---

## Sub-Menu 10. COMPOSITE INDEXES FOR PERFORMANCE OPTIMIZATION

All partial indexes (with WHERE clauses, unsupported in MySQL 8) from earlier versions were replaced with standard composite indexes:

|Index Name                          |Table                       |Columns                                  |Purpose
|--------------------------------------|------------------------------|--------------------------------------------|------------------------------------------------------------
|idx_transactions_overdue            |lib_transactions             |(status, due_date)                       |Identify overdue transactions
|idx_members_outstanding             |lib_members                  |(outstanding_fines)                      |Find members with outstanding fines
|idx_fines_pending                   |lib_fines                    |(status, created_at)                     |Find pending fines
|idx_reservations_available          |lib_reservations             |(status, expected_available_date, notification_sent) |Find pending reservations awaiting notification
|idx_digital_license_expiry          |lib_digital_resources        |(license_end_date)                       |Identify digital resources nearing license expiry
|idx_books_publisher_year            |lib_books_master             |(publisher_id, publication_year)         |Reporting by publisher and year
|idx_copies_location_status          |lib_book_copies              |(shelf_location_id, status)              |Locate copies by shelf and status
|idx_transactions_member_dates       |lib_transactions             |(member_id, issue_date, return_date)     |Member borrowing history reporting


---

## Sub-Menu 11. TRIGGERS & EVENTS FOR DATA INTEGRITY

|Name                            |Type     |Fires On                              |Purpose
|-----------------------------------|---------|------------------------------------------|------------------------------------------------------------
|update_member_borrowed_count    |TRIGGER  |AFTER INSERT ON lib_transactions       |When a new transaction is created with status = 'Issued' (looked up dynamically from lib_library_status_masters), increments lib_members.total_books_borrowed and updates last_activity_date.
|update_copy_status_on_issue     |TRIGGER  |AFTER INSERT ON lib_transactions       |When a new transaction is created with status = 'Issued', sets the corresponding lib_book_copies.status to 'Issued' (Book Status).
|update_copy_status_on_return    |TRIGGER  |AFTER UPDATE ON lib_transactions       |When a transaction's status changes to 'Returned', sets the corresponding lib_book_copies.status to 'Available' and updates current_condition_id from return_condition_id.
|auto_calculate_fines            |EVENT    |Daily (EVERY 1 DAY, starts CURRENT_DATE) |For all 'Issued' transactions past due_date beyond the member's grace_period_days, inserts a 'Pending' lib_fines row of fine_type 'LateReturn' (amount = days overdue × fine_rate_per_day), skipping transactions that already have a pending late-return fine.

All status comparisons in triggers/events use dynamic lookups against lib_library_status_masters (and lib_fine_type for fine type codes) rather than hardcoded IDs.


---

## Sub-Menu 12. VIEWS FOR COMMON REPORTING

### View: lib_view_member_360
**Purpose:** Comprehensive 360-degree view of member engagement and behavior, combining membership, profile, circulation, and analytics data for the current academic year.

|Field Name                      |Description
|----------------------------------|-----------------------------------------------------------------
|member_id                        |lib_members.id
|membership_number                |Member's library membership number
|first_name                       |Member's first name (from sys_users)
|last_name                        |Member's last name (from sys_users)
|email                            |Member's email
|phone                            |Member's phone
|membership_type                  |Name of the member's membership type
|registration_date                |Date of membership registration
|expiry_date                      |Membership expiry date
|status                           |Member status (FK id into lib_library_status_masters)
|total_books_borrowed             |Lifetime total books borrowed
|outstanding_fines                |Current unpaid fines
|engagement_score                 |Member's engagement score
|churn_risk_score                 |Member's churn risk score
|lifetime_value                   |Member's estimated lifetime value
|reading_level                    |Member's reading level
|total_pages_read                 |Total pages read (current academic year, from lib_reading_behavior_analytics)
|avg_reading_days_per_book        |Average days per book (current academic year)
|reading_consistency_score        |Reading consistency score (current academic year)
|genre_diversity_index            |Genre diversity index (current academic year)
|preferred_genre                  |Name of the member's preferred genre
|preferred_borrowing_time         |Preferred borrowing time of day/week
|digital_vs_physical_ratio        |Ratio of digital to physical resource usage
|active_reservations              |Count of the member's reservations with status 'Pending'
|currently_borrowed               |Count of the member's transactions with status 'Issued'
|days_since_last_activity         |Days since last_activity_date
|activity_status                  |Derived label: 'New' (no activity yet), 'Active' (≤30 days), 'At Risk' (≤90 days), 'Inactive' (>90 days)


### View: lib_view_collection_performance
**Purpose:** Real-time performance and demand metrics per book title for collection management.

|Field Name                      |Description
|----------------------------------|-----------------------------------------------------------------
|book_id                          |lib_books_master.id
|title                            |Book title
|isbn                             |Book ISBN
|publisher                        |Publisher name
|resource_type                    |Resource type name
|total_copies                     |Total physical copies of this title
|available_copies                 |Count of copies with status 'Available'
|issued_copies                    |Count of copies with status 'Issued'
|reserved_copies                  |Count of copies with status 'Reserved'
|lost_copies                      |Count of copies marked is_lost
|damaged_copies                   |Count of copies marked is_damaged
|total_issues                     |Total number of transactions for this title's copies
|overdue_count                    |Count of unreturned transactions past due_date
|avg_loan_days                    |Average loan duration (days) for returned transactions
|active_reservations              |Count of pending reservations for this title
|avg_queue_position               |Average queue position across pending reservations
|popularity_rank                  |Book's popularity rank
|curricular_relevance_score       |Book's curricular relevance score
|student_rating                   |Book's average student rating
|popularity_score                 |Today's popularity score (from lib_book_popularity_trends)
|trend_direction                  |Today's trend direction (from lib_book_popularity_trends)
|collection_utilization_rate      |Today's collection utilization rate (from lib_collection_health_metrics)
|demand_category                  |Derived label: 'High Demand' (>100 issues), 'Medium Demand' (>50), 'Low Demand' (>10), 'Very Low Demand' (otherwise)


### View: lib_view_predictive_demand
**Purpose:** Predictive demand forecasting view for inventory planning, combining recent circulation activity with model predictions and curricular relevance.

|Field Name                      |Description
|----------------------------------|-----------------------------------------------------------------
|book_id                          |lib_books_master.id
|title                            |Book title
|category_name                    |Name of an associated category
|genre_name                       |Name of an associated genre
|publication_year                 |Year of publication
|last_3_months_issues             |Number of issues in the last 3 months
|last_year_issues                 |Number of issues in the last 12 months
|predicted_next_3_months          |Predicted demand value for the next 3 months (from lib_predictive_analytics, prediction_type = 'Demand_Forecast')
|confidence_score                 |Confidence score of the prediction
|insights                         |Insights text from the prediction record
|recommendations                  |Recommendations text from the prediction record
|curricular_relevance             |Alignment score from lib_curricular_alignment for the current academic year
|acquisition_recommendation       |Derived label: 'Acquire More Copies' (>50), 'Monitor Demand' (>30), 'Maintain Current' (>10), 'Consider Weeding' (otherwise)

**Note:** Only includes books that have a non-null `predicted_value` for today's date (rows are filtered with `WHERE pa.predicted_value IS NOT NULL`).


### View: lib_view_overdue_books
**Purpose:** Real-time view of all overdue books with member contact information and estimated fine calculations.

|Field Name          |Description
|----------------------|-----------------------------------------------------------------
|transaction_id       |lib_transactions.id
|title                |Book title
|isbn                 |Book ISBN
|barcode              |Copy barcode
|membership_number    |Member's membership number
|first_name           |Member's first name (from sys_users)
|last_name            |Member's last name (from sys_users)
|email                |Member's email
|phone                |Member's phone
|due_date             |Expected return date
|days_overdue         |Days past the due date
|fine_rate_per_day    |Daily fine rate from the member's membership type
|estimated_fine       |Calculated fine amount (days_overdue × fine_rate_per_day)

**Note:** Only includes transactions with status 'Issued' where `due_date < CURDATE()` and the overdue period exceeds the member's `grace_period_days`.


### View: lib_view_most_issued_books
**Purpose:** Analytics view showing the most popular books based on circulation history of returned transactions.

|Field Name          |Description
|----------------------|-----------------------------------------------------------------
|book_id              |lib_books_master.id
|title                |Book title
|issue_count          |Total number of times issued (returned transactions)
|unique_borrowers     |Number of unique members who borrowed this title
|avg_loan_days        |Average days per loan for returned transactions

Results are ordered by `issue_count` descending.


---

## Sub-Menu 13. SEED DATA (Lookup Tables)

The following lookup tables are seeded with initial data in v6:

- **lib_library_status_masters** — full status catalog across all status_type categories (see Sub-Menu 3 seed mapping above).
- **lib_fine_type** — LateReturn, LostBook, DamagedBook, ProcessingFee.
- **lib_digital_access_request_types** — Download, View_Online, Stream, Offline, Extended.
- **lib_membership_types** — STD_STUDENT, STD_STAFF, RESEARCH_SCHOLAR, PREMIUM_STUDENT, EXTERNAL (with associated borrowing/loan/fine/digital-access defaults).
- **lib_categories** — Fiction, Non-Fiction, Science, Mathematics, Computer Science, Literature, History, Geography, Art.
- **lib_genres** — Science Fiction, Fantasy, Mystery, Biography, Technology, Educational, Reference, Classics, Poetry.
- **lib_resource_types** — Physical Book, E-Book, PDF Document, Audio Book, Video Resource, Journal, Magazine.
- **lib_book_conditions** — New, Excellent, Good, Fair, Poor, Damaged, Lost, Withdrawn.
- **lib_background_services** — 'Book Condition Update' background job (interval: 1440 minutes / daily).


---

## Database Design Patterns Summary

|Pattern              |Implementation                                            |Purpose
|-----------------------|-------------------------------------------------------------|------------------------------------------------------------
|Soft Delete           |deleted_at (TIMESTAMP NULL)                                 |Data retention without permanent deletion
|Audit Tracking        |created_at, updated_at, deleted_at, *_by_id columns         |Compliance and traceability
|Generic Status Master |lib_library_status_masters (status_type + code)             |Add new statuses across modules without schema/code changes
|JSON Storage          |tags_json, awards_json, key_concepts_json, *_breakdown_json, *_history_json, filters_used_json, features_used_json |Flexible schema for variable/structured data
|Enum Types            |status/category fields (e.g., access_type, action_type)      |Controlled vocabulary with constraints
|Junction Tables       |lib_book_*_jnt tables                                        |Many-to-many relationships
|Full-text Search      |FULLTEXT INDEX on lib_books_master, lib_digital_resources    |Efficient text searching
|Check Constraints     |CHECK (amount >= 0), CHECK (rating BETWEEN 1 AND 5), etc.    |Data integrity at database level
|Foreign Keys          |FOREIGN KEY references to (id)                               |Referential integrity
|Composite Indexes     |See Sub-Menu 10                                              |Query performance optimization
|Triggers & Events     |See Sub-Menu 11                                              |Automatic state synchronization (copy status, borrowed counts) and scheduled fine calculation


---

## SUMMARY OF ANALYTICS CAPABILITIES

|Analytics Area          |Key Tables                                                              |Key Metrics                                                       |Business Value
|---------------------------|---------------------------------------------------------------------------|---------------------------------------------------------------------|------------------------------------------------------------------------------
|Member Behavior          |lib_reading_behavior_analytics, lib_members, lib_engagement_events       |Reading patterns, preferences, engagement/churn scores, lifetime value |Personalized recommendations, retention strategies, targeted communication
|Collection Performance   |lib_collection_health_metrics, lib_view_collection_performance            |Utilization rates, turnover rates, popularity trends                 |Data-driven acquisition, weeding decisions, budget optimization
|Predictive Analytics     |lib_predictive_analytics, lib_view_predictive_demand, lib_book_popularity_trends |Demand forecasting, resource optimization, seasonal patterns | Proactive inventory management, cost savings, improved availability
|Curricular Alignment     |lib_curricular_alignment, lib_book_subject_jnt                            |Subject relevance, faculty ratings, exam/assignment references       |Enhanced academic support, curriculum integration, student success
|Financial Analytics      |lib_fines, lib_fine_payments, lib_fine_slab_config, lib_account_entry_config |Fine patterns, collection ROI, accounting integration               |Financial planning, cost optimization, resource allocation
|Operational Insights     |lib_engagement_events, lib_reservations, lib_inventory_audit              |Peak usage times, location popularity, queue/audit metrics           |Staff scheduling, space planning, service improvement
|Digital Access Tracking  |lib_digital_access_transactions, lib_digital_access_requests, lib_digital_resource_access_restrictions |Download/view counts, license consumption, access restrictions | License compliance, digital ROI, access governance


---

## Change Log Reference
This data dictionary corresponds to **Library_ddl_v6.sql** (Created: 2026-06-09), incorporating fixes F-001 through F-045 from Lib_DDL_Enhancement_Report.md and new tables NT-001 through NT-005. The previous data dictionary (`data_dictionary.md`) was based on a pre-v6 schema and is now superseded by this document.
