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
-- Trả lời: từ là khi scan index tức dữ liệu của index đã được sắp xếp sau khi nó quay lại dữ liệu bảng chính trong heap để lấy dữ liệu, trong dữ liệu bảng này không được sắp xếp nên, ví dụ đi từ vị trí dữ liệu đầu tiên trong bảng index, nó phải nhảy lần lượt trong heap để tìm

-- Q2: hàm áp lên cột đã index sẽ vô hiệu hoá index đó.
CREATE INDEX IF NOT EXISTS idx_orders_placed_at ON orders (placed_at);
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE placed_at > now() - interval '25 days';               -- dùng index
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE date_trunc('day', placed_at) = current_date;         -- KHÔNG dùng index
-- Câu hỏi: sửa query thứ 2 thành dạng range (placed_at >= ... AND placed_at < ...)
-- để index dùng lại được, không cần thêm expression index.

-- Q3: đọc "Buffers: shared hit=... read=..." để phân biệt cache hit (RAM) và
-- disk read thật. Chạy CÙNG 1 query 2 lần liên tiếp, so sánh buffers ở lần 1 vs lần 2.
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM products WHERE category_id = 25;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM products WHERE category_id = 25;
-- Câu hỏi: vì sao lần 2 thường có "read" thấp hơn (hoặc =0) so với lần 1?
-- Lần 1 đọc từ disk, lần 2 đọc từ cache (RAM) -> giảm I/O. tuy có index nhưng vẫn phải đọc dữ liệu lần đầu từ heap, nếu dữ liệu đã được cache trong RAM thì lần 2 sẽ nhanh hơn.

-- Q4: estimated rows (trong "Seq Scan ... (cost=... rows=N)") vs actual rows
-- (trong "(actual time=... rows=M)"). Khi 2 số này lệch xa nhau, planner statistics
-- đang bị stale -> cần ANALYZE lại bảng.
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM order_items WHERE quantity = 3;
-- Câu hỏi: nếu estimate và actual lệch nhiều, lệnh nào cập nhật lại statistics
-- cho riêng bảng order_items? (gợi ý: không cần ANALYZE toàn bộ database).
ANALYZE order_items;