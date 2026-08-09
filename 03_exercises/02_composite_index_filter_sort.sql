-- BÀI 02: Composite index cho filter + sort cùng lúc (trang danh mục sản phẩm).
-- Đây chính là pattern liệt kê ở database-design.md §5: products (status, category_id).

-- ============================================================
-- PROBLEM: trang danh mục -- lọc theo category + status ACTIVE, sắp xếp theo giá tăng dần.
-- ============================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, name, base_price, sale_price
FROM products
WHERE status = 'ACTIVE' AND category_id = 10
ORDER BY base_price ASC
LIMIT 20;

-- Quan sát: nếu chưa có index phù hợp, planner phải Seq Scan + Sort toàn bộ
-- tập con khớp category_id=10 rồi mới LIMIT 20 -- lãng phí nếu category đó có hàng ngàn sản phẩm.

-- ============================================================
-- TỰ LÀM:
-- 1. Thử index đơn lẻ trên category_id trước, so sánh plan.
-- 2. Sau đó thử composite index (category_id, status, base_price) -- để ý thứ tự
--    cột: cột filter bằng (=) đứng trước, cột dùng ORDER BY đứng sau để tránh
--    bước Sort riêng.
-- ============================================================
CREATE INDEX idx_products_category_id ON products(category_id);
DROP INDEX idx_products_category_id;
CREATE INDEX idx_products_category_status_price
    ON products (category_id, status, base_price);

-- ============================================================
-- SOLUTION
-- ============================================================
-- CREATE INDEX idx_products_category_status_price
--     ON products (category_id, status, base_price);
--
-- Chạy lại EXPLAIN (ANALYZE, BUFFERS) ở trên -> kỳ vọng thấy:
--   Index Scan using idx_products_category_status_price on products
-- và KHÔNG còn node "Sort" riêng (index đã trả dữ liệu đúng thứ tự base_price).
--
-- Biến thể đáng thử thêm: nếu trang danh mục luôn lọc status = 'ACTIVE' (chiếm
-- đa số bản ghi) thì composite index vẫn tốt hơn partial index ở đây, vì còn
-- cần lọc theo NHIỀU category_id khác nhau (không phải 1 giá trị cố định như
-- bài 05 partial index).
