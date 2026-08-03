-- LAB CONCURRENCY 02: cách reserve tồn kho AN TOÀN theo database-design.md §4.1 --
-- 1 câu UPDATE atomic, điều kiện tồn kho nằm ngay trong WHERE, không tách bước
-- "đọc rồi tính ở app rồi ghi".

-- Chuẩn bị: lại 1 sản phẩm chỉ còn 1 cái.
UPDATE inventory_items SET quantity_available = 1, quantity_reserved = 0, version = 0
WHERE id = 1;

-- ============================================================
-- Terminal A                              | Terminal B
-- ============================================================
-- A1: (chạy trước)
BEGIN;
UPDATE inventory_items
SET quantity_available = quantity_available - 1,
    quantity_reserved  = quantity_reserved  + 1,
    version = version + 1
WHERE id = 1 AND quantity_available >= 1;
-- Postgres khoá dòng id=1 ngay tại đây cho tới khi A COMMIT/ROLLBACK.
SELECT pg_sleep(5);  -- vẫn mô phỏng xử lý business logic, nhưng dòng ĐÃ bị khoá

--                                          B1: (chạy trong lúc A đang pg_sleep)
--                                          BEGIN;
--                                          UPDATE inventory_items
--                                          SET quantity_available = quantity_available - 1,
--                                              quantity_reserved  = quantity_reserved  + 1,
--                                              version = version + 1
--                                          WHERE id = 1 AND quantity_available >= 1;
--                                          -- session B BỊ BLOCK ở đây -- phải chờ A giải phóng row lock.
--                                          -- (đây là hành vi ĐÚNG, không phải lỗi treo -- cứ để B chờ)

-- A2:
COMMIT;   -- A giải phóng lock. B lập tức được tiếp tục.

--                                          B2: (B vừa được tiếp tục ngay sau A COMMIT)
--                                          -- Postgres RE-EVALUATE điều kiện WHERE với giá trị MỚI NHẤT
--                                          -- (quantity_available lúc này = 0, sau khi A đã trừ) -> điều kiện
--                                          -- ">= 1" SAI -> UPDATE của B khớp 0 dòng.
--                                          COMMIT;

-- ============================================================
-- Kiểm tra affected rows của UPDATE ở mỗi session (psql tự in ra "UPDATE 1" hoặc
-- "UPDATE 0" ngay sau câu UPDATE) -- session A: UPDATE 1, session B: UPDATE 0.
-- Tầng application PHẢI kiểm tra affected rows = 0 -> ném InsufficientStockException,
-- KHÔNG coi đó là thành công.
-- ============================================================
SELECT quantity_available, quantity_reserved, version FROM inventory_items WHERE id = 1;
-- quantity_available = 0, quantity_reserved = 1, version = 1 -- ĐÚNG, chỉ 1 đơn thành công.

-- Dọn dẹp:
UPDATE inventory_items SET quantity_available = 1, quantity_reserved = 0, version = 0 WHERE id = 1;
