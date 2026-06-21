# Complete Data Dictionary for Library Module

## Overview
This comprehensive data dictionary documents all tables, fields, relationships, and business purposes for the Library Module in the ERP+LMS+LXP system.

## 1. CORE LOOKUP TABLES (System Dropdowns)
### Table Name: lib_membership_types
**Purpose:** Defines different types of library memberships with their associated privileges and rules. Controls borrowing limits, loan periods, and fine calculations.

|Field Name	            |Description
|-----------------------|-----------------------------------------------------------------
|id	                    |Unique identifier for each membership type
|code	                |Business code (e.g., 'STD_STUDENT', 'PREMIUM_STAFF')
|name	                |Display name (e.g., 'Standard Student', 'Premium Staff')
|max_books_allowed	    |Maximum number of books a member can borrow simultaneously
|loan_period_days	    |Standard loan duration in days
|renewal_allowed	    |Whether members can renew books
|max_renewals	        |Maximum number of times a book can be renewed
|fine_rate_per_day	    |Daily fine amount for late returns
|grace_period_days	    |Days after due date before fines start accruing
|priority_level	        |Priority for reservations (higher = better priority)
|is_active	            |Whether this membership type is currently available
|is_deleted	            |Soft delete flag
|created_at	            |Record creation timestamp
|updated_at	            |Last update timestamp
|deleted_at	            |Soft delete timestamp


### Table Name: lib_categories
**Purpose:** Hierarchical classification of books/resources (e.g., Fiction → Science Fiction → Space Opera). Supports multi-level categorization.

|Field Name	                |Description
|---------------------------|-----------------------------------------------------------------
|id	                        |Unique identifier for each category
|parent_id	                |Self-reference for hierarchical categories
|code	                    |Business code (e.g., 'FIC', 'SCI_FI')
|name	                    |Display name (e.g., 'Fiction', 'Science Fiction')
|description	                |Detailed description of the category
|level	                    |Depth in hierarchy (1 = top level)
|display_order	            |Order for display in dropdowns
|is_active	                |Whether this category is currently active
|is_deleted	                |Soft delete flag
|created_at	                |Record creation timestamp
|updated_at	                |Last update timestamp
|deleted_at	                |Soft delete timestamp


### Table Name: lib_genres
**Purpose:** Tags for literary genres that can be applied across categories for flexible searching and recommendations.

|Field Name	            |Description
|-----------------------|-----------------------------------------------------------------
|id	                    |Unique identifier for each genre
|code	                |Business code (e.g., 'SF', 'MYSTERY')
|name	                |Display name (e.g., 'Science Fiction', 'Mystery')
|description	            |Description of the genre
|is_active	            |Whether this genre is currently active
|is_deleted	            |Soft delete flag
|created_at	            |Record creation timestamp
|updated_at	            |Last update timestamp
|deleted_at	            |Soft delete timestamp


### Table Name: lib_publishers
**Purpose:** Master list of publishers for books and resources.

|Field Name		    |Description
|-------------------|-----------------------------------------------------------------
|id			    |Unique identifier for each publisher
|code			|Business code for the publisher
|name			|Full name of the publishing company
|address			|Physical/registered address
|contact			|Primary contact person
|email			|Contact email address
|publisher_phone	|Contact phone number
|website			|Publisher's website URL
|is_active		    |Whether this publisher is currently active
|is_deleted		    |Soft delete flag
|created_at		    |Record creation timestamp
|updated_at		    |Last update timestamp
|deleted_at		    |Soft delete timestamp

### Table Name: lib_resource_types
**Purpose:** Classification of resource formats (physical books, e-books, PDFs, audio books, etc.) to handle different media types appropriately.

|Field Name		    |Description
|-------------------|-----------------------------------------------------------------
|id			    |Unique identifier for each resource type
|code			|Business code (e.g., 'PHY_BOOK', 'EBOOK')
|name			|Display name (e.g., 'Physical Book', 'E-Book')
|is_physical		|Whether this is a physical resource
|is_digital		    |Whether this is a digital resource
|is_active		    |Whether this resource type is currently active
|is_deleted		    |Soft delete flag
|created_at		    |Record creation timestamp
|updated_at		    |Last update timestamp
|deleted_at		    |Soft delete timestamp

### Table Name: lib_shelf_locations
**Purpose:** Physical location mapping for books in the library, enabling efficient shelving and retrieval.

|Field Name		    |Description
|-------------------|-----------------------------------------------------------------
|id			    |Unique identifier for each shelf location
|code			    |Business code (e.g., 'A1-S1-R1')
|aisle_number	    |Aisle identifier (e.g., 'A1', 'B2')
|shelf_number	    |Shelf identifier within aisle
|rack_number		|Rack identifier if applicable
|floor_number	    |Floor/level in the building
|building		    |Building name or code
|zone		        |Zone or section (e.g., 'Reference', 'Children')
|description		|Additional location details
|is_active		    |Whether this location is currently active
|is_deleted		    |Soft delete flag
|created_at		    |Record creation timestamp
|updated_at		    |Last update timestamp
|deleted_at		    |Soft delete timestamp

### Table Name: lib_book_conditions
**Purpose:** Standardized condition states for physical books to track wear and tear, damage, and usability.

|Field Name	    |Description
|---------------|-----------------------------------------------------------------
|id	            |Unique identifier for each condition
|code	        |Business code (e.g., 'NEW', 'DAMAGED')
|name	        |Display name (e.g., 'New', 'Damaged')
|description	|Detailed description of the condition
|is_borrowable	|Whether books in this condition can be issued
|is_active	    |Whether this condition is currently active
|is_deleted	    |Soft delete flag
|created_at	    |Record creation timestamp
|updated_at	    |Last update timestamp
|deleted_at	    |Soft delete timestamp

### Table Name: lib_books_master
**Purpose:** Central repository for all bibliographic information about books and resources. This is the title-level master record.

|Field Name	        |Description
|-------------------|-----------------------------------------------------------------
|id	                |Unique identifier for each book title
|title	            |Main title of the book
|subtitle	        |Subtitle if applicable
|edition	        |Edition information (e.g., '2nd', 'Revised')
|isbn	            |International Standard Book Number (13 digits)
|issn	            |International Standard Serial Number (for journals)
|doi	            |Digital Object Identifier
|publication_year	|Year of publication
|publisher_id	    |Reference to lib_publishers
|language	        |Primary language of the resource
|page_count	        |Total number of pages
|summary	        |Brief summary/abstract
|table_of_contents	|Structured table of contents
|cover_image_url	|URL to cover image
|resource_type_id	|Reference to lib_resource_types
|is_reference_only	|Whether book cannot be borrowed (in-library use only)
|is_active	        |Whether this title is currently active
|is_deleted	        |Soft delete flag
|created_at	        |Record creation timestamp
|updated_at	        |Last update timestamp
|deleted_at	        |Soft delete timestamp

### Table Name: lib_book_authors
**Purpose:** Supports multiple authors per book with ordering and primary author designation.

|Field Name	        |Description
|-------------------|-----------------------------------------------------------------
|id     |Unique identifier for each author assignment
|book_id		    |Reference to lib_books_master
|author_name	    |Full name of the author
|author_order	    |Display order of authors (1 = first)
|is_primary	        |Whether this is the primary author
|created_at	        |Record creation timestamp

### Table Name: lib_book_category_mapping
**Purpose:** Many-to-many relationship between books and categories. Books can belong to multiple categories.

|Field Name	    |Description
|----------------|-----------------------------------------------------------------
|book_id	    |Reference to lib_books_master
|category_id	|Reference to lib_categories
|created_at	    |Record creation timestamp

### Table Name: lib_book_genre_mapping
**Purpose:** Many-to-many relationship between books and genres for flexible tagging and filtering.

|Field Name	    |Description
|---------------|-----------------------------------------------------------------
|book_id	    |Reference to lib_books_master
|genre_id	    |Reference to lib_genres
|created_at	    |Record creation timestamp

### Table Name: lib_book_copies
**Purpose:** Item-level tracking of each physical copy of a book, including location, condition, and circulation status.

|Field Name	            |Description
|-----------------------|-----------------------------------------------------------------
|id	            |Unique identifier for each physical copy
|book_id	            |Reference to lib_books_master
|accession_number	    |Institution's unique accession number
|barcode	            |Scannable barcode for circulation
|rfid_tag	            |RFID tag identifier if used
|shelf_location_id	    |Current physical location
|current_condition_id	|Current condition of the copy
|purchase_date	        |Date when copy was purchased
|purchase_price	        |Purchase cost
|vendor	                |Supplier/vendor name
|is_lost	            |Whether copy is reported lost
|is_damaged	            |Whether copy is damaged
|is_withdrawn	        |Whether copy is withdrawn from collection
|withdrawal_reason	    |Reason for withdrawal
|status	                |Circulation status (available, issued, reserved, under_maintenance, lost, withdrawn)
|notes	                |Additional notes about this copy
|is_active	            |Whether this copy is currently active
|is_deleted	            |Soft delete flag
|created_at	            |Record creation timestamp
|updated_at	            |Last update timestamp
|deleted_at	            |Soft delete timestamp

### Table Name: lib_digital_resources
**Purpose:** Manages digital assets including e-books, PDFs, audio files, and video resources with licensing and access controls.

|Field Name	            |Description
|-----------------------|-----------------------------------------------------------------
|id	            |Unique identifier for each digital resource
|book_id	            |Reference to lib_books_master
|file_name	            |Original file name
|file_path	            |Storage path or URL
|file_size_bytes	    |Size of the file in bytes
|mime_type	            |MIME type (e.g., 'application/pdf')
|file_format	        |Format (e.g., 'PDF', 'EPUB', 'MP3')
|download_count	        |Number of times downloaded
|view_count	            |Number of times viewed online
|license_key	        |License identifier if applicable
|license_type	        |Type of license (e.g., 'Single User', 'Concurrent', 'Site')
|license_start_date	    |License validity start date
|license_end_date	    |License validity end date
|access_restriction	    |JSON defining access rules (user roles, IP ranges, etc.)
|is_active	            |Whether this resource is currently active
|is_deleted	            |Soft delete flag
|created_at	            |Record creation timestamp
|updated_at	            |Last update timestamp
|deleted_at	            |Soft delete timestamp

### Table Name: lib_digital_resource_tags
**Purpose:** Searchable tags for digital resources to enhance discovery and categorization.

|Field Name	                |Description
|---------------------------|-----------------------------------------------------------------
|id	                    |Unique identifier for each tag assignment
|digital_resource_id	    |Reference to lib_digital_resources
|tag_name	                |Tag text (e.g., 'interactive', 'video-lecture')
|created_at	                |Record creation timestamp

### Table Name: lib_members
**Purpose:** Library-specific member profiles linked to the main user table in the ERP system.

|Field Name	            |Description
|------------------------|-----------------------------------------------------------------
|id	            |Unique identifier for library member
|user_id	            |Reference to main users table in ERP
|membership_type_id	    |Reference to lib_membership_types
|membership_number	    |Unique library membership number
|library_card_barcode	|Barcode on physical library card
|registration_date	    |Date of membership registration
|expiry_date	        |Membership expiry date
|is_auto_renew	        |Whether membership auto-renews
|last_activity_date	    |Last library activity date
|total_books_borrowed	|Lifetime total books borrowed
|total_fines_paid	    |Lifetime fines paid
|outstanding_fines	    |Current unpaid fines
|status	                |Membership status (active, expired, suspended, deactivated)
|suspension_reason	    |Reason if membership is suspended
|notes	                |Additional notes
|is_active	            |Whether this member record is active
|is_deleted	            |Soft delete flag
|created_at	            |Record creation timestamp
|updated_at	            |Last update timestamp
|deleted_at	            |Soft delete timestamp

### Table Name: lib_transactions
**Purpose:** Core circulation table tracking all book issues and returns. This is the most active table in the library system.

|Field Name	            |Description
|-----------------------|-----------------------------------------------------------------
|id	                    |Unique identifier for each circulation transaction
|transaction_uuid	    |UUID for distributed tracing
|copy_id	            |Reference to lib_book_copies
|member_id	            |Reference to lib_members
|issue_date	            |Date and time when book was issued
|due_date	            |Expected return date
|return_date	        |Actual return date (NULL if not returned)
|issued_by	            |User ID who issued the book
|received_by	        |User ID who received the return
|issue_condition_id	    |Condition at time of issue
|return_condition_id	|Condition at time of return
|is_renewed	            |Whether this transaction is a renewal
|renewal_count	        |Number of times this has been renewed
|status	                |Transaction status (issued, returned, overdue, lost)
|notes	                |Additional notes
|created_at	            |Record creation timestamp
|updated_at	            |Last update timestamp

### Table Name: lib_reservations
**Purpose:** Manages holds and reservations for books that are currently issued.

|Field Name		            |Description
|---------------------------|-----------------------------------------------------------------
|id					    |Unique identifier for each reservation
|reservation_uuid		    |UUID for distributed tracing
|book_id				    |Reference to lib_books_master
|member_id				    |Reference to lib_members
|reservation_date		    |Date and time of reservation
|expected_available_date	|Estimated date when book will be available
|notification_sent	        |Whether availability notification was sent
|notification_sent_at	    |When notification was sent
|pickup_by_date	            |Date by which member must pick up
|status	                    |Reservation status (pending, available, picked_up, cancelled, expired)
|queue_position	            |Position in reservation queue
|cancellation_reason	    |Reason if cancelled
|created_at	                |Record creation timestamp
|updated_at	                |Last update timestamp

### Table Name: lib_fines
**Purpose:** Tracks all fines generated for late returns, lost books, or damages.

|Field Name			|Description
|-------------------|-----------------------------------------------------------------
|id				|Unique identifier for each fine
|transaction_id		|Reference to lib_transactions
|member_id			|Reference to lib_members
|fine_type			|Type of fine (late_return, lost_book, damaged_book, processing_fee)
|amount				|Fine amount
|days_overdue		|Number of days overdue (for late returns)
|calculated_from	|Start date for fine calculation
|calculated_to		|End date for fine calculation
|waived_amount		|Amount waived
|waived_by			|User ID who waived the fine
|waived_reason		|Reason for waiving
|waived_at			|When fine was waived
|status				|Fine status (pending, paid, waived, overdue)
|notes				|Additional notes
|created_at			|Record creation timestamp
|updated_at			|Last update timestamp

### Table Name: lib_fine_payments
**Purpose:** Records all payments made against fines with receipt tracking.

|Field Name	    	|Description
|-------------------|-----------------------------------------------------------------
|id			    |Unique identifier for each payment
|fine_id			|Reference to lib_fines
|payment_uuid	    |UUID for distributed tracing
|amount_paid		|Amount paid
|payment_method	    |Method (cash, card, online, waiver)
|payment_reference  | External reference (e.g., transaction ID)
|payment_date	    |Date and time of payment
|received_by		|User ID who received payment
|receipt_number	    |Generated receipt number
|notes			    |Additional notes
|created_at		    |Record creation timestamp
|updated_at		    |Last update timestamp

### Table Name: lib_transaction_history
**Purpose:** Audit trail for all circulation transactions, tracking changes over time.
  
|Field Name	        |Description
|-------------------|-----------------------------------------------------------------
|id	        |Unique identifier for each history record
|transaction_id	    |Reference to lib_transactions
|action_type	    |Type of action (issued, returned, renewed, marked_lost, condition_updated)
|old_value	        |Previous values as JSON
|new_value	        |New values as JSON
|performed_by	    |User ID who performed the action
|performed_at	    |When action was performed
|notes	            |Additional notes

### Table Name: lib_inventory_audit
**Purpose:** Tracks physical inventory audit sessions for stock verification.

|Field Name	        |Description
|-------------------|-----------------------------------------------------------------
|id	        |Unique identifier for each audit
|audit_uuid	        |UUID for distributed tracing
|audit_date	        |Date of audit
|performed_by	    |User ID who performed the audit
|total_scanned	    |Total copies scanned
|total_expected	    |Total copies expected in collection
|missing_copies	    |Number of copies not found
|misplaced_copies	|Number of copies found in wrong location
|damaged_copies	    |Number of copies found damaged
|status		        |Audit status
|notes		        |Additional notes
|created_at	        |Record creation timestamp
|completed_at	    |When audit was completed

### Table Name: lib_inventory_audit_details
**Purpose:** Line items for each copy scanned during an inventory audit.

|Field Name	            |Description
|-----------------------|-----------------------------------------------------------------
|id	    |Unique identifier for each audit detail
|audit_id	            |Reference to lib_inventory_audit
|copy_id	            |Reference to lib_book_copies
|expected_location_id	|Where copy should be
|actual_location_id	    |Where copy was found
|scanned_at	            |When this copy was scanned
|condition_id	        |Observed condition
|status	                |Status (found, missing, misplaced, damaged)
|notes	                |Additional notes

### Table Name: lib_view_overdue_books (VIEW)
**Purpose:** Real-time view of all overdue books with member contact information and fine calculations.

|Field Name	        |Description
|-------------------|-----------------------------------------------------------------
|id	        |Transaction identifier
|title	            |Book title
|isbn	            |ISBN number
|barcode	        |Copy barcode
|membership_number	|Member's membership number
|first_name	        |Member's first name (from users table)
|last_name	        |Member's last name
|email	            |Member's email
|phone	            |Member's phone
|due_date	        |Expected return date
|days_overdue	    |Days past due date
|fine_rate_per_day	|Daily fine rate
|estimated_fine	    |Calculated fine amount

### Table Name: lib_view_most_issued_books (VIEW)
**Purpose:** Analytics view showing most popular books based on circulation data.

|Field Name	        |Description
|-------------------|-----------------------------------------------------------------
|book_id	        |Book identifier
|title	            |Book title
|issue_count	    |Total number of times issued
|unique_borrowers   |Number of unique members who borrowed
|avg_loan_days	    |Average days per loan

### Database Design Patterns Summary

|Pattern	        |Implementation	                                |Purpose
|-------------------|-----------------------------------------------|------------------------------------------
|Soft Delete	    |is_deleted, deleted_at	                        |Data retention without permanent deletion
|Audit Tracking	    |created_at, updated_at, created_by, updated_by	|Compliance and traceability
|UUID Support	    |*_uuid fields	                                |Distributed system tracing
|JSON Storage	    |access_restriction, old_value, new_value	    |Flexible schema for variable data
|Enum Types	        |status fields	                                |Controlled vocabulary with constraints
|Composite Keys	    |Mapping tables	                                |Many-to-many relationships
|Full-text Search	|FULLTEXT INDEX	                                |Efficient text searching
|Check Constraints	|CHECK (amount >= 0)	                        |Data integrity at database level
|Foreign Keys	    |FOREIGN KEY references	                        |Referential integrity
|Indexes	        |Various indexes	                            |Query performance optimization




## SUMMARY OF ANALYTICS CAPABILITIES

|Analytics Area	        |Key Metrics	                                    |Business Value
|---------------------------|---------------------------------------------------------------|------------------------------------------------------------------------------
|Member Behavior	        |Reading patterns, preferences, engagement scores, churn risk	|Personalized recommendations, retention strategies, targeted communication
|Collection Performance	    |Utilization rates, turnover rates, popula  rity trends	        |Data-driven acquisition, weeding decisions, budget optimization
|Predictive Analytics	    |Demand forecasting, resource optimization, seasonal patterns	|Proactive inventory management, cost savings, improved availability
|Curricular Alignment	    |Subject relevance, faculty ratings, exam references	        |Enhanced academic support, curriculum integration, student success
|Financial Analytics	    |Fine patterns, collection ROI, budget efficiency	            |Financial planning, cost optimization, resource allocation
|Operational Insights	    |Peak usage times, location popularity, event engagement	    |Staff scheduling, space planning, service improvement

