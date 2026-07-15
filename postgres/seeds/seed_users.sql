-- ShopAssist :: seed data - customers ("users" of the ShopAssist platform)
-- 10 customers with explicit IDs so downstream seed files (orders) can
-- reference them deterministically. The identity sequence is bumped
-- afterwards so subsequent application inserts don't collide.

\echo 'ShopAssist :: loading seed_users.sql (customers) ...'

INSERT INTO customers (id, first_name, last_name, email, phone, address_line1, city, state, postal_code, country) VALUES
(1,  'Alice',    'Johnson', 'alice.johnson@example.com',   '+1-206-555-0101', '221 Pine St',        'Seattle',   'WA',  '98101', 'USA'),
(2,  'Brian',    'Smith',   'brian.smith@example.com',     '+1-512-555-0102', '48 Congress Ave',    'Austin',    'TX',  '73301', 'USA'),
(3,  'Carla',    'Gomez',   'carla.gomez@example.com',     '+1-305-555-0103', '900 Ocean Dr',       'Miami',     'FL',  '33139', 'USA'),
(4,  'David',    'Lee',     'david.lee@example.com',       '+1-408-555-0104', '77 Tech Way',        'San Jose',  'CA',  '95110', 'USA'),
(5,  'Emma',     'Wilson',  'emma.wilson@example.com',     '+1-303-555-0105', '15 Mile High Cir',   'Denver',    'CO',  '80202', 'USA'),
(6,  'Farhan',   'Ahmed',   'farhan.ahmed@example.com',    '+1-312-555-0106', '5 Lakeshore Dr',     'Chicago',   'IL',  '60601', 'USA'),
(7,  'Grace',    'Kim',     'grace.kim@example.com',       '+1-416-555-0107', '10 Bay St',          'Toronto',   'ON',  'M5J2R8', 'Canada'),
(8,  'Henry',    'Davis',   'henry.davis@example.com',     '+44-20-7946-0108', '1 Baker St',        'London',    NULL,  'NW1 6XE', 'United Kingdom'),
(9,  'Isabella', 'Rossi',   'isabella.rossi@example.com',  '+39-02-5550-0109', 'Via Roma 12',       'Milan',     NULL,  '20121', 'Italy'),
(10, 'Jack',     'Turner',  'jack.turner@example.com',     '+61-2-5550-0110',  '25 George St',      'Sydney',    'NSW', '2000',  'Australia')
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('customers', 'id'), COALESCE((SELECT MAX(id) FROM customers), 1));

\echo 'ShopAssist :: seed_users.sql loaded (10 customers).'
