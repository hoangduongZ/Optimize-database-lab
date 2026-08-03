-- Module: Inventory
-- version: dùng cho optimistic locking khi reserve/release tồn kho (xem 04_concurrency/).

CREATE TABLE warehouses (
    id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name    VARCHAR(255) NOT NULL,
    address VARCHAR(500)
);

CREATE TABLE inventory_items (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id          BIGINT NOT NULL REFERENCES products(id),
    variant_id          BIGINT NOT NULL REFERENCES product_variants(id),
    warehouse_id        BIGINT NOT NULL REFERENCES warehouses(id),
    quantity_available  INT NOT NULL DEFAULT 0 CHECK (quantity_available >= 0),
    quantity_reserved   INT NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0),
    low_stock_threshold INT NOT NULL DEFAULT 5,
    version             INT NOT NULL DEFAULT 0,
    last_updated        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (product_id, variant_id, warehouse_id)
);

CREATE TABLE stock_movements (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inventory_item_id BIGINT NOT NULL REFERENCES inventory_items(id),
    type              VARCHAR(20) NOT NULL
                      CHECK (type IN ('IMPORT', 'EXPORT', 'RESERVE', 'RELEASE', 'ADJUST')),
    quantity          INT NOT NULL,
    related_order_id  BIGINT,
    note              VARCHAR(500),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
