-- BÀI 05: Partial index -- khi chỉ cần index cho 1 tập con nhỏ, "nóng" của bảng lớn.
-- Trong seed data, order_status = 'PENDING' chỉ chiếm ~1/8 tổng số đơn (job quét đơn
-- hết hạn giữ hàng ở database-design.md §4.4 sẽ liên tục quét đúng tập này).

-- ============================================================
-- PROBLEM: job quét các đơn PENDING quá X phút để tự huỷ / giải phóng tồn kho.
-- ============================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, customer_id, placed_at
FROM orders
WHERE order_status = 'PENDING'
  AND placed_at < now() - interval '30 minutes';

-- ============================================================
-- TỰ LÀM: so sánh 2 lựa chọn index sau, xem cái nào nhỏ hơn và nhanh hơn cho
-- ĐÚNG truy vấn trên (dùng \di+ trong psql để xem kích thước index):
--
--   (a) Index thường trên toàn bảng:      (order_status, placed_at)
--   (b) Partial index chỉ cho PENDING:    (placed_at) WHERE order_status = 'PENDING'
-- ============================================================


-- ============================================================
-- SOLUTION
-- ============================================================
-- CREATE INDEX idx_orders_pending_placed_at
--     ON orders (placed_at)
--     WHERE order_status = 'PENDING';
--
-- Partial index chỉ chứa entry cho ~1/8 số dòng -> nhỏ hơn nhiều, ghi cũng rẻ hơn
-- (chỉ phải cập nhật index khi dòng đang/đang-trở-thành PENDING), và vẫn đủ dùng
-- vì mọi query của job quét luôn có điều kiện order_status = 'PENDING' khớp
-- chính xác với predicate của index.
--
-- Lưu ý quan trọng: điều kiện WHERE trong query PHẢI implies được predicate của
-- partial index (ở đây là order_status = 'PENDING') để planner chọn dùng nó.
-- Nếu quét với order_status IN ('PENDING', 'CONFIRMED') thì index này sẽ KHÔNG
-- được dùng cho toàn bộ query đó.
