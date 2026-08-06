-- Module: Promotion & Pricing

CREATE TABLE coupons (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code                VARCHAR(50) NOT NULL UNIQUE,
    description         VARCHAR(500),
    discount_type       VARCHAR(20) NOT NULL CHECK (discount_type IN ('PERCENTAGE', 'FIXED_AMOUNT')),
    discount_value      NUMERIC(15, 2) NOT NULL,
    min_order_amount    NUMERIC(15, 2),
    max_discount_amount NUMERIC(15, 2),
    start_date          TIMESTAMPTZ NOT NULL,
    end_date            TIMESTAMPTZ NOT NULL,
    usage_limit         INT,
    usage_per_user      INT,
    status              VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
                        CHECK (status IN ('ACTIVE', 'INACTIVE', 'EXPIRED')),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE coupon_redemptions ( -- propose to track coupon usage by users, can be used for analytics and enforcing usage limits
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    coupon_id    BIGINT NOT NULL REFERENCES coupons(id),
    user_id      BIGINT NOT NULL REFERENCES users(id),
    order_id     BIGINT NOT NULL,
    redeemed_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE promotions (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name           VARCHAR(255) NOT NULL,
    description    VARCHAR(500),
    discount_type  VARCHAR(20) NOT NULL CHECK (discount_type IN ('PERCENTAGE', 'FIXED_AMOUNT')),
    discount_value NUMERIC(15, 2) NOT NULL,
    start_date     TIMESTAMPTZ NOT NULL,
    end_date       TIMESTAMPTZ NOT NULL,
    priority       INT NOT NULL DEFAULT 0,
    status         VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
                   CHECK (status IN ('ACTIVE', 'INACTIVE', 'EXPIRED')),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE promotion_products ( -- many-to-many relationship between promotions and products
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    promotion_id BIGINT NOT NULL REFERENCES promotions(id),
    product_id   BIGINT NOT NULL REFERENCES products(id),
    UNIQUE (promotion_id, product_id)
);
