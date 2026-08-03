-- Chạy toàn bộ schema theo đúng thứ tự phụ thuộc FK.
-- Dùng \ir (include relative) thay vì \i -- resolve theo thư mục của chính file
-- này, nên chạy đúng bất kể đang gọi từ cwd nào (host, container, ...).
\ir V1__iam.sql
\ir V2__catalog.sql
\ir V3__attributes.sql
\ir V4__inventory.sql
\ir V5__cart.sql
\ir V6__promotion.sql
\ir V7__order.sql
\ir V8__payment.sql
\ir V9__review.sql
