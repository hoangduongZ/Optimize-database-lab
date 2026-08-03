-- Chạy toàn bộ seed data. Tổng ~2.3 triệu dòng, thường mất 1-3 phút tuỳ máy.
-- psql -f 02_seed/run_all.sql
\timing on
\ir V1__reference_data.sql
\ir V2__users_and_addresses.sql
\ir V3__products_catalog.sql
\ir V4__inventory.sql
\ir V5__carts.sql
\ir V6__orders.sql
\ir V7__reviews.sql

-- Cập nhật planner statistics sau khi load dữ liệu lớn -- BẮT BUỘC trước khi chạy
-- EXPLAIN ở 03_exercises/, nếu không estimate của planner sẽ sai lệch nghiêm trọng.
ANALYZE;
