-- ShopAssist :: seed data - orders and order_items
-- 15 orders (referencing the 10 customers in seed_users.sql) and 22 order
-- line items (referencing the 25 products in seed_products.sql). Order
-- totals are the sum of their line item subtotals, kept in sync by hand
-- for a clean, referentially-correct sample dataset.
--
-- Depends on: seed_users.sql, seed_products.sql having been loaded first.

\echo 'ShopAssist :: loading seed_orders.sql (orders + order_items) ...'

INSERT INTO orders (id, order_number, customer_id, status, total_amount, currency, shipping_address, billing_address, placed_at) VALUES
(1,  'ORD-2026-0001', 1,  'delivered',  179.97, 'USD', '221 Pine St, Seattle, WA 98101, USA',        '221 Pine St, Seattle, WA 98101, USA',        '2026-06-01 14:32:00+00'),
(2,  'ORD-2026-0002', 2,  'shipped',     69.99, 'USD', '48 Congress Ave, Austin, TX 73301, USA',     '48 Congress Ave, Austin, TX 73301, USA',     '2026-06-03 09:10:00+00'),
(3,  'ORD-2026-0003', 3,  'processing', 189.97, 'USD', '900 Ocean Dr, Miami, FL 33139, USA',         '900 Ocean Dr, Miami, FL 33139, USA',         '2026-06-05 17:45:00+00'),
(4,  'ORD-2026-0004', 4,  'pending',    199.99, 'USD', '77 Tech Way, San Jose, CA 95110, USA',       '77 Tech Way, San Jose, CA 95110, USA',       '2026-06-08 11:05:00+00'),
(5,  'ORD-2026-0005', 5,  'delivered',   84.96, 'USD', '15 Mile High Cir, Denver, CO 80202, USA',    '15 Mile High Cir, Denver, CO 80202, USA',    '2026-06-10 08:20:00+00'),
(6,  'ORD-2026-0006', 6,  'shipped',    299.99, 'USD', '5 Lakeshore Dr, Chicago, IL 60601, USA',     '5 Lakeshore Dr, Chicago, IL 60601, USA',     '2026-06-13 19:00:00+00'),
(7,  'ORD-2026-0007', 7,  'delivered',   79.97, 'USD', '10 Bay St, Toronto, ON M5J2R8, Canada',      '10 Bay St, Toronto, ON M5J2R8, Canada',      '2026-06-16 10:15:00+00'),
(8,  'ORD-2026-0008', 8,  'processing', 549.99, 'USD', '1 Baker St, London, NW1 6XE, United Kingdom','1 Baker St, London, NW1 6XE, United Kingdom','2026-06-19 13:40:00+00'),
(9,  'ORD-2026-0009', 9,  'pending',    174.98, 'USD', 'Via Roma 12, Milan, 20121, Italy',           'Via Roma 12, Milan, 20121, Italy',           '2026-06-22 07:55:00+00'),
(10, 'ORD-2026-0010', 10, 'shipped',    149.99, 'USD', '25 George St, Sydney, NSW 2000, Australia',  '25 George St, Sydney, NSW 2000, Australia',  '2026-06-25 16:30:00+00'),
(11, 'ORD-2026-0011', 1,  'delivered',   69.98, 'USD', '221 Pine St, Seattle, WA 98101, USA',        '221 Pine St, Seattle, WA 98101, USA',        '2026-06-28 12:00:00+00'),
(12, 'ORD-2026-0012', 2,  'cancelled',  244.98, 'USD', '48 Congress Ave, Austin, TX 73301, USA',     '48 Congress Ave, Austin, TX 73301, USA',     '2026-07-01 15:20:00+00'),
(13, 'ORD-2026-0013', 3,  'delivered',  129.99, 'USD', '900 Ocean Dr, Miami, FL 33139, USA',         '900 Ocean Dr, Miami, FL 33139, USA',         '2026-07-04 18:10:00+00'),
(14, 'ORD-2026-0014', 5,  'processing', 239.97, 'USD', '15 Mile High Cir, Denver, CO 80202, USA',    '15 Mile High Cir, Denver, CO 80202, USA',    '2026-07-07 09:45:00+00'),
(15, 'ORD-2026-0015', 9,  'refunded',    89.99, 'USD', 'Via Roma 12, Milan, 20121, Italy',           'Via Roma 12, Milan, 20121, Italy',           '2026-07-10 20:05:00+00')
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('orders', 'id'), COALESCE((SELECT MAX(id) FROM orders), 1));

INSERT INTO order_items (id, order_id, product_id, quantity, unit_price, subtotal) VALUES
(1,  1,  1,  1, 79.99,  79.99),
(2,  1,  4,  2, 49.99,  99.98),
(3,  2,  10, 1, 69.99,  69.99),
(4,  3,  16, 1, 129.99, 129.99),
(5,  3,  17, 2, 29.99,  59.98),
(6,  4,  9,  1, 199.99, 199.99),
(7,  5,  12, 3, 14.99,  44.97),
(8,  5,  11, 1, 39.99,  39.99),
(9,  6,  19, 1, 299.99, 299.99),
(10, 7,  22, 2, 29.99,  59.98),
(11, 7,  24, 1, 19.99,  19.99),
(12, 8,  3,  1, 549.99, 549.99),
(13, 9,  14, 1, 149.99, 149.99),
(14, 9,  15, 1, 24.99,  24.99),
(15, 10, 25, 1, 149.99, 149.99),
(16, 11, 6,  2, 34.99,  69.98),
(17, 12, 7,  1, 219.99, 219.99),
(18, 12, 8,  1, 24.99,  24.99),
(19, 13, 2,  1, 129.99, 129.99),
(20, 14, 23, 1, 199.99, 199.99),
(21, 14, 24, 2, 19.99,  39.98),
(22, 15, 5,  1, 89.99,  89.99)
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('order_items', 'id'), COALESCE((SELECT MAX(id) FROM order_items), 1));

\echo 'ShopAssist :: seed_orders.sql loaded (15 orders, 22 order items).'
\echo 'ShopAssist :: PostgreSQL initialization completed successfully.'
