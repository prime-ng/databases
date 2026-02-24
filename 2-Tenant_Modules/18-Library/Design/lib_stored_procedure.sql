-- ----------------------------------------------------------------------------
-- STORED PROCEDURES FOR ANALYTICS
-- ----------------------------------------------------------------------------
-- sp_calculate_member_segments
-- Automatically segments members based on behavior patterns.
DELIMITER $$

CREATE PROCEDURE `sp_calculate_member_segments`()
BEGIN
    -- Update member segments based on activity and value
    UPDATE lib_members m
    LEFT JOIN (
        SELECT 
            member_id,
            COUNT(*) as transaction_count,
            SUM(CASE WHEN return_date > due_date THEN 1 ELSE 0 END) as late_returns,
            AVG(DATEDIFF(return_date, issue_date)) as avg_loan_period
        FROM lib_transactions
        WHERE issue_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
        GROUP BY member_id
    ) t ON m.member_id = t.member_id
    LEFT JOIN (
        SELECT 
            member_id,
            SUM(amount) as total_fines_paid_6m
        FROM lib_fine_payments fp
        INNER JOIN lib_fines f ON fp.fine_id = f.id
        WHERE fp.payment_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
        GROUP BY member_id
    ) f ON m.member_id = f.member_id
    SET 
        m.engagement_score = COALESCE(
            (t.transaction_count * 10) + 
            (100 - (t.late_returns / NULLIF(t.transaction_count, 0) * 100)) * 0.3 +
            (f.total_fines_paid_6m * 0.1), 0
        ),
        m.churn_risk_score = CASE
            WHEN m.last_activity_date IS NULL THEN 80
            WHEN DATEDIFF(CURDATE(), m.last_activity_date) > 90 THEN 90
            WHEN DATEDIFF(CURDATE(), m.last_activity_date) > 60 THEN 70
            WHEN DATEDIFF(CURDATE(), m.last_activity_date) > 30 THEN 40
            ELSE 10
        END,
        m.member_segment = CASE
            WHEN m.engagement_score >= 80 AND m.outstanding_fines = 0 THEN 'High-Value'
            WHEN m.engagement_score >= 50 THEN 'Regular'
            WHEN m.churn_risk_score >= 70 THEN 'At-Risk'
            WHEN m.last_activity_date IS NULL THEN 'New'
            ELSE 'Inactive'
        END,
        m.last_segment_calculation = NOW()
    WHERE 1=1;
END$$

DELIMITER ;

-- sp_generate_collection_insights (Generates daily collection health metrics and insights.)
DELIMITER $$

CREATE PROCEDURE `sp_generate_collection_insights`()
BEGIN
    -- Insert daily collection health metrics
    INSERT INTO lib_collection_health_metrics (
        metric_date,
        total_titles,
        total_copies,
        active_titles,
        damaged_copies,
        lost_copies,
        utilization_rate,
        turnover_rate,
        collection_diversity_score
    )
    SELECT 
        CURDATE(),
        COUNT(DISTINCT b.book_id),
        COUNT(DISTINCT c.copy_id),
        COUNT(DISTINCT CASE WHEN c.status = 'available' OR c.status = 'issued' THEN b.book_id END),
        SUM(CASE WHEN c.is_damaged = 1 THEN 1 ELSE 0 END),
        SUM(CASE WHEN c.is_lost = 1 THEN 1 ELSE 0 END),
        (COUNT(DISTINCT CASE WHEN t.transaction_id IS NOT NULL THEN c.copy_id END) / NULLIF(COUNT(DISTINCT c.copy_id), 0)) * 100,
        COUNT(DISTINCT t.transaction_id) / NULLIF(COUNT(DISTINCT c.copy_id), 0),
        (
            SELECT COUNT(DISTINCT genre_id) * 10.0 / NULLIF(COUNT(DISTINCT b2.book_id), 0)
            FROM lib_books_master b2
            LEFT JOIN lib_book_genre_jnt bg ON b2.book_id = bg.book_id
        )
    FROM lib_books_master b
    LEFT JOIN lib_book_copies c ON b.book_id = c.book_id
    LEFT JOIN lib_transactions t ON c.copy_id = t.copy_id AND t.issue_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    WHERE c.is_active = 1;
    
    -- Generate predictive analytics for top books
    INSERT INTO lib_predictive_analytics (
        prediction_date,
        prediction_type,
        target_entity_type,
        target_entity_id,
        prediction_period_start,
        prediction_period_end,
        predicted_value,
        confidence_score,
        model_version,
        insights
    )
    SELECT 
        CURDATE(),
        'Demand_Forecast',
        'Book',
        b.book_id,
        DATE_ADD(CURDATE(), INTERVAL 1 DAY),
        DATE_ADD(CURDATE(), INTERVAL 3 MONTH),
        COALESCE((
            SELECT AVG(monthly_avg) * 3 FROM (
                SELECT 
                    DATE_FORMAT(issue_date, '%Y-%m') as month,
                    COUNT(*) as monthly_avg
                FROM lib_transactions t
                INNER JOIN lib_book_copies c ON t.copy_id = c.copy_id
                WHERE c.book_id = b.book_id
                AND t.issue_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
                GROUP BY DATE_FORMAT(issue_date, '%Y-%m')
            ) t
        ), 0) * (
            1 + (pt.popularity_score / 100) * 0.3
        ),
        75 + (pt.popularity_score / 4),
        'v1.0',
        CONCAT('Based on ', COALESCE(pt.daily_issues, 0), ' daily issues and seasonal patterns')
    FROM lib_books_master b
    LEFT JOIN lib_book_popularity_trends pt ON b.book_id = pt.book_id AND pt.tracking_date = CURDATE()
    WHERE b.is_active = 1
    LIMIT 100;
END$$

DELIMITER ;

-- sp_generate_usage_predictions (Generates usage predictions for books and digital resources.)
DELIMITER $$

CREATE PROCEDURE `sp_generate_usage_predictions`()
BEGIN
    -- Insert usage predictions for books
    INSERT INTO lib_predictive_analytics (
        prediction_date,
        prediction_type,
        target_entity_type,
        target_entity_id,
        prediction_period_start,
        prediction_period_end,
        predicted_value,
        confidence_score,
        model_version,
        insights
    )
    SELECT 
        CURDATE(),
        'Usage_Prediction',
        'Book',
        b.book_id,
        DATE_ADD(CURDATE(), INTERVAL 1 DAY),
        DATE_ADD(CURDATE(), INTERVAL 3 MONTH),
        COALESCE((
            SELECT AVG(monthly_avg) * 3 FROM (
                SELECT 
                    DATE_FORMAT(issue_date, '%Y-%m') as month,
                    COUNT(*) as monthly_avg
                FROM lib_transactions t
                INNER JOIN lib_book_copies c ON t.copy_id = c.copy_id
                WHERE c.book_id = b.book_id
                AND t.issue_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
                GROUP BY DATE_FORMAT(issue_date, '%Y-%m')
            ) t
        ), 0) * (
            1 + (pt.popularity_score / 100) * 0.3
        ),
        75 + (pt.popularity_score / 4),
        'v1.0',
        CONCAT('Based on ', COALESCE(pt.daily_issues, 0), ' daily issues and seasonal patterns')
    FROM lib_books_master b
    LEFT JOIN lib_book_popularity_trends pt ON b.book_id = pt.book_id AND pt.tracking_date = CURDATE()
    WHERE b.is_active = 1
    LIMIT 100;
    
    -- Insert usage predictions for digital resources
    INSERT INTO lib_predictive_analytics (
        prediction_date,
        prediction_type,
        target_entity_type,
        target_entity_id,
        prediction_period_start,
        prediction_period_end,
        predicted_value,
        confidence_score,
        model_version,
        insights
    )
    SELECT 
        CURDATE(),
        'Usage_Prediction',
        'Digital_Resource',
        dr.digital_resource_id,
        DATE_ADD(CURDATE(), INTERVAL 1 DAY),
        DATE_ADD(CURDATE(), INTERVAL 3 MONTH),
        COALESCE((
            SELECT AVG(monthly_avg) * 3 FROM (
                SELECT 
                    DATE_FORMAT(access_date, '%Y-%m') as month,
                    COUNT(*) as monthly_avg
                FROM lib_digital_resource_accesses
                WHERE digital_resource_id = dr.digital_resource_id
                AND access_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
                GROUP BY DATE_FORMAT(access_date, '%Y-%m')
            ) t
        ), 0) * (
            1 + (dr.usage_score / 100) * 0.3
        ),
        75 + (dr.usage_score / 4),
        'v1.0',
        CONCAT('Based on ', COALESCE(dr.daily_accesses, 0), ' daily accesses and seasonal patterns')
    FROM lib_digital_resources dr
    WHERE dr.is_active = 1
    LIMIT 100;
END$$

DELIMITER ;

-- sp_generate_fine_predictions (Generates fine predictions for overdue books.)
DELIMITER $$

CREATE PROCEDURE `sp_generate_fine_predictions`()
BEGIN
    -- Insert fine predictions for overdue books
    INSERT INTO lib_predictive_analytics (
        prediction_date,
        prediction_type,
        target_entity_type,
        target_entity_id,
        prediction_period_start,
        prediction_period_end,
        predicted_value,
        confidence_score,
        model_version,
        insights
    )
    SELECT 
        CURDATE(),
        'Fine_Prediction',
        'Book',
        b.book_id,
        DATE_ADD(CURDATE(), INTERVAL 1 DAY),
        DATE_ADD(CURDATE(), INTERVAL 30 DAY),
        COALESCE((
            SELECT SUM(fine_amount) 
            FROM lib_fines 
            WHERE copy_id = c.copy_id 
            AND fine_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        ), 0) * 1.5,
        85,
        'v1.0',
        CONCAT('Predicted fines for ', COALESCE(b.title, 'Unknown Title'))
    FROM lib_books_master b
    INNER JOIN lib_book_copies c ON b.book_id = c.book_id
    INNER JOIN lib_transactions t ON c.copy_id = t.copy_id
    WHERE t.due_date < CURDATE()
    AND t.return_date IS NULL
    LIMIT 100;
END$$

DELIMITER ;

-- sp_generate_renewal_predictions (Generates renewal predictions for active loans.)
DELIMITER $$

CREATE PROCEDURE `sp_generate_renewal_predictions`()
BEGIN
    -- Insert renewal predictions for active loans
    INSERT INTO lib_predictive_analytics (
        prediction_date,
        prediction_type,
        target_entity_type,
        target_entity_id,
        prediction_period_start,
        prediction_period_end,
        predicted_value,
        confidence_score,
        model_version,
        insights
    )
    SELECT 
        CURDATE(),
        'Renewal_Prediction',
        'Book',
        b.book_id,
        DATE_ADD(CURDATE(), INTERVAL 1 DAY),
        DATE_ADD(CURDATE(), INTERVAL 30 DAY),
        COALESCE((
            SELECT COUNT(*) 
            FROM lib_transactions t2 
            WHERE t2.copy_id = t.copy_id 
            AND t2.issue_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        ), 0) * 1.2,
        80,
        'v1.0',
        CONCAT('Predicted renewals for ', COALESCE(b.title, 'Unknown Title'))
    FROM lib_books_master b
    INNER JOIN lib_book_copies c ON b.book_id = c.book_id
    INNER JOIN lib_transactions t ON c.copy_id = t.copy_id
    WHERE t.return_date IS NULL
    AND t.due_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    LIMIT 100;
END$$

DELIMITER ;

-- sp_generate_reservation_predictions (Generates reservation predictions for high-demand books.)
DELIMITER $$

CREATE PROCEDURE `sp_generate_reservation_predictions`()
BEGIN
    -- Insert reservation predictions for high-demand books
    INSERT INTO lib_predictive_analytics (
        prediction_date,
        prediction_type,
        target_entity_type,
        target_entity_id,
        prediction_period_start,
        prediction_period_end,
        predicted_value,
        confidence_score,
        model_version,
        insights
    )
    SELECT 
        CURDATE(),
        'Reservation_Prediction',
        'Book',
        b.book_id,
        DATE_ADD(CURDATE(), INTERVAL 1 DAY),
        DATE_ADD(CURDATE(), INTERVAL 30 DAY),
        COALESCE((
            SELECT COUNT(*) 
            FROM lib_reservations r 
            WHERE r.book_id = b.book_id 
            AND r.reservation_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        ), 0) * 1.3,
        85,
        'v1.0',
        CONCAT('Predicted reservations for ', COALESCE(b.title, 'Unknown Title'))
    FROM lib_books_master b
    WHERE b.is_active = 1
    AND (
        SELECT COUNT(*) 
        FROM lib_book_copies c 
        WHERE c.book_id = b.book_id 
        AND c.status = 'available'
    ) = 0
    LIMIT 100;
END$$

DELIMITER ;

-- sp_generate_recommendation_predictions (Generates book recommendations for members.)
DELIMITER $$

CREATE PROCEDURE `sp_generate_recommendation_predictions`()
BEGIN
    -- Insert book recommendations for members
    INSERT INTO lib_predictive_analytics (
        prediction_date,
        prediction_type,
        target_entity_type,
        target_entity_id,
        prediction_period_start,
        prediction_period_end,
        predicted_value,
        confidence_score,
        model_version,
        insights
    )
    SELECT 
        CURDATE(),
        'Recommendation_Prediction',
        'Book',
        b.book_id,
        DATE_ADD(CURDATE(), INTERVAL 1 DAY),
        DATE_ADD(CURDATE(), INTERVAL 30 DAY),
        COALESCE((
            SELECT COUNT(*) 
            FROM lib_transactions t 
            WHERE t.copy_id IN (
                SELECT copy_id 
                FROM lib_book_copies 
                WHERE book_id = b.book_id
            ) 
            AND t.issue_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        ), 0) * 1.1,
        80,
        'v1.0',
        CONCAT('Recommended for ', COALESCE(b.title, 'Unknown Title'))
    FROM lib_books_master b
    WHERE b.is_active = 1
    AND (
        SELECT COUNT(*) 
        FROM lib_book_copies c 
        WHERE c.book_id = b.book_id 
        AND c.status = 'available'
    ) > 0
    LIMIT 100;
END$$

DELIMITER ;


-- sp_generate_collection_gap_analysis (Generates collection gap analysis report.)
DELIMITER $$

CREATE PROCEDURE `sp_generate_collection_gap_analysis`()
BEGIN
    -- Insert collection gap analysis report
    INSERT INTO lib_reports (
        report_name,
        report_type,
        generated_date,
        generated_by,
        report_period_start,
        report_period_end,
        report_data,
        report_status,
        file_path
    )
    SELECT 
        'Collection Gap Analysis',
        'Analytics',
        CURDATE(),
        'System',
        DATE_SUB(CURDATE(), INTERVAL 1 YEAR),
        CURDATE(),
        JSON_OBJECT(
            'total_books', (SELECT COUNT(*) FROM lib_books_master),
            'available_books', (SELECT COUNT(*) FROM lib_book_copies WHERE status = 'available'),
            'loaned_books', (SELECT COUNT(*) FROM lib_book_copies WHERE status = 'loaned'),
            'missing_books', (SELECT COUNT(*) FROM lib_book_copies WHERE status = 'missing'),
            'damaged_books', (SELECT COUNT(*) FROM lib_book_copies WHERE status = 'damaged'),
            'category_distribution', (
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'category', c.category_name,
                        'total_books', COUNT(b.book_id),
                        'available_books', SUM(CASE WHEN cp.status = 'available' THEN 1 ELSE 0 END),
                        'loaned_books', SUM(CASE WHEN cp.status = 'loaned' THEN 1 ELSE 0 END)
                    )
                )
                FROM lib_books_master b
                INNER JOIN lib_categories c ON b.category_id = c.category_id
                LEFT JOIN lib_book_copies cp ON b.book_id = cp.book_id
                GROUP BY c.category_name
            )
        ),
        'Completed',
        NULL
    FROM lib_books_master b;
END$$

DELIMITER ;

-- sp_generate_circulation_analytics (Generates circulation analytics report.)
DELIMITER $$

CREATE PROCEDURE `sp_generate_circulation_analytics`()
BEGIN
    -- Insert circulation analytics report
    INSERT INTO lib_reports (
        report_name,
        report_type,
        generated_date,
        generated_by,
        report_period_start,
        report_period_end,
        report_data,
        report_status,
        file_path
    )
    SELECT 
        'Circulation Analytics',
        'Analytics',
        CURDATE(),
        'System',
        DATE_SUB(CURDATE(), INTERVAL 1 YEAR),
        CURDATE(),
        JSON_OBJECT(
            'total_transactions', (SELECT COUNT(*) FROM lib_transactions),
            'total_loans', (SELECT COUNT(*) FROM lib_transactions WHERE transaction_type = 'issue'),
            'total_returns', (SELECT COUNT(*) FROM lib_transactions WHERE transaction_type = 'return'),
            'total_renewals', (SELECT COUNT(*) FROM lib_transactions WHERE transaction_type = 'renewal'),
            'average_loan_period', (
                SELECT AVG(DATEDIFF(return_date, issue_date)) 
                FROM lib_transactions 
                WHERE return_date IS NOT NULL
            ),
            'most_borrowed_books', (
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'book_id', b.book_id,
                        'title', b.title,
                        'total_loans', COUNT(t.transaction_id)
                    )
                )
                FROM lib_transactions t
                INNER JOIN lib_book_copies c ON t.copy_id = c.copy_id
                INNER JOIN lib_books_master b ON c.book_id = b.book_id
                WHERE t.transaction_type = 'issue'
                GROUP BY b.book_id, b.title
                ORDER BY COUNT(t.transaction_id) DESC
                LIMIT 10
            )
        ),
        'Completed',
        NULL
    FROM lib_transactions;
END$$

DELIMITER ;

-- sp_generate_fine_analytics (Generates fine analytics report.)
DELIMITER $$

CREATE PROCEDURE `sp_generate_fine_analytics`()
BEGIN
    -- Insert fine analytics report
    INSERT INTO lib_reports (
        report_name,
        report_type,
        generated_date,
        generated_by,
        report_period_start,
        report_period_end,
        report_data,
        report_status,
        file_path
    )
    SELECT 
        'Fine Analytics',
        'Analytics',
        CURDATE(),
        'System',
        DATE_SUB(CURDATE(), INTERVAL 1 YEAR),
        CURDATE(),
        JSON_OBJECT(
            'total_fines', (SELECT COUNT(*) FROM lib_fines),
            'total_fine_amount', (SELECT SUM(fine_amount) FROM lib_fines),
            'total_paid_fines', (SELECT SUM(amount_paid) FROM lib_fines WHERE is_paid = 1),
            'total_unpaid_fines', (SELECT SUM(fine_amount - COALESCE(amount_paid, 0)) FROM lib_fines WHERE is_paid = 0),
            'average_fine_amount', (
                SELECT AVG(fine_amount) 
                FROM lib_fines
            ),
            'fines_by_category', (
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'category', c.category_name,
                        'total_fines', COUNT(f.fine_id),
                        'total_fine_amount', SUM(f.fine_amount)
                    )
                )
                FROM lib_fines f
                INNER JOIN lib_transactions t ON f.transaction_id = t.transaction_id
                INNER JOIN lib_book_copies cp ON t.copy_id = cp.copy_id
                INNER JOIN lib_books_master b ON cp.book_id = b.book_id
                INNER JOIN lib_categories c ON b.category_id = c.category_id
                GROUP BY c.category_name
            )
        ),
        'Completed',
        NULL
    FROM lib_fines;
END$$

DELIMITER ;

