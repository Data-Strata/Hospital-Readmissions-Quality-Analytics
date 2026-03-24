-- ============================================================================
-- DATA-STRATA PROJECT 2: Hospital Readmission & Quality Analytics
-- SQL Server Database Setup Script
-- ============================================================================
-- Purpose: Create database, tables, and import cleaned data from Excel/CSV
-- Author: Mairilyn Yera Galindo
-- Date: 2025
-- ============================================================================

-- STEP 1: Create the database
-- ============================================================================
USE master;
GO

-- Drop existing database if it exists (for clean rebuild)
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'HospitalReadmissions')
BEGIN
    ALTER DATABASE HospitalReadmissions SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE HospitalReadmissions;
END
GO

-- Create new database
CREATE DATABASE HospitalReadmissions;
GO

USE HospitalReadmissions;
GO

-- ============================================================================
-- STEP 2: Create TABLE 1 - hospitals
-- ============================================================================
-- This table contains one row per hospital with facility details
-- Source: hospital_info_cleaned.csv (5,426 hospitals)
-- ============================================================================

CREATE TABLE hospitals (
    -- Primary key
    provider_id VARCHAR(6) PRIMARY KEY,  -- CMS 6-digit facility ID
    
    -- Facility identification
    facility_name VARCHAR(255) NOT NULL,
    address VARCHAR(255),
    city VARCHAR(100),
    state CHAR(2) NOT NULL,  -- 2-letter state code
    zip_code VARCHAR(10),
    county VARCHAR(100),
    phone VARCHAR(20),
    
    -- Hospital classification
    hospital_type VARCHAR(100),  -- e.g., "Acute Care Hospitals"
    hospital_ownership VARCHAR(100),  -- e.g., "Government - Hospital District or Authority"
    emergency_services VARCHAR(50),  -- Yes/No
    
    -- Quality ratings
    star_rating TINYINT,  -- 1-5 stars (NULL if not rated)
    rating_available CHAR(1),  -- Y/N flag
    
    -- Quality measure counts
    mort_measure_count INT,
    safety_measure_count INT,
    readm_measure_count INT,
    pt_exp_measure_count INT,
    te_measure_count INT,
    
    -- Audit fields
    created_date DATETIME DEFAULT GETDATE()
);
GO

-- Create indexes for common queries
CREATE INDEX idx_hospitals_state ON hospitals(state);
CREATE INDEX idx_hospitals_type ON hospitals(hospital_type);
CREATE INDEX idx_hospitals_rating ON hospitals(star_rating);
GO

-- ============================================================================
-- STEP 3: Create TABLE 2 - readmission_measures
-- ============================================================================
-- This table contains one row per hospital-condition combination
-- Source: Hospital_readmission_cleaned.xlsx (18,330 rows)
-- Key: 3,055 hospitals × 6 conditions = 18,330 rows
-- ============================================================================

CREATE TABLE readmission_measures (
    -- Composite primary key
    measure_id INT IDENTITY(1,1) PRIMARY KEY,  -- Auto-increment surrogate key
    provider_id VARCHAR(6) NOT NULL,
    condition_short VARCHAR(50) NOT NULL,
    
    -- CMS measure details
    measure_name VARCHAR(255),  -- Full CMS measure name
    start_date DATE,
    end_date DATE,
    
    -- Volume metrics
    num_discharges INT,  -- NULL if suppressed ("Too Few")
    num_readmissions INT,  -- NULL if suppressed
    
    -- Performance ratios (core analytics)
    excess_readmission_ratio DECIMAL(6,4),  -- ERR - NULL if suppressed
    predicted_rate DECIMAL(6,4),
    expected_rate DECIMAL(6,4),
    
    -- Categorization
    performance_tier VARCHAR(50),  -- Top Performer / At or Below Average / Elevated / High Risk / Suppressed
    suppressed_flag VARCHAR(20),  -- Full / Partial / ERR Only / None
    
    -- Footnotes
    footnote VARCHAR(500),
    
    -- Foreign key to hospitals table
    CONSTRAINT fk_readmission_hospital FOREIGN KEY (provider_id) 
        REFERENCES hospitals(provider_id),
    
    -- Unique constraint - one row per hospital-condition
    CONSTRAINT uk_provider_condition UNIQUE (provider_id, condition_short),
    
    -- Audit fields
    created_date DATETIME DEFAULT GETDATE()
);
GO

-- Create indexes for analytical queries
CREATE INDEX idx_readmission_provider ON readmission_measures(provider_id);
CREATE INDEX idx_readmission_condition ON readmission_measures(condition_short);
CREATE INDEX idx_readmission_tier ON readmission_measures(performance_tier);
CREATE INDEX idx_readmission_err ON readmission_measures(excess_readmission_ratio);
CREATE INDEX idx_readmission_suppression ON readmission_measures(suppressed_flag);
GO

-- ============================================================================
-- STEP 4: Data Import Instructions
-- ============================================================================
-- Use SQL Server Management Studio (SSMS) Import Wizard:
--
-- TABLE 1 - hospitals:
--   1. Right-click HospitalReadmissions database → Tasks → Import Data
--   2. Source: Flat File Source → Select hospital_info_cleaned.csv
--   3. Destination: SQL Server Native Client → HospitalReadmissions database
--   4. Map columns from CSV to hospitals table
--   5. Field mapping:
--      - Facility ID → provider_id
--      - Facility Name → facility_name
--      - City/Town → city
--      - Hospital Overall Rating → star_rating
--      - rating_available → rating_available
--      - Count of Facility MORT Measures → mort_measure_count
--      - Count of Facility Safety Measures → safety_measure_count
--      - Count of Facility READM Measures → readm_measure_count
--      - Count of Facility Pt Exp Measures → pt_exp_measure_count
--      - Count of Facility TE Measures → te_measure_count
--
-- TABLE 2 - readmission_measures:
--   1. Right-click HospitalReadmissions database → Tasks → Import Data
--   2. Source: Excel → Select Hospital_readmission_cleaned.xlsx
--   3. Select sheet: hospital_readmissions_cleaned
--   4. Destination: SQL Server → readmission_measures table
--   5. Field mapping:
--      - facility_id_clean → provider_id
--      - Condition_Short → condition_short
--      - Measure Name → measure_name
--      - Start Date → start_date
--      - End Date → end_date
--      - Number of Discharges → num_discharges
--      - Number of Readmissions → num_readmissions
--      - Excess Readmission Ratio → excess_readmission_ratio
--      - Predicted Readmission Rate → predicted_rate
--      - Expected Readmission Rate → expected_rate
--      - performance_tier → performance_tier
--      - suppressed_flag → suppressed_flag
--      - Footnote → footnote
--
-- ============================================================================
-- STEP 5: Post-Import Validation
-- ============================================================================

-- Verify row counts
-- Expected: hospitals = 5,426 rows, readmission_measures = 18,330 rows
-- Run after import:

-- SELECT COUNT(*) AS hospital_count FROM hospitals;
-- SELECT COUNT(*) AS readmission_count FROM readmission_measures;

-- Verify foreign key integrity
-- Should return 0 orphaned records:

-- SELECT COUNT(*) 
-- FROM readmission_measures r
-- LEFT JOIN hospitals h ON r.provider_id = h.provider_id
-- WHERE h.provider_id IS NULL;

-- Check condition distribution (should be 3,055 per condition)
-- SELECT condition_short, COUNT(*) as row_count
-- FROM readmission_measures
-- GROUP BY condition_short
-- ORDER BY row_count DESC;

-- ============================================================================
-- NOTES
-- ============================================================================
-- 1. This script creates the foundation for 4 analytical views (see next script)
-- 2. All suppressed values (Too Few, N/A) are stored as NULL
-- 3. Performance tier includes "Suppressed" for records with NULL ERR
-- 4. The suppressed_flag field has 4 values: Full, Partial, ERR Only, None
-- 5. Florida-specific analysis will filter on state = 'FL'
-- ============================================================================
