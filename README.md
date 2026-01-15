# Laptop Market Analysis: MySQL Cleaning & Exploratory Data Analysis (EDA)

## 📌 Project Overview
This project demonstrates a professional-grade SQL workflow for processing and analyzing a raw dataset of laptop specifications. Using **MySQL**, I transformed "dirty" unstructured text into a clean, relational format and performed deep statistical analysis to uncover market trends and hardware correlations.

## 🛠️ Tech Stack
*   **Database:** MySQL 8.0+
*   **Techniques:** Data Staging, Window Functions (CTEs), Statistical Modeling, Regex Pattern Matching, Feature Engineering.

---

## 🧹 Phase 1: Data Cleaning & Staging
To ensure data integrity, I utilized a **Staging Strategy**, creating temporary tables to perform destructive operations safely.

### 1. Data Standardisation
*   **RAM & Weight:** Cleaned unit markers ("GB", "kg") and used `REGEXP` to handle non-numeric noise before casting to `INT` and `FLOAT`.
*   **Price:** Rounded and converted to `INT` for better storage efficiency.
*   **Operating Systems:** Normalized fragmented categories (e.g., merging various Windows versions into a single "Windows" label).

### 2. Advanced Feature Decomposition
I extracted granular data from complex string columns:
*   **CPU/GPU:** Separated Brand, Model Name, and Speed (GHz) using `SUBSTRING_INDEX` and nested `REPLACE`.
*   **Screen Resolution:** Decomposed into `ResolutionWidth`, `ResolutionHeight`, and a binary `Touchscreen` flag.
*   **Storage:** Created a logic-based architecture to identify `Memory_type` and split capacities into `Primary_storage` and `Secondary_storage` (with TB to GB conversion).

---

## 📊 Phase 2: Exploratory Data Analysis (EDA)
In this phase, I treated MySQL as a statistical tool to perform univariate and bivariate analysis.

### 1. Univariate Statistical Analysis
*   **8-Number Summary:** Calculated the Count, Min, Max, Mean, StdDev, and Quartiles (Q1, Median, Q3) for the `Price` column using `ROW_NUMBER()` and `PERCENTILE` logic.
*   **Outlier Detection:** Implemented an **Interquartile Range (IQR)** formula to identify price points that fall outside the typical market range.
*   **Data Distribution:** Created a **Vertical Histogram** directly in the SQL console using the `REPEAT()` function to visualize price density across buckets.

### 2. Bivariate Analysis & Correlation
*   **Pearson Correlation Coefficient:** Manually calculated the correlation between `cpu_speed` and `Price` using a mathematical formula within SQL.
*   **Contingency Tables:** Used `CASE` statements with `SUM()` to analyze the relationship between `Company` and hardware features like `Touchscreen` or `CPU_brand`.
*   **Category Benchmarking:** Aggregated min, max, and average prices per brand to identify market positioning (Luxury vs. Budget).

---

## 🏗️ Phase 3: Advanced Feature Engineering
To make the data "Machine Learning ready," I engineered new analytical features:
*   **PPI (Pixels Per Inch):** Created a calculation using the Pythagorean theorem: `SQRT(Width² + Height²) / Inches`.
*   **Screen Size Categorization:** Binned screen sizes into `Small`, `Medium`, and `Large` based on physical dimensions.
*   **One-Hot Encoding:** Demonstrated the conversion of categorical `gpu_brand` into binary numerical columns (Intel, AMD, Nvidia, Arm) within SQL.

---

## 🚀 Key Insights
1.  **Price Distribution:** Found a wide variance in pricing ($9,271 to $324,955) with a median of $52,694.
2.  **Hardware Trends:** Successfully mapped how CPU speed correlates with price, providing a clear ROI analysis for hardware upgrades.
3.  **Clean Architecture:** Removed all nulls and duplicates, ensuring the dataset is 100% reliable for visualization tools like Power BI or Tableau.

---
*Developed by Aditya Kumar 
