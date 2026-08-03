-- Seed: 20,000 carts + 40,000 cart_items (2/cart).

INSERT INTO carts (customer_id, session_id, created_at, updated_at)
SELECT
    (floor(random() * 50000) + 1)::bigint,
    'sess-' || gs,
    now() - (random() * interval '30 days'),
    now()
FROM generate_series(1, 20000) AS gs;

INSERT INTO cart_items (cart_id, product_id, variant_id, quantity, price_at_add_time)
SELECT
    ceil(gs / 2.0)::bigint,
    p.product_id,
    (p.product_id - 1) * 2 + 1,
    (floor(random() * 3) + 1)::int,
    (500000 + floor(random() * 50000000))::numeric(15, 2)
FROM generate_series(1, 40000) AS gs
CROSS JOIN LATERAL (SELECT (floor(random() * 100000) + 1)::bigint AS product_id) AS p;
