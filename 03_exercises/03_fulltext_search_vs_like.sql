-- BÀI 03: LIKE '%keyword%' không dùng được B-tree index
-- Mục tiêu: hiểu tại sao ILIKE '%...%' khiến Postgres phải Seq Scan,
-- rồi tự khắc phục bằng 1 trong 2 hướng:
--   (a) trigram index (pg_trgm)  → giữ nguyên cách viết ILIKE %...%
--   (b) full-text search (tsvector + GIN) → tìm theo "từ", có xếp hạng relevance
-- Tham khảo: database-design.md §5 – GIN trên tsvector(name + description).

-- ============================================================
-- PROBLEM: tìm sản phẩm theo từ khoá tự do, kiểu search box đơn giản.
-- ============================================================
-- Hình dung: bảng products là cuốn sách 100.000 trang, mỗi trang là một sản phẩm.
-- ILIKE '%Laptop Gaming%' nghĩa là: "Lật từng trang một, đọc xem có chứa cụm từ
-- 'Laptop Gaming' không?" – đây là Sequential Scan, chậm kinh khủng.
--
-- Tại sao B-tree index (nếu đã có trên name) cũng bó tay?
-- → B-tree giống danh bạ điện thoại sắp theo ABC. Bạn tra được "Laptop..." (prefix)
--   nhưng "%Laptop%" bắt đầu bằng ký tự bất kỳ → danh bạ vô dụng, phải lật hết.

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, name
FROM products
WHERE name ILIKE '%Laptop Gaming%'
LIMIT 50000;

-- Quan sát: "Seq Scan on products" – quét toàn bộ 100k dòng
-- dù chỉ tìm vài dòng khớp. B-tree index (nếu có) không được sử dụng.

-- ============================================================
-- TỰ LÀM: chọn 1 trong 2 hướng (hoặc cả 2 để so sánh).
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- HƯỚNG A · Trigram Index (pg_trgm) – khi cần giữ nguyên ILIKE %...%
-- ────────────────────────────────────────────────────────────
-- Ý tưởng: thay vì tra danh bạ ABC (B-tree), ta xé mỗi tên sản phẩm thành
-- các mảnh 3 ký tự (trigram). Ví dụ "Laptop" → {"Lap", "apt", "pto", "top"}.
-- Khi tìm '%Laptop%', Postgres tìm các mảnh {"Lap","apt","pto","top"} trong index
-- → nhanh hơn rất nhiều so với lật từng trang.
--
-- Bước 1: Bật extension pg_trgm (chỉ cần chạy 1 lần)
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;
--
-- Bước 2: Tạo trigram index
CREATE INDEX idx_products_name_trgm ON products USING GIN (name gin_trgm_ops);

-- Bước 3: Chạy lại EXPLAIN ANALYZE của PROBLEM ở trên, so sánh kết quả.
--   Kỳ vọng: "Bitmap Heap Scan" + "Bitmap Index Scan on idx_products_name_trgm"
--
-- Bước 4: Dọn dẹp (nếu muốn thử hướng B)
DROP INDEX idx_products_name_trgm;

-- ────────────────────────────────────────────────────────────
-- HƯỚNG B · Full-Text Search (tsvector + GIN) – khi cần tìm theo "từ"
-- ────────────────────────────────────────────────────────────
-- Ý tưởng: thay vì tìm "chuỗi con" (ILIKE), ta tìm "từ" (word).
-- Postgres sẽ tách nội dung thành danh sách từ chuẩn hóa (tsvector),
-- giống như ông thủ thư lập "bảng chỉ mục chủ đề" ở cuối sách:
--   "Gaming" → trang 12, 45, 789
--   "Laptop" → trang 12, 200, 456
-- Tìm sản phẩm chứa cả "Gaming" VÀ "Laptop" → chỉ cần dò bảng chỉ mục,
-- lấy giao của {12, 45, 789} ∩ {12, 200, 456} = {12}. Nhanh gọn!
--
-- Ưu điểm so với trigram:
--   • "Laptop Gaming" và "Gaming Laptop" cho cùng kết quả (không phụ thuộc thứ tự từ)
--   • Có hàm ts_rank() để xếp hạng mức độ liên quan (relevance ranking)
--
-- Bước 1: Thêm cột search_vector (generated column, tự cập nhật khi name/description đổi)
ALTER TABLE products
ADD COLUMN search_vector tsvector GENERATED ALWAYS AS (
    to_tsvector(
        'simple',
        coalesce(name, '') || ' ' || coalesce(description, '')
    )
) STORED;

-- Bước 2: Tạo GIN index trên cột search_vector
CREATE INDEX idx_products_search_vector ON products USING GIN (search_vector);

-- Bước 3: Chạy query full-text search có ranking
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, name, ts_rank(search_vector, query) AS rank
FROM products, to_tsquery('simple', 'Gaming & Laptop') AS query
WHERE search_vector @@ query
ORDER BY rank DESC
LIMIT 20;

-- ============================================================
-- SOLUTION (mở comment sau khi đã tự thử)
-- ============================================================

-- -- HƯỚNG A: Trigram
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;
-- CREATE INDEX idx_products_name_trgm ON products USING GIN (name gin_trgm_ops);
--
-- -- Chạy lại query PROBLEM → kỳ vọng: Bitmap Heap Scan + Bitmap Index Scan.
-- -- Sau khi xác nhận, có thể drop nếu chuyển sang hướng B:
-- -- DROP INDEX idx_products_name_trgm;

-- -- HƯỚNG B: Full-Text Search (khuyên dùng khi cần tìm theo nhiều từ + ranking)
-- ALTER TABLE products
    -- ADD COLUMN search_vector tsvector GENERATED ALWAYS AS (
    --     to_tsvector('simple', coalesce(name, '') || ' ' || coalesce(description, ''))
    -- ) STORED;
--
-- CREATE INDEX idx_products_search_vector ON products USING GIN (search_vector);
--
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT id, name, ts_rank(search_vector, query) AS rank
-- FROM products, to_tsquery('simple', 'Gaming & Laptop') AS query
-- WHERE search_vector @@ query
-- ORDER BY rank DESC
-- LIMIT 20;

-- ============================================================
-- GHI CHÚ THÊM
-- ============================================================
-- • Trigram phù hợp khi user gõ "một phần" từ (autocomplete, fuzzy search).
-- • Full-text search phù hợp khi user tìm theo "từ khóa" (search box e-commerce).
-- • Cả hai đều dùng GIN index – loại index "bảng chỉ mục ngược" (inverted index):
--   thay vì "dòng → giá trị", nó lưu "giá trị → danh sách dòng chứa giá trị đó".
-- • GIN index tốn nhiều dung lượng đĩa hơn B-tree và chậm hơn khi INSERT/UPDATE,
--   nhưng tìm kiếm text thì nhanh vượt trội. Trade-off cổ điển: đổi tốc độ ghi
--   lấy tốc độ đọc.