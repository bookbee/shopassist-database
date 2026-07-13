-- ShopAssist :: seed data - product catalog
-- 25 products across four categories, with explicit IDs so order_items in
-- seed_orders.sql can reference them deterministically.

\echo 'ShopAssist :: loading seed_products.sql (products) ...'

INSERT INTO products (id, sku, name, description, category, price, currency, stock_quantity, is_active) VALUES
(1,  'SKU-1001', 'Wireless Bluetooth Headphones',   'Over-ear headphones with 30h battery life',      'Electronics',        79.99,  'USD', 150, TRUE),
(2,  'SKU-1002', 'Noise Cancelling Earbuds',        'True wireless earbuds with active noise cancel', 'Electronics',        129.99, 'USD', 100, TRUE),
(3,  'SKU-1003', '4K Ultra HD Smart TV 55"',        '55-inch smart TV with HDR support',              'Electronics',        549.99, 'USD', 40,  TRUE),
(4,  'SKU-1004', 'Portable Bluetooth Speaker',      'Water-resistant portable speaker',               'Electronics',        49.99,  'USD', 200, TRUE),
(5,  'SKU-1005', 'Mechanical Gaming Keyboard',      'RGB backlit mechanical keyboard',                'Electronics',        89.99,  'USD', 120, TRUE),
(6,  'SKU-1006', 'Wireless Ergonomic Mouse',        'Ergonomic mouse with adjustable DPI',            'Electronics',        34.99,  'USD', 180, TRUE),
(7,  'SKU-1007', '27" LED Monitor',                 '27-inch 1440p IPS monitor',                      'Electronics',        219.99, 'USD', 60,  TRUE),
(8,  'SKU-1008', 'USB-C Fast Charger 65W',          'Compact GaN fast charger',                       'Electronics',        24.99,  'USD', 300, TRUE),
(9,  'SKU-1009', 'Smartwatch Series 5',             'Fitness tracking smartwatch',                    'Electronics',        199.99, 'USD', 90,  TRUE),
(10, 'SKU-2001', 'Men''s Running Shoes',            'Lightweight breathable running shoes',           'Apparel',            69.99,  'USD', 150, TRUE),
(11, 'SKU-2002', 'Women''s Yoga Leggings',          'High-waisted stretch leggings',                  'Apparel',            39.99,  'USD', 200, TRUE),
(12, 'SKU-2003', 'Unisex Cotton T-Shirt',           '100% cotton crew neck t-shirt',                  'Apparel',            14.99,  'USD', 500, TRUE),
(13, 'SKU-2004', 'Men''s Denim Jacket',             'Classic fit denim jacket',                       'Apparel',            79.99,  'USD', 80,  TRUE),
(14, 'SKU-2005', 'Women''s Winter Parka',           'Insulated waterproof parka',                     'Apparel',            149.99, 'USD', 60,  TRUE),
(15, 'SKU-2006', 'Kids'' Rain Boots',               'Waterproof rain boots for kids',                 'Apparel',            24.99,  'USD', 100, TRUE),
(16, 'SKU-3001', 'Stainless Steel Cookware Set',    '10-piece stainless steel cookware set',          'Home & Kitchen',     129.99, 'USD', 45,  TRUE),
(17, 'SKU-3002', 'Non-Stick Frying Pan 12"',        '12-inch non-stick frying pan',                   'Home & Kitchen',     29.99,  'USD', 150, TRUE),
(18, 'SKU-3003', 'Electric Kettle 1.7L',            'Fast-boil electric kettle',                      'Home & Kitchen',     34.99,  'USD', 130, TRUE),
(19, 'SKU-3004', 'Robot Vacuum Cleaner',            'Smart robot vacuum with app control',            'Home & Kitchen',     299.99, 'USD', 35,  TRUE),
(20, 'SKU-3005', 'Memory Foam Pillow',              'Contour memory foam pillow',                     'Home & Kitchen',     44.99,  'USD', 160, TRUE),
(21, 'SKU-3006', 'Cotton Bed Sheet Set Queen',      '4-piece queen size cotton sheet set',            'Home & Kitchen',     59.99,  'USD', 120, TRUE),
(22, 'SKU-4001', 'Yoga Mat Premium',                'Non-slip extra thick yoga mat',                  'Sports & Outdoors',  29.99,  'USD', 200, TRUE),
(23, 'SKU-4002', 'Adjustable Dumbbell Set',         'Space-saving adjustable dumbbells',              'Sports & Outdoors',  199.99, 'USD', 50,  TRUE),
(24, 'SKU-4003', 'Insulated Water Bottle 1L',       'Vacuum insulated stainless steel bottle',        'Sports & Outdoors',  19.99,  'USD', 300, TRUE),
(25, 'SKU-4004', 'Camping Tent 4-Person',           'Weatherproof 4-person camping tent',             'Sports & Outdoors',  149.99, 'USD', 40,  TRUE)
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('products', 'id'), COALESCE((SELECT MAX(id) FROM products), 1));

\echo 'ShopAssist :: seed_products.sql loaded (25 products).'
