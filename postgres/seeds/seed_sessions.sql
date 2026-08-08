-- ShopAssist :: seed data - sessions
-- One session per customer, explicit human-readable IDs (sess-1001 ...) so
-- seed_orders.sql can link an order back to the session it was placed in.
--
-- ip_address/user_agent are left unset - shopassist-service populates them
-- from live request context, not from seed data. See ../../README.md.

\echo 'ShopAssist :: loading seed_sessions.sql (sessions) ...'

INSERT INTO sessions (session_id, user_id, device_type, status) VALUES
('sess-1001', 'alum-1001', 'web', 'expired'),
('sess-1002', 'alum-1002', 'mobile', 'expired'),
('sess-1003', 'alum-1003', 'web', 'expired'),
('sess-1004', 'alum-1004', 'desktop', 'expired'),
('sess-1005', 'alum-1005', 'mobile', 'expired'),
('sess-1006', 'alum-1006', 'web', 'expired'),
('sess-1007', 'alum-1007', 'mobile', 'expired'),
('sess-1008', 'alum-1008', 'web', 'expired'),
('sess-1009', 'alum-1009', 'desktop', 'expired'),
('sess-1010', 'alum-1010', 'web', 'active')
ON CONFLICT (session_id) DO NOTHING;

\echo 'ShopAssist :: seed_sessions.sql loaded (10 sessions).'
