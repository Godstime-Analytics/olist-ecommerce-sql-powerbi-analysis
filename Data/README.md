## Data Description

This project uses the Olist E-commerce dataset from Kaggle.

Due to GitHub file size limitations, the datasets used in this project are hosted externally:

🔗 **Download Datasets:**  
https://drive.google.com/drive/folders/1pe4aJIW2PIVFIcQNYGXlp33vp_SfP-wn

---

## Datasets Used

- **Olist Master Dataset**  
  A processed dataset created in PostgreSQL by joining multiple tables.  
  This serves as the primary dataset for analysis.

- **Olist Geolocation Dataset**  
  Contains location-related information such as customer state and coordinates.  
  Used for regional and geographic analysis.

---

## Data Preparation

- Data was cleaned and transformed using SQL (PostgreSQL)
- Multiple tables were combined into a master dataset
- Duplicate checks were performed to ensure data quality

---

## Why Geolocation Was Handled Separately

The geolocation dataset was not merged into the master dataset in SQL.  
Instead, it was loaded separately into Power BI to:

- Enable accurate **regional analysis**
- Avoid unnecessary duplication in the main dataset
- Support better relationship modeling in Power BI

---

## Data Model Overview

The Power BI model includes:

- **Master Dataset (Fact Table)**  
- **Geolocation Dataset (Dimension Table)**  
- **Date Table (Created in Power BI)**  

---

## Original Dataset

Kaggle Source:  
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
