# Excelerate Opportunity Dataset — Data Cleaning & Quality Assessment

## 📌 Project Overview

This project was completed as part of the **Excelerate Data Analytics Internship — Week 1**.

The objective was to explore, assess, clean, document, and validate an Opportunity dataset containing information about internships, courses, careers, competitions, events, and other opportunities.

The project followed a structured data preparation workflow:

**Explore → Assess → Clean → Document → Validate**

The raw dataset contained **5,733 rows and 33 columns**. After cleaning and preparation, the final dataset contained **5,730 rows and 32 columns**.

---

## 🎯 Project Objectives

The project focused on six key deliverables:

1. Explore and understand the dataset
2. Create a data dictionary
3. Assess data quality
4. Clean and prepare the dataset
5. Document the cleaning process
6. Validate the final dataset

---

## 🛠️ Tools & Technologies

* **Python**
* **Pandas**
* **NumPy**
* **Regular Expressions (Regex)**
* Jupyter Notebook
* Data Cleaning
* Data Quality Assessment
* Data Validation
* Feature Engineering

---

## 📊 Dataset Overview

| Metric  |             Raw Dataset |         Cleaned Dataset |
| ------- | ----------------------: | ----------------------: |
| Rows    |                   5,733 |                   5,730 |
| Columns |                      33 |                      32 |
| Grain   | One row per opportunity | One row per opportunity |

The dataset contains information about opportunities such as internships, courses, careers, competitions, and other programs.

---

## 🔍 Data Quality Issues Identified

During the assessment, several data-quality problems were identified.

### 1. Structurally Corrupted Records

Three rows were structurally corrupted because unescaped JSON within `tracking_questions` broke the CSV column alignment. These records were considered unrecoverable and were removed.

### 2. Location Inconsistencies

Different variations such as:

* `virtual`
* `Virtual`
* `vitrual`
* `wfm`
* `WFM`
* `work from home`

were standardized into:

* `Virtual`
* `Work From Home`

A missing-value detection issue involving the value `Null` was also identified and corrected.

### 3. Duration Type Inconsistencies

Seventeen different duration variations were standardized into six consistent units:

* Weeks
* Months
* Days
* Hours
* Minutes
* Years

An ambiguous value (`da`) was resolved using the context of the associated opportunity.

### 4. Role Inconsistencies

The dataset contained **429 unique role values**, including placeholder and test values.

A whitelist approach was used to retain recognized roles such as:

* Manager
* Intern
* Tester
* Developer
* Admin
* Learner
* Student
* Instructor
* Host
* Data Analyst

Unrecognized or obvious junk values were converted to missing rather than being arbitrarily assigned.

### 5. Currency Inconsistencies

`EURO` was standardized to `EUR`, leaving:

* USD
* INR
* EUR

as the valid currency values.

### 6. Incorrect Data Types

Several fields required type conversion:

* Epoch timestamps → datetime
* `fee` → numeric
* `duration` → numeric
* `microscholarship` → numeric
* `is_archived` → Boolean
* `is_auto_approve` → Boolean

An epoch-zero date was treated as missing, and an implausible fee value associated with a testing record was also handled appropriately.

### 7. Text Quality Issues

HTML tags embedded within text fields were removed, and broken apostrophes caused by encoding issues were repaired using a targeted pattern.

### 8. Test/QA Data

The dataset contained **397 records (approximately 6.9%)** identified as likely internal test/QA records.

Rather than automatically deleting these records, an `is_likely_test_data` flag was created so analysts can exclude them when necessary while preserving the original information.

### 9. Nested JSON Fields

Several relationship columns contained raw JSON, including:

* `Badge`
* `CareerAddOn`
* `Cohort`
* `Eligibility`
* `Panellist`
* `Reward`
* `Testimonial`
* `DropoutTransaction`
* `NotStartedTransaction`
* `tracking_questions`

These were transformed into analytical features such as Boolean indicators and count variables. The original JSON relationship data was preserved separately using `opportunity_id` as the key.

### 10. Low-Value Columns

`pk` was removed because it became constant after the corrupted records were removed, while `current_editor` was removed because it was largely missing and represented internal administrative metadata rather than an opportunity attribute.

---

## 🧹 Cleaning & Feature Engineering

The cleaning process included:

* Standardizing categorical values
* Handling missing values
* Converting data types
* Converting timestamps to dates
* Cleaning text fields
* Removing HTML tags
* Repairing encoding issues
* Identifying test/QA records
* Creating Boolean relationship indicators
* Creating relationship count features
* Removing low-value administrative columns
* Preserving original nested JSON data separately

---

## 📖 Data Dictionary

A data dictionary was created for the cleaned dataset.

It documents:

* Column name
* Data type
* Number of missing values
* Missing-value percentage
* Number of unique values
* Example values

The final dataset contains **32 columns**, including standardized opportunity information, dates, costs, descriptions, Boolean indicators, and relationship counts.

---

## ✅ Validation

The final dataset was subjected to **nine automated validation checks**.

The checks confirmed that:

* `opportunity_id` is complete and duplicate-free
* Category values are standardized
* Duration types are standardized
* Currency values are standardized
* `fee` and `duration` have numeric data types
* HTML tags have been removed from description fields
* `is_archived` contains valid Boolean/missing values
* Fully duplicated rows are absent

**All nine validation checks passed.**

---

## 📁 Project Files

```text
Excelerate-Opportunity-Dataset/
│
├── Opportunity_data.ipynb
├── cleaned_opportunity_dataset.csv
├── Opportunity_Dataset_Project_Report.pdf
└── README.md
```

### Files Description

| File                                     | Description                                                    |
| ---------------------------------------- | -------------------------------------------------------------- |
| `Opportunity_data.ipynb`                 | Complete Python/Pandas data-cleaning and validation workflow   |
| `cleaned_opportunity_dataset.csv`        | Final cleaned dataset                                          |
| `Opportunity_Dataset_Project_Report.pdf` | Cleaning documentation, data dictionary, and validation report |
| `README.md`                              | Project documentation                                          |

---

## 💡 Key Learning Outcomes

This project provided practical experience in:

* Data exploration
* Data cleaning with Pandas
* Data quality assessment
* Handling inconsistent categorical data
* Working with dates and timestamps
* Cleaning unstructured text
* Handling nested JSON data
* Feature engineering
* Data validation
* Documenting data-cleaning decisions

A key lesson from the project was that **data cleaning is not simply about deleting bad records**. Cleaning decisions should be based on evidence, context, and the potential impact on downstream analysis.

---

## 👤 Contributor

**Stephen Ejiro Ogbariemu**

Data Analytics | Python | SQL | Excel | Power BI

---

## 🚀 Future Analysis

The cleaned dataset provides a stronger foundation for future analysis, including:

* Opportunity category analysis
* Opportunity duration analysis
* Fee and scholarship analysis
* Location analysis
* Application-deadline analysis
* Opportunity engagement analysis
* Test/QA data exclusion
* Relationship and participation analysis

---

## 📌 Project Status

**Completed — Excelerate Data Analytics Internship, Week 1**
