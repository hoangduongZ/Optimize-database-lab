-- Module: Cart
-- Theo doc: user đã đăng nhập -> DB; guest -> Redis (TTL). Lab chỉ mô phỏng phần lưu DB.

CREATE TABLE carts (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT REFERENCES users(id),
    session_id  VARCHAR(255),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE cart_items (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cart_id           BIGINT NOT NULL REFERENCES carts(id),
    product_id        BIGINT NOT NULL REFERENCES products(id),
    variant_id        BIGINT REFERENCES product_variants(id),
    quantity          INT NOT NULL CHECK (quantity > 0),
    price_at_add_time NUMERIC(15, 2) NOT NULL
);
