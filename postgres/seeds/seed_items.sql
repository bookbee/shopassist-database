-- ShopAssist :: seed data - item catalog (IISc alumni shop merchandise)
-- 75 items across six categories, priced in INR, with explicit,
-- human-readable IDs (item-1001 ...) so order_items in seed_orders.sql can
-- reference them deterministically.
--
-- The rating/rating_count/discount_percentage/img_link/product_link
-- columns are left unset here: they exist for the Amazon-style product CSV
-- that shopassist-service's RAG pipeline ingests (see ../schema/schema.sql),
-- and this hand-written catalog predates that dataset - all five are
-- nullable for exactly this reason. See ../../README.md.

\echo 'ShopAssist :: loading seed_items.sql (items) ...'

INSERT INTO items (item_id, name, description, category, price, mrp, stock_quantity, is_active) VALUES
-- Apparel (18)
('item-1001', 'IISc Crest T-Shirt', 'Cotton crew-neck tee with the institute crest embroidered on the chest', 'Apparel', 499.00, 558.88, 150, TRUE),
('item-1002', 'IISc Alumni Hoodie', 'Fleece-lined pullover hoodie with ''IISc Alumni'' print on the back', 'Apparel', 1299.00, 1454.88, 80, TRUE),
('item-1003', 'IISc Polo Shirt', 'Pique cotton polo with embroidered institute crest', 'Apparel', 799.00, 894.88, 120, TRUE),
('item-1004', 'IISc Baseball Cap', 'Adjustable cotton cap with embroidered logo', 'Apparel', 349.00, 390.88, 200, TRUE),
('item-1005', 'IISc Convocation Stole', 'Silk-blend stole in institute colours, worn at convocation', 'Apparel', 899.00, 1006.88, 60, TRUE),
('item-1006', 'IISc Alumni Jacket', 'Windcheater jacket with alumni print on the back', 'Apparel', 1799.00, 2014.88, 45, TRUE),
('item-1007', 'IISc Zip-Up Sweatshirt', 'Cotton fleece zip-up hoodie with crest patch', 'Apparel', 1199.00, 1342.88, 70, TRUE),
('item-1008', 'IISc Crest Snapback Cap', 'Flat-brim snapback cap with embroidered crest', 'Apparel', 399.00, 446.88, 90, TRUE),
('item-1009', 'IISc Alumni Scarf', 'Woven scarf in institute colours', 'Apparel', 599.00, 670.88, 55, TRUE),
('item-1010', 'IISc Institute Socks (Pack of 3)', 'Cotton crew socks with crest motif, pack of 3', 'Apparel', 299.00, 334.88, 180, TRUE),
('item-1011', 'IISc Women''s Fit Crest Tee', 'Fitted crew-neck tee with crest print', 'Apparel', 549.00, 614.88, 100, TRUE),
('item-1012', 'IISc Alumni Track Pants', 'Cotton-blend joggers with side stripe', 'Apparel', 999.00, 1118.88, 65, TRUE),
('item-1013', 'IISc Crest Muffler', 'Winter muffler in maroon and gold', 'Apparel', 449.00, 502.88, 70, TRUE),
('item-1014', 'IISc Alumni Rain Jacket', 'Packable waterproof shell jacket', 'Apparel', 1599.00, 1790.88, 40, TRUE),
('item-1015', 'IISc Institute Bandana', 'Printed cotton bandana with crest motif', 'Apparel', 199.00, 222.88, 120, TRUE),
('item-1016', 'IISc Convocation Pin Set', 'Enamel pin set for convocation blazers', 'Apparel', 249.00, 278.88, 150, TRUE),
('item-1017', 'IISc Alumni Beanie', 'Ribbed knit winter cap with crest patch', 'Apparel', 349.00, 390.88, 85, TRUE),
('item-1018', 'IISc Crest Golf Tee', 'Moisture-wicking polo for sports events', 'Apparel', 849.00, 950.88, 60, TRUE),
-- Drinkware (10)
('item-1019', 'IISc Ceramic Mug', '320ml ceramic mug printed with the institute crest', 'Drinkware', 299.00, 334.88, 250, TRUE),
('item-1020', 'IISc Steel Tumbler', 'Double-walled stainless steel tumbler, 500ml', 'Drinkware', 599.00, 670.88, 150, TRUE),
('item-1021', 'IISc Insulated Water Bottle', '750ml vacuum-insulated bottle, keeps drinks cold for 24h', 'Drinkware', 449.00, 502.88, 180, TRUE),
('item-1022', 'IISc Travel Coffee Mug', '350ml spill-proof travel mug', 'Drinkware', 549.00, 614.88, 100, TRUE),
('item-1023', 'IISc Copper Water Bottle', '1L pure copper bottle, Ayurvedic design', 'Drinkware', 699.00, 782.88, 90, TRUE),
('item-1024', 'IISc Glass Sipper Bottle', '600ml borosilicate glass bottle with silicone sleeve', 'Drinkware', 499.00, 558.88, 110, TRUE),
('item-1025', 'IISc Crest Beer Mug', '400ml oversized ceramic mug with crest', 'Drinkware', 349.00, 390.88, 130, TRUE),
('item-1026', 'IISc Insulated Coffee Flask', '500ml flask, keeps beverages hot for 12h', 'Drinkware', 799.00, 894.88, 75, TRUE),
('item-1027', 'IISc Kids Sipper Bottle', '400ml BPA-free sipper bottle for young alumni', 'Drinkware', 299.00, 334.88, 95, TRUE),
('item-1028', 'IISc Wine Tumbler Set (2)', 'Stainless steel stemless wine tumblers, set of 2', 'Drinkware', 899.00, 1006.88, 50, TRUE),
-- Stationery (18)
('item-1029', 'IISc Hardbound Notebook', 'A5 ruled notebook with a debossed institute crest', 'Stationery', 249.00, 278.88, 300, TRUE),
('item-1030', 'IISc Centenary Coffee Table Book', 'Hardbound pictorial history of the institute', 'Stationery', 1499.00, 1678.88, 40, TRUE),
('item-1031', 'IISc Desk Diary', 'A5 dated diary with ribbon bookmark', 'Stationery', 399.00, 446.88, 120, TRUE),
('item-1032', 'IISc Sticky Notes Set', 'Crest-branded sticky note pad set', 'Stationery', 149.00, 166.88, 200, TRUE),
('item-1033', 'IISc Fountain Pen', 'Institute-branded fountain pen with gift case', 'Stationery', 899.00, 1006.88, 55, TRUE),
('item-1034', 'IISc Ballpoint Pen Set (3)', 'Crest-engraved metal ballpoint pens, set of 3', 'Stationery', 349.00, 390.88, 140, TRUE),
('item-1035', 'IISc Notebook & Sleeve Combo', 'Notebook and matching laptop sleeve gift set', 'Stationery', 999.00, 1118.88, 45, TRUE),
('item-1036', 'IISc Desk Calendar', 'Annual desk calendar with campus photography', 'Stationery', 299.00, 334.88, 160, TRUE),
('item-1037', 'IISc Sketchbook', 'A4 spiral-bound sketchbook, blank pages', 'Stationery', 349.00, 390.88, 90, TRUE),
('item-1038', 'IISc Bookmark Set (5)', 'Metal bookmarks with crest cutout, set of 5', 'Stationery', 199.00, 222.88, 170, TRUE),
('item-1039', 'IISc File Folder Set', 'Set of 3 ring-binder folders with crest', 'Stationery', 449.00, 502.88, 100, TRUE),
('item-1040', 'IISc Sticky Flag Set', 'Assorted page-marker flags', 'Stationery', 129.00, 144.88, 220, TRUE),
('item-1041', 'IISc Wall Planner', 'Yearly wall planner with campus map', 'Stationery', 349.00, 390.88, 80, TRUE),
('item-1042', 'IISc Highlighter Set (5)', 'Pastel highlighter set in crest pouch', 'Stationery', 249.00, 278.88, 150, TRUE),
('item-1043', 'IISc Correction Tape Set', 'Twin-pack correction tape', 'Stationery', 149.00, 166.88, 190, TRUE),
('item-1044', 'IISc Institute Postcard Set', 'Campus photography postcard set, pack of 10', 'Stationery', 249.00, 278.88, 130, TRUE),
('item-1045', 'IISc Greeting Card Set', 'Alumni-themed greeting cards, pack of 6', 'Stationery', 299.00, 334.88, 100, TRUE),
('item-1046', 'IISc Exam Pad', 'A4 hardboard clipboard exam pad', 'Stationery', 199.00, 222.88, 140, TRUE),
-- Bags & Accessories (14)
('item-1047', 'IISc Laptop Backpack', 'Padded 15.6-inch laptop backpack with crest', 'Bags & Accessories', 1899.00, 2126.88, 60, TRUE),
('item-1048', 'IISc Canvas Tote Bag', 'Cotton canvas tote bag with alumni print', 'Bags & Accessories', 399.00, 446.88, 150, TRUE),
('item-1049', 'IISc Laptop Sleeve', 'Neoprene 14-inch laptop sleeve', 'Bags & Accessories', 599.00, 670.88, 100, TRUE),
('item-1050', 'IISc Drawstring Gym Bag', 'Polyester drawstring sports bag', 'Bags & Accessories', 349.00, 390.88, 120, TRUE),
('item-1051', 'IISc Leather Wallet', 'Bifold leather wallet with debossed crest', 'Bags & Accessories', 799.00, 894.88, 70, TRUE),
('item-1052', 'IISc Crest Keychain', 'Enamel metal keychain with institute crest', 'Bags & Accessories', 149.00, 166.88, 250, TRUE),
('item-1053', 'IISc Lanyard', 'Woven lanyard with breakaway safety clip', 'Bags & Accessories', 129.00, 144.88, 300, TRUE),
('item-1054', 'IISc Duffel Bag', 'Weekend duffel bag with shoe compartment', 'Bags & Accessories', 1599.00, 1790.88, 40, TRUE),
('item-1055', 'IISc Passport Cover', 'Faux-leather passport holder, embossed crest', 'Bags & Accessories', 349.00, 390.88, 110, TRUE),
('item-1056', 'IISc Card Holder', 'Slim RFID-blocking card holder', 'Bags & Accessories', 299.00, 334.88, 130, TRUE),
('item-1057', 'IISc Crest Umbrella', '3-fold auto-open umbrella with crest print', 'Bags & Accessories', 599.00, 670.88, 90, TRUE),
('item-1058', 'IISc Tote Cooler Bag', 'Insulated lunch/cooler tote bag', 'Bags & Accessories', 649.00, 726.88, 75, TRUE),
('item-1059', 'IISc Sling Bag', 'Crossbody sling bag with crest patch', 'Bags & Accessories', 799.00, 894.88, 65, TRUE),
('item-1060', 'IISc Luggage Tag Set (2)', 'Leatherette luggage tags with name card, set of 2', 'Bags & Accessories', 249.00, 278.88, 140, TRUE),
-- Home & Decor (9)
('item-1061', 'IISc Photo Frame', 'Wooden desk photo frame with engraved crest', 'Home & Decor', 399.00, 446.88, 100, TRUE),
('item-1062', 'IISc Campus Wall Art Print', 'Framed print of the institute''s main building', 'Home & Decor', 1299.00, 1454.88, 40, TRUE),
('item-1063', 'IISc Desk Organizer', 'Wooden multi-slot desk organizer', 'Home & Decor', 699.00, 782.88, 70, TRUE),
('item-1064', 'IISc Crest Paperweight', 'Brass paperweight with engraved crest', 'Home & Decor', 499.00, 558.88, 90, TRUE),
('item-1065', 'IISc Coaster Set (6)', 'Wooden coaster set with campus motifs, set of 6', 'Home & Decor', 449.00, 502.88, 110, TRUE),
('item-1066', 'IISc Table Clock', 'Wooden desk clock with crest dial', 'Home & Decor', 899.00, 1006.88, 55, TRUE),
('item-1067', 'IISc Wall Clock', 'Analog wall clock in institute colours', 'Home & Decor', 1099.00, 1230.88, 40, TRUE),
('item-1068', 'IISc Cushion Cover Set (2)', 'Printed cushion covers with crest motif, set of 2', 'Home & Decor', 599.00, 670.88, 80, TRUE),
('item-1069', 'IISc Wooden Nameplate', 'Engraved wooden desk nameplate', 'Home & Decor', 549.00, 614.88, 60, TRUE),
-- Electronics & Gadgets (6)
('item-1070', 'IISc USB Flash Drive 32GB', 'Metal-body pen drive with crest engraving', 'Electronics', 599.00, 670.88, 100, TRUE),
('item-1071', 'IISc Power Bank 10000mAh', 'Compact power bank with crest print', 'Electronics', 1299.00, 1454.88, 70, TRUE),
('item-1072', 'IISc Wireless Mouse', 'Ergonomic wireless mouse in institute colours', 'Electronics', 799.00, 894.88, 65, TRUE),
('item-1073', 'IISc Mobile Stand', 'Foldable aluminium phone/tablet stand', 'Electronics', 349.00, 390.88, 120, TRUE),
('item-1074', 'IISc Bluetooth Speaker', 'Portable Bluetooth speaker with crest badge', 'Electronics', 1499.00, 1678.88, 50, TRUE),
('item-1075', 'IISc Laptop Cooling Pad', 'USB-powered laptop cooling pad, dual fan', 'Electronics', 999.00, 1118.88, 45, TRUE)
ON CONFLICT (item_id) DO NOTHING;

\echo 'ShopAssist :: seed_items.sql loaded (75 items).'
