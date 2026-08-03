-- Seed: 150,000 orders + 300,000 order_items (2/order) + 300,000 order_status_history (2/order)
-- + 150,000 payments (1/order).
-- addresses.id == users.id (ánh xạ 1-1 ở V2) nên customer_id cũng dùng làm shipping/billing address.

INSERT INTO orders (order_number, customer_id, subtotal, discount_amount, shipping_fee, tax_fee,
                     total_amount, payment_method, payment_status, order_status, shipping_status,
                     shipping_provider, shipping_tracking_code, shipping_address_id, billing_address_id,
                     placed_at, updated_at)
SELECT
    'ORD-' || lpad(gs::text, 10, '0'),
    cust.customer_id,
    calc.subtotal,
    calc.discount_amount,
    calc.shipping_fee,
    0,
    calc.subtotal - calc.discount_amount + calc.shipping_fee,
    (ARRAY['COD', 'BANK_TRANSFER', 'VNPAY', 'MOMO'])[(floor(random() * 4) + 1)],
    (ARRAY['PENDING', 'PAID', 'FAILED', 'REFUNDED'])[(floor(random() * 4) + 1)],
    -- lệch tỉ lệ để PENDING là thiểu số -> hợp lý cho bài partial index (03_exercises/05)
    (ARRAY['CONFIRMED', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'DELIVERED', 'DELIVERED',
           'CANCELLED', 'PENDING'])[(floor(random() * 8) + 1)],
    (ARRAY['NOT_SHIPPED', 'SHIPPED', 'IN_TRANSIT', 'DELIVERED', 'RETURNED'])[(floor(random() * 5) + 1)],
    (ARRAY['GHTK', 'GHN', 'ViettelPost', 'J&T'])[(floor(random() * 4) + 1)],
    'TRACK' || gs,
    cust.customer_id,
    cust.customer_id,
    calc.placed_at,
    calc.placed_at + (random() * interval '5 days')
FROM generate_series(1, 150000) AS gs
CROSS JOIN LATERAL (SELECT (floor(random() * 50000) + 1)::bigint AS customer_id) AS cust
CROSS JOIN LATERAL (
    SELECT
        (200000 + floor(random() * 20000000))::numeric(15, 2) AS subtotal,
        (floor(random() * 500000))::numeric(15, 2) AS discount_amount,
        (CASE WHEN random() < 0.5 THEN 30000 ELSE 0 END)::numeric(15, 2) AS shipping_fee,
        now() - (random() * interval '365 days') AS placed_at
) AS calc;

-- 2 order_items / order
INSERT INTO order_items (order_id, product_id, variant_id, product_name_snapshot, sku_snapshot,
                          price_snapshot, quantity)
SELECT
    ceil(gs / 2.0)::bigint,
    p.product_id,
    (p.product_id - 1) * 2 + 1,
    'Product snapshot ' || p.product_id,
    'SKU-' || lpad(p.product_id::text, 8, '0'),
    (500000 + floor(random() * 50000000))::numeric(15, 2),
    (floor(random() * 3) + 1)::int
FROM generate_series(1, 300000) AS gs
CROSS JOIN LATERAL (SELECT (floor(random() * 100000) + 1)::bigint AS product_id) AS p;

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
