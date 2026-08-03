-- BÀI 03: LIKE '%keyword%' không dùng được B-tree index -- 2 cách khắc phục:
-- (a) trigram index (pg_trgm) nếu vẫn cần LIKE/ILIKE %...%
-- (b) full-text search (tsvector + GIN) nếu tìm theo "từ", có xếp hạng relevance.
-- database-design.md §5 gợi ý: GIN trên tsvector(name + description).

-- ============================================================
-- PROBLEM: tìm sản phẩm theo từ khoá tự do, kiểu search box đơn giản.
-- ============================================================
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, name
FROM products
WHERE name ILIKE '%Laptop Gaming%';

-- Quan sát: Seq Scan trên 100k dòng vì '%...%' không có prefix cố định -> B-tree index
-- (nếu có trên name) cũng vô dụng ở đây.

-- ============================================================
-- TỰ LÀM (chọn 1 trong 2 hướng, hoặc làm cả 2 để so sánh):
--
-- Hướng A -- trigram (giữ nguyên cách viết query bằng ILIKE):
--   CREATE INDEX idx_products_name_trgm ON products USING GIN (name gin_trgm_ops);
--
-- Hướng B -- full-text search (đổi cách viết query, có relevance ranking):
--   ALTER TABLE products ADD COLUMN search_vector tsvector
--       GENERATED ALWAYS AS (to_tsvector('simple', coalesce(name, '') || ' ' || coalesce(description, ''))) STORED;
--   CREATE INDEX idx_products_search_vector ON products USING GIN (search_vector);
--
--   SELECT id, name, ts_rank(search_vector, query) AS rank
--   FROM products, to_tsquery('simple', 'Gaming & Laptop') AS query
--   WHERE search_vector @@ query
--   ORDER BY rank DESC
--   LIMIT 20;
-- ============================================================


-- ============================================================
-- SOLUTION
-- ============================================================
-- -- Hướng A: chạy lại EXPLAIN ANALYZE của PROBLEM sau khi tạo index trigram
-- -- -> "Bitmap Heap Scan" + "Bitmap Index Scan on idx_products_name_trgm".
-- CREATE INDEX idx_products_name_trgm ON products USING GIN (name gin_trgm_ops);
--
-- -- Hướng B: full-text search, tốt hơn khi cần tìm theo NHIỀU TỪ không liền nhau
-- -- (vd "Laptop Gaming" và "Gaming Laptop" phải cho cùng kết quả) và cần ranking.
-- ALTER TABLE products ADD COLUMN search_vector tsvector
--     GENERATED ALWAYS AS (to_tsvector('simple', coalesce(name, '') || ' ' || coalesce(description, ''))) STORED;
-- CREATE INDEX idx_products_search_vector ON products USING GIN (search_vector);
--
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT id, name, ts_rank(search_vector, query) AS rank
-- FROM products, to_tsquery('simple', 'Gaming & Laptop') AS query
-- WHERE search_vector @@ query
-- ORDER BY rank DESC
-- LIMIT 20;
