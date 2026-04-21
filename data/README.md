# Data Documentation

## 📊 Data Sources

All data used in this project comes from publicly available CMS (Centers for Medicare & Medicaid Services) datasets. No proprietary or confidential information is included.

---

## 🔗 Primary Data Sources

### 1. CMS Hospital Readmissions Reduction Program (HRRP)
**Source URL:** [data.cms.gov/provider-data/dataset/9n3s-kdb3](https://data.cms.gov/provider-data/dataset/9n3s-kdb3)

**File Name:** `Hospital_Readmissions_Reduction_Program.csv`

**Description:** Hospital-level data on excess readmission ratios (ERR) for six clinical conditions tracked under the HRRP penalty program.

**Scope:**
- ~18,330 records (3,055 hospitals × 6 conditions)
- Performance period: Varies by dataset version (typically 3-year measurement window)
- Geography: All 50 states, DC, and US territories

**Conditions Tracked:**
1. Heart Failure (READM-30-HF-HRRP)
2. Acute Myocardial Infarction / Heart Attack (READM-30-AMI-HRRP)
3. Pneumonia (READM-30-PN-HRRP)
4. Chronic Obstructive Pulmonary Disease (READM-30-COPD-HRRP)
5. Elective Total Hip Arthroplasty and/or Total Knee Arthroplasty / Hip & Knee Replacement (READM-30-HIP-KNEE-HRRP)
6. Coronary Artery Bypass Graft / Heart Bypass (READM-30-CABG-HRRP)

---

### 2. CMS Hospital General Information
**Source URL:** [data.cms.gov/provider-data/dataset/xubh-q36u](https://data.cms.gov/provider-data/dataset/xubh-q36u)

**File Name:** `Hospital_General_Information.csv`

**Description:** Comprehensive facility details including location, ownership type, hospital classification, and CMS Overall Hospital Quality Star Rating.

**Scope:**
- 5,426 registered hospital facilities
- Geography: All 50 states, DC, and US territories
- Includes Acute Care, Critical Access, Psychiatric, Rehabilitation, and other facility types

**Note:** This project filters to **Acute Care Hospitals only** as the HRRP program exclusively applies to this hospital type.

---

## 📋 Data Dictionary

### Base Table: `hospitals`

| Column Name | Data Type | Description | Source Field | Notes |
|-------------|-----------|-------------|--------------|-------|
| `provider_id` | VARCHAR(6) | CMS 6-digit facility identifier | Facility ID | Primary key |
| `facility_name` | VARCHAR(255) | Hospital name | Facility Name | Cleaned: trimmed, standardized |
| `address` | VARCHAR(255) | Street address | Address | |
| `city` | VARCHAR(100) | City/town | City/Town | |
| `state` | CHAR(2) | 2-letter state code | State | Indexed for geographic queries |
| `zip_code` | VARCHAR(10) | ZIP code | ZIP Code | |
| `county` | VARCHAR(100) | County/parish name | County/Parish | Used for South Florida regional flag |
| `phone` | VARCHAR(20) | Telephone number | Telephone Number | |
| `hospital_type` | VARCHAR(100) | Facility type classification | Hospital Type | Should be "Acute Care Hospitals" only |
| `hospital_ownership` | VARCHAR(100) | Ownership category | Hospital Ownership | Government / Non-Profit / For-Profit |
| `emergency_services` | VARCHAR(50) | Emergency department availability | Emergency Services | Yes / No |
| `star_rating` | TINYINT | CMS Overall Hospital Quality Star Rating (1-5) | Hospital Overall Rating | NULL if not rated |
| `rating_available` | CHAR(1) | Flag indicating if star rating exists | Derived | Y / N |
| `mort_measure_count` | INT | Count of mortality measures | Count of Facility MORT Measures | |
| `safety_measure_count` | INT | Count of patient safety measures | Count of Facility Safety Measures | |
| `readm_measure_count` | INT | Count of readmission measures | Count of Facility READM Measures | |
| `pt_exp_measure_count` | INT | Count of patient experience measures | Count of Facility Pt Exp Measures | |
| `te_measure_count` | INT | Count of timely & effective care measures | Count of Facility TE Measures | |

---

### Base Table: `readmission_measures`

| Column Name | Data Type | Description | Source Field | Notes |
|-------------|-----------|-------------|--------------|-------|
| `measure_id` | INT IDENTITY | Auto-increment surrogate key | N/A | Primary key |
| `provider_id` | VARCHAR(6) | Links to hospitals table | facility_id_clean | Foreign key |
| `condition_short` | VARCHAR(50) | Simplified condition name | Condition_Short | Created during cleaning |
| `measure_name` | VARCHAR(255) | Full CMS measure code | Measure Name | e.g., READM-30-HF-HRRP |
| `start_date` | DATE | Performance period start | Start Date | |
| `end_date` | DATE | Performance period end | End Date | |
| `num_discharges` | INT | Patient discharge volume | Number of Discharges | NULL if suppressed |
| `num_readmissions` | INT | 30-day readmission count | Number of Readmissions | NULL if suppressed |
| `excess_readmission_ratio` | DECIMAL(6,4) | ERR - Core performance metric | Excess Readmission Ratio | NULL if suppressed |
| `predicted_rate` | DECIMAL(6,4) | Hospital's expected rate (risk-adjusted) | Predicted Readmission Rate | |
| `expected_rate` | DECIMAL(6,4) | National benchmark rate | Expected Readmission Rate | |
| `performance_tier` | VARCHAR(50) | Performance categorization | Derived | Created during cleaning |
| `suppressed_flag` | VARCHAR(20) | Suppression type indicator | Derived | Created during cleaning |
| `footnote` | VARCHAR(500) | CMS notes or qualifiers | Footnote | |

---

## 🧹 Data Cleaning Methodology

All cleaning steps are documented in `data/cleaned/cleaning_log.xlsx` with 32+ logged issues.

### Cleaning Process Overview

#### Phase 1: Excel Data Validation (Hospital Readmissions)
**File:** `Hospital_Readmissions_Reduction_Program.csv` → `hospital_readmissions_cleaned.xlsx`

**Key Cleaning Actions:**

1. **Suppressed Value Handling (Issue #1-3)**
   - Replaced CMS suppression text with NULL:
     - "N/A" (full suppression) → NULL
     - "Too Few to Report" (partial suppression) → NULL
   - Affected columns: `Number of Discharges`, `Number of Readmissions`, `Excess Readmission Ratio`
   - Rows affected: ~10,088 (discharges), ~10,293 (readmissions), ~6,610 (ERR)

2. **Condition Name Standardization (Issue #4-9)**
   - Created `Condition_Short` column with readable names:
     - READM-30-HF-HRRP → Heart Failure
     - READM-30-AMI-HRRP → Heart Attack
     - READM-30-PN-HRRP → Pneumonia
     - READM-30-COPD-HRRP → COPD
     - READM-30-HIP-KNEE-HRRP → Hip & Knee Replacement
     - READM-30-CABG-HRRP → Heart Bypass (CABG)

3. **Performance Tier Calculation (Issue #10-14)**
   - Created `performance_tier` column with formula logic:
     - ERR < 0.90 → "Top Performer"
     - ERR 0.90-0.999 → "At or Below Average"
     - ERR 1.00-1.099 → "Elevated"
     - ERR ≥ 1.10 → "High Risk"
     - ERR = NULL → "Suppressed"

4. **Suppression Flag Creation (Issue #15-17)**
   - Created `suppressed_flag` column to categorize suppression types:
     - **Full**: All metrics NULL (ERR, volumes, rates)
     - **Partial**: Volumes NULL but ERR valid
     - **None**: All metrics populated

5. **Text Field Cleaning (Issue #18-20)**
   - Trimmed leading/trailing spaces from `State` and `Facility Name`
   - Standardized state codes to uppercase (all already correct)
   - Fixed 168 rows with extra spaces in `Facility Name`

6. **Facility ID Standardization (Issue #21)**
   - Created `facility_id_clean` column with 6-digit format (leading zeros preserved)
   - Converted numeric Facility IDs to text to match `hospital_info_clean` format

---

#### Phase 2: Excel Data Validation (Hospital General Information)
**File:** `Hospital_General_Information.csv` → `hospital_info_cleaned.csv`

**Key Cleaning Actions:**

1. **Star Rating Handling (Issue #22)**
   - Created `rating_available` flag (Y/N)
   - Replaced "Not Available" with NULL
   - Converted remaining values to numeric (1-5)
   - Rows affected: 2,560

2. **Text Field Validation (Issue #23-25)**
   - Trimmed all text columns: `State`, `City/Town`, `Hospital Type`, `Hospital Ownership`, `Emergency Services`
   - Verified capitalization consistency
   - All fields clean, zero issues found

3. **Safety Measure Count Handling (Issue #26)**
   - Replaced "Not Available" with NULL
   - Converted to numeric format
   - Rows affected: 2,073

4. **Hospital Type Validation (Issue #27)**
   - Confirmed only "Acute Care Hospitals" appear in joined data
   - This is correct — HRRP program exclusively targets Acute Care facilities
   - No changes needed

---

#### Phase 3: Data Integration (Join Hospital Info to Readmissions)
**Action:** VLOOKUP join from `hospital_info_clean` to `cleaned_data` on `facility_id_clean`

**Columns Joined:**
1. City/Town
2. Hospital Type
3. Hospital Ownership
4. Emergency Services
5. Hospital Overall Rating (star_rating)
6. rating_available
7. Count of Facility Safety Measures

**Result:** All 18,330 rows joined successfully with zero #N/A errors.

---

#### Phase 4: SQL Post-Import Validation (Issues #29-31)
**Validation suite executed after SQL import:**

1. **Suppression Classification Verification (Issue #29)**
   - Validated 3-tier suppression model accuracy across all 18,330 records
   - Confirmed suppression flag distribution:
     - Full = 6,610 (36.05%)
     - Partial = 3,680 (20.07%)
     - None = 8,040 (43.88%)
   - All suppressed rows correctly aligned with performance_tier = "Suppressed"

2. **Edge Case Testing (Issue #30)**
   - Tested for statistical edge case: NULL ERR with valid predicted_rate and expected_rate
   - Query: `WHERE predicted_readmis IS NOT NULL AND expected_readmis IS NOT NULL AND excess_readmission_ratio IS NULL`
   - Result: **0 rows returned** — edge case does not exist in dataset
   - Confirms 3-tier suppression model (Full/Partial/None) is complete and sufficient

3. **Performance Tier Alignment Check (Issue #31)**
   - Verified all suppressed records correctly assigned performance_tier = "Suppressed"
   - Validated ERR-based tier logic for non-suppressed records:
     - Top Performer (ERR < 0.90): 874 rows
     - At or Below Average (0.90 ≤ ERR < 1.00): 5,203 rows
     - Elevated (1.00 ≤ ERR < 1.10): 4,627 rows
     - High Risk (ERR ≥ 1.10): 1,016 rows
     - Suppressed: 6,610 rows
   - Total: 18,330 ✓ — Zero misclassifications found

**Validation outcome:** 
The 3-tier suppression classification system built during Excel cleaning (Full/Partial/None) was proven accurate and complete through comprehensive SQL testing. No data corrections were required post-import.
---

## 📊 Final Data Characteristics

### Cleaned Data Summary

| Metric | Count / Value |
|--------|---------------|
| Total hospitals | 5,426 |
| Total readmission measures | 18,330 |
| Unique hospitals in readmission data | 3,055 |
| Conditions tracked | 6 |
| Measures per condition | 3,055 (consistent) |
| Full suppression (all metrics NULL) | 6,610 (36.05%) |
| Partial suppression (volumes NULL, ERR valid) | 3,680 (20.07%) |
| No suppression (all metrics populated) | 8,033 (43.88%) |
| Hospitals with star ratings | 2,866 (53%) |
| Hospitals without star ratings | 2,560 (47%) |

---

### Performance Tier Distribution

| Tier | Count | Percentage |
|------|-------|------------|
| Suppressed | 6,610 | 36.1% |
| At or Below Average | 5,203 | 28.4% |
| Elevated | 4,627 | 25.2% |
| High Risk | 1,016 | 5.5% |
| Top Performer | 874 | 4.8% |

**Key Insight:** Only ~5% of hospital-condition measures achieve "Top Performer" status (ERR < 0.90), while ~31% fall into "Elevated" or "High Risk" categories (ERR ≥ 1.0).

---

### Suppression Analysis

**Why CMS Suppresses Data:**
- Patient privacy protection (< 25 cases)
- Statistical reliability (small sample sizes produce unstable metrics)
- HIPAA compliance

**Suppression Impact:**
- 36% of measures have complete suppression (mostly small/rural hospitals)
- 20% have partial suppression (volumes hidden, ERR still calculable)
- Affects rural and specialty hospitals disproportionately
- Does not impact large urban teaching hospitals

---

## 🔍 Data Quality Checks

### Validation Queries (Run After SQL Import)

**1. Check row counts:**
```sql
SELECT 'hospitals' AS tbl, COUNT(*) AS cnt FROM hospitals
UNION ALL
SELECT 'readmission_measures', COUNT(*) FROM readmission_measures;
-- Expected: 5,426 and 18,330
```

**2. Verify condition distribution:**
```sql
SELECT condition_short, COUNT(*) AS measure_count
FROM readmission_measures
GROUP BY condition_short
ORDER BY condition_short;
-- Expected: 3,055 for each of 6 conditions
```

**3. Check suppression tiers:**
```sql
SELECT suppressed_flag, COUNT(*) AS cnt
FROM readmission_measures
GROUP BY suppressed_flag;
-- Expected: Full, Partial, ERR Only, None
```

**4. Validate foreign key integrity:**
```sql
SELECT COUNT(*) AS orphaned_records
FROM readmission_measures r
LEFT JOIN hospitals h ON r.provider_id = h.provider_id
WHERE h.provider_id IS NULL;
-- Expected: 0
```

**5. Check ERR value range:**
```sql
SELECT MIN(excess_readmission_ratio) AS min_err,
       MAX(excess_readmission_ratio) AS max_err,
       AVG(excess_readmission_ratio) AS avg_err
FROM readmission_measures
WHERE excess_readmission_ratio IS NOT NULL;
-- Typical range: 0.5 to 2.0, average ~1.0
```

---

## 📁 File Inventory

### Raw Data Files
- `Hospital_Readmissions_Reduction_Program.csv` — Original CMS HRRP data (downloaded)
- `Hospital_General_Information.csv` — Original CMS facility data (downloaded)

### Cleaned Data Files
- `hospital_readmissions_cleaned.xlsx` — Cleaned readmission measures (18,330 rows)
  - Worksheet: `hospital_readmissions_cleaned`
- `hospital_info_cleaned.csv` — Cleaned hospital facility data (5,426 rows)
- `cleaning_log.xlsx` — Complete QA documentation (32 logged issues)

### Data Import Order
1. Import `hospital_info_cleaned.csv` → `hospitals` table
2. Import `hospital_readmissions_cleaned.xlsx` → `readmission_measures` table
3. Run validation queries

---

## 🎓 Domain Knowledge Notes

### Understanding Excess Readmission Ratio (ERR)

**Definition:** The ratio of a hospital's actual 30-day readmission rate to its predicted readmission rate, adjusted for patient risk factors.

**Formula:**
```
ERR = Actual Readmissions / Predicted Readmissions
```

**Interpretation:**
- **ERR = 1.0**: Hospital readmits at the expected rate
- **ERR < 1.0**: Hospital performs **better** than expected (fewer readmissions)
- **ERR > 1.0**: Hospital performs **worse** than expected (more readmissions)

**CMS Penalty Logic:**
- Hospitals with ERR > 1.0 face Medicare payment reductions (up to 3% of base DRG payments)
- Penalty calculated across all tracked conditions, not condition-specific

---

### Star Rating System

**CMS Overall Hospital Quality Star Rating:**
- 1 star = Lowest quality
- 5 stars = Highest quality
- Composite score based on 7 quality measure groups:
  1. Mortality
  2. Safety of Care
  3. Readmissions (includes HRRP data)
  4. Patient Experience
  5. Timely & Effective Care
  6. Imaging Efficiency
  7. Payment & Value of Care

**Coverage:** ~53% of hospitals have star ratings (others excluded due to insufficient data)

---

## 📞 Data Update Frequency

**CMS Update Schedule:**
- HRRP data: Updated **annually** (typically July)
- Hospital General Information: Updated **quarterly**
- Performance periods: Rolling 3-year measurement windows

**For Portfolio Use:**
- Data snapshot represents a point-in-time analysis
- Real-world implementations would refresh monthly/quarterly
- Power BI dashboards can connect to updated SQL tables via scheduled refresh

---

## ✍️ Author

© 2025 Mairilyn Yera Galindo | *Data-Strata Analytics Portfolio*  
Healthcare Data Cleaning & QA Documentation

*Last Updated: March 2026*
