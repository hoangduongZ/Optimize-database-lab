-- BÀI 07: OFFSET pagination càng vào trang sau càng chậm -- kể cả khi mọi cột đã có index.
-- Keyset (cursor-based) pagination giữ tốc độ ổn định bất kể đang ở trang nào.

-- ============================================================
-- PROBLEM: trang quản trị đơn hàng, sort theo id giảm dần, "trang 3000" (offset sâu).
-- Giả định đã có index (placed_at) hoặc dùng PK id -- vẫn chậm vì OFFSET buộc
-- Postgres phải ĐỌC và BỎ hết N dòng đầu trước khi trả 20 dòng tiếp theo.
-- ============================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, order_number, order_status, placed_at
FROM orders
ORDER BY id DESC
OFFSET 60000 LIMIT 20;

-- So sánh với trang đầu (offset nhỏ) -- gần như luôn nhanh, dễ gây "ảo tưởng" là
-- pagination ổn khi mới demo/test với ít dữ liệu.
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, order_number, order_status, placed_at
FROM orders
ORDER BY id DESC
OFFSET 20 LIMIT 20;

-- ============================================================
-- TỰ LÀM: viết lại query "trang 3000" bằng keyset pagination -- client gửi lên
-- id nhỏ nhất đã thấy ở trang trước (last_seen_id), server lọc id < last_seen_id
-- thay vì OFFSET.
-- ============================================================


-- ============================================================
-- SOLUTION
-- ============================================================
-- Giả sử trang trước kết thúc ở id = 90000 (dòng cuối cùng client đã render):
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT id, order_number, order_status, placed_at
-- FROM orders
-- WHERE id < 90000
-- ORDER BY id DESC
-- LIMIT 20;
--
-- Query này luôn là Index Scan Backward + LIMIT 20, chi phí KHÔNG phụ thuộc vào
-- "đang ở trang bao nhiêu" -- vì Postgres dừng lại ngay khi đủ 20 dòng, không
-- cần đếm/bỏ qua các dòng phía trước.
--
-- Đánh đổi: keyset không cho nhảy thẳng tới "trang số N" tuỳ ý (chỉ có
-- next/prev tuần tự) -- chấp nhận được cho hầu hết UI dạng feed/infinite-scroll,
-- không phù hợp cho UI có ô nhập "đến trang số...".
