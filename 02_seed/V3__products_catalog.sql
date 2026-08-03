-- Seed: 100,000 products, 200,000 images (2/product), 200,000 variants (2/product),
-- 800,000 product_attribute_values (8/product).
-- product_id được ánh xạ số học từ generate_series -> KHÔNG cần JOIN, insert nhanh
-- ngay cả ở quy mô triệu dòng.

-- Từ vựng có chủ đích để bài full-text-search / LIKE (03_exercises/03) có kết quả thật.
INSERT INTO products (category_id, brand_id, sku, name, slug, short_description, description,
                       base_price, sale_price, currency, weight, status, created_at)
SELECT
    (floor(random() * 50) + 1)::bigint,
    (floor(random() * 30) + 1)::bigint,
    'SKU-' || lpad(gs::text, 8, '0'),
    kind.name || ' ' || variant_word.name || ' ' || gs,
    'sku-' || lpad(gs::text, 8, '0'),
    'Chính hãng, bảo hành 12 tháng',
    kind.name || ' ' || variant_word.name || ' đời mới, hiệu năng cao, phù hợp học tập, làm việc và giải trí. Model #' || gs || '.',
    (500000 + floor(random() * 50000000))::numeric(15, 2),
    CASE WHEN random() < 0.3 THEN (400000 + floor(random() * 45000000))::numeric(15, 2) ELSE NULL END,
    'VND',
    round((0.1 + random() * 5)::numeric, 2),
    'ACTIVE',
    now() - (random() * interval '900 days')
FROM generate_series(1, 100000) AS gs
CROSS JOIN LATERAL (
    SELECT (ARRAY['Laptop', 'Smartphone', 'Tablet', 'Monitor', 'Keyboard',
                  'Mouse', 'Headphone', 'Camera', 'SSD', 'RAM'])[((gs % 10) + 1)] AS name
) AS kind
CROSS JOIN LATERAL (
    SELECT (ARRAY['Gaming', 'Pro', 'Lite', 'Ultra', 'Air'])[((gs % 5) + 1)] AS name
) AS variant_word;

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
    ceil(gs / 8.0)::bigint,
    (floor(random() * 40) + 1)::bigint,
    val::text,
    val
FROM generate_series(1, 800000) AS gs
CROSS JOIN LATERAL (SELECT round((random() * 30)::numeric, 1) AS val) AS v;
