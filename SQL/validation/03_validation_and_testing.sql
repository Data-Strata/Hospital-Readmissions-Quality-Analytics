-- ============================================================================
-- DATA-STRATA PROJECT 2: Hospital Readmission & Quality Analytics
-- Data Validation & Testing Script
-- ============================================================================
-- Purpose: Validate data integrity and test analytical views
-- Author: Mairilyn Yera Galindo
-- Date: 2025
-- ============================================================================

USE HospitalReadmissions;
GO

PRINT '============================================================================';
PRINT 'VALIDATION REPORT: Hospital Readmissions Database';
PRINT '============================================================================';
PRINT '';

-- ============================================================================
-- SECTION 1: Table Row Counts
-- ============================================================================
PRINT '1. TABLE ROW COUNTS';
PRINT '--------------------';

SELECT 'hospitals' AS table_name, COUNT(*) AS row_count 
FROM hospitals
UNION ALL
SELECT 'readmission_measures', COUNT(*) 
FROM readmission_measures;

PRINT '';
PRINT 'Expected: hospitals = 5,426 | readmission_measures = 18,330';
PRINT '';

-- ============================================================================
-- SECTION 2: Foreign Key Integrity
-- ============================================================================
PRINT '2. FOREIGN KEY INTEGRITY';
PRINT '------------------------';

-- Check for orphaned records in readmission_measures
SELECT 
    'Orphaned readmission records' AS check_name,
    COUNT(*) AS orphan_count
FROM readmission_measures r
LEFT JOIN hospitals h ON r.provider_id = h.provider_id
WHERE h.provider_id IS NULL;

PRINT 'Expected: 0 orphaned records';
PRINT '';

-- ============================================================================
-- SECTION 3: Condition Distribution
-- ============================================================================
PRINT '3. CONDITION DISTRIBUTION';
PRINT '-------------------------';

SELECT 
    condition_short,
    COUNT(*) AS row_count
FROM readmission_measures
GROUP BY condition_short
ORDER BY condition_short;

PRINT '';
PRINT 'Expected: 3,055 rows per condition (6 conditions)';
PRINT '';

-- ============================================================================
-- SECTION 4: Performance Tier Distribution
-- ============================================================================
PRINT '4. PERFORMANCE TIER DISTRIBUTION';
PRINT '---------------------------------';

SELECT 
    performance_tier,
    COUNT(*) AS row_count,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM readmission_measures) AS DECIMAL(5,2)) AS percentage
FROM readmission_measures
GROUP BY performance_tier
ORDER BY row_count DESC;

PRINT '';

-- ============================================================================
-- SECTION 5: Suppression Flag Distribution
-- ============================================================================
PRINT '5. SUPPRESSION FLAG DISTRIBUTION';
PRINT '---------------------------------';

SELECT 
    suppressed_flag,
    COUNT(*) AS row_count,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM readmission_measures) AS DECIMAL(5,2)) AS percentage
FROM readmission_measures
GROUP BY suppressed_flag
ORDER BY row_count DESC;

PRINT '';
PRINT 'Expected tiers: Full, Partial, None';
PRINT '';

-- ============================================================================
-- SECTION 6: NULL Value Check
-- ============================================================================
PRINT '6. NULL VALUE ANALYSIS';
PRINT '----------------------';

SELECT 
    'excess_readmission_ratio' AS column_name,
    COUNT(*) AS null_count,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM readmission_measures) AS DECIMAL(5,2)) AS pct_null
FROM readmission_measures
WHERE excess_readmission_ratio IS NULL
UNION ALL
SELECT 
    'num_discharges',
    COUNT(*),
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM readmission_measures) AS DECIMAL(5,2))
FROM readmission_measures
WHERE num_discharges IS NULL
UNION ALL
SELECT 
    'num_readmissions',
    COUNT(*),
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM readmission_measures) AS DECIMAL(5,2))
FROM readmission_measures
WHERE num_readmissions IS NULL;

PRINT '';

-- ============================================================================
-- SECTION 7: State Distribution (Top 10)
-- ============================================================================
PRINT '7. STATE DISTRIBUTION (TOP 10)';
PRINT '-------------------------------';

SELECT TOP 10
    state,
    COUNT(*) AS hospital_count
FROM hospitals
GROUP BY state
ORDER BY hospital_count DESC;

PRINT '';

-- ============================================================================
-- SECTION 8: Star Rating Distribution
-- ============================================================================
PRINT '8. STAR RATING DISTRIBUTION';
PRINT '---------------------------';

SELECT 
    star_rating,
    COUNT(*) AS hospital_count,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hospitals) AS DECIMAL(5,2)) AS percentage
FROM hospitals
GROUP BY star_rating
ORDER BY star_rating;

PRINT '';

-- ============================================================================
-- SECTION 9: View Validation
-- ============================================================================
PRINT '9. ANALYTICAL VIEW ROW COUNTS';
PRINT '------------------------------';

SELECT 'vw_condition_summary' AS view_name, COUNT(*) AS row_count 
FROM vw_condition_summary
UNION ALL
SELECT 'vw_state_performance', COUNT(*) 
FROM vw_state_performance
UNION ALL
SELECT 'vw_top_bottom_performers', COUNT(*) 
FROM vw_top_bottom_performers
UNION ALL
SELECT 'vw_florida_hospitals', COUNT(*) 
FROM vw_florida_hospitals;

PRINT '';
PRINT 'Expected:';
PRINT '  vw_condition_summary: 6 rows (one per condition)';
PRINT '  vw_state_performance: ~50-56 rows (states/territories)';
PRINT '  vw_top_bottom_performers: ~8,000 rows (non-suppressed measures)';
PRINT '  vw_florida_hospitals: varies (FL hospitals × 6 conditions)';
PRINT '';

-- ============================================================================
-- SECTION 10: Sample Data Quality Checks
-- ============================================================================
PRINT '10. DATA QUALITY CHECKS';
PRINT '-----------------------';

-- Check for ERR values outside expected range (0.5 to 2.0 is typical)
SELECT 
    'ERR out of range' AS check_name,
    COUNT(*) AS flagged_count
FROM readmission_measures
WHERE excess_readmission_ratio < 0.5 
   OR excess_readmission_ratio > 2.0;

-- Check for mismatched performance tiers (ERR > 1.0 should not be "Top Performer")
SELECT 
    'Performance tier mismatch' AS check_name,
    COUNT(*) AS flagged_count
FROM readmission_measures
WHERE (excess_readmission_ratio > 1.0 AND performance_tier = 'Top Performer')
   OR (excess_readmission_ratio < 0.9 AND performance_tier = 'High Risk');

-- Check for records with ERR but marked as suppressed
SELECT 
    'ERR present but flagged suppressed' AS check_name,
    COUNT(*) AS flagged_count
FROM readmission_measures
WHERE excess_readmission_ratio IS NOT NULL 
  AND performance_tier = 'Suppressed';

PRINT '';
PRINT 'Expected: All flagged counts should be 0';
PRINT '';

-- ============================================================================
-- SECTION 11: Florida-Specific Validation
-- ============================================================================
PRINT '11. FLORIDA DATA VALIDATION';
PRINT '----------------------------';

SELECT 
    'Total FL hospitals' AS metric,
    COUNT(DISTINCT provider_id) AS value
FROM hospitals
WHERE state = 'FL'
UNION ALL
SELECT 
    'FL readmission measures',
    COUNT(*)
FROM readmission_measures r
JOIN hospitals h ON r.provider_id = h.provider_id
WHERE h.state = 'FL'
UNION ALL
SELECT 
    'South Florida hospitals',
    COUNT(DISTINCT h.provider_id)
FROM hospitals h
WHERE h.state = 'FL'
  AND h.county IN ('Miami-Dade', 'Broward', 'Palm Beach');

PRINT '';

-- ============================================================================
-- SECTION 12: Sample Records from Each View
-- ============================================================================
PRINT '12. SAMPLE RECORDS FROM VIEWS';
PRINT '------------------------------';
PRINT '';
PRINT 'VIEW 1: vw_condition_summary (Top 3 by avg ERR)';
PRINT '------------------------------------------------';

SELECT TOP 3
    condition_short,
    total_hospitals,
    avg_err,
    pct_penalized
FROM vw_condition_summary
ORDER BY avg_err DESC;

PRINT '';
PRINT 'VIEW 2: vw_state_performance (Top 5 worst states)';
PRINT '--------------------------------------------------';

SELECT TOP 5
    state,
    total_hospitals,
    avg_err,
    pct_penalized
FROM vw_state_performance
ORDER BY avg_err DESC;

PRINT '';
PRINT 'VIEW 3: vw_top_bottom_performers (Sample top performers)';
PRINT '---------------------------------------------------------';

SELECT TOP 5
    facility_name,
    state,
    condition_short,
    err,
    performance_tier,
    rank_best
FROM vw_top_bottom_performers
WHERE ranking_group = 'Top 20'
ORDER BY condition_short, rank_best;

PRINT '';
PRINT 'VIEW 4: vw_florida_hospitals (Best South FL hospitals)';
PRINT '-------------------------------------------------------';

SELECT TOP 5
    facility_name,
    city,
    condition_short,
    err,
    err_vs_national,
    fl_rank
FROM vw_florida_hospitals
WHERE region = 'South Florida'
ORDER BY condition_short, fl_rank;

PRINT '';
PRINT '============================================================================';
PRINT 'VALIDATION COMPLETE';
PRINT '============================================================================';
PRINT '';
PRINT 'Next steps:';
PRINT '1. Review all validation results above';
PRINT '2. Confirm row counts match expected values';
PRINT '3. Verify no data quality issues flagged';
PRINT '4. Connect Power BI Desktop to these views';
PRINT '5. Build dashboard using validated data';
PRINT '';
PRINT '============================================================================';
