-- Materialized View Table (Physical Table)
-- ----------------------------------------
CREATE TABLE cmp_mv_complaint_hotspots (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    target_user_type_id BIGINT UNSIGNED NOT NULL,
    target_selected_id BIGINT UNSIGNED NOT NULL,
    target_name VARCHAR(255) NOT NULL,

    total_complaints INT NOT NULL,
    unique_complainants INT NOT NULL,

    most_common_category_id BIGINT UNSIGNED NULL,

    avg_risk_score DECIMAL(6,2) NOT NULL,
    avg_escalation_risk_score DECIMAL(6,2) NOT NULL,
    avg_safety_risk_score DECIMAL(6,2) NOT NULL,

    last_complaint_at DATETIME NOT NULL,

    snapshot_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_mv_target_snapshot (
        target_user_type_id,
        target_selected_id,
        snapshot_date
    ),

    INDEX idx_mv_target (target_user_type_id, target_selected_id),
    INDEX idx_mv_snapshot (snapshot_date)
) ENGINE=InnoDB;


-- ------------------------------------------------------------------------------------------------
-- Materialized View Table (cmp_mv_complaint_hotspots) Data Dictionary
-- ------------------------------------------------------------------------------------------------
| Column	                | Purpose
| target_user_type_id	    | Vehicle / Teacher / Route
| target_selected_id	    | FK reference
| target_name	            | Display
| total_complaints	        | Frequency
| unique_complainants	    | Bias detection
| most_common_category_id	| Trend
| avg_risk_score	        | Hotspot severity
| avg_escalation_risk_score | Escalation likelihood
| avg_safety_risk_score	    | Child safety
| last_complaint_at	        | Recency
| snapshot_date	            | MV versioning


-- ------------------------------------------------------------------------------------------------
-- Data Insertion
-- ------------------------------------------------------------------------------------------------

INSERT INTO cmp_mv_complaint_hotspots (
    target_user_type_id,
    target_selected_id,
    target_name,
    total_complaints,
    unique_complainants,
    most_common_category_id,
    avg_risk_score,
    avg_escalation_risk_score,
    avg_safety_risk_score,
    last_complaint_at,
    snapshot_date
)
SELECT
    c.target_user_type_id,
    c.target_selected_id,
    MAX(c.target_name) AS target_name,

    COUNT(c.id) AS total_complaints,
    COUNT(DISTINCT c.complainant_user_id) AS unique_complainants,

    (
        SELECT c2.category_id
        FROM cmp_complaints c2
        WHERE c2.target_selected_id = c.target_selected_id
        GROUP BY c2.category_id
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS most_common_category_id,

    AVG(ai.risk_score) AS avg_risk_score,
    AVG(ai.escalation_risk_score) AS avg_escalation_risk_score,
    AVG(ai.safety_risk_score) AS avg_safety_risk_score,

    MAX(c.created_at) AS last_complaint_at,

    CURDATE() AS snapshot_date
FROM cmp_complaints c
JOIN cmp_ai_insights ai ON ai.complaint_id = c.id
WHERE c.target_selected_id IS NOT NULL
GROUP BY c.target_user_type_id, c.target_selected_id;

