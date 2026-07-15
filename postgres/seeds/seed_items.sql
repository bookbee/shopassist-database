-- ShopAssist :: seed data - item catalog (IISc alumni shop merchandise)
-- 25 items across five categories, priced in INR, with explicit,
-- human-readable IDs (item-1001 ...) so order_items in seed_orders.sql can
-- reference them deterministically.

\echo 'ShopAssist :: loading seed_items.sql (items) ...'

INSERT INTO items (item_id, name, description, category, price, mrp, stock_quantity, is_active) VALUES
('item-1001', 'IISc Crest T-Shirt', 'Cotton crew-neck tee with the institute crest embroidered on the chest', 'Apparel', 499.00, 558.88, 150, TRUE),
('item-1002', 'IISc Alumni Hoodie', 'Fleece-lined pullover hoodie with ''IISc Alumni'' print on the back', 'Apparel', 1299.00, 1454.88, 80, TRUE),
('item-1003', 'IISc Polo Shirt', 'Pique cotton polo with embroidered institute crest', 'Apparel', 799.00, 894.88, 120, TRUE),
('item-1004', 'IISc Baseball Cap', 'Adjustable cotton cap with embroidered logo', 'Apparel', 349.00, 390.88, 200, TRUE),
('item-1005', 'IISc Convocation Stole', 'Silk-blend stole in institute colours, worn at convocation', 'Apparel', 899.00, 1006.88, 60, TRUE),
('item-1006', 'IISc Ceramic Mug', '320ml ceramic mug printed with the institute crest', 'Drinkware', 299.00, 334.88, 250, TRUE),
('item-1007', 'IISc Steel Tumbler', 'Double-walled stainless steel tumbler, 500ml', 'Drinkware', 599.00, 670.88, 150, TRUE),
('item-1008', 'IISc Insulated Water Bottle', '750ml vacuum-insulated bottle, keeps drinks cold for 24h', 'Drinkware', 449.00, 502.88, 180, TRUE),
('item-1009', 'IISc Centenary Coffee Table Book', 'Hardbound pictorial history of the institute', 'Stationery', 1499.00, 1678.88, 40, TRUE),
('item-1010', 'IISc Hardbound Notebook', 'A5 ruled notebook with a debossed institute crest', 'Stationery', 249.00, 278.88, 300, TRUE),
('item-1011', 'IISc Premium Pen Set', 'Twin ballpoint and roller pen gift set in a branded case', 'Stationery', 599.00, 670.88, 100, TRUE),
('item-1012', 'IISc Desk Diary', 'A5 dated diary with the academic calendar', 'Stationery', 349.00, 390.88, 150, TRUE),
('item-1013', 'IISc Table Calendar', 'Desk calendar featuring campus photography', 'Stationery', 199.00, 222.88, 200, TRUE),
('item-1014', 'IISc Canvas Tote Bag', 'Heavy-duty cotton canvas tote, screen-printed logo', 'Bags', 349.00, 390.88, 220, TRUE),
('item-1015', 'IISc Laptop Backpack', 'Padded 15.6" laptop compartment, water-resistant fabric', 'Bags', 1799.00, 2014.88, 70, TRUE),
('item-1016', 'IISc Laptop Sleeve', 'Neoprene sleeve, fits up to 14" laptops', 'Bags', 699.00, 782.88, 130, TRUE),
('item-1017', 'IISc Duffel Gym Bag', '40L duffel bag with a separate shoe compartment', 'Bags', 1499.00, 1678.88, 50, TRUE),
('item-1018', 'IISc Enamel Lapel Pin', 'Metal enamel pin of the institute crest', 'Accessories', 149.00, 166.88, 400, TRUE),
('item-1019', 'IISc Keychain', 'Metal keychain with a laser-engraved logo', 'Accessories', 129.00, 144.48, 350, TRUE),
('item-1020', 'IISc Lanyard with ID Holder', 'Woven lanyard with a clear ID card holder', 'Accessories', 179.00, 200.48, 300, TRUE),
('item-1021', 'IISc Fridge Magnet', 'Acrylic fridge magnet featuring the Main Building', 'Accessories', 99.00, 110.88, 400, TRUE),
('item-1022', 'IISc Desk Nameplate', 'Engraved wooden desk nameplate', 'Accessories', 599.00, 670.88, 90, TRUE),
('item-1023', 'IISc Umbrella', '3-fold auto-open umbrella with institute branding', 'Accessories', 499.00, 558.88, 140, TRUE),
('item-1024', 'IISc Wall Clock', 'Wooden-frame wall clock with the institute crest', 'Accessories', 899.00, 1006.88, 60, TRUE),
('item-1025', 'IISc Convocation Photo Frame', 'Engraved photo frame for convocation keepsakes', 'Accessories', 399.00, 446.88, 110, TRUE)
ON CONFLICT (item_id) DO NOTHING;

\echo 'ShopAssist :: seed_items.sql loaded (25 items).'
