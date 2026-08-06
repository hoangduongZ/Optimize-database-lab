-- BÀI 09: Luyện đọc EXPLAIN (ANALYZE, BUFFERS) -- không có "solution" ẩn, mục tiêu là
-- hiểu ĐÚNG output, không phải tối ưu thêm. Chạy từng query, trả lời câu hỏi kèm theo.

-- Q1: Seq Scan vs Index Scan tuỳ selectivity.
-- Cùng 1 cột có index (id là PK), nhưng điều kiện khác selectivity -> planner chọn
-- chiến lược khác nhau. Chạy cả 2, so sánh "Seq Scan" vs "Index Scan"/"Bitmap Heap Scan".
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE id < 5;          -- rất chọn lọc
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE id < 11000000;   -- gần như cả bảng
-- Câu hỏi: từ threshold (điểm) nào planner chuyển từ Index Scan sang Seq Scan? Vì sao
-- Seq Scan lại RẺ HƠN Index Scan khi phải đọc phần lớn bảng (gợi ý: random I/O vs
-- sequential I/O, và mỗi lần Index Scan nhảy vào heap là 1 lần đọc trang riêng lẻ).

-- Q2: hàm áp lên cột đã index sẽ vô hiệu hoá index đó.
CREATE INDEX IF NOT EXISTS idx_orders_placed_at ON orders (placed_at);
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE placed_at > now() - interval '7 days';               -- dùng index
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE date_trunc('day', placed_at) = current_date;         -- KHÔNG dùng index
-- Câu hỏi: sửa query thứ 2 thành dạng range (placed_at >= ... AND placed_at < ...)
-- để index dùng lại được, không cần thêm expression index.

-- Q3: đọc "Buffers: shared hit=... read=..." để phân biệt cache hit (RAM) và
-- disk read thật. Chạy CÙNG 1 query 2 lần liên tiếp, so sánh buffers ở lần 1 vs lần 2.
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM products WHERE category_id = 25;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM products WHERE category_id = 25;
-- Câu hỏi: vì sao lần 2 thường có "read" thấp hơn (hoặc =0) so với lần 1?

-- Q4: estimated rows (trong "Seq Scan ... (cost=... rows=N)") vs actual rows
-- (trong "(actual time=... rows=M)"). Khi 2 số này lệch xa nhau, planner statistics
-- đang bị stale -> cần ANALYZE lại bảng.
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM order_items WHERE quantity = 3;
-- Câu hỏi: nếu estimate và actual lệch nhiều, lệnh nào cập nhật lại statistics
-- cho riêng bảng order_items? (gợi ý: không cần ANALYZE toàn bộ database).
