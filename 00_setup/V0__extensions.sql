-- Lab setup: chạy đầu tiên, 1 lần duy nhất (per database).
-- pg_trgm: cần cho bài LIKE '%keyword%' -> trigram GIN/GiST index (03_exercises/03).
-- pg_stat_statements: xem query nào tốn thời gian nhất (không bắt buộc nhưng rất hữu ích khi optimize).
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;


-- Extension là mở rộng của gói tính năng thay vì postgreSQL phải chứa tất cả, các chức năng bổ sung được đóng gói thành exténsion có thể bật bằng
-- CREATE EXTENSION IF NOT EXISTS <extension_name>;