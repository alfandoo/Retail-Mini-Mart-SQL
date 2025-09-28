-- =========================================================
-- Retail Mini-Mart — Schema + Seed
-- =========================================================

DROP TABLE IF EXISTS payments, order_items, orders, products, customers CASCADE;

-- Master: customers
CREATE TABLE customers (
  customer_id SERIAL PRIMARY KEY,
  full_name   TEXT NOT NULL,
  city        TEXT NOT NULL,
  join_date   DATE NOT NULL
);

-- Master: products
CREATE TABLE products (
  product_id   SERIAL PRIMARY KEY,
  product_name TEXT NOT NULL,
  category     TEXT NOT NULL,
  price        NUMERIC(10,2) NOT NULL CHECK (price >= 0)
);

-- Transaksi: orders
CREATE TABLE orders (
  order_id    SERIAL PRIMARY KEY,
  customer_id INT REFERENCES customers(customer_id),
  order_date  DATE NOT NULL,
  status      TEXT NOT NULL CHECK (status IN ('delivered','pending','cancelled'))
);

-- Transaksi: order_items (detail)
CREATE TABLE order_items (
  order_id   INT REFERENCES orders(order_id),
  product_id INT REFERENCES products(product_id),
  qty        INT NOT NULL CHECK (qty > 0),
  unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
  PRIMARY KEY (order_id, product_id)
);

-- Pembayaran
CREATE TABLE payments (
  payment_id SERIAL PRIMARY KEY,
  order_id   INT REFERENCES orders(order_id),
  method     TEXT NOT NULL CHECK (method IN ('cash','card','transfer','ewallet')),
  amount     NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
  paid_at    TIMESTAMP NOT NULL
);

-- ==========================
-- SEED DATA
-- ==========================

-- customers
INSERT INTO customers (full_name, city, join_date) VALUES
('Ana',   'Pekanbaru',  '2024-01-10'),
('Budi',  'Jakarta',    '2024-02-15'),
('Cici',  'Bandung',    '2024-03-05'),
('Dani',  'Surabaya',   '2024-04-12'),
('Eka',   'Medan',      '2024-05-20'),
('Fajar', 'Yogyakarta', '2024-06-18');

-- products
INSERT INTO products (product_name, category, price) VALUES
('Coffee Arabica 200g', 'Beverages',    5.50),
('Green Tea 50g',       'Beverages',    3.00),
('Milk 1L',             'Dairy',        2.20),
('Bread Loaf',          'Bakery',       1.80),
('Eggs 12pc',           'Grocery',      2.50),
('Rice 5kg',            'Grocery',      7.50),
('Shampoo 250ml',       'PersonalCare', 4.20),
('Soap Bar',            'PersonalCare', 1.20);

-- orders
INSERT INTO orders (customer_id, order_date, status) VALUES
(1,'2024-06-01','delivered'),
(2,'2024-06-02','delivered'),
(3,'2024-06-03','cancelled'),
(1,'2024-06-10','delivered'),
(4,'2024-06-11','pending'),
(5,'2024-06-12','delivered'),
(6,'2024-06-15','delivered'),
(2,'2024-06-18','delivered');

-- order_items
INSERT INTO order_items (order_id, product_id, qty, unit_price) VALUES
(1,1,2,5.50),(1,4,1,1.80),(1,5,1,2.50),
(2,6,1,7.50),(2,8,3,1.20),
(3,7,1,4.20),
(4,2,1,3.00),(4,3,2,2.20),(4,5,2,2.50),
(5,6,1,7.50),
(6,1,1,5.50),(6,8,2,1.20),
(7,4,2,1.80),(7,5,1,2.50),
(8,2,2,3.00),(8,7,1,4.20);

-- View total per order (reusable metric)
CREATE OR REPLACE VIEW vw_order_totals AS
SELECT
  oi.order_id,
  SUM(oi.qty * oi.unit_price)::NUMERIC(12,2) AS order_total
FROM order_items oi
GROUP BY oi.order_id;

-- payments (full paid untuk order delivered)
-- o1: 15.30, o2: 11.10, o4: 12.40, o6: 7.90, o7: 6.10, o8: 10.20
INSERT INTO payments (order_id, method, amount, paid_at) VALUES
(1,'cash',     15.30,'2024-06-01 10:00'),
(2,'card',     11.10,'2024-06-02 11:00'),
(4,'ewallet',  12.40,'2024-06-10 12:00'),
(6,'transfer',  7.90,'2024-06-12 13:00'),
(7,'cash',      6.10,'2024-06-15 14:00'),
(8,'card',     10.20,'2024-06-18 15:00');
