-- LAB CONCURRENCY 01: tái hiện lỗi oversell kinh điển ("check-then-act" / TOCTOU).
-- Đây KHÔNG phải lỗi do thiếu index -- là lỗi LOGIC: đọc số lượng tồn (SELECT),
-- quyết định ở tầng application, rồi mới UPDATE bằng giá trị đã tính sẵn -- không
-- có gì khoá dòng dữ liệu giữa 2 bước đó.
--
-- Cách chạy: mở 2 terminal, mỗi terminal 1 session `psql`, dán lệnh theo đúng thứ tự
-- thời gian ghi trong comment (A1, B1, A2, B2, A3, B3...).

-- Chuẩn bị: 1 sản phẩm chỉ còn đúng 1 cái trong kho.
UPDATE inventory_items SET quantity_available = 1, quantity_reserved = 0, version = 0
WHERE id = 1;

-- ============================================================
-- Terminal A                              | Terminal B
-- ============================================================
-- A1: (chạy trước)
BEGIN;
SELECT quantity_available FROM inventory_items WHERE id = 1;   -- trả về 1 -- app A nghĩ "còn hàng, mua được"
SELECT pg_sleep(5);  -- mô phỏng thời gian xử lý business logic (validate coupon, tính tiền,...)

--                                          B1: (chạy trong lúc A đang pg_sleep, tức trong 5 giây trên)
--                                          BEGIN;
--                                          SELECT quantity_available FROM inventory_items WHERE id = 1;  -- CŨNG trả về 1!
--                                          SELECT pg_sleep(1);

-- A2: (sau khi A's pg_sleep(5) kết thúc)
UPDATE inventory_items SET quantity_available = 0, quantity_reserved = 1, version = version + 1
WHERE id = 1;   -- app A tự tính "1 - 1 = 0" rồi ghi thẳng giá trị này
COMMIT;

--                                          B2: (sau khi B's pg_sleep(1) kết thúc, có thể trước hoặc sau A COMMIT)
--                                          UPDATE inventory_items SET quantity_available = 0, quantity_reserved = 1, version = version + 1
--                                          WHERE id = 1;   -- app B CŨNG tự tính "1 - 1 = 0" -- không biết A vừa mới bán
--                                          COMMIT;

-- ============================================================
-- KẾT QUẢ: cả A và B đều COMMIT thành công, cả 2 đơn hàng đều nghĩ mình đã giữ
-- được hàng -- nhưng kho chỉ có 1 cái. Kiểm tra lại:
-- ============================================================
SELECT quantity_available, quantity_reserved, version FROM inventory_items WHERE id = 1;
-- quantity_reserved = 1 (do cả 2 UPDATE đều ghi cứng giá trị 1, không dùng phép + tương đối)
-- nhưng thực tế có 2 "đơn hàng" (2 session) đều tin rằng họ đã reserve thành công
-- -> oversell nếu cả 2 UPDATE này gắn với 2 order khác nhau trong hệ thống thật.
--
-- Đây chính là vì sao database-design.md §4 yêu cầu KHÔNG BAO GIỜ tách
-- "đọc số dư rồi tính ở app rồi ghi lại" -- phải dùng UPDATE ... WHERE
-- quantity_available >= :qty như bài 02_safe_reserve_manual_demo.sql.

-- Dọn dẹp trước khi làm bài tiếp theo:
UPDATE inventory_items SET quantity_available = 1, quantity_reserved = 0, version = 0 WHERE id = 1;
