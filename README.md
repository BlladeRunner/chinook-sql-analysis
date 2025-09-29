# 🎵 Chinook Music Store Analytics (SQLite + SQL)

## Overview

SQL portfolio project on the classic **Chinook** dataset (albums, tracks, customers, invoices).  
Questions answered: monthly revenue, top customers, countries/genres performance, employee sales, market basket (track pairs), cohorts, and RFM segmentation.

## Dataset

- DB: `chinook.db` (SQLite version of Chinook)
- Main helper view: `v_invoice_detail` (see `bootstrap_chinook.sql`)
- Important tables: `invoices, invoice_items, customers, employees, tracks, albums, artists, genres, media_types`

## Reproduce

```bash
# 1) Put 'chinook.db' into the project folder
# 2) Build helper view
sqlite3 chinook.db ".read bootstrap_chinook.sql"

# 3) Run analysis queries (VS Code + SQLTools)
# open queries.sql → select query → Ctrl+E, Ctrl+E
```
