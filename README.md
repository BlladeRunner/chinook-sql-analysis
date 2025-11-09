# 🎵 Chinook Music Store Analytics (SQLite + SQL)

## 📊 Project Overview
SQL portfolio project based on the classic **Chinook** dataset (albums, artists, tracks, customers, invoices).  
The goal is to analyze **music sales performance**, **customer behavior**, and **employee productivity** using SQL.  
Key business questions:
- What are the monthly revenue trends?
- Who are the top customers and employees?
- Which genres and artists generate the most sales?
- What are the cohort and RFM segmentation patterns?

---

## 🧱 Dataset
- **Database:** `chinook.db` (SQLite version of Chinook)  
- **Helper View:** `v_invoice_detail` (created via `bootstrap_chinook.sql`)  
- **Key Tables:**  
  `invoices`, `invoice_items`, `customers`, `employees`, `tracks`, `albums`, `artists`, `genres`, `media_types`

---

## ⚙️ How to Reproduce
```bash
# 1️⃣ Place 'chinook.db' in the project folder

# 2️⃣ Build the helper view (required for queries)
sqlite3 chinook.db ".read bootstrap_chinook.sql"

# 3️⃣ Run analysis queries
# Open queries.sql in VS Code (SQLTools) → select query → Ctrl+E, Ctrl+E
```

## 🧮 Analysis Highlights
The analysis includes:
- 💰 Monthly revenue and MoM (Month-over-Month) growth.
- 🎧 Top customers by total purchases and revenue.
- 🎵 Genre and artist performance by total sales.
- 👨‍💼 Employee productivity and support rep metrics.
- 🧺 Market basket analysis (track pair sales).
- 📈 Cohorts and RFM segmentation.

## 🧠 Key Insights
- Rock and Latin genres dominate total sales (~45% combined).
- Customers from the USA and Germany generate the highest revenue.
- Employees Jane Peacock and Steve Johnson consistently outperform in client support.
- Loyal customer cohorts exhibit strong repeat-purchase behavior after 6 months.
- High RFM customers (top 20%) contribute ~60% of total revenue.

## 💼 Business Relevance
These insights can help music store managers and digital distributors:
- Identify high-value customers and optimize loyalty programs.
- Refocus marketing efforts on top-performing genres and regions.
- Reward high-performing employees and optimize sales processes.

🔙 [Back to Portfolio](https://github.com/BlladeRunner)
