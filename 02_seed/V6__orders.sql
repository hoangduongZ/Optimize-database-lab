-- Seed: 12,000,000 orders + 24,000,000 order_items (2/order) + ~22,500,000 order_status_history
-- (derived: 1 PENDING/order + 1 thêm cho ~87.5% order không PENDING) + 12,000,000 payments (1/order).
-- Đây là các bảng transaction -- lệch tỉ lệ có chủ đích so với catalog (users/products) để
-- mô phỏng đúng 1 hệ thống lớn thật: catalog tăng chậm, transaction tăng theo traffic.
-- addresses.id == users.id (ánh xạ 1-1 ở V2) nên customer_id cũng dùng làm shipping/billing address.
--
-- QUAN TRỌNG: random() cần đa dạng theo dòng phải tính trong SELECT list của
-- 1 subquery có FROM là generate_series trực tiếp (xem ghi chú đầu
-- V3__products_catalog.sql) -- CROSS JOIN LATERAL với 1 derived table không
-- tương quan sẽ bị Postgres tính 1 LẦN DUY NHẤT cho cả statement.

INSERT INTO orders (order_number, customer_id, subtotal, discount_amount, shipping_fee, tax_fee,
                     total_amount, payment_method, payment_status, order_status, shipping_status,
                     shipping_provider, shipping_tracking_code, shipping_address_id, billing_address_id,
                     placed_at, updated_at)
SELECT
    'ORD-' || lpad(base.gs::text, 10, '0'),
    base.customer_id,
    base.subtotal,
    base.discount_amount,
    base.shipping_fee,
    0,
    base.subtotal - base.discount_amount + base.shipping_fee,
    (ARRAY['COD', 'BANK_TRANSFER', 'VNPAY', 'MOMO'])[base.payment_method_idx],
    (ARRAY['PENDING', 'PAID', 'FAILED', 'REFUNDED'])[base.payment_status_idx],
    -- lệch tỉ lệ để PENDING là thiểu số -> hợp lý cho bài partial index (03_exercises/05)
    (ARRAY['CONFIRMED', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'DELIVERED', 'DELIVERED',
           'CANCELLED', 'PENDING'])[base.order_status_idx],
    (ARRAY['NOT_SHIPPED', 'SHIPPED', 'IN_TRANSIT', 'DELIVERED', 'RETURNED'])[base.shipping_status_idx],
    (ARRAY['GHTK', 'GHN', 'ViettelPost', 'J&T'])[base.shipping_provider_idx],
    'TRACK' || base.gs,
    base.customer_id,
    base.customer_id,
    base.placed_at,
    base.placed_at + base.update_offset
FROM (
    SELECT
        gs,
        (floor(random() * 500000) + 1)::bigint AS customer_id,
        (200000 + floor(random() * 20000000))::numeric(15, 2) AS subtotal,
        (floor(random() * 500000))::numeric(15, 2) AS discount_amount,
        (CASE WHEN random() < 0.5 THEN 30000 ELSE 0 END)::numeric(15, 2) AS shipping_fee,
        now() - (random() * interval '365 days') AS placed_at,
        (random() * interval '5 days') AS update_offset,
        (floor(random() * 4) + 1)::int AS payment_method_idx,
        (floor(random() * 4) + 1)::int AS payment_status_idx,
        (floor(random() * 8) + 1)::int AS order_status_idx,
        (floor(random() * 5) + 1)::int AS shipping_status_idx,
        (floor(random() * 4) + 1)::int AS shipping_provider_idx
    FROM generate_series(1, 12000000) AS gs
) AS base;

-- 2 order_items / order
INSERT INTO order_items (order_id, product_id, variant_id, product_name_snapshot, sku_snapshot,
                          price_snapshot, quantity)
SELECT
    ceil(base.gs / 2.0)::bigint,
    base.product_id,
    (base.product_id - 1) * 2 + 1,
    'Product snapshot ' || base.product_id,
    'SKU-' || lpad(base.product_id::text, 8, '0'),
    base.price,
    base.quantity
FROM (
    SELECT
        gs,
        (floor(random() * 300000) + 1)::bigint AS product_id,
        (500000 + floor(random() * 50000000))::numeric(15, 2) AS price,
        (floor(random() * 3) + 1)::int AS quantity
    FROM generate_series(1, 24000000) AS gs
) AS base;

-- Lịch sử trạng thái: PENDING lúc tạo đơn + trạng thái hiện tại
INSERT INTO order_status_history (order_id, status, changed_at, note)
SELECT o.id, 'PENDING', o.placed_at, 'Order created'
FROM orders o;

INSERT INTO order_status_history (order_id, status, changed_at, note)
SELECT o.id, o.order_status, o.updated_at, 'Status updated'
FROM orders o
WHERE o.order_status <> 'PENDING';

-- 1 payment / order
INSERT INTO payments (order_id, method, amount, status, transaction_ref, created_at, paid_at)
SELECT
    o.id,
    o.payment_method,
    o.total_amount,
    CASE o.payment_status
        WHEN 'PAID' THEN 'SUCCESS'
        WHEN 'FAILED' THEN 'FAILED'
        WHEN 'REFUNDED' THEN 'REFUNDED'
        ELSE 'PENDING'
    END,
    'TXN-' || o.id,
    o.placed_at,
    CASE WHEN o.payment_status = 'PAID' THEN o.placed_at + interval '10 minutes' ELSE NULL END
FROM orders o;
