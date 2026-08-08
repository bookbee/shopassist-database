-- ShopAssist :: seed data - orders and order_items
-- 25 orders (referencing the 10 customers in seed_customers.sql and the 10
-- sessions in seed_sessions.sql) and 38 order line items (referencing the
-- 75 items in seed_items.sql), all keyed by the human-readable ord-1001 /
-- alum-1001 / item-1001 IDs. subtotal/shipping_fee/total_amount (INR) are
-- derived from the line items below (free shipping above a Rs 999
-- subtotal, else a flat Rs 49 fee) and kept in sync by hand for a clean,
-- referentially-correct sample dataset. order_items.line_total IS part of
-- the INSERT below: it's a plain stored column, not GENERATED ALWAYS -
-- shopassist-service writes it explicitly on every order it creates, and
-- Postgres rejects an INSERT that supplies a value for a generated column.
-- See ../schema/schema.sql's note on order_items.
--
-- See ../../README.md. Timestamps carry an
-- explicit +05:30 (IST) offset since each /docker-entrypoint-initdb.d/
-- file runs in its own psql session, so schema.sql's
-- `SET timezone = 'Asia/Kolkata'` doesn't carry over to this file's
-- session.
--
-- Depends on: seed_customers.sql, seed_items.sql, seed_sessions.sql having
-- been loaded first.

\echo 'ShopAssist :: loading seed_orders.sql (orders + order_items) ...'

INSERT INTO orders (order_id, user_id, session_id, status, subtotal, discount, shipping_fee, total_amount, shipping_address, placed_at) VALUES
('ord-1001', 'alum-1001', 'sess-1001', 'delivered',  1197.00,   0.00,  0.00, 1197.00, '12 MG Road, Bengaluru, Karnataka 560001, India', '2026-05-15 10:00:00+05:30'),
('ord-1002', 'alum-1002', 'sess-1002', 'delivered',   598.00,   0.00, 49.00,  647.00, '45 Anna Salai, Chennai, Tamil Nadu 600002, India', '2026-05-17 09:10:00+05:30'),
('ord-1003', 'alum-1003', 'sess-1003', 'pending',    1499.00,   0.00,  0.00, 1499.00, '7 Marine Drive, Mumbai, Maharashtra 400002, India', '2026-05-20 17:45:00+05:30'),
('ord-1004', 'alum-1004', 'sess-1004', 'confirmed',   598.00,   0.00, 49.00,  647.00, '23 MG Road, Kochi, Kerala 682016, India', '2026-05-22 11:05:00+05:30'),
('ord-1005', 'alum-1005', 'sess-1005', 'delivered',  1748.00,   0.00,  0.00, 1748.00, '88 Banjara Hills, Hyderabad, Telangana 500034, India', '2026-05-25 08:20:00+05:30'),
('ord-1006', 'alum-1001', 'sess-1001', 'shipped',     799.00,   0.00, 49.00,  848.00, '12 MG Road, Bengaluru, Karnataka 560001, India', '2026-05-28 10:00:00+05:30'),
('ord-1007', 'alum-1001', 'sess-1001', 'pending',     349.00,   0.00, 49.00,  398.00, '12 MG Road, Bengaluru, Karnataka 560001, India', '2026-06-01 16:15:00+05:30'),
('ord-1008', 'alum-1002', 'sess-1002', 'delivered',  1899.00, 100.00,  0.00, 1799.00, '45 Anna Salai, Chennai, Tamil Nadu 600002, India', '2026-06-03 12:00:00+05:30'),
('ord-1009', 'alum-1002', 'sess-1002', 'cancelled',  1599.00,   0.00,  0.00, 1599.00, '45 Anna Salai, Chennai, Tamil Nadu 600002, India', '2026-06-05 14:30:00+05:30'),
('ord-1010', 'alum-1003', 'sess-1003', 'delivered',   847.00,   0.00, 49.00,  896.00, '7 Marine Drive, Mumbai, Maharashtra 400002, India', '2026-06-07 09:45:00+05:30'),
('ord-1011', 'alum-1004', 'sess-1004', 'delivered',   697.00,   0.00, 49.00,  746.00, '23 MG Road, Kochi, Kerala 682016, India', '2026-06-10 13:20:00+05:30'),
('ord-1012', 'alum-1005', 'sess-1005', 'shipped',    1299.00,   0.00,  0.00, 1299.00, '88 Banjara Hills, Hyderabad, Telangana 500034, India', '2026-06-12 15:00:00+05:30'),
('ord-1013', 'alum-1005', 'sess-1005', 'delivered',  1499.00, 150.00,  0.00, 1349.00, '88 Banjara Hills, Hyderabad, Telangana 500034, India', '2026-06-14 11:40:00+05:30'),
('ord-1014', 'alum-1006', 'sess-1006', 'delivered',  1799.00,   0.00,  0.00, 1799.00, '15 FC Road, Pune, Maharashtra 411004, India', '2026-06-17 10:10:00+05:30'),
('ord-1015', 'alum-1006', 'sess-1006', 'returned',   1599.00,   0.00,  0.00, 1599.00, '15 FC Road, Pune, Maharashtra 411004, India', '2026-06-19 09:30:00+05:30'),
('ord-1016', 'alum-1007', 'sess-1007', 'delivered',   697.00,   0.00, 49.00,  746.00, 'Fatima Nagar, Pune, Maharashtra 411014, India', '2026-06-22 14:00:00+05:30'),
('ord-1017', 'alum-1007', 'sess-1007', 'pending',     599.00,   0.00, 49.00,  648.00, 'Fatima Nagar, Pune, Maharashtra 411014, India', '2026-06-25 16:45:00+05:30'),
('ord-1018', 'alum-1007', 'sess-1007', 'confirmed',   599.00,   0.00, 49.00,  648.00, 'Fatima Nagar, Pune, Maharashtra 411014, India', '2026-06-28 12:15:00+05:30'),
('ord-1019', 'alum-1008', 'sess-1008', 'delivered',  1299.00,   0.00,  0.00, 1299.00, '221 Connaught Place, New Delhi, Delhi 110001, India', '2026-07-01 10:00:00+05:30'),
('ord-1020', 'alum-1008', 'sess-1008', 'shipped',    1398.00,   0.00,  0.00, 1398.00, '221 Connaught Place, New Delhi, Delhi 110001, India', '2026-07-03 11:30:00+05:30'),
('ord-1021', 'alum-1009', 'sess-1009', 'delivered',  2498.00, 200.00,  0.00, 2298.00, '5 Park Street, Kolkata, West Bengal 700016, India', '2026-07-05 09:00:00+05:30'),
('ord-1022', 'alum-1009', 'sess-1009', 'pending',     999.00,   0.00,  0.00,  999.00, '5 Park Street, Kolkata, West Bengal 700016, India', '2026-07-08 15:20:00+05:30'),
('ord-1023', 'alum-1009', 'sess-1009', 'confirmed',  1398.00,   0.00,  0.00, 1398.00, '5 Park Street, Kolkata, West Bengal 700016, India', '2026-07-10 13:00:00+05:30'),
('ord-1024', 'alum-1010', 'sess-1010', 'shipped',    1648.00,   0.00,  0.00, 1648.00, '14 CG Road, Ahmedabad, Gujarat 380009, India', '2026-07-13 10:45:00+05:30'),
('ord-1025', 'alum-1010', 'sess-1010', 'pending',    1947.00, 100.00,  0.00, 1847.00, '14 CG Road, Ahmedabad, Gujarat 380009, India', '2026-07-16 17:00:00+05:30')
ON CONFLICT (order_id) DO NOTHING;

INSERT INTO order_items (order_id, item_id, quantity, unit_price, line_total) VALUES
('ord-1001', 'item-1001', 1,  499.00,  499.00),
('ord-1001', 'item-1004', 2,  349.00,  698.00),
('ord-1002', 'item-1010', 1,  299.00,  299.00),
('ord-1002', 'item-1019', 1,  299.00,  299.00),
('ord-1003', 'item-1030', 1, 1499.00, 1499.00),
('ord-1004', 'item-1019', 2,  299.00,  598.00),
('ord-1005', 'item-1002', 1, 1299.00, 1299.00),
('ord-1005', 'item-1021', 1,  449.00,  449.00),
('ord-1006', 'item-1003', 1,  799.00,  799.00),
('ord-1007', 'item-1004', 1,  349.00,  349.00),
('ord-1008', 'item-1047', 1, 1899.00, 1899.00),
('ord-1009', 'item-1054', 1, 1599.00, 1599.00),
('ord-1010', 'item-1029', 2,  249.00,  498.00),
('ord-1010', 'item-1034', 1,  349.00,  349.00),
('ord-1011', 'item-1048', 1,  399.00,  399.00),
('ord-1011', 'item-1052', 2,  149.00,  298.00),
('ord-1012', 'item-1071', 1, 1299.00, 1299.00),
('ord-1013', 'item-1074', 1, 1499.00, 1499.00),
('ord-1014', 'item-1006', 1, 1799.00, 1799.00),
('ord-1015', 'item-1014', 1, 1599.00, 1599.00),
('ord-1016', 'item-1019', 1,  299.00,  299.00),
('ord-1016', 'item-1029', 1,  249.00,  249.00),
('ord-1016', 'item-1052', 1,  149.00,  149.00),
('ord-1017', 'item-1057', 1,  599.00,  599.00),
('ord-1018', 'item-1009', 1,  599.00,  599.00),
('ord-1019', 'item-1062', 1, 1299.00, 1299.00),
('ord-1020', 'item-1066', 1,  899.00,  899.00),
('ord-1020', 'item-1064', 1,  499.00,  499.00),
('ord-1021', 'item-1047', 1, 1899.00, 1899.00),
('ord-1021', 'item-1049', 1,  599.00,  599.00),
('ord-1022', 'item-1075', 1,  999.00,  999.00),
('ord-1023', 'item-1072', 1,  799.00,  799.00),
('ord-1023', 'item-1070', 1,  599.00,  599.00),
('ord-1024', 'item-1002', 1, 1299.00, 1299.00),
('ord-1024', 'item-1004', 1,  349.00,  349.00),
('ord-1025', 'item-1030', 1, 1499.00, 1499.00),
('ord-1025', 'item-1044', 1,  249.00,  249.00),
('ord-1025', 'item-1038', 1,  199.00,  199.00)
ON CONFLICT (order_id, item_id) DO NOTHING;

\echo 'ShopAssist :: seed_orders.sql loaded (25 orders, 38 order items).'
