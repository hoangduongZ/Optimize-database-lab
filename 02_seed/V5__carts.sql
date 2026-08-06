-- Seed: 200,000 carts + 400,000 cart_items (2/cart).

INSERT INTO carts (customer_id, session_id, created_at, updated_at)
SELECT
    (floor(random() * 500000) + 1)::bigint,
    'sess-' || gs,
    now() - (random() * interval '30 days'),
    now()
FROM generate_series(1, 200000) AS gs;

-- random() phải tính trong SELECT list của subquery có FROM generate_series
-- trực tiếp (xem ghi chú ở đầu V3__products_catalog.sql) -- không bọc qua
-- CROSS JOIN LATERAL không tương quan, kẻo mọi dòng dùng chung 1 giá trị.
INSERT INTO cart_items (cart_id, product_id, variant_id, quantity, price_at_add_time)
SELECT
    ceil(base.gs / 2.0)::bigint,
    base.product_id,
    (base.product_id - 1) * 2 + 1,
    base.quantity,
    base.price
FROM (
    SELECT
        gs,
        (floor(random() * 300000) + 1)::bigint AS product_id,
        (floor(random() * 3) + 1)::int AS quantity,
        (500000 + floor(random() * 50000000))::numeric(15, 2) AS price
    FROM generate_series(1, 400000) AS gs
) AS base;
