# SSRS Paginated Reports

## 📄 Overview

This folder contains **SQL Server Reporting Services (SSRS)** paginated reports built with **Report Builder** — demonstrating enterprise healthcare reporting capabilities beyond Power BI dashboards.

Both reports connect directly to the `HospitalReadmissions` SQL Server database and use the analytical views created in the SQL phase.

---

## 📊 Reports Included

### 1. Hospital_Readmissions_Detail.rdl
**Provider Detail Report — State-Filtered Hospital Performance**

**Purpose:**  
Detailed, print-ready report showing every hospital's readmission performance by condition for a selected state.

**Features:**
- **State Parameter** — Dropdown selection with Florida as default
- **Conditional Formatting** — ERR > 1.0 (penalty threshold) highlighted in dark red text with light red background
- **Grouped Layout** — Organized by state with bold, italic subtotals
- **Professional Formatting** — Landscape Letter-size (8.5" × 11"), optimized for print or PDF export

**Data Source:**  
Direct SQL query joining `hospitals` and `readmission_measures` tables

**Key Fields:**
- State
- Facility Name
- City
- Condition (Heart Failure, Heart Attack, Pneumonia, COPD, Hip & Knee Replacement, Heart Bypass)
- Excess Readmission Ratio (ERR)
- Performance Tier

**Use Cases:**
- Managed care provider directories
- Network performance monitoring
- Provider steering decisions
- Member communication materials

**Sample Output:**  
`outputs/Hospital_Readmissions_Detail_FL.pdf` — 26-page report showing all Florida hospitals

---

### 2. Hospital_Readmissions_State_Summary.rdl
**State Summary Report — Aggregate Performance with Embedded Chart**

**Purpose:**  
Executive summary showing state-level aggregate readmission performance across all six clinical conditions.

**Features:**
- **Aggregated Metrics Table**:
  - Hospital Count per condition
  - Average ERR
  - Best ERR (lowest in state)
  - Worst ERR (highest in state)
  - Hospitals Penalized count (ERR > 1.0)
- **Embedded Bar Chart** — Hospitals Penalized by Condition (visual complement to table)
- **State Parameter** — Dynamic filtering with Florida default
- **Conditional Formatting** — Avg ERR > 1.0 flagged with color

**Data Source:**  
SQL query with aggregations (AVG, MIN, MAX, COUNT) from `readmission_measures` joined to `hospitals`

**Key Aggregations:**
```sql
COUNT(DISTINCT provider_id) AS Hospital_Count
AVG(excess_readmission_ratio) AS AVG_ERR
MIN(excess_readmission_ratio) AS Best_ERR
MAX(excess_readmission_ratio) AS Worst_ERR
COUNT(CASE WHEN excess_readmission_ratio > 1.0 THEN 1 END) AS Hospitals_Penalized
```

**Use Cases:**
- State market analysis
- Condition-specific quality benchmarking
- Executive summaries for leadership
- Competitive market positioning

**Sample Output:**  
`outputs/State_Summary_FL_Screenshot.png` — Shows Florida summary table + chart

---

## 🛠️ How to Use These Reports

### Prerequisites
- SQL Server Report Builder installed (free download from Microsoft)
- Access to the `HospitalReadmissions` SQL Server database
- Both base tables (`hospitals`, `readmission_measures`) populated with data

### Opening Reports

1. **Launch Report Builder**
2. **File → Open**
3. **Navigate to** `SSRS/` folder
4. **Select** either `.rdl` file

### Running Reports

1. **Connect to Data Source**
   - Report Builder will prompt for SQL Server instance
   - Database: `HospitalReadmissions`
   - Authentication: Windows Authentication (or SQL Server auth if configured)

2. **Select State Parameter**
   - Default: FL (Florida)
   - Dropdown includes all 50+ states/territories

3. **Run Report**
   - Click **Run** button in toolbar
   - Report renders with selected state data

4. **Export Options**
   - **PDF** — Print-ready paginated format (recommended for stakeholder distribution)
   - **Excel** — Tabular export for further analysis
   - **Word** — Editable document format

---

## 🎨 Report Design Details

### Report 1: Provider Detail

**Layout:**
- **Page Size:** Letter (8.5" × 11")
- **Orientation:** Landscape
- **Margins:** 0.5" all sides
- **Font:** Arial, 10pt body text, 12pt headers

**Data Regions:**
- **Tablix** (table) with grouping on State
- **Text boxes** for report title and parameter display

**Expressions:**
- Conditional formatting: `=IIf(Fields!Excess_Readmission_Ratio.Value > 1.0, "DarkRed", "Black")`
- Background color: `=IIf(Fields!Excess_Readmission_Ratio.Value > 1.0, "MistyRose", "White")`

**Parameters:**
- `@State` — Text, Available Values populated from query, Default = "FL"

---

### Report 2: State Summary

**Layout:**
- **Page Size:** Letter (8.5" × 11")
- **Orientation:** Portrait
- **Margins:** 1" all sides
- **Font:** Arial, 11pt body text, 14pt headers

**Data Regions:**
- **Tablix** (summary table) with condition rows
- **Chart** (clustered bar) — Hospitals Penalized by Condition
- **Total row** at bottom with aggregates across all conditions

**Chart Properties:**
- **Chart Type:** Clustered Bar
- **Category Axis:** Condition
- **Value Axis:** Hospitals Penalized
- **Data Label:** Show values
- **Color:** Single color (dark blue)

**Expressions:**
- AVG ERR formatting: `=Format(Fields!AVG_ERR.Value, "N4")` (4 decimal places)
- Conditional color: `=IIf(Fields!AVG_ERR.Value > 1.0, "Salmon", "White")`

**Parameters:**
- `@State` — Text, Available Values from query, Default = "FL"

---

## 📈 Business Value

### Why SSRS for Healthcare Reporting?

**Print/PDF Distribution**  
Unlike interactive dashboards, SSRS reports are **paginated** — designed for printing and PDF export. Critical for:
- Board presentations
- Regulatory submissions
- Provider performance letters
- Executive summaries

**Parameter-Driven Filtering**  
Healthcare stakeholders need **consistent report formats** with **dynamic data**. SSRS parameters allow:
- State health departments to pull their own state data
- Managed care organizations to generate provider-specific reports
- Executives to request condition-specific summaries on demand

**Embedded in Applications**  
SSRS reports can be:
- Embedded in internal portals
- Automatically emailed on schedules
- Integrated into .NET applications
- Accessed via web URLs

---

## 🎓 **Skills Demonstrated**

**Technical:**

✅ Report Builder proficiency  
✅ Parameter design and default values  
✅ Conditional formatting with business rules  
✅ Tablix grouping and subtotals  
✅ Embedded chart integration  
✅ Professional page layout design  
✅ PDF export optimization  

**Healthcare Domain:**

✅ ERR penalty threshold (1.0) business rule  
✅ State-level market analysis  
✅ Condition-specific performance tracking  
✅ Provider quality reporting  

---

## 🔧 Troubleshooting

**Report won't connect to database:**
- Verify SQL Server instance name in data source properties
- Check Windows Authentication vs SQL Server Authentication
- Ensure `HospitalReadmissions` database exists

**Parameter dropdown is empty:**
- Verify the data source query is executing
- Check that `hospitals` table contains state data
- Refresh parameter available values (right-click parameter → Report Parameter Properties → Available Values)

**Conditional formatting not working:**
- Verify ERR field is numeric (not text)
- Check expression syntax in Tablix cell properties
- Ensure field name matches exactly (case-sensitive)

**PDF export cuts off data:**
- Check page size settings (File → Page Setup)
- Verify Tablix width fits within page margins
- Adjust column widths if needed

---

## 📁 Folder Contents

```
SSRS/
├── README.md                                    # This file
├── Hospital_Readmissions_Detail.rdl             # Provider detail report
├── Hospital_Readmissions_State_Summary.rdl      # State summary report
└── outputs/
    ├── Hospital_Readmissions_Detail_FL.pdf      # Sample FL provider report (26 pages)
    └── State_Summary_FL_Screenshot.png          # Report preview screenshot
```

---

## 🚀 Next Steps

### Enhancements to Consider

**Short-Term:**
- Add more parameters (Condition filter, Performance Tier filter)
- Create drill-through from summary to detail report
- Add year parameter for historical trending

**Medium-Term:**
- Deploy reports to SSRS Server for web access
- Set up subscriptions for automated email delivery
- Create mobile-optimized report versions

**Long-Term:**
- Build complete report library (10+ reports covering all CMS quality measures)
- Integrate with web portal for self-service access
- Add multi-language support for Spanish-speaking stakeholders

---

## ✍️ Author

© 2025 Mairilyn Yera Galindo | *Data-Strata Analytics Portfolio*  
SSRS Paginated Reports | Healthcare Quality Analytics

*Built with SQL Server Report Builder | CMS Public Data | March 2025*
