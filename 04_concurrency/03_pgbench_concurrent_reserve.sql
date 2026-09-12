-- LAB CONCURRENCY 03: test tự động N request đồng thời -- đúng yêu cầu bắt buộc ở
-- database-design.md §4 ("mô phỏng N request đồng thời mua sản phẩm còn 1 cái ->
-- chỉ 1 đơn thành công", tham chiếu [ECM-044], [ECM-120]).
--
-- File này LÀ script pgbench (không phải chạy trực tiếp bằng \i trong psql).
-- Cách chạy (từ terminal, KHÔNG phải trong psql):
--
--   1) Set tồn kho về 1:
--      psql -d <db> -c "UPDATE inventory_items SET quantity_available = 1, quantity_reserved = 0, version = 0 WHERE id = 1;"
--
--   2) Bắn 20 client đồng thời, mỗi client 1 transaction, dùng đúng file này:
--      pgbench -n -c 20 -j 20 -t 1 -f 04_concurrency/03_pgbench_concurrent_reserve.sql <db>
--
--      -c 20: 20 kết nối đồng thời (mô phỏng 20 user bấm "Mua ngay" cùng lúc)
--      -t 1 : mỗi kết nối chạy đúng 1 lần transaction dưới đây
--
--   3) Kiểm tra kết quả -- PHẢI đúng 1 UPDATE thành công trong 20 lần chạy:
--      psql -d <db> -c "SELECT quantity_available, quantity_reserved, version FROM inventory_items WHERE id = 1;"
--      -- kỳ vọng: quantity_available = 0, quantity_reserved = 1, version = 1
--      -- (không phải quantity_reserved = 20 -- nếu vậy nghĩa là bị oversell, có bug)

\set qty 1

BEGIN;
UPDATE inventory_items
SET quantity_available = quantity_available - :qty,
    quantity_reserved  = quantity_reserved  + :qty,
    version = version + 1
WHERE id = 1 AND quantity_available >= :qty;
COMMIT;

-- Ghi chú: pgbench không tự log "affected rows" ra rõ ràng như psql --
-- nguồn kiểm chứng thật là SELECT ở bước 3, không phải output của pgbench.


-- pgbench là công cụ tự động chạy nhiều giao dịch trên PostgreSQL để kiểm tra hiệu năng và khả năng xử lý đồng thời. 
-- Nó có thể chạy kịch bản SQL bạn viết, rồi đo tốc độ và thời gian xử lý