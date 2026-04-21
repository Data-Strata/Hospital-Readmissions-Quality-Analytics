# SQL Documentation

## 📊 Database Architecture Overview

The **HospitalReadmissions** database follows a normalized relational design with two core tables and four analytical views. This structure separates hospital facility information from condition-specific readmission measures, enabling efficient querying and modular analytics.

---

## 🗂️ Database Schema

### Core Tables

#### 1. `hospitals` (5,426 rows)
One row per hospital facility with CMS registration details and quality metrics.

**Primary Key:** `provider_id` (VARCHAR(6))

**Key Columns:**
- `provider_id` — 6-digit CMS facility identifier
- `facility_name` — Hospital name (cleaned, trimmed)
- `city`, `state`, `zip_code` — Geographic location
- `hospital_type` — Facility classification (e.g., "Acute Care Hospitals")
- `hospital_ownership` — Government, Non-Profit, For-Profit
- `star_rating` — CMS Overall Hospital Quality Star Rating (1-5, NULL if not rated)
- `rating_available` — Flag indicating if star rating exists (Y/N)
- `mort_measure_count`, `safety_measure_count`, `readm_measure_count` — Quality measure counts

**Indexes:**
- Primary key on `provider_id`
- Non-clustered indexes on `state`, `hospital_type`, `star_rating`

**Source:** `hospital_info_cleaned.csv`

---

#### 2. `readmission_measures` (18,330 rows)
One row per hospital-condition combination (3,055 hospitals × 6 conditions).

**Primary Key:** `measure_id` (INT IDENTITY)  
**Unique Constraint:** `provider_id` + `condition_short`  
**Foreign Key:** `provider_id` references `hospitals(provider_id)`

**Key Columns:**
- `provider_id` — Links to hospitals table
- `condition_short` — Simplified condition name (Heart Failure, Heart Attack, Pneumonia, COPD, Hip & Knee Replacement, Heart Bypass)
- `measure_name` — Full CMS measure name (e.g., "READM-30-HF-HRRP")
- `num_discharges` — Patient volume for condition (NULL if suppressed)
- `num_readmissions` — Readmission count (NULL if suppressed)
- `excess_readmission_ratio` — **ERR** - Core performance metric (NULL if suppressed)
- `predicted_rate` — Hospital's expected readmission rate adjusted for patient risk
- `expected_rate` — National benchmark rate
- `performance_tier` — Categorization: Top Performer / At or Below Average / Elevated / High Risk / Suppressed
- `suppressed_flag` — Suppression type: Full / Partial / ERR Only / None
- `start_date`, `end_date` — Performance measurement period

**Indexes:**
- Primary key on `measure_id`
- Non-clustered indexes on `provider_id`, `condition_short`, `performance_tier`, `excess_readmission_ratio`, `suppressed_flag`
- Unique constraint on `provider_id` + `condition_short`

**Source:** `Hospital_readmission_cleaned.xlsx`

---

## 📐 Analytical Views

### View Purpose & Design Philosophy

Each view represents a specific business question and pre-aggregates data for optimal Power BI performance. Views are designed to be modular, reusable, and transparent in their calculation logic.

---

### 1. `vw_condition_summary`
**Returns:** 6 rows (one per condition)

**Purpose:** National-level performance aggregation by clinical condition.

**Business Questions:**
- Which conditions have the highest readmission rates nationally?
- What percentage of hospitals are penalized for each condition?
- How many hospitals have suppressed data per condition?

**Key Metrics:**
- `total_hospitals` — Hospital count reporting this condition
- `total_discharges`, `total_readmissions` — Volume metrics
- `avg_err`, `min_err`, `max_err` — ERR distribution
- `hospitals_penalized` — Count with ERR > 1.0
- `pct_penalized` — Percentage in penalty territory
- `top_performers`, `elevated`, `high_risk`, `suppressed` — Performance tier counts

**Power BI Usage:** Overview page (national KPIs), Condition Deep-Dive page (condition slicer)

**SQL File:** `SQL/views/02_create_analytical_views.sql` (lines 15-48)

---

### 2. `vw_state_performance`
**Returns:** 56 rows (one per state/territory)

**Purpose:** State-level readmission performance aggregation across all conditions.

**Business Questions:**
- Which states have the worst hospital readmission performance?
- How does average ERR vary by geography?
- What is the correlation between state performance and star ratings?

**Key Metrics:**
- `state` — 2-letter state code
- `total_hospitals` — Unique hospital count per state
- `total_measures` — Total condition-level records
- `avg_err` — State average ERR across all conditions
- `penalized_measures` — Count of measures with ERR > 1.0
- `pct_penalized` — Percentage of measures in penalty territory
- `avg_star_rating` — State average hospital star rating

**Power BI Usage:** Geographic Analysis page (state map, regional comparisons)

**SQL File:** `SQL/views/02_create_analytical_views.sql` (lines 50-85)

---

### 3. `vw_top_bottom_performers`
**Returns:** 11,720 rows (non-suppressed measures only)

**Purpose:** Hospital rankings within each condition with top/bottom 20 flags.

**Business Questions:**
- Which hospitals have the best/worst readmission rates for each condition?
- How do high-volume hospitals compare to low-volume hospitals?
- What ownership types correlate with better performance?

**Key Metrics:**
- `provider_id`, `facility_name`, `state`, `city` — Hospital identifiers
- `condition_short` — Clinical condition
- `err` — Excess readmission ratio
- `performance_tier` — Top Performer / At Average / Elevated / High Risk
- `star_rating`, `hospital_ownership` — Quality and organizational attributes
- `rank_best` — Dense rank (1 = best ERR for condition)
- `rank_worst` — Dense rank (1 = worst ERR for condition)
- `ranking_group` — "Top 20" or "Bottom 20" flag for filtering

**Power BI Usage:** Condition Deep-Dive rankings table, provider comparison visuals

**SQL File:** `SQL/views/02_create_analytical_views.sql` (lines 87-135)

---

### 4. `vw_florida_hospitals`
**Returns:** 771 rows (FL hospitals only, non-suppressed measures)

**Purpose:** Florida-specific hospital performance with national benchmarking and South Florida regional flag.

**Business Questions:**
- Which Florida hospitals should Molina Healthcare recommend to members?
- How do South Florida providers compare to state and national averages?
- What is the performance distribution in key Florida markets (Miami-Dade, Broward, Palm Beach)?

**Key Metrics:**
- `provider_id`, `facility_name`, `city`, `county` — Hospital identifiers
- `condition_short` — Clinical condition
- `err` — Excess readmission ratio
- `performance_tier` — Performance categorization
- `national_avg_err` — National benchmark for this condition
- `err_vs_national` — Difference from national average (negative = better than national)
- `fl_rank` — Ranking within Florida for this condition
- `region` — "South Florida" (Miami-Dade, Broward, Palm Beach) or "Other FL"
- `star_rating`, `emergency_services`, `hospital_ownership` — Quality and service attributes

**Strategic Relevance:**
This view directly supports managed care network decisions in regional healthcare provider's market such as Molina Healthcare's Florida Medicaid. The `region` flag enables targeted analysis of South Florida — a high-density market with significant Medicaid enrollment.

**Power BI Usage:** Florida Provider Spotlight page (FL-only analysis, South FL comparison)

**SQL File:** `SQL/views/02_create_analytical_views.sql` (lines 137-180)

---

## 🔄 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    CMS Public Data Sources                      │
├────────────────────────┬────────────────────────────────────────┤
│ Hospital Readmissions  │  Hospital General Information          │
│ (HRRP Dataset)         │  (Facility Details)                    │
└────────────┬───────────┴─────────────────┬──────────────────────┘
             │                             │
             ▼                             ▼
    ┌────────────────┐          ┌─────────────────┐
    │  Excel Data    │          │  Excel Data     │
    │  Cleaning      │          │  Cleaning       │
    │  + QA Log      │          │  + QA Log       │
    └────────┬───────┘          └────────┬────────┘
             │                           │
             ▼                           ▼
    ┌────────────────────┐    ┌──────────────────┐
    │ readmission_       │    │  hospitals       │
    │ measures           │◄───┤  (5,426 rows)    │
    │ (18,330 rows)      │FK  └──────────────────┘
    └────────┬───────────┘
             │
      ┌──────┴──────┬──────────┬────────────┐
      ▼             ▼          ▼            ▼
┌──────────┐  ┌──────────┐ ┌────────┐ ┌──────────┐
│vw_       │  │vw_state_ │ │vw_top_ │ │vw_       │
│condition_│  │perform   │ │bottom_ │ │florida_  │
│summary   │  │ance      │ │perform │ │hospitals │
└─────┬────┘  └────┬─────┘ └───┬────┘ └────┬─────┘
      │            │            │           │
      └────────────┴────────────┴───────────┘
                       │
                       ▼
            ┌──────────────────────┐
            │   Power BI Desktop   │
            │   (6 Dashboard Pages)│
            └──────────────────────┘
```

---

## 📋 Implementation Order

### Step 1: Create Database and Tables
**Script:** `SQL/schema/01_create_database_and_tables.sql`

**Actions:**
1. Creates `HospitalReadmissions` database
2. Creates `hospitals` table with indexes
3. Creates `readmission_measures` table with foreign key constraint

**Expected Result:** Empty database with 2 tables, ready for data import.

**Validation:**
```sql
SELECT COUNT(*) FROM hospitals;          -- Should return 0
SELECT COUNT(*) FROM readmission_measures;  -- Should return 0
```

---

### Step 2: Import Data
**Method:** SQL Server Management Studio (SSMS) Import Wizard

**Import 1: hospitals table**
- Source: `data/cleaned/hospital_info_cleaned.csv`
- Destination: `[dbo].[hospitals]`
- Critical mappings:
  - `Facility ID` → `provider_id`
  - `Facility Name` → `facility_name`
  - `Hospital Overall Rating` → `star_rating`
- Expected row count: **5,426**

**Import 2: readmission_measures table**
- Source: `data/cleaned/hospital_readmissions_cleaned.xlsx`
- Worksheet: `hospital_readmissions_cleaned`
- Destination: `[dbo].[readmission_measures]`
- Critical mappings:
  - `facility_id_clean` → `provider_id`
  - `Condition_Short` → `condition_short`
  - `Excess Readmission Ratio` → `excess_readmission_ratio`
- Expected row count: **18,330**

**Validation:**
```sql
-- Check row counts
SELECT 'hospitals' AS tbl, COUNT(*) AS cnt FROM hospitals
UNION ALL
SELECT 'readmission_measures', COUNT(*) FROM readmission_measures;

-- Check foreign key integrity (should return 0)
SELECT COUNT(*) FROM readmission_measures r
LEFT JOIN hospitals h ON r.provider_id = h.provider_id
WHERE h.provider_id IS NULL;
```

---

### Step 3: Create Analytical Views
**Script:** `SQL/views/02_create_analytical_views.sql`

**Actions:**
1. Creates `vw_condition_summary`
2. Creates `vw_state_performance`
3. Creates `vw_top_bottom_performers`
4. Creates `vw_florida_hospitals`

**Expected Result:** 4 views created successfully.

**Validation:**
```sql
-- Check view row counts
SELECT 'vw_condition_summary' AS vw, COUNT(*) AS cnt FROM vw_condition_summary
UNION ALL
SELECT 'vw_state_performance', COUNT(*) FROM vw_state_performance
UNION ALL
SELECT 'vw_top_bottom_performers', COUNT(*) FROM vw_top_bottom_performers
UNION ALL
SELECT 'vw_florida_hospitals', COUNT(*) FROM vw_florida_hospitals;

-- Expected:
-- vw_condition_summary: 6 rows
-- vw_state_performance: 56 rows
-- vw_top_bottom_performers: 11720 rows
-- vw_florida_hospitals: 771 rows
```

---

### Step 4: Run Validation Suite
**Script:** `SQL/validation/03_validation_and_testing.sql`

**Actions:**
Runs 12 validation checks including:
1. Table row counts
2. Foreign key integrity
3. Condition distribution (should be 3,055 per condition)
4. Performance tier distribution
5. Suppression flag distribution
6. NULL value analysis
7. State distribution
8. Star rating distribution
9. View row counts
10. Data quality checks (ERR range, tier logic)
11. Florida-specific validation
12. Sample records from each view

**Expected Result:** All checks pass with 0 errors.

**Key Validations:**
- ✅ hospitals = 5,426 rows
- ✅ readmission_measures = 18,330 rows
- ✅ 0 orphaned records
- ✅ Each condition has 3,055 rows
- ✅ No performance tier mismatches
- ✅ All views return expected row counts

---

## 🎨 Power BI Connection

### Recommended Connection Method

1. **Get Data → SQL Server**
2. **Server:** [Your SQL Server instance name]
3. **Database:** HospitalReadmissions
4. **Data Connectivity Mode:** Import (recommended for performance)

### What to Import

✅ **Import all 4 views:**
- vw_condition_summary
- vw_state_performance
- vw_top_bottom_performers
- vw_florida_hospitals

❌ **Do NOT import raw tables:**
- hospitals *(use views instead for pre-aggregated logic)*
- readmission_measures *(use views instead)*

### View-to-Dashboard Mapping

| Power BI Page | Primary View(s) |
|---------------|-----------------|
| 1. Executive Overview | vw_condition_summary, vw_state_performance |
| 2. Condition Deep-Dive | vw_condition_summary, vw_top_bottom_performers |
| 3. Geographic Analysis | vw_state_performance |
| 4. Florida Provider Spotlight | vw_florida_hospitals |
| 5. Data Quality & Methodology | *(Reference cleaning_log.xlsx, not SQL views)* |
| 6. Florida Provider's Recommendations Bookmark| * _Florida Provider Spotlight_ Page|
---

## 🔧 Troubleshooting

### Issue: Import fails with data type mismatch
**Solution:** In SSMS Import Wizard, click "Edit Mappings" and verify:
- Numeric columns (ERR, star_rating, counts) map to appropriate SQL types
- NULL handling is correct for suppressed values
- VARCHAR lengths are sufficient for text fields

### Issue: Foreign key violation during readmission_measures import
**Solution:** 
1. Verify `hospitals` table was imported first
2. Check that all `facility_id_clean` values in Excel exist in `hospitals.provider_id`
3. Run validation query:
```sql
SELECT DISTINCT r.provider_id
FROM readmission_measures r
LEFT JOIN hospitals h ON r.provider_id = h.provider_id
WHERE h.provider_id IS NULL;
```

### Issue: View returns no data
**Solution:**
1. Verify both tables have data: `SELECT COUNT(*) FROM hospitals; SELECT COUNT(*) FROM readmission_measures;`
2. Check view definition executed without errors
3. Test underlying join:
```sql
SELECT COUNT(*) FROM readmission_measures r
JOIN hospitals h ON r.provider_id = h.provider_id;
```

### Issue: Performance tier or suppression flag distribution looks wrong
**Solution:** Run the validation script (`03_validation_and_testing.sql`) section 4 and 5 to see expected distributions. If mismatched, check Excel formulas in `Hospital_readmission_cleaned.xlsx`.

---

## 📚 Technical Notes

### Performance Tier Logic
Defined in Excel during data cleaning, imported as calculated values:

```
ERR < 0.90           → "Top Performer"
ERR >= 0.90 AND < 1.00 → "At or Below Average"
ERR >= 1.00 AND < 1.10 → "Elevated"
ERR >= 1.10            → "High Risk"
ERR IS NULL            → "Suppressed"
```

### Suppression Flag Types
- **Full**: ERR, num_discharges, num_readmissions, predicted_rate, expected_rate all NULL
- **Partial**: num_discharges and num_readmissions = NULL, but ERR is valid
- **None**: All metrics populated

### Index Strategy
- **Primary keys**: Clustered indexes for fast lookups
- **Foreign keys**: Non-clustered index on `readmission_measures.provider_id` for join performance
- **Filter columns**: Indexes on `state`, `condition_short`, `performance_tier` for Power BI slicers
- **Sort columns**: Index on `excess_readmission_ratio` for ranking queries

### ERR Interpretation
- **ERR = 1.0**: Hospital readmits at the national expected rate
- **ERR < 1.0**: Hospital performs better than expected (fewer readmissions)
- **ERR > 1.0**: Hospital performs worse than expected (more readmissions) → **Penalty territory**

---

## 🎓 Learning Resources

### CMS HRRP Program
- [CMS HRRP Overview](https://www.cms.gov/medicare/payment/prospective-payment-systems/acute-inpatient-pps/hospital-readmissions-reduction-program-hrrp)
- [HRRP Measure Methodology](https://qualitynet.cms.gov/inpatient/measures/readmission/methodology)

### SQL Best Practices
- Normalized schema design
- Foreign key constraints for referential integrity
- Views for reusable business logic
- Indexes for query performance

---

## ✍️ Author

© 2025 Mairilyn Yera Galindo | *Data-Strata Analytics Portfolio*  
SQL Server Database Design | Healthcare Analytics

*Last Updated: March 2026*
