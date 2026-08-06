-- Seed: 500,000 users + profile + 1 address mặc định/user.
-- users.id và addresses.id đều là 1..500000 (ánh xạ 1-1) -> orders sau này dùng
-- customer_id = shipping_address_id = billing_address_id để đơn giản hoá.

INSERT INTO users (email, phone, password_hash, role, status, created_at)
SELECT
    'user' || gs || '@lab.local',
    '09' || lpad((gs % 100000000)::text, 8, '0'),
    -- password_hash giả (KHÔNG dùng để auth thật, chỉ để lấp cột NOT NULL)
    md5('password' || gs),
    'CUSTOMER',
    'ACTIVE',
    now() - (random() * interval '730 days')
FROM generate_series(1, 500000) AS gs;

INSERT INTO user_profiles (user_id, full_name, gender, dob, avatar_url)
SELECT
    gs,
    'User ' || gs,
    (ARRAY['MALE', 'FEMALE', 'OTHER'])[((gs % 3) + 1)],
    date '1980-01-01' + ((gs % 15000) || ' days')::interval,
    NULL
FROM generate_series(1, 500000) AS gs;

INSERT INTO addresses (user_id, full_name, phone, street, ward, district, city, country, type, is_default)
SELECT
    gs,
    'User ' || gs,
    '09' || lpad((gs % 100000000)::text, 8, '0'),
    gs || ' Main Street',
    'Ward ' || (gs % 20 + 1),
    'District ' || (gs % 12 + 1),
    (ARRAY['Ho Chi Minh', 'Ha Noi', 'Da Nang', 'Can Tho'])[((gs % 4) + 1)],
    'VN',
    'SHIPPING',
    true
FROM generate_series(1, 500000) AS gs;
