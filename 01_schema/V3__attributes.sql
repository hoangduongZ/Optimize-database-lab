-- Module: Attribute / Spec (đặc thù điện tử)

CREATE TABLE attribute_groups (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE attribute_definitions (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    group_id        BIGINT NOT NULL REFERENCES attribute_groups(id),
    code            VARCHAR(100) NOT NULL UNIQUE,
    name            VARCHAR(255) NOT NULL, -- example: "Color", "Size", "Screen Size"
    data_type       VARCHAR(20) NOT NULL
                    CHECK (data_type IN ('TEXT', 'SELECT', 'NUMBER', 'COLOR', 'BOOLEAN')),
    unit            VARCHAR(20),
    is_filterable   BOOLEAN NOT NULL DEFAULT false,
    is_comparable   BOOLEAN NOT NULL DEFAULT false,
    is_quick_spec   BOOLEAN NOT NULL DEFAULT false,
    sort_order      INT NOT NULL DEFAULT 0
);

CREATE TABLE attribute_options (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    attribute_id BIGINT NOT NULL REFERENCES attribute_definitions(id),
    value        VARCHAR(255) NOT NULL, -- example: "Red", "Blue", "13 inch", "15 inch"
    label        VARCHAR(255) NOT NULL
);

CREATE TABLE attribute_templates (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(255) NOT NULL, -- example: Laptop Specs, Phone Specs
    status     VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE template_attributes (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    template_id  BIGINT NOT NULL REFERENCES attribute_templates(id),
    attribute_id BIGINT NOT NULL REFERENCES attribute_definitions(id),
    sort_order   INT NOT NULL DEFAULT 0,
    UNIQUE (template_id, attribute_id)
);

CREATE TABLE category_attribute_template (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id BIGINT NOT NULL REFERENCES categories(id),
    template_id BIGINT NOT NULL REFERENCES attribute_templates(id),
    UNIQUE (category_id, template_id)
);

-- value_number dùng để lọc theo range (vd screen size 13-17"); value dùng để hiển thị.
CREATE TABLE product_attribute_values (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id   BIGINT NOT NULL REFERENCES products(id),
    attribute_id BIGINT NOT NULL REFERENCES attribute_definitions(id),
    value        VARCHAR(500),
    value_number NUMERIC(15, 4)
);
