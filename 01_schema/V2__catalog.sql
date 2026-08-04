-- Module: Catalog

CREATE TABLE categories (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    parent_id   BIGINT REFERENCES categories(id),
    name        VARCHAR(255) NOT NULL,
    slug        VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    image_url   VARCHAR(500),
    status      VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(), -- example: 2023-01-01 12:00:00+00
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE brands (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    slug       VARCHAR(255) NOT NULL UNIQUE,
    logo_url   VARCHAR(500),
    status     VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE products (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id       BIGINT NOT NULL REFERENCES categories(id),
    brand_id          BIGINT NOT NULL REFERENCES brands(id),
    sku               VARCHAR(100) NOT NULL UNIQUE, -- example: SKU-001
    name              VARCHAR(500) NOT NULL,
    slug              VARCHAR(500) NOT NULL UNIQUE, --example: product-name-1
    short_description VARCHAR(1000),
    description       TEXT,
    base_price        NUMERIC(15, 2) NOT NULL,
    sale_price        NUMERIC(15, 2),
    currency          VARCHAR(3) NOT NULL DEFAULT 'VND',
    weight            NUMERIC(10, 2),
    status            VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
                      CHECK (status IN ('ACTIVE', 'INACTIVE', 'OUT_OF_STOCK', 'DISCONTINUED')),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE product_images (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id  BIGINT NOT NULL REFERENCES products(id),
    url         VARCHAR(500) NOT NULL,
    alt_text    VARCHAR(255),
    is_primary  BOOLEAN NOT NULL DEFAULT false,
    sort_order  INT NOT NULL DEFAULT 0
);

CREATE TABLE product_variants (
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id       BIGINT NOT NULL REFERENCES products(id),
    sku              VARCHAR(100) NOT NULL UNIQUE, -- example: SKU-001-RED-L
    attribute_values JSONB NOT NULL DEFAULT '{}'::jsonb, -- example: {"color": "red", "size": "L"}
    price_override   NUMERIC(15, 2),
    status           VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
