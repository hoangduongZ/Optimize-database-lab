-- Chạy toàn bộ schema theo đúng thứ tự phụ thuộc FK.
-- Dùng \ir (include relative) thay vì \i -- resolve theo thư mục của chính file
-- này, nên chạy đúng bất kể đang gọi từ cwd nào (host, container, ...).
--
-- Lệnh chạy file này qua docker compose (container "db" trong docker-compose.yml
-- mount toàn bộ repo vào /lab, nên đường dẫn bên trong container là /lab/...):
--
--   docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/01_schema/run_all.sql
--
-- Giải thích:
--   docker compose exec   chạy lệnh bên trong container đang sống (không tạo container mới)
--   -T                     tắt cấp phát TTY giả -- cần khi output/pipe vào script, CI, ...
--   db                     tên service Postgres khai báo trong docker-compose.yml
--   psql -U postgres       kết nối bằng user "postgres" (POSTGRES_USER trong compose)
--   -d optimize_lab        chọn database "optimize_lab" (POSTGRES_DB trong compose)
--   -f /lab/01_schema/...  chạy file SQL này (psql tự đọc \ir bên trong file để include các V*.sql)
\ir V1__iam.sql
\ir V2__catalog.sql
\ir V3__attributes.sql
\ir V4__inventory.sql
\ir V5__cart.sql
\ir V6__promotion.sql
\ir V7__order.sql
\ir V8__payment.sql
\ir V9__review.sql
