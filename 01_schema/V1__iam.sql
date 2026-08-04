-- Module: IAM (Identity & Access)
-- Cố ý KHÔNG tạo index trên các cột FK/filter ngoài UNIQUE bắt buộc.
-- Postgres KHÔNG tự tạo index cho foreign key (khác vài RDBMS khác) -> đây là lỗ hổng
-- hiệu năng "mặc định" mà bài 03_exercises/01 sẽ cho thấy rõ.

CREATE TABLE users (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE,
    phone         VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    role          VARCHAR(20)  NOT NULL DEFAULT 'CUSTOMER'
                  CHECK (role IN ('CUSTOMER', 'ADMIN', 'MANAGER', 'SUPPORT')), -- CHECK is a constraint to ensure the value of the column is within a specified range or set of values.
    status        VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE'
                  CHECK (status IN ('ACTIVE', 'INACTIVE', 'BANNED')),
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(), -- TIMESTAMPTZ = timestamp with time zone, ex: 2023-01-01 12:00:00+07
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    created_by    BIGINT,
    updated_by    BIGINT
);

CREATE TABLE user_profiles (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- BIGINT GENERATED ALWAYS AS IDENTITY = auto increment, ex: 1, 2, 3, ...
    user_id    BIGINT NOT NULL UNIQUE REFERENCES users(id),
    full_name  VARCHAR(255),
    gender     VARCHAR(10) CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    dob        DATE, -- ex: 1990-01-01
    avatar_url VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE addresses (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id),
    full_name   VARCHAR(255) NOT NULL,
    phone       VARCHAR(20)  NOT NULL,
    street      VARCHAR(255),
    ward        VARCHAR(100),
    district    VARCHAR(100),
    city        VARCHAR(100),
    country     VARCHAR(100) NOT NULL DEFAULT 'VN',
    postal_code VARCHAR(20),
    type        VARCHAR(10) NOT NULL DEFAULT 'SHIPPING'
                CHECK (type IN ('SHIPPING', 'BILLING')),
    is_default  BOOLEAN NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- refresh_tokens: theo doc, lưu ở Redis trong production -> không tạo bảng trong lab này.
