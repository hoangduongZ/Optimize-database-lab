-- Seed: 100,000 products, 200,000 images (2/product), 200,000 variants (2/product),
-- 800,000 product_attribute_values (8/product).
-- product_id được ánh xạ số học từ generate_series -> KHÔNG cần JOIN, insert nhanh
-- ngay cả ở quy mô triệu dòng.
--
-- QUAN TRỌNG: mọi random() cần đa dạng thật theo từng dòng PHẢI được tính
-- trực tiếp trong SELECT list của 1 subquery có FROM là generate_series
-- (như bảng `base` dưới đây). KHÔNG bọc random() trong 1 derived table rồi
-- CROSS JOIN LATERAL nếu derived table đó không thực sự tham chiếu cột
-- ngoài -- Postgres coi đó là subquery KHÔNG tương quan và chỉ tính 1 LẦN
-- DUY NHẤT cho toàn bộ statement (mọi dòng dùng chung 1 giá trị) dù có
-- ghi chữ LATERAL. Đây không phải bug của Postgres -- đúng ngữ nghĩa SQL:
-- LATERAL chỉ có tác dụng khi subquery THỰC SỰ tham chiếu cột ngoài.

-- Từ vựng có chủ đích để bài full-text-search / LIKE (03_exercises/03) có kết quả thật.
INSERT INTO products (category_id, brand_id, sku, name, slug, short_description, description,
                       base_price, sale_price, currency, weight, status, created_at)
SELECT
    base.category_id,
    base.brand_id,
    'SKU-' || lpad(base.gs::text, 8, '0'),
    base.kind_name || ' ' || base.variant_name || ' ' || base.gs,
    'sku-' || lpad(base.gs::text, 8, '0'),
    'Chính hãng, bảo hành 12 tháng',
    base.kind_name || ' ' || base.variant_name || ' đời mới, hiệu năng cao, phù hợp học tập, làm việc và giải trí. Model #' || base.gs || '.',
    base.base_price,
    CASE WHEN base.sale_roll < 0.3 THEN base.sale_price_raw ELSE NULL END,
    'VND',
    base.weight,
    -- status thật đa dạng (90% ACTIVE / 5% INACTIVE / 3% OUT_OF_STOCK / 2% DISCONTINUED)
    -- -- cần cho các bài luyện tập filter theo status (không chỉ toàn ACTIVE).
    CASE
        WHEN base.status_r < 0.90 THEN 'ACTIVE'
        WHEN base.status_r < 0.95 THEN 'INACTIVE'
        WHEN base.status_r < 0.98 THEN 'OUT_OF_STOCK'
        ELSE 'DISCONTINUED'
    END,
    base.created_at
FROM (
    SELECT
        gs,
        (ARRAY['Laptop', 'Smartphone', 'Tablet', 'Monitor', 'Keyboard',
               'Mouse', 'Headphone', 'Camera', 'SSD', 'RAM'])[((gs % 10) + 1)] AS kind_name,
        (ARRAY['Gaming', 'Pro', 'Lite', 'Ultra', 'Air'])[((gs % 5) + 1)] AS variant_name,
        (floor(random() * 50) + 1)::bigint AS category_id,
        (floor(random() * 30) + 1)::bigint AS brand_id,
        (500000 + floor(random() * 50000000))::numeric(15, 2) AS base_price,
        random() AS sale_roll,
        (400000 + floor(random() * 45000000))::numeric(15, 2) AS sale_price_raw,
        round((0.1 + random() * 5)::numeric, 2) AS weight,
        random() AS status_r,
        now() - (random() * interval '900 days') AS created_at
    FROM generate_series(1, 100000) AS gs
) AS base;

-- 2 ảnh / product
INSERT INTO product_images (product_id, url, alt_text, is_primary, sort_order)
SELECT
    ceil(gs / 2.0)::bigint,
    'https://cdn.lab.local/products/' || ceil(gs / 2.0)::bigint || '/' || gs || '.jpg',
    'Product image ' || gs,
    (gs % 2 = 1),
    (gs % 2)
FROM generate_series(1, 200000) AS gs;

-- 2 variant / product
INSERT INTO product_variants (product_id, sku, attribute_values, price_override, status)
SELECT
    ceil(gs / 2.0)::bigint,
    'VAR-' || lpad(gs::text, 8, '0'),
    jsonb_build_object(
        'color', (ARRAY['black', 'white', 'silver', 'blue', 'red'])[((gs % 5) + 1)],
        'storage_gb', (ARRAY[128, 256, 512, 1024])[((gs % 4) + 1)],
        'ram_gb', (ARRAY[8, 16, 32])[((gs % 3) + 1)]
    ),
    CASE WHEN gs % 3 = 0 THEN (500000 + floor(random() * 50000000))::numeric(15, 2) ELSE NULL END,
    'ACTIVE'
FROM generate_series(1, 200000) AS gs;

-- 8 attribute value / product (attribute_id ngẫu nhiên trong 1..40)
INSERT INTO product_attribute_values (product_id, attribute_id, value, value_number)
SELECT
    ceil(base.gs / 8.0)::bigint,
    base.attribute_id,
    base.val::text,
    base.val
FROM (
    SELECT
        gs,
        (floor(random() * 40) + 1)::bigint AS attribute_id,
        round((random() * 30)::numeric, 1) AS val
    FROM generate_series(1, 800000) AS gs
) AS base;
