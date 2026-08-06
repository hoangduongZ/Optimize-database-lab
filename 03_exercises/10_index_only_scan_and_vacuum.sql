-- BÀI 10: Index Only Scan phụ thuộc vào visibility map, KHÔNG chỉ vào việc có index
-- chứa đủ cột hay không. Bài này cho thấy tác động của UPDATE + (chưa) VACUUM.

-- ============================================================
-- Bước 1: tạo covering index cho 1 truy vấn tồn kho hay dùng.
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_inventory_variant_covering
    ON inventory_items (variant_id)
    INCLUDE (quantity_available, quantity_reserved);
VACUUM inventory_items;

EXPLAIN (ANALYZE, BUFFERS)
SELECT quantity_available, quantity_reserved
FROM inventory_items
WHERE variant_id = 555;
-- Kỳ vọng: "Index Only Scan" với "Heap Fetches: 0" -- vì bảng vừa VACUUM,
-- visibility map xác nhận toàn bộ trang đều "all-visible".

-- ============================================================
-- Bước 2: mô phỏng traffic ghi liên tục (giống hệ thống reserve/release tồn kho
-- thật) rồi chạy lại query TRƯỚC KHI VACUUM.
-- ============================================================
UPDATE inventory_items
SET quantity_reserved = quantity_reserved + 1, version = version + 1
WHERE variant_id BETWEEN 1 AND 150000;

EXPLAIN (ANALYZE, BUFFERS)
SELECT quantity_available, quantity_reserved
FROM inventory_items
WHERE variant_id = 555;
-- Câu hỏi: "Heap Fetches" bây giờ có còn = 0 không? Vì sao UPDATE lại làm mất
-- tính "all-visible" của trang chứa dòng variant_id = 555 (gợi ý: UPDATE tạo
-- ra 1 phiên bản dòng mới -- MVCC / dead tuple -- visibility map phải reset cho
-- trang đó cho tới khi VACUUM chạy lại).

-- ============================================================
-- TỰ LÀM: chạy VACUUM inventory_items rồi lặp lại EXPLAIN ở Bước 2 -- xác nhận
-- Heap Fetches trở lại 0.
-- ============================================================
-- VACUUM inventory_items;

-- Bài học thực tế: autovacuum thường KHÔNG kịp chạy trên bảng ghi liên tục với
-- tần suất cao (hot table như inventory_items) -- cần tinh chỉnh autovacuum
-- threshold cho riêng bảng đó, hoặc chấp nhận Index Only Scan sẽ không luôn
-- đạt Heap Fetches = 0 trong thực tế production.
