-- ShopAssist :: SQLite seed data
-- Lightweight sample dataset for local development (~28 rows total).
-- Safe to re-run after reset_db.sh recreates the schema.

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------------
-- customers (6)
-- ---------------------------------------------------------------------------
INSERT INTO customers (id, first_name, last_name, email, phone, address_line1, city, state, postal_code, country) VALUES
(1, 'Alice',  'Johnson', 'alice.johnson@example.com', '+1-206-555-0101', '221 Pine St',      'Seattle',   'WA', '98101', 'USA'),
(2, 'Brian',  'Smith',   'brian.smith@example.com',   '+1-512-555-0102', '48 Congress Ave',  'Austin',    'TX', '73301', 'USA'),
(3, 'Carla',  'Gomez',   'carla.gomez@example.com',   '+1-305-555-0103', '900 Ocean Dr',     'Miami',     'FL', '33139', 'USA'),
(4, 'David',  'Lee',     'david.lee@example.com',     '+1-408-555-0104', '77 Tech Way',      'San Jose',  'CA', '95110', 'USA'),
(5, 'Emma',   'Wilson',  'emma.wilson@example.com',   '+1-303-555-0105', '15 Mile High Cir', 'Denver',    'CO', '80202', 'USA'),
(6, 'Farhan', 'Ahmed',   'farhan.ahmed@example.com',  '+1-312-555-0106', '5 Lakeshore Dr',   'Chicago',   'IL', '60601', 'USA');

-- ---------------------------------------------------------------------------
-- products (10)
-- ---------------------------------------------------------------------------
INSERT INTO products (id, sku, name, description, category, price, currency, stock_quantity) VALUES
(1,  'SKU-1001', 'Wireless Bluetooth Headphones', 'Over-ear headphones with 30h battery life', 'Electronics', 79.99,  'USD', 150),
(2,  'SKU-1002', 'Noise Cancelling Earbuds',      'True wireless earbuds with ANC',            'Electronics', 129.99, 'USD', 100),
(3,  'SKU-1003', '4K Ultra HD Smart TV 55"',      '55-inch smart TV with HDR support',         'Electronics', 549.99, 'USD', 40),
(4,  'SKU-1004', 'Portable Bluetooth Speaker',    'Water-resistant portable speaker',          'Electronics', 49.99,  'USD', 200),
(5,  'SKU-1005', 'Mechanical Gaming Keyboard',    'RGB backlit mechanical keyboard',           'Electronics', 89.99,  'USD', 120),
(6,  'SKU-1006', 'Wireless Ergonomic Mouse',      'Ergonomic mouse with adjustable DPI',       'Electronics', 34.99,  'USD', 180),
(7,  'SKU-1007', '27" LED Monitor',               '27-inch 1440p IPS monitor',                 'Electronics', 219.99, 'USD', 60),
(8,  'SKU-1008', 'USB-C Fast Charger 65W',        'Compact GaN fast charger',                  'Electronics', 24.99,  'USD', 300),
(9,  'SKU-1009', 'Smartwatch Series 5',           'Fitness tracking smartwatch',               'Electronics', 199.99, 'USD', 90),
(10, 'SKU-2001', 'Men''s Running Shoes',          'Lightweight breathable running shoes',      'Apparel',      69.99,  'USD', 150);

-- ---------------------------------------------------------------------------
-- orders (5)
-- ---------------------------------------------------------------------------
INSERT INTO orders (id, order_number, customer_id, status, total_amount, currency, shipping_address, placed_at) VALUES
(1, 'ORD-2026-0001', 1, 'delivered',  179.97, 'USD', '221 Pine St, Seattle, WA 98101, USA',   '2026-06-20 14:32:00'),
(2, 'ORD-2026-0002', 2, 'shipped',     69.99, 'USD', '48 Congress Ave, Austin, TX 73301, USA', '2026-06-25 09:10:00'),
(3, 'ORD-2026-0003', 3, 'pending',    199.99, 'USD', '900 Ocean Dr, Miami, FL 33139, USA',    '2026-07-01 17:45:00'),
(4, 'ORD-2026-0004', 4, 'processing', 69.98,  'USD', '77 Tech Way, San Jose, CA 95110, USA',  '2026-07-05 11:05:00'),
(5, 'ORD-2026-0005', 5, 'delivered',  154.98, 'USD', '15 Mile High Cir, Denver, CO 80202, USA','2026-07-08 08:20:00');

-- ---------------------------------------------------------------------------
-- order_items (7)
-- ---------------------------------------------------------------------------
INSERT INTO order_items (id, order_id, product_id, quantity, unit_price, subtotal) VALUES
(1, 1, 1, 1, 79.99,  79.99),
(2, 1, 4, 2, 49.99,  99.98),
(3, 2, 10, 1, 69.99, 69.99),
(4, 3, 9, 1, 199.99, 199.99),
(5, 4, 6, 2, 34.99,  69.98),
(6, 5, 2, 1, 129.99, 129.99),
(7, 5, 8, 1, 24.99,  24.99);
