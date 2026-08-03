-- Seed: 80,000 reviews.

INSERT INTO reviews (product_id, user_id, order_id, rating, title, content, status, created_at)
SELECT
    (floor(random() * 100000) + 1)::bigint,
    (floor(random() * 50000) + 1)::bigint,
    CASE WHEN random() < 0.7 THEN (floor(random() * 150000) + 1)::bigint ELSE NULL END,
    (floor(random() * 5) + 1)::smallint,
    'Review title ' || gs,
    'Sản phẩm dùng tốt, đóng gói cẩn thận, giao hàng nhanh. Review #' || gs,
    'APPROVED',
    now() - (random() * interval '365 days')
FROM generate_series(1, 80000) AS gs;
