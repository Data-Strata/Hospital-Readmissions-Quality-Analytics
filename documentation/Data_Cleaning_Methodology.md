# Data Cleaning Methodology

## 📋 Overview

This document details the complete data cleaning and quality assurance process applied to the CMS Hospital Readmissions Reduction Program (HRRP) datasets before importing into SQL Server.

All cleaning was performed in **Microsoft Excel** with a documented **cleaning log** (`cleaning_log.xlsx`) tracking every issue discovered and resolution applied.

---

## 📥 Source Data

### **Dataset 1: Hospital Readmissions Reduction Program (HRRP)**
- **Source:** CMS Hospital Compare - Provider Data Catalog
- **URL:** https://data.cms.gov/provider-data/topics/hospitals
- **File:** Hospital Readmissions Reduction Program.csv
- **Original Rows:** ~18,500 (varies by reporting period)
- **Columns:** 15+ fields including Provider ID, Facility Name, State, Condition, ERR, Volumes, Predicted/Expected Rates

### **Dataset 2: Hospital General Information**
- **Source:** CMS Hospital Compare - Provider Data Catalog
- **URL:** https://data.cms.gov/provider-data/topics/hospitals
- **File:** Hospital General Information.csv
- **Original Rows:** ~5,500 hospitals
- **Columns:** 25+ fields including Provider ID, Facility Name, Address, City, State, ZIP, Ownership, Star Rating, Emergency Services

### **Data Period**
- FY 2023-2024 reporting period
- Last updated: January 2025

---

## 🧹 Cleaning Process Overview

The cleaning process followed a systematic 8-step workflow:

1. **Initial Data Review** — Inspect structure, identify issues
2. **Duplicate Detection** — Check for duplicate provider IDs
3. **Missing Value Analysis** — Identify NULL patterns
4. **Data Type Validation** — Verify numeric/text field consistency
5. **Range Validation** — Check ERR, star ratings, volumes for outliers
6. **Suppression Flag Classification** — Create taxonomy for CMS-suppressed data
7. **Cross-Dataset Validation** — Verify provider IDs match across datasets
8. **Final QA Check** — Document all changes in cleaning log

---

## 🔍 Step-by-Step Cleaning Process

### **Step 1: Initial Data Review**

**Actions:**
1. Open raw CSV files in Excel
2. Convert to Excel tables (Ctrl+T) for easier filtering/sorting
3. Freeze header row (View → Freeze Panes)
4. Apply AutoFilter to all columns
5. Review column headers for consistency
6. Check row count against CMS documentation

**Issues Found:**
- ✅ Column headers consistent with CMS data dictionary
- ✅ No unexpected special characters in headers
- ✅ Row counts aligned with expected values

---

### **Step 2: Duplicate Detection**

**Hospital General Information:**

**Test:**
```excel
= COUNTIF($A:$A, A2) > 1
```
Applied to Provider ID column to flag duplicates.

**Result:** ✅ **0 duplicates found** — Each provider ID appears exactly once

**Hospital Readmissions Data:**

**Expected Behavior:** Each provider can appear **up to 6 times** (once per condition):
- Heart Failure
- Heart Attack
- Pneumonia
- COPD
- Heart Bypass (CABG)
- Hip & Knee Replacement

**Test:**
```excel
= COUNTIFS($A:$A, A2, $D:$D, D2) > 1
```
Tests for duplicates within same Provider ID + Condition combination.

**Result:** ✅ **0 invalid duplicates** — Each provider-condition pair appears exactly once

---

### **Step 3: Missing Value Analysis**

**Hospital General Information:**

| Field | Missing Count | Action Taken |
|-------|---------------|--------------|
| Provider ID | 0 | ✅ No action needed |
| Facility Name | 0 | ✅ No action needed |
| Address | 3 | ✅ Retained (not critical for analysis) |
| City | 0 | ✅ No action needed |
| State | 0 | ✅ No action needed |
| ZIP Code | 12 | ✅ Retained (not critical for analysis) |
| County Name | 47 | ✅ Retained (not critical for analysis) |
| Phone Number | 89 | ✅ Retained (not critical for analysis) |
| Hospital Type | 0 | ✅ No action needed |
| Hospital Ownership | 0 | ✅ No action needed |
| Emergency Services | 24 | ✅ Retained as NULL |
| Hospital Overall Rating | 892 | ✅ Retained as NULL (not all hospitals rated) |

**Hospital Readmissions Data:**

| Field | Missing Count | Pattern Identified |
|-------|---------------|-------------------|
| Provider ID | 0 | ✅ No action needed |
| Facility Name | 0 | ✅ No action needed |
| State | 0 | ✅ No action needed |
| Condition | 0 | ✅ No action needed |
| Number of Discharges | 10,293 | ⚠️ **CMS Suppression Pattern** |
| Number of Readmissions | 10,293 | ⚠️ **CMS Suppression Pattern** |
| Excess Readmission Ratio | 6,610 | ⚠️ **Full Suppression (low volume)** |
| Predicted Readmission Rate | 6,617 | ⚠️ **Suppression + 7 edge cases** |
| Expected Readmission Rate | 6,617 | ⚠️ **Suppression + 7 edge cases** |

**Key Finding:** NULL patterns follow **CMS data suppression methodology** (see Step 6).

---

### **Step 4: Data Type Validation**

**Numeric Fields — Hospital Readmissions:**

**Test for ERR (Excess Readmission Ratio):**
```excel
= ISNUMBER(E2)
```
Applied to all non-NULL ERR values.

**Result:** ✅ All ERR values are valid decimals (e.g., 1.0234, 0.8967)

**Test for Discharge Volumes:**
```excel
= AND(ISNUMBER(F2), F2 >= 0, F2 = INT(F2))
```
Checks: Is number, non-negative, whole integer.

**Result:** ✅ All volume fields are valid whole numbers

**Text Fields:**

**Test for State Codes:**
```excel
= LEN(C2) = 2
```
All state codes should be 2-character abbreviations.

**Result:** ✅ All state codes valid (CA, FL, TX, etc.)

**Test for Facility Names:**
- ✅ No leading/trailing spaces: `=TRIM(B2)=B2`
- ✅ No special characters causing import issues
- ✅ Consistent capitalization (mostly uppercase)

---

### **Step 5: Range Validation**

**Excess Readmission Ratio (ERR):**

**Expected Range:** 0.5 to 2.0 (typical)

**Test:**
```excel
= OR(E2 < 0.5, E2 > 2.0)
```

**Result:** ✅ **1 outlier flagged**
- Provider: 050290 (Saint John's Health Center, CA)
- Condition: Hip & Knee Replacement
- ERR: 0.4698
- Discharges: 1,749
- Readmissions: 31

**Investigation:** 
- Actual readmission rate: 31/1,749 = 1.77%
- ERR = 0.47 means hospital readmits **53% fewer patients than expected**
- **High volume** (1,749 cases) = statistically reliable
- **Conclusion:** ✅ **Legitimate high performer** — NOT a data error

**Star Rating:**

**Expected Range:** 1 to 5 stars

**Test:**
```excel
= OR(StarRating < 1, StarRating > 5)
```

**Result:** ✅ **0 outliers** — All ratings between 1-5

**Discharge Volumes:**

**Test for negative values:**
```excel
= Discharges < 0
```

**Result:** ✅ **0 negative values found**

---

### **Step 6: Suppression Flag Classification**

CMS suppresses data when **patient volume is too low** (<25 cases) to protect patient privacy and ensure statistical reliability.

**Created New Column:** `suppressed_flag`

**Classification Logic:**

```excel
= IF(
    AND(ISBLANK(ERR), ISBLANK(Discharges), ISBLANK(Readmissions)),
    "Full",
    IF(
        AND(ISBLANK(Discharges), ISBLANK(Readmissions), NOT(ISBLANK(ERR))),
        "Partial",
        IF(
            AND(NOT(ISBLANK(Discharges)), NOT(ISBLANK(Readmissions)), NOT(ISBLANK(ERR))),
            "None",
            "Check Manually"
        )
    )
)
```

**Suppression Taxonomy:**

| Flag | Definition | Count | % of Total |
|------|-----------|-------|------------|
| **None** | All data available (ERR, volumes, predicted/expected rates) | 8,037 | 43.85% |
| **Full** | All metrics suppressed (low volume <25 cases) | 6,610 | 36.06% |
| **Partial** | Volumes suppressed, but ERR calculated and valid | 3,683 | 20.09% |
| **Total** | | **18,330** | **100%** |

**Key Insight:**
- **Partial suppression** means CMS calculated ERR from actual data but suppressed volume details
- These 3,683 records are **still usable for quality analysis** even without volume metrics
- **Full suppression** records excluded from penalty rate calculations

---

### **Step 7: Cross-Dataset Validation**

**Test:** Verify all Provider IDs in readmissions data exist in hospital info data.

**SQL-style Check (done manually in Excel):**

```excel
= ISNUMBER(MATCH(A2, HospitalInfo!$A:$A, 0))
```

Applied to readmissions Provider ID column, checking against hospital info table.

**Result:** ✅ **100% match rate** — All 3,055 unique provider IDs in readmissions data found in hospital info

**Test:** Check for orphaned hospitals (in hospital info but not in readmissions).

**Result:** ⚠️ **~2,400 hospitals** in hospital info with no readmission data

**Investigation:**
- Specialty hospitals (rehabilitation, psychiatric, long-term care)
- Critical Access Hospitals (CAHs) — exempt from HRRP
- Hospitals without sufficient volume for any condition
- **Action:** ✅ **Retained in hospital info table** (valid hospitals, just not measured under HRRP)

---

### **Step 8: Final QA Check**

**Validation Summary:**

| Check | Status | Count |
|-------|--------|-------|
| Duplicate provider IDs (hospital info) | ✅ Pass | 0 found |
| Duplicate provider-condition pairs (readmissions) | ✅ Pass | 0 found |
| Missing critical fields (Provider ID, State, Condition) | ✅ Pass | 0 missing |
| Invalid state codes | ✅ Pass | 0 found |
| Negative ERR values | ✅ Pass | 0 found |
| ERR outliers flagged | ✅ Validated | 1 legitimate |
| Star rating out of range (1-5) | ✅ Pass | 0 found |
| Suppression flags assigned | ✅ Complete | 18,330 classified |
| Cross-dataset provider ID match | ✅ Pass | 100% match |

---

## 📊 Cleaning Log Documentation

All 32+ cleaning actions were documented in **`cleaning_log.xlsx`** with the following structure:

| Column | Description |
|--------|-------------|
| **Issue ID** | Unique identifier (001, 002, etc.) |
| **Date Found** | When issue was discovered |
| **Dataset** | Hospital Info or Readmissions |
| **Field** | Column name affected |
| **Issue Description** | Detailed description of problem |
| **Row Count Affected** | How many records |
| **Resolution** | Action taken to resolve |
| **Validation Method** | How fix was verified |
| **Status** | Resolved / Retained / Flagged |

**Sample Entries:**

| ID | Dataset | Field | Issue | Resolution | Status |
|----|---------|-------|-------|------------|--------|
| 001 | Hospital Info | Hospital_Overall_Rating | 892 NULL values | Retained as NULL (valid - not all rated) | ✅ Resolved |
| 002 | Readmissions | Excess_Readmission_Ratio | 6,610 NULL values | Classified as "Full Suppression" | ✅ Resolved |
| 003 | Readmissions | Number_of_Discharges | 10,293 NULL values | Classified as Full/Partial suppression | ✅ Resolved |
| 004 | Readmissions | ERR outlier | 1 value at 0.4698 | Validated as legitimate high performer | ✅ Resolved |

---

## 📁 Output Files

**After Cleaning:**

1. **hospital_info_cleaned.csv** (5,426 rows)
   - Ready for SQL Server import
   - All provider IDs verified unique
   - NULL values documented and retained where appropriate

2. **hospital_readmissions_cleaned.xlsx** (18,330 rows)
   - Includes new `suppressed_flag` column
   - All ERR values validated
   - Ready for SQL Server import

3. **cleaning_log.xlsx** (32+ documented issues)
   - Complete audit trail
   - Validation methods documented
   - Portfolio evidence of QA process

---

## 🔧 Excel Formulas Reference

**Key formulas used during cleaning:**

### **Duplicate Detection:**
```excel
= COUNTIF($A:$A, A2) > 1
```

### **Missing Value Highlighting:**
```excel
= ISBLANK(A2)
```

### **Data Type Check (Numeric):**
```excel
= ISNUMBER(E2)
```

### **Range Validation (ERR):**
```excel
= AND(E2 >= 0.5, E2 <= 2.0)
```

### **Suppression Flag Assignment:**
```excel
= IF(AND(ISBLANK(E2), ISBLANK(F2), ISBLANK(G2)), "Full",
    IF(AND(ISBLANK(F2), ISBLANK(G2), NOT(ISBLANK(E2))), "Partial",
        IF(AND(NOT(ISBLANK(E2)), NOT(ISBLANK(F2))), "None", "Review")
    )
)
```

### **Cross-Dataset Lookup:**
```excel
= ISNUMBER(MATCH(A2, HospitalInfo!$A:$A, 0))
```

### **Trim Whitespace:**
```excel
= TRIM(A2)
```

---

## ⚠️ Known Limitations

1. **Suppressed Data (56% of records):**
   - 36% fully suppressed (no ERR, no volumes)
   - 20% partially suppressed (ERR valid, volumes suppressed)
   - Analysis limited to 11,720 measures with valid ERR

2. **Missing Star Ratings (892 hospitals):**
   - Not all hospitals have overall quality ratings
   - Valid — CMS doesn't rate all facilities

3. **Outlier Handling:**
   - One extreme ERR value (0.4698) validated as legitimate
   - No automated outlier removal — all flagged for manual review

4. **Temporal Limitations:**
   - Data represents single reporting period (FY 2023-2024)
   - No longitudinal trending available

---

## ✅ Quality Assurance Summary

**Final Dataset Quality:**
- ✅ **0 duplicate records**
- ✅ **0 invalid provider IDs**
- ✅ **0 out-of-range values** (after validation)
- ✅ **100% provider ID match** across datasets
- ✅ **32+ documented QA checks** in cleaning log
- ✅ **18,330 suppression flags** correctly classified

**Ready for SQL Import:** Both cleaned datasets passed all validation checks and were successfully imported into SQL Server without errors.

---

## 📚 References

- **CMS Data Dictionary:** https://data.cms.gov/provider-data/sites/default/files/data_dictionaries/hospital/Hospital_Data_Dictionary.pdf
- **HRRP Methodology:** https://qualitynet.cms.gov/inpatient/measures/readmission/methodology
- **CMS Suppression Rules:** Data suppressed when n<25 cases to protect patient privacy

---

© 2025 Mairilyn Yera Galindo | Data-Strata Analytics Portfolio  
*Documented Data Cleaning Process | Healthcare Quality Analytics*
