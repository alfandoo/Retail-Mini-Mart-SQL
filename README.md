# 🛒 Retail Mini-Mart — SQL Portfolio 

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue?logo=postgresql)
![pgAdmin4](https://img.shields.io/badge/pgAdmin-4-1f425f)
![SQL Skills](https://img.shields.io/badge/Skills-JOIN%20%7C%20CTE%20%7C%20Window%20%7C%20GROUP%20BY%20%7C%20HAVING-green)
![Status](https://img.shields.io/badge/Data-%E2%89%A5%201000%20orders-brightgreen)

Proyek SQL ringkas yang menunjukkan **schema rapi**, **query analitik nyata**, dan **window functions** di mini toko retail. Dibangun dengan **PostgreSQL + pgAdmin 4**. 

---

## ✨ Highlights
- **Schema**: `customers, products, orders, order_items, payments` (+ view reusable `vw_order_totals`).
- **Analytics**: Top-N products, daily revenue, AOV, RFM mini, Pareto 80/20, unpaid orders, running total, product pairs.
- **Skills**: JOIN, GROUP BY/HAVING, **Window Functions**, Views, data quality checks.
- **Data Volume**: Seed kecil + generator hingga **≥ 1000 orders**.

---

## 🧱 ERD (Mermaid)
> GitHub otomatis merender Mermaid.
```mermaid
erDiagram
  customers ||--o{ orders : places
  orders ||--o{ order_items : contains
  products ||--o{ order_items : referenced
  orders ||--o{ payments : settles

  customers {
    int customer_id PK
    text full_name
    text city
    date join_date
  }

  products {
    int product_id PK
    text product_name
    text category
    numeric price
  }

  orders {
    int order_id PK
    int customer_id FK
    date order_date
    text status
  }

  order_items {
    int order_id FK
    int product_id FK
    int qty
    numeric unit_price
  }

  payments {
    int payment_id PK
    int order_id FK
    text method
    numeric amount
    timestamp paid_at
  }

Daily Revenue:

![Daily Revenue](reports/screenshots/daily_revenue.png)
![Daily Revenue](reports/screenshots/revenue_by_day.png)

AOV:

![AOV](reports/screenshots/aov.png)

RFM:

![RFM Mini](reports/screenshots/rfm.png)

Pareto 80/20:

![Pareto 80/20](reports/screenshots/pareto.png)

Unpaid Orders:

![Unpaid Orders](reports/screenshots/unpaid_orders.png)

