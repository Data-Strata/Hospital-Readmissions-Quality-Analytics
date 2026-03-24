# 🏥 Hospital Readmissions & Quality Analytics

> **End-to-end healthcare data analytics project using CMS public data — from Excel cleaning to SQL database design to Power BI dashboard storytelling.**

---

**Hospital Readmissions & Quality Analytics** is a full-stack data analytics project demonstrating how to transform raw government healthcare data into strategic provider performance insights.

Using real CMS Hospital Readmissions Reduction Program (HRRP) data, it models a complete healthcare analytics workflow — from documented data cleaning and SQL database design to automated analytical views and interactive Power BI dashboards.

The project applies real-world healthcare BI concepts such as readmission risk analysis, quality measure tracking, provider performance benchmarking, and geographic market analysis.

Each SQL view represents a modular analytical layer, providing transparent, reusable logic that mirrors the work of data analysts at managed care organizations like Molina Healthcare and Garner Health.

The result is a portfolio-ready case study showing how a data analyst can design healthcare reporting systems that support data-driven decisions on provider network selection, quality monitoring, and patient steering strategies.

**Hospital Readmissions Analytics** illustrates not just *how* to build healthcare analytical solutions, but *why* they matter for improving patient outcomes and reducing costs.

---
## 📸 Dashboard Preview

(Screenshots located in /assets/screenshots)
- Executive Overview
- Condition Deep‑Dive
- Geographic Analysis
- Florida Provider Spotlight
- SSRS Provider Detail Report
- SSRS State Summary Report

---
## 💡 Why This Project Matters

Hospital readmissions are one of the most expensive and closely monitored quality metrics in U.S. healthcare.
This project shows how public CMS data can be transformed into actionable insights that help managed care organizations:
- Reduce readmission‑related costs
- Identify high‑value hospitals
- Target high‑risk regions
- Support value‑based contracting
- Improve provider network quality
- Steer members toward better‑performing facilities
It’s a complete, portfolio‑ready demonstration of healthcare analytics strategy and execution.

---
## 🌟 Project Overview

This project demonstrates how to design an **end-to-end healthcare analytics pipeline**:
1. **Data cleaning & QA documentation** in Excel with complete validation log
2. **Relational database design** in SQL Server with normalized schema
3. **Automated analytical view layer** for hospital quality KPIs
4. **Interactive Power BI dashboards** for managed care stakeholders

All data sourced from public CMS datasets, processed through documented cleaning procedures, modeled in SQL, and visualized in Power BI.

---

## 🛠️ Tech Stack

| Layer | Tools & Technologies |
|-------|----------------------|
| **Data Cleaning** | Microsoft Excel / Google Sheets |
| **Database** | Microsoft SQL Server 2019+ |
| **Data Transformation** | SQL Views & Aggregations |
| **Reporting** | SQL Server Reporting Services (SSRS) / Report Builder |
| **Visualization** | Power BI Desktop |
| **Data Sources** | CMS Hospital Readmissions Reduction Program (HRRP), CMS Hospital General Information |
| **Documentation** | Excel QA Logs, Word Implementation Guides |
| **Version Control** | Git + GitHub |

---

## 🎯 Project Objectives

- Identify **high-performing and high-risk hospitals** by readmission rates
- Monitor **excess readmission ratios (ERR)** across six HRRP clinical conditions
- Analyze **geographic variation** in hospital quality performance
- Track **CMS penalty exposure** by provider and state
- Compare **Florida vs National performance**
- Evaluate **Regional variation within Florida**
- Generate **Florida-specific provider recommendations** for managed care networks
- Demonstrate a **complete healthcare analytics workflow**

---

## 📊 Data Source & Scope

### Primary Dataset: CMS Hospital Readmissions Reduction Program (HRRP)
- **Source**: [data.cms.gov/provider-data/dataset/9n3s-kdb3](https://data.cms.gov/provider-data/dataset/9n3s-kdb3)
- **Scope**: ~18,330 records covering 3,055 Acute Care Hospitals
- **Conditions Tracked**: Heart Failure, Heart Attack, Pneumonia, COPD, Hip/Knee Replacement, CABG

### Secondary Dataset: CMS Hospital General Information
- **Source**: [data.cms.gov/provider-data/dataset/xubh-q36u](https://data.cms.gov/provider-data/dataset/xubh-q36u)
- **Scope**: 5,426 hospitals with facility details, star ratings, and quality measure counts

### Data Characteristics
- **Performance Period**: 2021-2024 (varies by dataset version)
- **Suppression Handling**: CMS suppresses data for low-volume cases (<25 discharges)
- **Penalty Threshold**: ERR > 1.0 indicates hospital readmits more than expected

---

## 📈 Key Performance Indicators (KPIs)

| Category | KPI |
|-----------|-----|
| **Readmission Performance** | Excess Readmission Ratio (ERR), Predicted vs Expected Rates, Performance Tier Distribution |
| **Volume Metrics** | Total Discharges, Total Readmissions, Hospitals Analyzed per Condition |
| **Penalty Exposure** | % Hospitals Penalized (ERR > 1.0), Total Penalty Count by State |
| **Quality Ratings** | Star Rating Distribution, Correlation between ERR and Star Ratings |
| **Geographic Analysis** | Average ERR by State, Regional Performance Comparisons, Florida vs National |

---

## 📊 Power BI Dashboard Pages

| Page | Focus |
|------|--------|
| **1. Executive Overview** | National KPIs, penalty rates, performance tier distribution, worst-performing states |
| **2. Condition Deep-Dive** | Condition-specific ERR analysis, scatter plots (volume vs performance), hospital rankings |
| **3. Geographic Analysis** | State-level ERR heatmap, regional comparisons, condition breakdown by state |
| **4. Florida Provider Spotlight** | FL hospital rankings, South Florida analysis, national comparisons, bookmark to recommendations|
| **5. Data Quality & Methodology** | Cleaning log summary, suppression handling, data sources, ERR definitions |
| **6. Florida Provider Recommendation Bookmark** | Data-driven recommondations for providers, value-based contracting recommendation matrix |

---

## 🧩 Database Architecture

The SQL Server database is organized into two layers:

### Core Tables (2)
1. **hospitals** — 5,426 rows | One row per hospital facility
   - Primary key: `provider_id` (6-digit CMS facility ID)
   - Contains: Facility details, location, ownership, star ratings, quality measure counts

2. **readmission_measures** — 18,330 rows | One row per hospital-condition
   - Composite key: `provider_id` + `condition_short`
   - Contains: ERR scores, volume metrics, performance tiers, suppression flags
   - Foreign key to `hospitals` table

### Analytical Views (4)
1. **vw_condition_summary** — 6 rows (one per condition)
   - Aggregates: National performance, penalty rates, tier distributions
   - Powers: Overview page, Condition Deep-Dive page

2. **vw_state_performance** — 56 rows (one per state/territory)
   - Aggregates: State-level ERR averages, penalty rates, star ratings
   - Powers: Geographic Analysis page

3. **vw_top_bottom_performers** — 11,720 rows (non-suppressed measures)
   - Includes: Rankings per condition, top/bottom 20 flags
   - Powers: Condition Deep-Dive rankings, provider comparison tables

4. **vw_florida_hospitals** — 771 rows (FL hospital count)
   - Includes: FL rankings, national comparisons, South Florida regional flag
   - Powers: Florida Provider Spotlight page (strategic for Molina Healthcare)

---

## 📄 SSRS Paginated Reports

In addition to Power BI dashboards, this project includes **SQL Server Reporting Services (SSRS)** paginated reports built with Report Builder — demonstrating enterprise healthcare reporting capabilities.

### Report 1: Hospital Readmissions — Provider Detail Report
**Purpose:** Detailed provider-level readmission performance with state filtering

**Features:**
- **Parameter-driven filtering** — State dropdown with Florida default
- **Conditional formatting** — ERR > 1.0 highlighted in red (penalty threshold)
- **Grouped layout** — Organized by state with subtotals
- **Professional formatting** — Landscape Letter-size, ready for print/PDF export

**Use Case:** Managed care provider directories, network performance monitoring, provider steering decisions

**Output:** `Hospital_Readmissions_Detail_FL.pdf` (31 pages of FL hospital data)

---

### Report 2: Hospital Readmissions — State Summary Report  
**Purpose:** State-level aggregate performance across all six clinical conditions

**Features:**
- **Aggregated metrics** — Hospital counts, Avg ERR, Best/Worst ERR, Hospitals Penalized per condition
- **Embedded visualization** — Bar chart showing penalized hospitals by condition
- **State parameter** — Dynamic filtering with Florida default
- **Conditional formatting** — Avg ERR > 1.0 flagged

**Use Case:** State market analysis, condition-specific quality benchmarking, executive summaries

**Output:** Interactive SSRS report with table + chart

---

## 📁 Repository Structure

```text
Hospital-Readmissions-Analytics/
│
├── README.md                          # Root README (project overview, insights, KPIs)
├── LICENSE                            # MIT license
│
├── data/
│   ├── raw/                           # Links to CMS public datasets
│   │   └── README.md                  # Download instructions, data sources
│   ├── cleaned/
│   │   ├── hospital_info_cleaned.csv
│   │   ├── hospital_readmissions_cleaned.xlsx
│   │   └── cleaning_log.xlsx          # Complete QA documentation
│   └── README.md                      # Data dictionary, cleaning methodology
│
├── SQL/
│   ├── schema/
│   │   └── 01_create_database_and_tables.sql    # Database + 2 tables
│   ├── views/
│   │   └── 02_create_analytical_views.sql       # 4 analytical views
│   ├── validation/
│   │   └── 03_validation_and_testing.sql        # Complete validation suite
│   └── README.md                                # SQL documentation, ERD, view purposes
│
├── SSRS/
│   ├── Hospital_Readmissions_Detail.rdl         # Provider detail report
│   ├── Hospital_Readmissions_State_Summary.rdl  # State summary report
│   └── outputs/
│       ├── Hospital_Readmissions_Detail_FL.pdf  # Sample FL provider report
│       └── State_Summary_FL_Screenshot.png      # Report preview
│
├── PowerBI/
│   └── Hospital_Readmissions_Dashboard.pbix     # Final Power BI file (6 pages)
│
├── documentation/
│   ├── SQL_Implementation_Guide.docx            # Step-by-step setup instructions
│   ├── Data_Cleaning_Methodology.md             # Excel cleaning process
│   └── Project_ROADMAP.md                       # Complete project roadmap
│
├── assets/
│   └── screenshots/                   # Dashboard previews for GitHub
│       ├── overview_page.png
│       ├── condition_deepdive.png
│       ├── geographic_analysis.png
│       ├── geographic_analysis_statespotlight.png
│       ├── florida_spotlight.png
│       ├── fl_provider_recommendations.png
│       ├── qa_methodology.png
│       ├── data_model_diagram.png
│       ├── ssrs_detail_report.png      # SSRS Provider Detail Report
│       └── ssrs_state_summary.png      # SSRS State Summary Report
│
└── .gitignore                         # Ignores temp files, local configs

```

---

## ⚙️ Quick Start

### Prerequisites
- SQL Server 2019+ (Express Edition works)
- SQL Server Management Studio (SSMS)
- SQL Server Report Builder (free download from Microsoft)
- Power BI Desktop
- Microsoft Excel / Google Sheets

### Setup Instructions

1. **Download CMS data**
   - See `data/raw/README.md` for source URLs
   - Download both CSVs to `data/raw/` folder

2. **Clean the data**
   - Follow cleaning methodology in `data/README.md`
   - Document all cleaning steps in `cleaning_log.xlsx`
   - Output: `hospital_info_cleaned.csv` and `hospital_readmissions_cleaned.xlsx`

3. **Build SQL database**
   ```sql
   -- Create database and tables
   :r .\SQL\schema\01_create_database_and_tables.sql
   
   -- Import data using SSMS Import Wizard (see SQL/README.md)
   
   -- Create analytical views
   :r .\SQL\views\02_create_analytical_views.sql
   
   -- Validate everything
   :r .\SQL\validation\03_validation_and_testing.sql
   ```

4. **Build SSRS Reports (Optional)**
   - Open Report Builder and connect to HospitalReadmissions database
   - Create provider detail report with state parameter and conditional formatting
   - Create state summary report with aggregated metrics and embedded chart
   - Export sample PDFs for portfolio

5. **Connect Power BI**
   - Open `PowerBI/Hospital_Readmissions_Dashboard.pbix`
   - Refresh data connections (point to your SQL Server instance)
   - Import all 4 views (not raw tables)

6. **Explore dashboards**
   - Navigate through 5 pages for national trends, condition analysis, geographic patterns, Florida insights, and QA documentation

---

## 🧱 Data Model (Simplified)

```
CMS HRRP Data ──┬──> hospitals (5,426 rows)
                │     └──> vw_state_performance
                │     └──> vw_florida_hospitals
                │
                └──> readmission_measures (18,330 rows)
                      ├──> vw_condition_summary
                      ├──> vw_top_bottom_performers
                      └──> (joins to hospitals via provider_id)
```

---

## 🧩 Key Features

- **Healthcare Domain Expertise** — Real CMS data, HRRP program knowledge, ERR calculations
- **Documented Data Cleaning** — 32+ cleaning issues logged with row counts and actions taken
- **Normalized Database Design** — Proper foreign keys, indexes, performance optimization
- **Modular SQL Views** — Each view serves specific business questions
- **Strategic Geographic Analysis** — Florida-focused view aligns with Molina Healthcare's market presence
- **Complete QA Documentation** — Validation suite proves data integrity and proper handling of suppressed values
- **Portfolio-Ready** — Professional documentation, clean code, business context

---

## 🔍 Insights & Findings

After building and analyzing the complete dashboard pipeline, several key healthcare insights emerged from the CMS HRRP dataset:

### 🏥 National Readmission Performance Patterns

**Penalty Exposure Analysis:**
- **48.15%** of hospital-condition measures exceed the CMS penalty threshold (ERR > 1.0), representing 5,643 penalized measures out of 11,720 total measures with valid ERR data
- National average ERR of **1.002** indicates hospitals collectively readmit **0.2% more patients than expected** after risk adjustment
- This "just above threshold" national average masks significant variation across conditions and individual facilities

**Quality Distribution:**
- Only **4.8%** of measures achieve Top Performer status (ERR < 0.90), highlighting the rarity of exceptional readmission prevention
- The concentration of hospitals near ERR = 1.0 suggests many facilities are performing at the national benchmark without significant differentiation
- Wide performance variance within conditions creates clear opportunities for managed care network optimization

**Condition-Specific Patterns:**
- Performance varies significantly across the six measured conditions (Heart Failure, Heart Attack, Pneumonia, COPD, Heart Bypass, Hip & Knee Replacement)
- Medical conditions (Heart Failure, COPD) tend to show higher average ERR values compared to surgical procedures
- Surgical procedures demonstrate tighter ERR clustering, suggesting more standardized care protocols

### 📍 Geographic & Market Variation

**State-Level Performance:**
- Clear geographic clustering of high-performing and high-risk states visible in filled map analysis
- Regional variations suggest differences in care delivery models, population health status, and Medicaid expansion impact
- Some states show consistently better performance across all conditions, indicating systemic quality infrastructure

**Florida Market Deep-Dive:**
- South Florida regions (Miami-Dade, Broward, Palm Beach) show mixed performance across conditions
- Clear stratification exists between Top Performer facilities and High Risk facilities within the same geographic market
- Regional analysis enables targeted provider network development for managed care organizations operating in Florida (e.g., Molina Healthcare's FL market presence)


### 📊 Data Quality & Suppression Patterns

**Suppression Distribution (Critical for Analysis Scope):**
- **43.85%** of measures (8,037 records) have complete data with no suppression
- **36.06%** fully suppressed (6,610 records) due to low patient volume
- **20.09%** partially suppressed (3,683 records) — volumes suppressed but ERR remains valid for analysis

**Analytical Implications:**
- Analysis based on 11,720 hospital-condition measures with valid ERR (64% of total dataset)
- Suppressed data disproportionately affects rural hospitals and specialized facilities with lower case volumes
- Partial suppression records still contribute to performance tier classification despite missing volume metrics

**Data Quality Validation:**
- One statistical outlier identified: Saint John's Health Center (CA) with ERR = 0.4698 for Hip & Knee Replacement across 1,749 discharges
- Verified as legitimate high performer (53% reduction in readmissions vs. expected) — not a data quality issue
- Zero duplicate provider IDs, zero invalid state codes, zero negative ERR values after cleaning

---

## 💼 Business Impact & Strategic Recommendations

### For Managed Care Organizations (Molina Healthcare, Garner Health)

**Network Optimization Strategy:**
- **Provider Tiering:** Use the 48.15% penalty rate as baseline to identify improvement opportunities — steer members toward the 4.8% of Top Performer facilities
- **Quality Scorecards:** Combine ERR performance with star ratings and ownership type from `vw_top_bottom_performers` to build comprehensive provider assessment tools
- **Centers of Excellence:** Partner with hospitals achieving ERR < 0.90 to develop condition-specific referral networks

**Risk-Based Contracting:**
- **Value-Based Payments:** Structure incentive programs rewarding hospitals that achieve ERR < 0.95 (better than national average of 1.002)
- **Penalty Mitigation:** Flag High Risk facilities (ERR > 1.10) for enhanced care coordination and discharge planning support to reduce readmission exposure
- **Performance Monitoring:** Use quarterly ERR trends to adjust network participation and reimbursement tiers

**Geographic Market Strategy:**
- **Florida Market Focus:** Leverage `vw_florida_hospitals` to identify high-quality, cost-effective providers in South Florida (Miami-Dade, Broward, Palm Beach) where Molina has significant membership
- **State Expansion Planning:** Compare state-level performance using `vw_state_performance` to guide market entry decisions and competitive positioning
- **Regional Network Development:** Build differentiated networks in states with wide ERR variance to capture quality-conscious membership

**Condition-Specific Programs:**
- **Resource Allocation:** Focus care management on conditions with highest ERR variance (Heart Failure, COPD, Pneumonia) where coaching interventions can reduce readmissions
- **Transitional Care:** Deploy pharmacy and nursing support for members discharged from High Risk facilities to mitigate elevated readmission probability
- **Preventive Outreach:** Target pre-admission interventions for members scheduled for elective procedures at facilities with ERR > 1.0

**Florida‑Specific Provider Recommendations (Data‑driven, based on ERR, tiers, and regional variation):**<br>
**Top Performers (Tier 1 Candidates)**<br>
- Sarasota Memorial Hospital — ERR 0.74 (CABG), 5 stars
- Holmes Regional Medical Center — ERR 0.82 (Pneumonia)<br>
**High‑ERR Regions (Target for Care Coordination)**<br>
- Palm Beach — ERR 1.0601
- Orlando Metro — ERR 1.0483
- Tampa Bay — ERR 1.0454<br>
**Lower‑ERR Regions (Network Expansion)**<br>
- Broward — ERR 1.0391
- Panhandle — ERR 1.0283<br>
**High‑Penalty Hospitals (ERR > 1.0)**<br>
**Target for quality improvement contracting**

**Member Communication & Transparency:**
- Translate ERR metrics into consumer-friendly language for provider directories and decision-support tools
- Highlight performance differences to educate members on choosing high-quality facilities

**Quality Monitoring:**
- Implement quarterly ERR trend monitoring using the analytical views
- Set up automated alerts for provider performance changes or new penalty exposures

> 🔸 *This analytical framework demonstrates how public CMS data can be transformed into actionable managed care intelligence — empowering health plans to build higher-quality networks, reduce costs, and improve member outcomes.*

---

## 🚀 Next Steps / Future Enhancements

While the current version provides a complete, functional healthcare analytics workflow, several improvements could extend its capabilities:

- **Longitudinal Trending** — Add historical HRRP data from prior years to track hospital performance trajectories
- **Predictive Modeling** — Integrate Python/R models to forecast which hospitals are at risk of penalty increases
- **Cost Integration** — Join with CMS payment data to analyze cost-quality tradeoffs (high ERR + high cost = avoid)
- **Patient Safety Integration** — Combine with CMS Hospital-Acquired Condition (HAC) data for comprehensive quality scoring
- **Automated Refresh Pipeline** — Schedule monthly data refreshes via SQL Server Agent or Power BI Service
- **API Integration** — Connect to live CMS APIs for real-time updates as new data becomes available

> *Each enhancement builds on the existing SQL + Power BI foundation, strengthening automation, predictive capability, and strategic decision-making.*

---

## 📚 What This Project Demonstrates

### 🧠 Skills Demonstrated
✅**Technical**
- SQL Server (schema, views, validation)
- Power BI (DAX, modeling, storytelling)
- SSRS (parameters, conditional formatting)
- Data cleaning & QA
- Git + GitHub
✅**Healthcare Domain**
- HRRP program
- ERR methodology
- Penalty thresholds
- Star ratings
- Managed care network strategy
✅**Business & Strategy**
- Provider tiering
- Value‑based contracting
- Geographic market analysis
- Network optimization
- Executive storytelling


### Portfolio Differentiators
- **Real government data** (not mock/simulated)
- **Complete documentation** (cleaning log, implementation guide, validation suite)
- **Business context** (managed care use case, strategic recommendations)
- **Healthcare expertise** (HRRP program, ERR calculations, quality measures)
- **Professional presentation** (clean code, modular design, reproducible workflow)

---

## 🧾 License

This project is licensed under the [MIT License](LICENSE).

---

## ✍️ Author

© 2025 Mairilyn Yera Galindo | *Data-Strata Analytics Portfolio*  
Healthcare Data Analytics | SQL Server + Power BI + Excel  
🏖️ Boca Raton, FL  
🌐 [https://github.com/Data-Strata](https://github.com/Data-Strata)

---

## 📞 Contact & Feedback

Interested in discussing this project or healthcare analytics?  
📧 [mairilynyera@gmail.com]  
💼 [LinkedIn Profilewww.linkedin.com/in/mairilyn-yera-galindo-07a93932]  
📁 [Additional Portfolio Projects](https://github.com/Data-Strata)

---

*Built with SQL Server, Power BI, and Excel | CMS Public Data | March 2025*
