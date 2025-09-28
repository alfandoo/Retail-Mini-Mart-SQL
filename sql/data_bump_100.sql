-- =========================================================
-- Retail Mini-Mart — Generator ≥ 1000 Orders
-- Jalankan setelah schema + seed.
-- =========================================================

-- Untuk hasil random yang repeatable (opsional)
SELECT setseed(0.42);

-- Pastikan view ada
CREATE OR REPLACE VIEW vw_order_totals AS
SELECT
  oi.order_id,
  SUM(oi.qty * oi.unit_price)::NUMERIC(12,2) AS order_total
FROM order_items oi
GROUP BY oi.order_id;

WITH
params AS (
  SELECT GREATEST(1000 - COUNT(*), 0) AS n_needed
  FROM orders
),

-- 1) Tambah orders baru sebanyak yang dibutuhkan
ins_orders AS (
  INSERT INTO orders (customer_id, order_date, status)
  SELECT
    c.customer_id,
    (DATE '2024-06-01' + ((random()*90)::int) * INTERVAL '1 day')::date AS order_date,
    CASE
      WHEN random() < 0.75 THEN 'delivered'
      WHEN random() < 0.90 THEN 'pending'
      ELSE 'cancelled'
    END AS status
  FROM params
  JOIN LATERAL (SELECT customer_id FROM customers ORDER BY random() LIMIT 1) AS c ON TRUE
  JOIN LATERAL generate_series(1, (SELECT n_needed FROM params)) AS g(n) ON TRUE
  RETURNING order_id, customer_id, order_date, status
),

-- 2) Tambah 1–5 item unik per order
ins_items AS (
  INSERT INTO order_items (order_id, product_id, qty, unit_price)
  SELECT
    io.order_id,
    p.product_id,
    (1 + floor(random()*4))::int AS qty,        -- 1..4
    p.price AS unit_price
  FROM ins_orders io
  CROSS JOIN LATERAL (
    SELECT product_id, price
    FROM products
    ORDER BY random()
    LIMIT (1 + floor(random()*5))::int          -- 1..5 produk unik
  ) AS p
  RETURNING 1
),

-- 3) Tambah payment penuh untuk order delivered
ins_payments AS (
  INSERT INTO payments (order_id, method, amount, paid_at)
  SELECT
    io.order_id,
    (ARRAY['cash','card','transfer','ewallet'])[1 + floor(random()*4)::int] AS method,
    t.order_total,
    (io.order_date + ((1 + floor(random()*20))::text || ' hours')::interval) AS paid_at
  FROM ins_orders io
  JOIN vw_order_totals t ON t.order_id = io.order_id
  WHERE io.status = 'delivered'
  RETURNING 1
)

-- Ringkasan hasil
SELECT
  (SELECT n_needed FROM params)        AS inserted_orders,
  (SELECT COUNT(*) FROM ins_items)     AS inserted_items_rows,
  (SELECT COUNT(*) FROM ins_payments)  AS inserted_payments_rows,
  (SELECT COUNT(*) FROM orders)        AS total_orders_after;
