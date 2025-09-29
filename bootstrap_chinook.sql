-- Chinook bootstrap: helper view for analytics (SQLite)

DROP VIEW IF EXISTS v_invoice_detail;
CREATE VIEW v_invoice_detail AS
SELECT
  il.InvoiceLineId,
  i.InvoiceId,
  date(i.InvoiceDate)                      AS InvoiceDate,
  strftime('%Y-%m', i.InvoiceDate)         AS ym,
  i.CustomerId,
  c.FirstName || ' ' || c.LastName         AS CustomerName,
  c.Country,
  c.SupportRepId,
  e.FirstName || ' ' || e.LastName         AS SupportRepName,
  il.TrackId,
  t.Name                                   AS TrackName,
  t.Milliseconds / 1000                    AS TrackSeconds,
  t.Bytes,
  t.AlbumId,
  al.Title                                 AS AlbumTitle,
  al.ArtistId,
  ar.Name                                  AS ArtistName,
  t.GenreId,
  g.Name                                   AS GenreName,
  il.UnitPrice,
  il.Quantity,
  (il.UnitPrice * il.Quantity)             AS LineRevenue
FROM InvoiceLine il
JOIN Invoice     i  ON i.InvoiceId   = il.InvoiceId
JOIN Customer    c  ON c.CustomerId  = i.CustomerId
LEFT JOIN Employee e ON e.EmployeeId = c.SupportRepId
JOIN Track       t  ON t.TrackId     = il.TrackId
JOIN Album       al ON al.AlbumId    = t.AlbumId
JOIN Artist      ar ON ar.ArtistId   = al.ArtistId
LEFT JOIN Genre  g  ON g.GenreId     = t.GenreId;

-- Optional indexes (on base tables)
CREATE INDEX IF NOT EXISTS idx_inv_date       ON Invoice(InvoiceDate);
CREATE INDEX IF NOT EXISTS idx_inv_customer   ON Invoice(CustomerId);
CREATE INDEX IF NOT EXISTS idx_cust_support   ON Customer(SupportRepId);
