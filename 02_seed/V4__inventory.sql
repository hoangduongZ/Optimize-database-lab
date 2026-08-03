-- Seed: 200,000 inventory_items (1 / variant) + 200,000 stock_movements (IMPORT ban đầu).

INSERT INTO inventory_items (product_id, variant_id, warehouse_id, quantity_available,
                              quantity_reserved, low_stock_threshold, version, last_updated)
SELECT
    ceil(gs / 2.0)::bigint,
    gs,
    (floor(random() * 5) + 1)::bigint,
    (10 + floor(random() * 200))::int,
    0,
    5,
    0,
    now()
FROM generate_series(1, 200000) AS gs;

INSERT INTO stock_movements (inventory_item_id, type, quantity, note, created_at)
SELECT
    id,
    'IMPORT',
    quantity_available,
    'Initial stock import',
    now() - (random() * interval '365 days')
FROM inventory_items;
