-- BÀI 06: Covering index (INCLUDE) -- tránh phải "quay lại" bảng heap để lấy thêm cột.
-- inventory_items đã có UNIQUE (product_id, variant_id, warehouse_id) theo
-- database-design.md §5, nhưng UNIQUE index đó không giúp gì khi SELECT thêm cột khác.

-- ============================================================
-- PROBLEM: check tồn kho khi thêm vào giỏ hàng -- cần đủ 3 cột filter + đọc số lượng.
-- ============================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT quantity_available, quantity_reserved, version
FROM inventory_items
WHERE product_id = 100 AND variant_id = 199 AND warehouse_id = 1;

-- Với unique index sẵn có trên (product_id, variant_id, warehouse_id), planner đã
-- dùng Index Scan để TÌM đúng dòng -- nhưng vẫn phải ghé heap (table) để lấy
-- quantity_available, quantity_reserved, version vì các cột này không có trong index.

-- ============================================================
-- TỰ LÀM: thêm INCLUDE các cột cần đọc vào unique index, để index scan có thể trả
-- kết quả mà KHÔNG cần đọc heap (Index Only Scan) -- miễn trang heap tương ứng đã
-- được đánh dấu all-visible trong visibility map (chạy VACUUM inventory_items nếu cần,
-- xem thêm bài 10).
-- ============================================================


-- ============================================================
-- SOLUTION
-- ============================================================
ALTER TABLE inventory_items DROP CONSTRAINT inventory_items_product_id_variant_id_warehouse_id_key;
CREATE UNIQUE INDEX idx_inventory_lookup_covering
    ON inventory_items (product_id, variant_id, warehouse_id)
    INCLUDE (quantity_available, quantity_reserved, version);
-- REVERT
DROP INDEX idx_inventory_lookup_covering;
VACUUM inventory_items; -- cập nhật visibility map để Index Only Scan khả dụng
--
-- Chạy lại EXPLAIN (ANALYZE, BUFFERS) ở PROBLEM -> kỳ vọng "Index Only Scan using
-- idx_inventory_lookup_covering" với "Heap Fetches: 0".
