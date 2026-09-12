-- BÀI 08: N+1 query -- lỗi kinh điển khi ORM (JPA/Hibernate) lazy-load quan hệ trong loop.
-- Bài này mô phỏng ở tầng SQL thuần để thấy sự khác biệt số round-trip / tổng thời gian.

-- ============================================================
-- PROBLEM: hiển thị 50 đơn hàng gần nhất của 1 khách, kèm danh sách order_items.
-- Cách viết "N+1" (giống code lặp for-each order rồi query order_items riêng lẻ):
-- ============================================================
-- 1 query lấy danh sách order
EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM orders WHERE customer_id = 1234 ORDER BY placed_at DESC LIMIT 50;

-- rồi lặp N lần (ở đây minh hoạ với 1 order_id cụ thể, thực tế client lặp cho cả 50):
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM order_items WHERE order_id = 555;
-- => nếu có 50 đơn, tầng ứng dụng phải chạy query trên 50 LẦN, mỗi lần 1 round-trip
--    riêng đến DB -- tổng latency network cộng dồn dù mỗi query tự nó rất nhanh.

-- ============================================================
-- TỰ LÀM: viết 1 query DUY NHẤT lấy cả order + toàn bộ order_items tương ứng
-- bằng JOIN hoặc IN (subquery), thay cho 1 + N query riêng lẻ.
-- ============================================================


-- ============================================================
-- SOLUTION
-- ============================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.id AS order_id, o.order_number, o.placed_at,
       oi.id AS order_item_id, oi.product_name_snapshot, oi.quantity, oi.price_snapshot
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
WHERE o.customer_id = 1234
ORDER BY o.placed_at DESC
LIMIT 50;
--
-- Lưu ý: JOIN kiểu này trả nhiều dòng hơn (1 dòng / order_item, order bị lặp lại) --
-- ứng dụng cần group lại theo order_id ở tầng code. Đây là đánh đổi hợp lý: 1
-- round-trip DB + gộp dữ liệu ở app luôn rẻ hơn N round-trip DB.
--
-- Trong JPA/Hibernate, cách tránh N+1 tương đương là dùng JOIN FETCH / @EntityGraph
-- (hoặc batch fetching qua @BatchSize) thay cho lazy-load orderItems trong 1 loop.
