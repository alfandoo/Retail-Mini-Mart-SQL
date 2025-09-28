-- =========================================================
-- Retail Mini-Mart — 15 Query Analitik Utama
-- =========================================================

-- 1) Top-5 produk berdasarkan revenue
SELECT p.product_name, SUM(oi.qty*oi.unit_price) AS revenue
FROM order_items oi
JOIN products p USING (product_id)
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 5;

-- 2) Revenue harian (hanya delivered)
SELECT o.order_date, SUM(oi.qty*oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi USING (order_id)
WHERE o.status='delivered'
GROUP BY o.order_date
ORDER BY o.order_date;

-- 3) AOV (Average Order Value) pada delivered
SELECT AVG(order_total) AS aov
FROM vw_order_totals
JOIN orders o USING (order_id)
WHERE o.status='delivered';

-- 4) Repeat rate (% customer dengan >1 pesanan delivered)
SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE delivered_cnt>1)/NULLIF(COUNT(*),0),2) AS repeat_rate_pct
FROM (
  SELECT c.customer_id, COUNT(*) FILTER (WHERE o.status='delivered') AS delivered_cnt
  FROM customers c
  LEFT JOIN orders o USING (customer_id)
  GROUP BY c.customer_id
) s;

-- 5) RFM mini (Recency, Frequency, Monetary)
WITH delivered AS (
  SELECT o.customer_id, o.order_id, o.order_date,
         (SELECT order_total FROM vw_order_totals t WHERE t.order_id=o.order_id) AS total
  FROM orders o
  WHERE o.status='delivered'
)
SELECT
  c.customer_id, c.full_name,
  (CURRENT_DATE - MAX(d.order_date))::INT AS recency_days,
  COUNT(d.order_id) AS frequency,
  COALESCE(SUM(d.total),0)::NUMERIC(12,2) AS monetary
FROM customers c
LEFT JOIN delivered d USING (customer_id)
GROUP BY c.customer_id, c.full_name
ORDER BY monetary DESC NULLS LAST;

-- 6) Share revenue per kategori
SELECT p.category,
       ROUND(100.0 * SUM(oi.qty*oi.unit_price) / SUM(SUM(oi.qty*oi.unit_price)) OVER (), 2) AS pct_revenue
FROM order_items oi
JOIN products p USING (product_id)
GROUP BY p.category
ORDER BY pct_revenue DESC;

-- 7) Deteksi order belum lunas (due)
SELECT o.order_id, o.status,
       t.order_total, COALESCE(SUM(pm.amount),0) AS paid,
       (t.order_total - COALESCE(SUM(pm.amount),0)) AS due
FROM orders o
JOIN vw_order_totals t USING (order_id)
LEFT JOIN payments pm USING (order_id)
GROUP BY o.order_id, o.status, t.order_total
HAVING t.order_total > COALESCE(SUM(pm.amount),0)
ORDER BY due DESC;

-- 8) Persentase cancelled
SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE status='cancelled') / COUNT(*), 2) AS cancelled_pct
FROM orders;

-- 9) Revenue per kota
SELECT c.city, SUM(oi.qty*oi.unit_price) AS revenue
FROM customers c
JOIN orders o USING (customer_id)
JOIN order_items oi USING (order_id)
WHERE o.status='delivered'
GROUP BY c.city
ORDER BY revenue DESC;

-- 10) New vs Returning (bulan 2024-06)
WITH june AS (
  SELECT o.customer_id, o.order_id
  FROM orders o
  WHERE o.order_date >= '2024-06-01' AND o.order_date < '2024-07-01'
),
first_order AS (
  SELECT customer_id, MIN(order_date) AS first_date
  FROM orders GROUP BY customer_id
)
SELECT
  SUM(CASE WHEN fo.first_date >= '2024-06-01' AND fo.first_date < '2024-07-01' THEN 1 ELSE 0 END) AS new_customers,
  SUM(CASE WHEN fo.first_date <  '2024-06-01' THEN 1 ELSE 0 END) AS returning_customers
FROM june j JOIN first_order fo USING (customer_id);

-- 11) Running total revenue by day (window)
WITH daily AS (
  SELECT o.order_date AS d, SUM(oi.qty*oi.unit_price) AS rev
  FROM orders o
  JOIN order_items oi USING (order_id)
  WHERE o.status='delivered'
  GROUP BY o.order_date
)
SELECT d, rev,
       SUM(rev) OVER (ORDER BY d ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM daily
ORDER BY d;

-- 12) Pareto 80/20 — kontribusi kumulatif revenue per customer
WITH cust_rev AS (
  SELECT c.customer_id, c.full_name, SUM(oi.qty*oi.unit_price) AS revenue
  FROM customers c
  JOIN orders o USING (customer_id)
  JOIN order_items oi USING (order_id)
  WHERE o.status='delivered'
  GROUP BY c.customer_id, c.full_name
),
ranked AS (
  SELECT *,
         revenue / SUM(revenue) OVER () AS pct,
         SUM(revenue) OVER (ORDER BY revenue DESC) / SUM(revenue) OVER () AS cum_pct
  FROM cust_rev
)
SELECT * FROM ranked ORDER BY revenue DESC;

-- 13) Last order per customer
SELECT c.full_name, MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN orders o USING (customer_id)
GROUP BY c.full_name
ORDER BY last_order_date DESC NULLS LAST;

-- 14) Revenue by payment method
SELECT pm.method, SUM(pm.amount) AS paid
FROM payments pm
GROUP BY pm.method
ORDER BY paid DESC;

-- 15) Produk yang sering dibeli bareng (pair sederhana)
SELECT p1.product_name AS item_a, p2.product_name AS item_b, COUNT(*) AS times_bought_together
FROM order_items a
JOIN order_items b ON a.order_id=b.order_id AND a.product_id < b.product_id
JOIN products p1 ON p1.product_id=a.product_id
JOIN products p2 ON p2.product_id=b.product_id
GROUP BY item_a, item_b
ORDER BY times_bought_together DESC, item_a, item_b;
