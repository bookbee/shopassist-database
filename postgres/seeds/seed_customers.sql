-- ShopAssist :: seed data - customers
-- 10 customers with explicit, human-readable IDs (cust-1001 ...) so
-- downstream seed files (sessions, orders) can reference them
-- deterministically, and so a developer can recognize a customer_id at a
-- glance instead of chasing an opaque integer.

\echo 'ShopAssist :: loading seed_customers.sql (customers) ...'

INSERT INTO customers (customer_id, first_name, last_name, email, phone, address_line1, city, state, postal_code, country) VALUES
('cust-1001', 'Aarav', 'Sharma', 'aarav.sharma@example.com', '+91-98450-12345', '12 MG Road', 'Bengaluru', 'Karnataka', '560001', 'India'),
('cust-1002', 'Ananya', 'Iyer', 'ananya.iyer@example.com', '+91-90030-22345', '45 Anna Salai', 'Chennai', 'Tamil Nadu', '600002', 'India'),
('cust-1003', 'Rohan', 'Mehta', 'rohan.mehta@example.com', '+91-98200-33345', '7 Marine Drive', 'Mumbai', 'Maharashtra', '400002', 'India'),
('cust-1004', 'Priya', 'Nair', 'priya.nair@example.com', '+91-94470-44345', '23 MG Road', 'Kochi', 'Kerala', '682016', 'India'),
('cust-1005', 'Vikram', 'Reddy', 'vikram.reddy@example.com', '+91-90000-55345', '88 Banjara Hills', 'Hyderabad', 'Telangana', '500034', 'India'),
('cust-1006', 'Sneha', 'Deshpande', 'sneha.deshpande@example.com', '+91-98220-66345', '15 FC Road', 'Pune', 'Maharashtra', '411004', 'India'),
('cust-1007', 'Arjun', 'Singh', 'arjun.singh@example.com', '+91-98100-77345', '5 Connaught Place', 'New Delhi', 'Delhi', '110001', 'India'),
('cust-1008', 'Kavya', 'Rao', 'kavya.rao@example.com', '+91-99000-88345', '30 Malleshwaram', 'Bengaluru', 'Karnataka', '560012', 'India'),
('cust-1009', 'Rahul', 'Banerjee', 'rahul.banerjee@example.com', '+91-98300-99345', '18 Park Street', 'Kolkata', 'West Bengal', '700016', 'India'),
('cust-1010', 'Neha', 'Joshi', 'neha.joshi@example.com', '+91-94140-10345', '9 C-Scheme', 'Jaipur', 'Rajasthan', '302001', 'India')
ON CONFLICT (customer_id) DO NOTHING;

\echo 'ShopAssist :: seed_customers.sql loaded (10 customers).'
