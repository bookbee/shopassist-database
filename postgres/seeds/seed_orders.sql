-- ShopAssist :: seed data - orders and order_items
-- 15 orders (referencing the 10 customers in seed_customers.sql and the 10
-- sessions in seed_sessions.sql) and 22 order line items (referencing the 25
-- items in seed_items.sql), all keyed by the human-readable ord-1001 /
-- cust-1001 / item-1001 IDs. subtotal/shipping_fee/total_amount (INR) are
-- derived from the line items below (free shipping above a Rs 999 subtotal,
-- else a flat Rs 49 fee) and kept in sync by hand for a clean,
-- referentially-correct sample dataset. order_items.line_total is a
-- GENERATED ALWAYS column, so it is never part of the INSERT - Postgres
-- computes it from quantity * unit_price.
--
-- Depends on: seed_customers.sql, seed_items.sql, seed_sessions.sql having
-- been loaded first.

\echo 'ShopAssist :: loading seed_orders.sql (orders + order_items) ...'

INSERT INTO orders (order_id, customer_id, session_id, status, subtotal, discount, shipping_fee, total_amount, shipping_address, placed_at) VALUES
('ord-1001', 'cust-1001', '11111111-1111-1111-1111-000000000001', 'delivered', 1197.00, 0.00, 0.00, 1197.00, '12 MG Road, Bengaluru, Karnataka 560001, India', '2026-06-01 14:32:00+00'),
('ord-1002', 'cust-1002', '11111111-1111-1111-1111-000000000002', 'shipped', 249.00, 0.00, 49.00, 298.00, '45 Anna Salai, Chennai, Tamil Nadu 600002, India', '2026-06-03 09:10:00+00'),
('ord-1003', 'cust-1003', '11111111-1111-1111-1111-000000000003', 'confirmed', 3697.00, 0.00, 0.00, 3697.00, '7 Marine Drive, Mumbai, Maharashtra 400002, India', '2026-06-05 17:45:00+00'),
('ord-1004', 'cust-1004', '11111111-1111-1111-1111-000000000004', 'pending', 1499.00, 0.00, 0.00, 1499.00, '23 MG Road, Kochi, Kerala 682016, India', '2026-06-08 11:05:00+00'),
('ord-1005', 'cust-1005', '11111111-1111-1111-1111-000000000005', 'delivered', 1646.00, 0.00, 0.00, 1646.00, '88 Banjara Hills, Hyderabad, Telangana 500034, India', '2026-06-10 08:20:00+00'),
('ord-1006', 'cust-1006', '11111111-1111-1111-1111-000000000006', 'shipped', 129.00, 0.00, 49.00, 178.00, '15 FC Road, Pune, Maharashtra 411004, India', '2026-06-13 19:00:00+00'),
('ord-1007', 'cust-1007', '11111111-1111-1111-1111-000000000007', 'delivered', 2097.00, 0.00, 0.00, 2097.00, '5 Connaught Place, New Delhi, Delhi 110001, India', '2026-06-16 10:15:00+00'),
('ord-1008', 'cust-1008', '11111111-1111-1111-1111-000000000008', 'confirmed', 799.00, 0.00, 49.00, 848.00, '30 Malleshwaram, Bengaluru, Karnataka 560012, India', '2026-06-19 13:40:00+00'),
('ord-1009', 'cust-1009', '11111111-1111-1111-1111-000000000009', 'pending', 2148.00, 0.00, 0.00, 2148.00, '18 Park Street, Kolkata, West Bengal 700016, India', '2026-06-22 07:55:00+00'),
('ord-1010', 'cust-1010', '11111111-1111-1111-1111-000000000010', 'shipped', 399.00, 0.00, 49.00, 448.00, '9 C-Scheme, Jaipur, Rajasthan 302001, India', '2026-06-25 16:30:00+00'),
('ord-1011', 'cust-1001', '11111111-1111-1111-1111-000000000001', 'delivered', 598.00, 0.00, 49.00, 647.00, '12 MG Road, Bengaluru, Karnataka 560001, India', '2026-06-28 12:00:00+00'),
('ord-1012', 'cust-1002', '11111111-1111-1111-1111-000000000002', 'cancelled', 1048.00, 0.00, 0.00, 1048.00, '45 Anna Salai, Chennai, Tamil Nadu 600002, India', '2026-07-01 15:20:00+00'),
('ord-1013', 'cust-1003', '11111111-1111-1111-1111-000000000003', 'delivered', 1299.00, 0.00, 0.00, 1299.00, '7 Marine Drive, Mumbai, Maharashtra 400002, India', '2026-07-04 18:10:00+00'),
('ord-1014', 'cust-1005', '11111111-1111-1111-1111-000000000005', 'confirmed', 2297.00, 0.00, 0.00, 2297.00, '88 Banjara Hills, Hyderabad, Telangana 500034, India', '2026-07-07 09:45:00+00'),
('ord-1015', 'cust-1009', '11111111-1111-1111-1111-000000000009', 'returned', 899.00, 0.00, 49.00, 948.00, '18 Park Street, Kolkata, West Bengal 700016, India', '2026-07-10 20:05:00+00')
ON CONFLICT (order_id) DO NOTHING;

INSERT INTO order_items (order_id, item_id, quantity, unit_price) VALUES
('ord-1001', 'item-1001', 1, 499.00),
('ord-1001', 'item-1004', 2, 349.00),
('ord-1002', 'item-1010', 1, 249.00),
('ord-1003', 'item-1016', 1, 699.00),
('ord-1003', 'item-1017', 2, 1499.00),
('ord-1004', 'item-1009', 1, 1499.00),
('ord-1005', 'item-1012', 3, 349.00),
('ord-1005', 'item-1011', 1, 599.00),
('ord-1006', 'item-1019', 1, 129.00),
('ord-1007', 'item-1022', 2, 599.00),
('ord-1007', 'item-1024', 1, 899.00),
('ord-1008', 'item-1003', 1, 799.00),
('ord-1009', 'item-1014', 1, 349.00),
('ord-1009', 'item-1015', 1, 1799.00),
('ord-1010', 'item-1025', 1, 399.00),
('ord-1011', 'item-1006', 2, 299.00),
('ord-1012', 'item-1007', 1, 599.00),
('ord-1012', 'item-1008', 1, 449.00),
('ord-1013', 'item-1002', 1, 1299.00),
('ord-1014', 'item-1023', 1, 499.00),
('ord-1014', 'item-1024', 2, 899.00),
('ord-1015', 'item-1005', 1, 899.00)
ON CONFLICT (order_id, item_id) DO NOTHING;

\echo 'ShopAssist :: seed_orders.sql loaded (15 orders, 22 order items).'
\echo 'ShopAssist :: PostgreSQL initialization completed successfully.'
