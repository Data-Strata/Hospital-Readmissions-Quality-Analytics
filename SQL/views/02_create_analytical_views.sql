-- ============================================================================
-- DATA-STRATA PROJECT 2: Hospital Readmission & Quality Analytics
-- Analytical Views Script
-- ============================================================================
-- Purpose: Create 4 analytical views for Power BI dashboard
-- Author: Mairilyn Yera Galindo
-- Date: 2025
-- ============================================================================

USE HospitalReadmissions;
GO

-- ============================================================================
-- VIEW 1: vw_condition_summary
-- ============================================================================
-- Purpose: Aggregate readmission performance by condition
-- Use case: "Which conditions have the highest readmission rates nationally?"
-- Power BI: Overview page, Condition Deep-Dive page
-- ============================================================================

CREATE OR ALTER VIEW vw_condition_summary AS
SELECT 
    condition_short,
    COUNT(*) AS total_hospitals,
    
    -- Volume metrics
    SUM(num_discharges) AS total_discharges,
    SUM(num_readmissions) AS total_readmissions,
    
    -- Performance metrics (only non-suppressed records)
    COUNT(CASE WHEN excess_readmission_ratio IS NOT NULL THEN 1 END) AS hospitals_with_err,
    AVG(excess_readmission_ratio) AS avg_err,
    MIN(excess_readmission_ratio) AS min_err,
    MAX(excess_readmission_ratio) AS max_err,
    
    -- Performance tier distribution
    COUNT(CASE WHEN performance_tier = 'Top Performer' THEN 1 END) AS top_performers,
    COUNT(CASE WHEN performance_tier = 'At or Below Average' THEN 1 END) AS at_average,
    COUNT(CASE WHEN performance_tier = 'Elevated' THEN 1 END) AS elevated,
    COUNT(CASE WHEN performance_tier = 'High Risk' THEN 1 END) AS high_risk,
    COUNT(CASE WHEN performance_tier = 'Suppressed' THEN 1 END) AS suppressed,
    
    -- Penalty metrics (ERR > 1.0 = penalty territory)
    COUNT(CASE WHEN excess_readmission_ratio > 1.0 THEN 1 END) AS hospitals_penalized,
    CAST(COUNT(CASE WHEN excess_readmission_ratio > 1.0 THEN 1 END) * 100.0 / 
         NULLIF(COUNT(CASE WHEN excess_readmission_ratio IS NOT NULL THEN 1 END), 0) 
         AS DECIMAL(5,2)) AS pct_penalized
    
FROM readmission_measures
GROUP BY condition_short;
GO

-- ============================================================================
-- VIEW 2: vw_state_performance
-- ============================================================================
-- Purpose: Aggregate readmission performance by state
-- Use case: "Which states have the worst hospital readmission rates?"
-- Power BI: Geographic Analysis page
-- ============================================================================

CREATE OR ALTER VIEW vw_state_performance AS
SELECT 
    h.state,
    COUNT(DISTINCT h.provider_id) AS total_hospitals,
    
    -- Performance metrics across all conditions
    COUNT(r.measure_id) AS total_measures,
    COUNT(CASE WHEN r.excess_readmission_ratio IS NOT NULL THEN 1 END) AS measures_with_err,
    AVG(r.excess_readmission_ratio) AS avg_err,
    
    -- Performance tier distribution
    COUNT(CASE WHEN r.performance_tier = 'Top Performer' THEN 1 END) AS top_performer_measures,
    COUNT(CASE WHEN r.performance_tier = 'At or Below Average' THEN 1 END) AS at_average_measures,
    COUNT(CASE WHEN r.performance_tier = 'Elevated' THEN 1 END) AS elevated_measures,
    COUNT(CASE WHEN r.performance_tier = 'High Risk' THEN 1 END) AS high_risk_measures,
    
    -- Penalty metrics
    COUNT(CASE WHEN r.excess_readmission_ratio > 1.0 THEN 1 END) AS penalized_measures,
    CAST(COUNT(CASE WHEN r.excess_readmission_ratio > 1.0 THEN 1 END) * 100.0 / 
         NULLIF(COUNT(CASE WHEN r.excess_readmission_ratio IS NOT NULL THEN 1 END), 0) 
         AS DECIMAL(5,2)) AS pct_penalized,
    
    -- Quality ratings (hospital-level, not measure-level)
    AVG(CAST(h.star_rating AS FLOAT)) AS avg_star_rating,
    COUNT(CASE WHEN h.star_rating IS NOT NULL THEN 1 END) AS hospitals_with_rating
    
FROM hospitals h
LEFT JOIN readmission_measures r ON h.provider_id = r.provider_id
GROUP BY h.state;
GO

-- ============================================================================
-- VIEW 3: vw_top_bottom_performers
-- ============================================================================
-- Purpose: Identify best and worst performing hospitals per condition
-- Use case: "Which hospitals should we recommend/avoid for each condition?"
-- Power BI: Condition Deep-Dive page, Top/Bottom Performers page
-- ============================================================================

CREATE OR ALTER VIEW vw_top_bottom_performers AS
SELECT 
    r.provider_id,
    h.facility_name,
    h.state,
    h.city,
    r.condition_short,
    r.excess_readmission_ratio AS err,
    r.performance_tier,
    h.star_rating,
    h.hospital_ownership,
    r.num_discharges,
    
    -- Ranking within condition (1 = best, highest = worst)
    DENSE_RANK() OVER (
        PARTITION BY r.condition_short 
        ORDER BY r.excess_readmission_ratio ASC
    ) AS rank_best,
    
    DENSE_RANK() OVER (
        PARTITION BY r.condition_short 
        ORDER BY r.excess_readmission_ratio DESC
    ) AS rank_worst,
    
    -- Label for filtering in Power BI
    CASE 
        WHEN DENSE_RANK() OVER (
            PARTITION BY r.condition_short 
            ORDER BY r.excess_readmission_ratio ASC
        ) <= 20 THEN 'Top 20'
        WHEN DENSE_RANK() OVER (
            PARTITION BY r.condition_short 
            ORDER BY r.excess_readmission_ratio DESC
        ) <= 20 THEN 'Bottom 20'
        ELSE NULL 
    END AS ranking_group

FROM readmission_measures r
JOIN hospitals h ON r.provider_id = h.provider_id
WHERE r.excess_readmission_ratio IS NOT NULL  -- Only non-suppressed records
    AND r.performance_tier IN ('Top Performer', 'At or Below Average', 'Elevated', 'High Risk');
GO

-- ============================================================================
-- VIEW 4: vw_florida_hospitals
-- ============================================================================
-- Purpose: Florida-specific hospital performance analysis
-- Use case: "Which South Florida hospitals should Molina/Garner recommend?"
-- Power BI: Florida Provider Spotlight page
-- Strategic relevance: Your location (Boca Raton) + Molina's FL Medicaid presence
-- ============================================================================

CREATE OR ALTER VIEW vw_florida_hospitals AS
SELECT 
    h.provider_id,
    h.facility_name,
    h.city,
    h.county,
    h.hospital_ownership,
    h.star_rating,
    h.emergency_services,
    r.condition_short,
    r.excess_readmission_ratio AS err,
    r.performance_tier,
    r.num_discharges,
    r.num_readmissions,
    
    -- National comparison
    (SELECT AVG(excess_readmission_ratio) 
     FROM readmission_measures 
     WHERE condition_short = r.condition_short 
       AND excess_readmission_ratio IS NOT NULL) AS national_avg_err,
    
    -- Difference from national average
    r.excess_readmission_ratio - 
    (SELECT AVG(excess_readmission_ratio) 
     FROM readmission_measures 
     WHERE condition_short = r.condition_short 
       AND excess_readmission_ratio IS NOT NULL) AS err_vs_national,
    
    -- Ranking within Florida for this condition
    DENSE_RANK() OVER (
        PARTITION BY r.condition_short 
        ORDER BY r.excess_readmission_ratio ASC
    ) AS fl_rank,
    
    -- South Florida flag (Miami-Dade, Broward, Palm Beach counties)
    CASE 
        WHEN h.county IN ('Miami-Dade', 'Broward', 'Palm Beach') THEN 'South Florida'
        ELSE 'Other FL'
    END AS region

FROM hospitals h
JOIN readmission_measures r ON h.provider_id = r.provider_id
WHERE h.state = 'FL'
    AND r.excess_readmission_ratio IS NOT NULL;  -- Only non-suppressed records
GO

-- ============================================================================
-- VALIDATION QUERIES - Run these to test the views
-- ============================================================================

-- Test VIEW 1: Should return 6 conditions
-- SELECT * FROM vw_condition_summary ORDER BY avg_err DESC;

-- Test VIEW 2: Should return ~50-56 states/territories
-- SELECT * FROM vw_state_performance ORDER BY avg_err DESC;

-- Test VIEW 3: Should show top/bottom 20 per condition with rankings
-- SELECT * FROM vw_top_bottom_performers 
-- WHERE ranking_group IS NOT NULL
-- ORDER BY condition_short, rank_best;

-- Test VIEW 4: Should return FL hospitals only
-- SELECT * FROM vw_florida_hospitals 
-- WHERE region = 'South Florida'
-- ORDER BY condition_short, fl_rank;

-- ============================================================================
-- POWER BI CONNECTION NOTES
-- ============================================================================
-- 1. Connect Power BI to SQL Server using these views, not the raw tables
-- 2. Views pre-aggregate and calculate metrics → faster dashboard performance
-- 3. Each view maps to specific dashboard pages:
--    - vw_condition_summary → Overview + Condition Deep-Dive
--    - vw_state_performance → Geographic Analysis
--    - vw_top_bottom_performers → Top/Bottom Performers table
--    - vw_florida_hospitals → Florida Provider Spotlight
-- 4. All ERR comparisons use 1.0 as the penalty threshold
-- 5. Performance tiers drive conditional formatting in Power BI
-- ============================================================================
