-- ShopAssist :: seed data - customers
-- 10 customers with explicit, human-readable IDs (alum-1001 ...) so
-- downstream seed files (sessions, orders) can reference them
-- deterministically, and so a developer can recognize a user_id at a
-- glance instead of chasing an opaque integer.
--
-- These are the user_ids shopassist-service resolves against: type one of
-- them as the "User ID" at shopassist-client's login to load that
-- customer's orders and history - see ../../README.md.

\echo 'ShopAssist :: loading seed_customers.sql (customers) ...'

INSERT INTO customers (user_id, first_name, last_name, email, phone, address_line1, city, state, postal_code, country) VALUES
('alum-1001', 'Aarav', 'Sharma', 'aarav.sharma@example.com', '+91-98450-12345', '12 MG Road', 'Bengaluru', 'Karnataka', '560001', 'India'),
('alum-1002', 'Ananya', 'Iyer', 'ananya.iyer@example.com', '+91-90030-22345', '45 Anna Salai', 'Chennai', 'Tamil Nadu', '600002', 'India'),
('alum-1003', 'Rohan', 'Mehta', 'rohan.mehta@example.com', '+91-98200-33345', '7 Marine Drive', 'Mumbai', 'Maharashtra', '400002', 'India'),
('alum-1004', 'Priya', 'Nair', 'priya.nair@example.com', '+91-94470-44345', '23 MG Road', 'Kochi', 'Kerala', '682016', 'India'),
('alum-1005', 'Vikram', 'Reddy', 'vikram.reddy@example.com', '+91-90000-55345', '88 Banjara Hills', 'Hyderabad', 'Telangana', '500034', 'India'),
('alum-1006', 'Sneha', 'Deshpande', 'sneha.deshpande@example.com', '+91-98220-66345', '15 FC Road', 'Pune', 'Maharashtra', '411004', 'India'),
('alum-1007', 'Ishan', 'Punekar', 'ishan.punekar@example.com', '+91-93717-66345', 'Fatima Nagar', 'Pune', 'Maharashtra', '411014', 'India'),
('alum-1008', 'Kavya', 'Rao', 'kavya.rao@example.com', '+91-99000-77345', '221 Connaught Place', 'New Delhi', 'Delhi', '110001', 'India'),
('alum-1009', 'Arjun', 'Bose', 'arjun.bose@example.com', '+91-98300-88345', '5 Park Street', 'Kolkata', 'West Bengal', '700016', 'India'),
('alum-1010', 'Meera', 'Iyengar', 'meera.iyengar@example.com', '+91-90990-99345', '14 CG Road', 'Ahmedabad', 'Gujarat', '380009', 'India')
ON CONFLICT (user_id) DO NOTHING;

\echo 'ShopAssist :: seed_customers.sql loaded (10 customers).'
