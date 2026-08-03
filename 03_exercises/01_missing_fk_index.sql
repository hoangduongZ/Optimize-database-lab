-- BÀI 01: Postgres KHÔNG tự tạo index cho foreign key.
-- Mục tiêu: thấy rõ seq scan trên bảng lớn khi lọc/join theo cột FK chưa có index,
-- rồi tự sửa bằng cách thêm index.

-- ============================================================
-- PROBLEM: lấy toàn bộ đơn hàng của 1 khách hàng.
-- orders có 150,000 dòng, customer_id chưa có index (chỉ có PK trên id).
-- ============================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, order_number, order_status, total_amount, placed_at
FROM orders
WHERE customer_id = 1234;

-- Quan sát: "Seq Scan on orders" quét toàn bộ 150k dòng để tìm ~3 dòng khớp.
-- Thử thêm join thực tế hay gặp: đơn hàng + tên khách hàng.
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.id, o.order_number, u.email
FROM orders o
JOIN users u ON u.id = o.customer_id
WHERE o.customer_id = 1234;

-- ============================================================
-- TỰ LÀM: viết CREATE INDEX cho orders.customer_id, chạy lại EXPLAIN ở trên,
-- so sánh execution time và loại scan (Index Scan / Bitmap Index Scan).
-- ============================================================


-- ============================================================
-- SOLUTION (mở comment sau khi đã tự thử)
-- ============================================================
-- CREATE INDEX idx_orders_customer_id ON orders (customer_id);
--
-- Áp dụng nguyên tắc tương tự cho các FK khác hay bị lọc/join trực tiếp:
-- CREATE INDEX idx_order_items_order_id       ON order_items (order_id);
-- CREATE INDEX idx_order_items_product_id     ON order_items (product_id);
-- CREATE INDEX idx_reviews_product_id         ON reviews (product_id);
-- CREATE INDEX idx_addresses_user_id          ON addresses (user_id);
-- CREATE INDEX idx_payments_order_id          ON payments (order_id);
-- CREATE INDEX idx_order_status_history_order_id ON order_status_history (order_id);
--
-- Lưu ý: KHÔNG index mọi FK "cho chắc" -- mỗi index tốn thêm chi phí ghi
-- (INSERT/UPDATE phải cập nhật index) và dung lượng đĩa. Chỉ index cột thực sự
-- dùng để lọc/join/sort trong query pattern thật của ứng dụng.
