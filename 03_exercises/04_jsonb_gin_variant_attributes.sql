-- BÀI 04: lọc theo thuộc tính lưu trong JSONB (product_variants.attribute_values).
-- database-design.md ghi rõ: "JSONB dùng cho variant.attribute_values ... linh hoạt
-- nhưng có kiểm soát" -- "kiểm soát" ở đây nghĩa là phải index đúng cách.

-- ============================================================
-- PROBLEM: tìm variant màu đen, RAM 16GB (bộ lọc kiểu "facet" trên trang sản phẩm).
-- ============================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, product_id, sku, attribute_values
FROM product_variants
WHERE attribute_values @> '{"color": "black", "ram_gb": 16}'::jsonb;

-- Quan sát: Seq Scan trên 200k variant vì JSONB không có index mặc định.

-- ============================================================
-- TỰ LÀM: thêm GIN index cho attribute_values, chạy lại EXPLAIN, so sánh.
-- Sau đó thử thêm 1 query chỉ lọc theo "color" (bỏ ram_gb) để xem GIN có
-- dùng lại được cho các subset điều kiện khác nhau hay không.
-- ============================================================


-- ============================================================
-- SOLUTION
-- ============================================================
-- CREATE INDEX idx_variants_attribute_values ON product_variants USING GIN (attribute_values);
--
-- GIN mặc định (jsonb_ops) hỗ trợ tốt operator @> (containment) với BẤT KỲ tổ hợp
-- key nào -- không cần 1 index riêng cho mỗi cột như bảng quan hệ thông thường.
--
-- Nếu chỉ cần lọc EXACT theo 1-2 key cố định và biết trước key đó (vd luôn lọc
-- theo "color"), cách khác rẻ hơn về write cost là expression index:
-- CREATE INDEX idx_variants_color ON product_variants ((attribute_values ->> 'color'));
-- rồi query: WHERE attribute_values ->> 'color' = 'black';
