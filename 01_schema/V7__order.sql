-- Module: Order

CREATE TABLE orders (
    id                     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_number           VARCHAR(50) NOT NULL UNIQUE,
    customer_id            BIGINT NOT NULL REFERENCES users(id),
    subtotal               NUMERIC(15, 2) NOT NULL,
    discount_amount        NUMERIC(15, 2) NOT NULL DEFAULT 0,
    shipping_fee           NUMERIC(15, 2) NOT NULL DEFAULT 0,
    tax_fee                NUMERIC(15, 2) NOT NULL DEFAULT 0,
    total_amount           NUMERIC(15, 2) NOT NULL,
    payment_method         VARCHAR(20) NOT NULL
                           CHECK (payment_method IN ('COD', 'BANK_TRANSFER', 'VNPAY', 'MOMO')),
    payment_status         VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                           CHECK (payment_status IN ('PENDING', 'PAID', 'FAILED', 'REFUNDED')),
    order_status           VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                           CHECK (order_status IN
                                  ('PENDING', 'CONFIRMED', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED')),
    shipping_status        VARCHAR(20) NOT NULL DEFAULT 'NOT_SHIPPED'
                           CHECK (shipping_status IN ('NOT_SHIPPED', 'SHIPPED', 'IN_TRANSIT', 'DELIVERED', 'RETURNED')),
    shipping_provider      VARCHAR(50),
    shipping_tracking_code VARCHAR(100),
    shipping_address_id    BIGINT NOT NULL REFERENCES addresses(id),
    billing_address_id     BIGINT NOT NULL REFERENCES addresses(id),
    note                   VARCHAR(1000),
    placed_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE order_items (
    id                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id             BIGINT NOT NULL REFERENCES orders(id),
    product_id           BIGINT NOT NULL REFERENCES products(id),
    variant_id           BIGINT REFERENCES product_variants(id),
    product_name_snapshot VARCHAR(500) NOT NULL,
    sku_snapshot         VARCHAR(100) NOT NULL,
    price_snapshot       NUMERIC(15, 2) NOT NULL,
    quantity             INT NOT NULL CHECK (quantity > 0)
);

CREATE TABLE order_status_history (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id   BIGINT NOT NULL REFERENCES orders(id),
    status     VARCHAR(20) NOT NULL,
    changed_by BIGINT,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    note       VARCHAR(500)
);
