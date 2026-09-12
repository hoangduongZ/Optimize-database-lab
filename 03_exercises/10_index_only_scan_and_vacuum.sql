-- BÀI 10: Index Only Scan phụ thuộc vào visibility map, KHÔNG chỉ vào việc có index
-- chứa đủ cột hay không. Bài này cho thấy tác động của UPDATE + (chưa) VACUUM.

-- ============================================================
-- Bước 1: tạo covering index cho 1 truy vấn tồn kho hay dùng.
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_inventory_variant_covering
    ON inventory_items (variant_id)
    INCLUDE (quantity_available, quantity_reserved);
DROP INDEX IF EXISTS idx_inventory_variant_covering;  -- chạy lại nhiều lần, tránh duplicate index
-- Lệnh VACUUM sẽ đánh dấu các trang dữ liệu "all-visible" trong visibility map, giúp Index Only Scan có thể đọc trực tiếp từ index mà không cần truy cập heap. Chạy VACUUM trước khi EXPLAIN để thấy hiệu quả.
VACUUM inventory_items;

EXPLAIN (ANALYZE, BUFFERS)
SELECT quantity_available, quantity_reserved
FROM inventory_items
WHERE variant_id = 555;
-- Kỳ vọng: "Index Only Scan" với "Heap Fetches: 0" -- vì bảng vừa VACUUM,
-- visibility map xác nhận toàn bộ trang đều "all-visible".

-- ============================================================
-- Bước 2: mô phỏng traffic ghi liên tục (giống hệ thống reserve/release tồn kho
-- thật) rồi chạy lại query TRƯỚC KHI VACUUM.
-- ============================================================
UPDATE inventory_items
SET quantity_reserved = quantity_reserved + 1, version = version + 1
WHERE variant_id BETWEEN 1 AND 150000;

EXPLAIN (ANALYZE, BUFFERS)
SELECT quantity_available, quantity_reserved
FROM inventory_items
WHERE variant_id = 555;
-- Câu hỏi: "Heap Fetches" bây giờ có còn = 0 không? Vì sao UPDATE lại làm mất
-- tính "all-visible" của trang chứa dòng variant_id = 555 (gợi ý: UPDATE tạo
-- ra 1 phiên bản dòng mới -- MVCC / dead tuple -- visibility map phải reset cho
-- trang đó cho tới khi VACUUM chạy lại).

-- ============================================================
-- TỰ LÀM: chạy VACUUM inventory_items rồi lặp lại EXPLAIN ở Bước 2 -- xác nhận
-- Heap Fetches trở lại 0.
-- ============================================================
-- VACUUM inventory_items;

-- Bài học thực tế: autovacuum thường KHÔNG kịp chạy trên bảng ghi liên tục với
-- tần suất cao (hot table như inventory_items) -- cần tinh chỉnh autovacuum
-- threshold cho riêng bảng đó, hoặc chấp nhận Index Only Scan sẽ không luôn
-- đạt Heap Fetches = 0 trong thực tế production.

SHOW data_directory;

-- ============================================================
-- GHI CHÚ: Hiện Tượng Cốt Lõi (Dead Tuples & VACUUM)
-- ============================================================
--
-- Trong PostgreSQL, lệnh DELETE hoặc UPDATE thực chất không hề xóa hay ghi đè
-- dữ liệu trên đĩa cứng ngay lập tức. Nó chỉ giấu dữ liệu đi. VACUUM chính là
-- công cụ dọn dẹp thứ rác vô hình này để lấy lại không gian lưu trữ vật lý --
-- một khái niệm rất đáng để lưu vào file Optimize-database của bạn.
--
-- ## Bức Tranh Kho Hàng (Đội Lao Công Đêm)
--
-- Hãy tưởng tượng ổ cứng của bạn là một nhà kho khổng lồ.
--
-- - **Lười biếng xóa bỏ**: khi bạn chạy lệnh DELETE, người thủ thư không mang
--   món đồ đó ra bãi rác. Họ chỉ dán một cái tem "Hàng Hết Hạn" lên nó và để
--   nguyên trên kệ.
-- - **Cập nhật là sinh ra rác**: khi bạn chạy UPDATE, thủ thư dán tem "Hết
--   Hạn" lên món cũ, rồi mang một món mới tinh đặt vào một khoảng trống khác
--   trong kho.
-- - **Khủng hoảng không gian**: qua thời gian, kho của bạn chứa đầy rác dán
--   tem "Hết Hạn". Nó chiếm hết chỗ của hàng mới, khiến thủ thư phải đẩy xe đi
--   qua hàng ngàn dãy kệ rác vô nghĩa, làm lãng phí thời gian và tăng vọt chi
--   phí Disk I/O.
-- - **Gọi đội dọn dẹp**: lệnh VACUUM chính là việc phái Đội Lao Công vào nhà
--   kho. Họ đi dọc các dãy kệ, gỡ những món đồ có tem "Hết Hạn" vứt đi, và dọn
--   dẹp sạch sẽ khoảng trống đó để thủ thư có thể xếp hàng mới vào sau này,
--   thay vì phải cơi nới xây thêm nhà kho.
--
-- ## Dịch Sang Ngôn Ngữ Kỹ Thuật (Dead Tuples và FSM)
--
-- - Trong cơ chế MVCC của PostgreSQL, dữ liệu bị dán tem hết hạn được gọi là
--   **Dead Tuples** (bản ghi chết).
-- - Lệnh VACUUM quét qua các trang dữ liệu vật lý (pages) để thu hồi không
--   gian từ các Dead Tuples này.
-- - Sau khi dọn xong, nó cập nhật một tấm bản đồ tên là **Free Space Map
--   (FSM)**, báo cho hệ thống biết: "Trang số 10 hiện đang có chỗ trống, lần
--   sau có lệnh INSERT thì nhét thẳng dữ liệu mới vào đây, đừng ghi nối thêm
--   vào cuối file ổ cứng nữa!"
--
-- > **Lưu ý vật lý**: VACUUM thông thường chỉ dọn chỗ bên trong file dữ liệu
-- > để tái sử dụng, chứ không làm file nhỏ lại. Để ép file trên hệ điều hành
-- > thực sự teo nhỏ lại, phải dùng `VACUUM FULL` (khóa toàn bộ bảng và mất rất
-- > nhiều thời gian để xây lại toàn bộ nhà kho).
--
-- ## Thử Nghiệm Phá Hoại (Bơm rác và dọn rác)
--
-- Hãy tự mình chứng kiến sự xuất hiện của đống rác vật lý bằng bài test sau:
--
-- 1. Tạo một bảng mới và INSERT 1 triệu dòng dữ liệu. Dùng hàm
--    `SELECT pg_size_pretty(pg_relation_size('ten_bang'));` để xem dung lượng
--    vật lý (ví dụ: nó báo là 40MB).
-- 2. Chạy lệnh `UPDATE ten_bang SET cot_nao_do = gia_tri_moi;` cho toàn bộ 1
--    triệu dòng đó.
-- 3. Kiểm tra lại dung lượng bảng -- sẽ phình lên gấp đôi (thành 80MB)! Hệ
--    thống đang chứa 1 triệu bản ghi cũ (rác) và 1 triệu bản ghi mới.
-- 4. Chạy lệnh `VACUUM ten_bang;`. Lần tới khi INSERT thêm dữ liệu mới, dung
--    lượng file sẽ không phình lên thành 120MB nữa, vì khoảng trống 40MB rác
--    cũ đã được đội lao công dọn dẹp để hệ thống ghi đè lên an toàn.