-- ShopAssist :: seed data - sessions
-- One session per customer, explicit IDs so seed_orders.sql can link an
-- order back to the session it was placed in. session_id stays a real UUID
-- (the column is UUID-typed) rather than a cust-1001-style business key.

\echo 'ShopAssist :: loading seed_sessions.sql (sessions) ...'

INSERT INTO sessions (session_id, customer_id, ip_address, user_agent, device_type, status) VALUES
('11111111-1111-1111-1111-000000000001', 'cust-1001', '203.0.113.11', 'Mozilla/5.0 (compatible; ShopAssistDemo/1.0)', 'web', 'expired'),
('11111111-1111-1111-1111-000000000002', 'cust-1002', '203.0.113.12', 'Mozilla/5.0 (compatible; ShopAssistDemo/1.0)', 'mobile', 'expired'),
('11111111-1111-1111-1111-000000000003', 'cust-1003', '203.0.113.13', 'Mozilla/5.0 (compatible; ShopAssistDemo/1.0)', 'web', 'expired'),
('11111111-1111-1111-1111-000000000004', 'cust-1004', '203.0.113.14', 'Mozilla/5.0 (compatible; ShopAssistDemo/1.0)', 'desktop', 'expired'),
('11111111-1111-1111-1111-000000000005', 'cust-1005', '203.0.113.15', 'Mozilla/5.0 (compatible; ShopAssistDemo/1.0)', 'mobile', 'expired'),
('11111111-1111-1111-1111-000000000006', 'cust-1006', '203.0.113.16', 'Mozilla/5.0 (compatible; ShopAssistDemo/1.0)', 'web', 'expired'),
('11111111-1111-1111-1111-000000000007', 'cust-1007', '203.0.113.17', 'Mozilla/5.0 (compatible; ShopAssistDemo/1.0)', 'desktop', 'expired'),
('11111111-1111-1111-1111-000000000008', 'cust-1008', '203.0.113.18', 'Mozilla/5.0 (compatible; ShopAssistDemo/1.0)', 'mobile', 'expired'),
('11111111-1111-1111-1111-000000000009', 'cust-1009', '203.0.113.19', 'Mozilla/5.0 (compatible; ShopAssistDemo/1.0)', 'web', 'expired'),
('11111111-1111-1111-1111-000000000010', 'cust-1010', '203.0.113.20', 'Mozilla/5.0 (compatible; ShopAssistDemo/1.0)', 'desktop', 'active')
ON CONFLICT (session_id) DO NOTHING;

\echo 'ShopAssist :: seed_sessions.sql loaded (10 sessions).'
