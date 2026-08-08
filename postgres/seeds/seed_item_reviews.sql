-- ShopAssist :: seed data - item_reviews
-- 10 product reviews with explicit, human-readable IDs (rev-1001 ...),
-- same convention as the other seed files.
--
-- Loads last: every row references both an item from seed_items.sql and a
-- customer from seed_customers.sql (item_reviews.user_id is a real FK to
-- customers - see schema.sql's note on why the reviewer's display name is
-- joined rather than stored).
--
-- The reviewers here happen to be reviewing items they actually bought in
-- seed_orders.sql, which is what shopassist-service's
-- EcommerceClient.add_review() enforces for new reviews (verified-purchase
-- check). The schema itself doesn't require it, so this is a property of
-- the seed data, not a constraint.

\echo 'ShopAssist :: loading seed_item_reviews.sql (item_reviews) ...'

INSERT INTO item_reviews (review_id, item_id, user_id, review_title, review_content) VALUES
('rev-1001', 'item-1001', 'alum-1001', 'Good quality', 'Fabric feels durable and the print hasn''t faded after several washes.'),
('rev-1002', 'item-1004', 'alum-1001', 'Fits well', 'Adjustable strap makes it comfortable for everyday wear.'),
('rev-1003', 'item-1002', 'alum-1005', 'Warm and cozy', 'Great for Bengaluru winters, the fleece lining is soft.'),
('rev-1004', 'item-1019', 'alum-1002', 'Nice mug', 'Crest print looks sharp, handle is sturdy.'),
('rev-1005', 'item-1019', 'alum-1004', 'As described', 'Good size for coffee, arrived well packaged.'),
('rev-1006', 'item-1029', 'alum-1003', 'Good paper quality', 'Ruled pages are smooth, no bleed-through with gel pens.'),
('rev-1007', 'item-1047', 'alum-1002', 'Sturdy backpack', 'Fits a 15-inch laptop easily, padding is solid.'),
('rev-1008', 'item-1047', 'alum-1009', 'Value for money', 'Zippers feel a bit light but overall happy with the purchase.'),
('rev-1009', 'item-1070', 'alum-1009', 'Fast transfer speeds', 'Metal body feels premium and transfer is quick.'),
('rev-1010', 'item-1074', 'alum-1005', 'Decent sound', 'Bass is a bit weak but fine for casual listening.')
ON CONFLICT (review_id) DO NOTHING;

\echo 'ShopAssist :: seed_item_reviews.sql loaded (10 item reviews).'
\echo 'ShopAssist :: PostgreSQL initialization completed successfully.'
