-- Module: Review (Phase 2)

CREATE TABLE reviews (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES products(id),
    user_id    BIGINT NOT NULL REFERENCES users(id),
    order_id   BIGINT REFERENCES orders(id),
    rating     SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title      VARCHAR(255),
    content    TEXT,
    status     VARCHAR(20) NOT NULL DEFAULT 'PENDING'
               CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
