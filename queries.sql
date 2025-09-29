/* =========================
   Chinook Music Store — SQL Queries (SQLite)
   Uses helper view: v_invoice_detail (see bootstrap_chinook.sql)
   ========================= */

/* 0) Quick sanity */
PRAGMA table_info('v_invoice_detail');
SELECT COUNT(*) AS rows FROM v_invoice_detail;
SELECT MIN(InvoiceDate) AS min_date, MAX(InvoiceDate) AS max_date FROM v_invoice_detail;

/* 1) Monthly revenue & MoM growth */
WITH m AS (
  SELECT ym, SUM(LineRevenue) AS revenue
  FROM v_invoice_detail
  GROUP BY ym
)
SELECT ym,
       ROUND(revenue,2) AS revenue,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY ym))
              / NULLIF(LAG(revenue) OVER (ORDER BY ym),0), 4) AS mom_growth
FROM m
ORDER BY ym;

/* 2) Top customers by revenue (with AOV) */
WITH inv AS (
  SELECT InvoiceId, CustomerId, CustomerName, SUM(LineRevenue) AS order_value
  FROM v_invoice_detail
  GROUP BY InvoiceId, CustomerId, CustomerName
)
SELECT
  CustomerId, CustomerName,
  COUNT(*)                         AS invoices,
  ROUND(SUM(order_value),2)        AS revenue,
  ROUND(AVG(order_value),2)        AS aov
FROM inv
GROUP BY CustomerId, CustomerName
ORDER BY revenue DESC
LIMIT 15;

/* 3) Country breakdown */
SELECT
  Country,
  COUNT(DISTINCT CustomerId)         AS customers,
  COUNT(DISTINCT InvoiceId)          AS invoices,
  ROUND(SUM(LineRevenue),2)          AS revenue,
  ROUND(SUM(LineRevenue)*1.0/COUNT(DISTINCT CustomerId),2) AS rev_per_customer
FROM v_invoice_detail
GROUP BY Country
ORDER BY revenue DESC;

/* 4) Genre revenue share */
WITH g AS (
  SELECT GenreName, SUM(LineRevenue) AS revenue
  FROM v_invoice_detail
  GROUP BY GenreName
),
t AS ( SELECT SUM(revenue) AS total FROM g )
SELECT g.GenreName,
       ROUND(g.revenue,2) AS revenue,
       ROUND(g.revenue * 1.0 / t.total, 4) AS share
FROM g, t
ORDER BY revenue DESC;

/* 5) Top tracks by purchases (qty) */
SELECT
  TrackId, TrackName, ArtistName, GenreName,
  SUM(Quantity) AS qty,
  ROUND(SUM(LineRevenue),2) AS revenue
FROM v_invoice_detail
GROUP BY TrackId, TrackName, ArtistName, GenreName
ORDER BY qty DESC, revenue DESC
LIMIT 20;

/* 6) Top artists by revenue */
SELECT
  ArtistId, ArtistName,
  ROUND(SUM(LineRevenue),2) AS revenue
FROM v_invoice_detail
GROUP BY ArtistId, ArtistName
ORDER BY revenue DESC
LIMIT 15;

/* 7) Employee (Support Rep) performance */
SELECT
  SupportRepId, SupportRepName,
  COUNT(DISTINCT InvoiceId) AS invoices,
  ROUND(SUM(LineRevenue),2) AS revenue
FROM v_invoice_detail
GROUP BY SupportRepId, SupportRepName
ORDER BY revenue DESC;

/* 8) Customer lifetime (first/last purchase, days, AOV) */
WITH c AS (
  SELECT CustomerId, CustomerName,
         MIN(InvoiceDate) AS first_date,
         MAX(InvoiceDate) AS last_date,
         COUNT(DISTINCT InvoiceId) AS invoices,
         SUM(LineRevenue) AS revenue
  FROM v_invoice_detail
  GROUP BY CustomerId, CustomerName
)
SELECT
  CustomerId, CustomerName,
  first_date, last_date,
  invoices,
  ROUND(revenue,2) AS revenue,
  ROUND(revenue*1.0/invoices,2) AS aov,
  CAST(julianday(last_date) - julianday(first_date) AS INT) AS lifetime_days
FROM c
ORDER BY revenue DESC
LIMIT 20;

/* 9) Market basket: track pairs bought together in the same invoice */
WITH pairs AS (
  SELECT a.TrackId AS t1, b.TrackId AS t2
  FROM InvoiceLine a
  JOIN InvoiceLine b
    ON a.InvoiceId = b.InvoiceId
   AND a.TrackId   < b.TrackId
)
SELECT
  p.t1, t1.Name AS Track1,
  p.t2, t2.Name AS Track2,
  COUNT(*)      AS together_count
FROM pairs p
JOIN Track t1 ON t1.TrackId = p.t1
JOIN Track t2 ON t2.TrackId = p.t2
GROUP BY p.t1, p.t2
ORDER BY together_count DESC
LIMIT 20;


/* 10) Cohort: next-month retention by first-purchase cohort */
WITH firsts AS (
  SELECT CustomerId, strftime('%Y-%m', MIN(InvoiceDate)) AS cohort
  FROM v_invoice_detail
  GROUP BY CustomerId
),
sizes AS (
  SELECT cohort, COUNT(*) AS cohort_size
  FROM firsts
  GROUP BY cohort
),
ret_next AS (
  SELECT f.cohort, COUNT(DISTINCT v.CustomerId) AS retained
  FROM firsts f
  JOIN v_invoice_detail v
    ON v.CustomerId = f.CustomerId
   AND strftime('%Y-%m', v.InvoiceDate) = strftime('%Y-%m', date(f.cohort || '-01','+1 month'))
  GROUP BY f.cohort
)
SELECT s.cohort, s.cohort_size,
       COALESCE(r.retained,0) AS retained_next_month,
       ROUND(COALESCE(r.retained,0)*1.0/s.cohort_size,3) AS retention_rate
FROM sizes s
LEFT JOIN ret_next r USING(cohort)
ORDER BY cohort;

/* 11) RFM scoring (1..5 per component; higher is better) */
WITH s AS (
  SELECT CustomerId, CustomerName,
         MAX(InvoiceDate) AS last_date,
         COUNT(DISTINCT InvoiceId) AS freq,
         SUM(LineRevenue) AS monetary
  FROM v_invoice_detail
  GROUP BY CustomerId, CustomerName
),
b AS (
  SELECT *,
         CAST(julianday((SELECT MAX(InvoiceDate) FROM v_invoice_detail)) - julianday(last_date) AS INT) AS recency_days
  FROM s
),
scores AS (
  SELECT *,
         (6 - NTILE(5) OVER (ORDER BY recency_days ASC)) AS R,
         NTILE(5) OVER (ORDER BY freq DESC)          AS F,
         NTILE(5) OVER (ORDER BY monetary DESC)      AS M
  FROM b
)
SELECT CustomerId, CustomerName, recency_days, freq, ROUND(monetary,2) AS monetary,
       R||F||M AS RFM, (R+F+M) AS RFM_score
FROM scores
ORDER BY RFM_score DESC, monetary DESC
LIMIT 20;

/* 12) Media types popularity */
SELECT mt.Name AS MediaType,
       COUNT(*) AS line_items,
       ROUND(SUM(ii.UnitPrice * ii.Quantity), 2) AS revenue
FROM InvoiceLine ii
JOIN Track t       ON t.TrackId = ii.TrackId
JOIN MediaType mt  ON mt.MediaTypeId = t.MediaTypeId
GROUP BY mt.Name
ORDER BY revenue DESC;


/* 13) Playlist coverage: how many unique sold tracks appear in playlists */
WITH sold AS (SELECT DISTINCT TrackId FROM v_invoice_detail),
pl AS (SELECT DISTINCT TrackId FROM PlaylistTrack)
SELECT
  (SELECT COUNT(*) FROM sold) AS sold_tracks,
  (SELECT COUNT(*) FROM pl)   AS playlist_tracks,
  (SELECT COUNT(*) FROM sold s JOIN pl p ON p.TrackId = s.TrackId) AS overlap_tracks;


/* 14) Track length stats (unique tracks) */
SELECT
  ROUND(AVG(Milliseconds)/60000.0, 2) AS avg_len_min,
  ROUND(MIN(Milliseconds)/60000.0, 2) AS min_len_min,
  ROUND(MAX(Milliseconds)/60000.0, 2) AS max_len_min
FROM Track;

