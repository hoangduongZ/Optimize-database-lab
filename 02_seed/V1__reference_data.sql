-- Seed: dữ liệu tham chiếu (số lượng nhỏ, không cần index để nhanh).
-- Toàn bộ seed dùng generate_series + ánh xạ FK bằng phép tính số học (không JOIN/subquery)
-- để insert nhanh trên tập lớn. Điều này CHỈ đúng vì các bảng đích đang trống và
-- IDENTITY bắt đầu từ 1 -> id sinh ra tuần tự, dự đoán được.

-- 50 categories
INSERT INTO categories (name, slug, description, status)
SELECT 'Category ' || gs,
       'category-' || gs,
       'Auto-generated category #' || gs,
       'ACTIVE'
FROM generate_series(1, 50) AS gs;

-- 30 brands
INSERT INTO brands (name, slug, status)
SELECT 'Brand ' || gs, 'brand-' || gs, 'ACTIVE'
FROM generate_series(1, 30) AS gs;

-- 8 attribute groups
INSERT INTO attribute_groups (name, sort_order)
SELECT 'Attribute Group ' || gs, gs
FROM generate_series(1, 8) AS gs;

-- 40 attribute definitions (5 per group)
INSERT INTO attribute_definitions (group_id, code, name, data_type, unit, is_filterable, is_comparable, is_quick_spec, sort_order)
SELECT
    ceil(gs / 5.0)::bigint,
    'attr_' || gs,
    'Attribute ' || gs,
    (ARRAY['TEXT', 'SELECT', 'NUMBER', 'COLOR', 'BOOLEAN'])[((gs - 1) % 5) + 1],
    CASE WHEN gs % 3 = 0 THEN 'inch' ELSE NULL END,
    (gs % 2 = 0),
    (gs % 3 = 0),
    (gs % 4 = 0),
    gs
FROM generate_series(1, 40) AS gs;

-- 200 attribute options (5 per attribute, chỉ có ý nghĩa với data_type = SELECT nhưng
-- không quan trọng với mục tiêu của lab này)
INSERT INTO attribute_options (attribute_id, value, label)
SELECT ceil(gs / 5.0)::bigint, 'value_' || gs, 'Label ' || gs
FROM generate_series(1, 200) AS gs;

-- 5 attribute templates
INSERT INTO attribute_templates (name, status)
SELECT 'Template ' || gs, 'ACTIVE'
FROM generate_series(1, 5) AS gs;

-- Mỗi template gắn toàn bộ 40 attribute (5 templates x 40 = 200 dòng)
INSERT INTO template_attributes (template_id, attribute_id, sort_order)
SELECT t.gs, a.gs, a.gs
FROM generate_series(1, 5) AS t(gs)
CROSS JOIN generate_series(1, 40) AS a(gs);

-- Mỗi category gắn 1 template (round-robin)
INSERT INTO category_attribute_template (category_id, template_id)
SELECT gs, ((gs - 1) % 5) + 1
FROM generate_series(1, 50) AS gs;

-- 5 warehouses
INSERT INTO warehouses (name, address)
SELECT 'Warehouse ' || gs, 'Address ' || gs
FROM generate_series(1, 5) AS gs;

-- 100 coupons
INSERT INTO coupons (code, description, discount_type, discount_value, min_order_amount,
                      max_discount_amount, start_date, end_date, usage_limit, usage_per_user, status)
SELECT
    'COUPON' || lpad(gs::text, 4, '0'),
    'Coupon #' || gs,
    CASE WHEN gs % 2 = 0 THEN 'PERCENTAGE' ELSE 'FIXED_AMOUNT' END,
    CASE WHEN gs % 2 = 0 THEN (5 + (gs % 20))::numeric ELSE (50000 + (gs % 10) * 10000)::numeric END,
    100000,
    200000,
    now() - interval '30 days',
    now() + interval '90 days',
    1000,
    1,
    'ACTIVE'
FROM generate_series(1, 100) AS gs;

-- 50 promotions
INSERT INTO promotions (name, description, discount_type, discount_value, start_date, end_date, priority, status)
SELECT
    'Promotion ' || gs,
    'Auto-generated promotion #' || gs,
    CASE WHEN gs % 2 = 0 THEN 'PERCENTAGE' ELSE 'FIXED_AMOUNT' END,
    (5 + (gs % 15))::numeric,
    now() - interval '10 days',
    now() + interval '60 days',
    gs,
    'ACTIVE'
FROM generate_series(1, 50) AS gs;
