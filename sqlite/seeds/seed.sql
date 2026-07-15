-- ShopAssist :: SQLite seed data (IISc alumni shop merchandise, INR pricing)
-- Lightweight sample dataset for local development. Safe to re-run after
-- reset_db.py recreates the schema.
--
-- customer_id / item_id / order_id are explicit, human-readable IDs
-- (cust-1001, item-1001, ord-1001 ...), same idea as session_id already
-- being a recognizable token instead of an opaque integer.
--
-- order_id ord-2001 / ord-2002 are seeded explicitly (outside the regular
-- ord-1001..ord-1005 sequence) so they match the order IDs
-- shopassist's main_simulation.py exercises out of the box.

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------------
-- customers (6)
-- ---------------------------------------------------------------------------
INSERT INTO customers (customer_id, first_name, last_name, email, phone, address_line1, city, state, postal_code, country) VALUES
('cust-1001', 'Aarav', 'Sharma', 'aarav.sharma@example.com', '+91-98450-12345', '12 MG Road', 'Bengaluru', 'Karnataka', '560001', 'India'),
('cust-1002', 'Ananya', 'Iyer', 'ananya.iyer@example.com', '+91-90030-22345', '45 Anna Salai', 'Chennai', 'Tamil Nadu', '600002', 'India'),
('cust-1003', 'Rohan', 'Mehta', 'rohan.mehta@example.com', '+91-98200-33345', '7 Marine Drive', 'Mumbai', 'Maharashtra', '400002', 'India'),
('cust-1004', 'Priya', 'Nair', 'priya.nair@example.com', '+91-94470-44345', '23 MG Road', 'Kochi', 'Kerala', '682016', 'India'),
('cust-1005', 'Vikram', 'Reddy', 'vikram.reddy@example.com', '+91-90000-55345', '88 Banjara Hills', 'Hyderabad', 'Telangana', '500034', 'India'),
('cust-1006', 'Sneha', 'Deshpande', 'sneha.deshpande@example.com', '+91-98220-66345', '15 FC Road', 'Pune', 'Maharashtra', '411004', 'India');

-- ---------------------------------------------------------------------------
-- items (10)
-- ---------------------------------------------------------------------------
INSERT INTO items (item_id, name, description, category, price, mrp, stock_quantity) VALUES
('item-1001', 'IISc Crest T-Shirt', 'Cotton crew-neck tee with the institute crest embroidered on the chest', 'Apparel', 499.00, 558.88, 150),
('item-1002', 'IISc Alumni Hoodie', 'Fleece-lined pullover hoodie with ''IISc Alumni'' print on the back', 'Apparel', 1299.00, 1454.88, 80),
('item-1003', 'IISc Polo Shirt', 'Pique cotton polo with embroidered institute crest', 'Apparel', 799.00, 894.88, 120),
('item-1004', 'IISc Baseball Cap', 'Adjustable cotton cap with embroidered logo', 'Apparel', 349.00, 390.88, 200),
('item-1005', 'IISc Convocation Stole', 'Silk-blend stole in institute colours, worn at convocation', 'Apparel', 899.00, 1006.88, 60),
('item-1006', 'IISc Ceramic Mug', '320ml ceramic mug printed with the institute crest', 'Drinkware', 299.00, 334.88, 250),
('item-1007', 'IISc Steel Tumbler', 'Double-walled stainless steel tumbler, 500ml', 'Drinkware', 599.00, 670.88, 150),
('item-1008', 'IISc Insulated Water Bottle', '750ml vacuum-insulated bottle, keeps drinks cold for 24h', 'Drinkware', 449.00, 502.88, 180),
('item-1009', 'IISc Centenary Coffee Table Book', 'Hardbound pictorial history of the institute', 'Stationery', 1499.00, 1678.88, 40),
('item-1010', 'IISc Hardbound Notebook', 'A5 ruled notebook with a debossed institute crest', 'Stationery', 249.00, 278.88, 300);

-- ---------------------------------------------------------------------------
-- sessions (6)
-- ---------------------------------------------------------------------------
INSERT INTO sessions (session_id, customer_id, device_type, status) VALUES
('sess-1001', 'cust-1001', 'web', 'expired'),
('sess-1002', 'cust-1002', 'mobile', 'expired'),
('sess-1003', 'cust-1003', 'web', 'expired'),
('sess-1004', 'cust-1004', 'desktop', 'expired'),
('sess-1005', 'cust-1005', 'mobile', 'expired'),
('sess-1006', 'cust-1006', 'web', 'active');

-- ---------------------------------------------------------------------------
-- orders (7)
-- ---------------------------------------------------------------------------
INSERT INTO orders (order_id, customer_id, session_id, status, subtotal, discount, shipping_fee, total_amount, shipping_address, placed_at) VALUES
('ord-1001', 'cust-1001', 'sess-1001', 'delivered', 1197.00, 0.00, 0.00, 1197.00, '12 MG Road, Bengaluru, Karnataka 560001, India', '2026-06-20 14:32:00'),
('ord-1002', 'cust-1002', 'sess-1002', 'shipped', 249.00, 0.00, 49.00, 298.00, '45 Anna Salai, Chennai, Tamil Nadu 600002, India', '2026-06-25 09:10:00'),
('ord-1003', 'cust-1003', 'sess-1003', 'pending', 1499.00, 0.00, 0.00, 1499.00, '7 Marine Drive, Mumbai, Maharashtra 400002, India', '2026-07-01 17:45:00'),
('ord-1004', 'cust-1004', 'sess-1004', 'confirmed', 598.00, 0.00, 49.00, 647.00, '23 MG Road, Kochi, Kerala 682016, India', '2026-07-05 11:05:00'),
('ord-1005', 'cust-1005', 'sess-1005', 'delivered', 1748.00, 0.00, 0.00, 1748.00, '88 Banjara Hills, Hyderabad, Telangana 500034, India', '2026-07-08 08:20:00'),
('ord-2001', 'cust-1001', 'sess-1001', 'shipped', 799.00, 0.00, 49.00, 848.00, '12 MG Road, Bengaluru, Karnataka 560001, India', '2026-07-11 10:00:00'),
('ord-2002', 'cust-1001', 'sess-1001', 'pending', 349.00, 0.00, 49.00, 398.00, '12 MG Road, Bengaluru, Karnataka 560001, India', '2026-07-13 16:15:00');

-- ---------------------------------------------------------------------------
-- order_items (9)
-- ---------------------------------------------------------------------------
INSERT INTO order_items (order_id, item_id, quantity, unit_price, line_total) VALUES
('ord-1001', 'item-1001', 1, 499.00, 499.00),
('ord-1001', 'item-1004', 2, 349.00, 698.00),
('ord-1002', 'item-1010', 1, 249.00, 249.00),
('ord-1003', 'item-1009', 1, 1499.00, 1499.00),
('ord-1004', 'item-1006', 2, 299.00, 598.00),
('ord-1005', 'item-1002', 1, 1299.00, 1299.00),
('ord-1005', 'item-1008', 1, 449.00, 449.00),
('ord-2001', 'item-1003', 1, 799.00, 799.00),
('ord-2002', 'item-1004', 1, 349.00, 349.00);
