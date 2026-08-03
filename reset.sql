-- Xoá toàn bộ schema + dữ liệu để làm lại lab từ đầu.
-- Sau khi chạy file này, chạy lại theo thứ tự:
--   psql -f 00_setup/V0__extensions.sql <db>
--   psql -f 01_schema/run_all.sql       <db>
--   psql -f 02_seed/run_all.sql         <db>
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO CURRENT_USER;
