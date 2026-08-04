# Drill 06 — SQL Query Concepts & EXPLAIN/Performance

## Q1: Các loại JOIN chính, khác nhau thế nào?
**Trả lời ngắn:** **INNER JOIN** — chỉ giữ dòng khớp ở CẢ HAI bảng. **LEFT
JOIN** — giữ TOÀN BỘ bảng trái, cột bảng phải là NULL nếu không khớp.
**RIGHT JOIN** — ngược lại LEFT (hiếm dùng, thường viết lại thành LEFT cho
dễ đọc). **FULL JOIN** — giữ cả 2 bên, NULL ở bên không khớp.

**Follow-up hay gặp:** "Muốn tìm dòng bảng A KHÔNG có liên kết ở bảng B thì
viết sao?" — `LEFT JOIN B ON ... WHERE B.id IS NULL` (xem [Track A Level 1](../01-queries/level-01-join-inner-left.md)).

**Bẫy hay gặp:** Quên rằng JOIN quan hệ 1-nhiều làm dòng bên "1" bị NHÂN
BẢN (fan-out) — `count(*)` sau JOIN có thể KHÔNG bằng số dòng bảng gốc.

---

## Q2: `WHERE` và `HAVING` khác nhau ở đâu?
**Trả lời ngắn:** `WHERE` lọc DÒNG THÔ, chạy TRƯỚC `GROUP BY` — không dùng
được hàm aggregate (`count`, `sum`...). `HAVING` lọc NHÓM, chạy SAU
`GROUP BY` — dùng được hàm aggregate, vì lúc này aggregate đã có kết quả.

**Follow-up hay gặp:** "Viết `WHERE count(*) > 5` được không?" — Không,
lỗi cú pháp (`aggregate functions are not allowed in WHERE clause`) — phải
dùng `HAVING count(*) > 5`.

**Bẫy hay gặp:** Đặt điều kiện lọc DÒNG (vd `status = 'ACTIVE'`) vào
`HAVING` thay vì `WHERE` — vẫn ra đúng kết quả nhưng KÉM HIỆU QUẢ (lọc
muộn hơn cần thiết, sau khi đã tốn công group những dòng lẽ ra bị loại từ
đầu).

---

## Q3: Khi nào dùng CTE, khi nào dùng subquery, khi nào dùng window function?
**Trả lời ngắn:** **CTE** (`WITH ... AS`) — khi cần đặt tên cho 1 bước
trung gian để query DỄ ĐỌC hơn, đặc biệt khi dùng lại nhiều lần. **Subquery**
— lồng trực tiếp, phù hợp cho check tồn tại (`EXISTS`) hay 1 giá trị đơn.
**Window function** (`OVER (PARTITION BY...)`) — khi cần tính toán XUYÊN
QUA từng dòng trong 1 nhóm mà KHÔNG gộp dòng lại (ranking, running total,
so với dòng trước/sau) — khác `GROUP BY` (gộp dòng).

**Follow-up hay gặp:** "CTE có luôn nhanh/chậm hơn subquery tương đương
không?" — TUỲ VERSION Postgres: từ bản 12+, CTE không đệ quy CÓ THỂ được
planner INLINE (tối ưu như subquery thường) — không còn là "optimization
fence" tuyệt đối như trước (xem [Track A Level 5](../01-queries/level-05-cte-window-functions.md) và [Track B Level 9](../02-optimize/level-09-cte-window-subquery.md)).

**Bẫy hay gặp:** Khẳng định chắc chắn "CTE luôn chậm hơn/nhanh hơn subquery"
— câu trả lời ĐÚNG phải là "tuỳ, cần xem EXPLAIN thật", không phải quy tắc
cứng.

---

## Q4: N+1 query problem là gì, cách fix?
**Trả lời ngắn:** Lấy N dòng ở query đầu, rồi LẶP LẠI N lần 1 query riêng
để lấy dữ liệu liên quan cho MỖI dòng đó — tổng cộng 1 + N round-trip tới
DB thay vì 1. Fix: gộp thành 1 query DUY NHẤT bằng `JOIN` hoặc `WHERE id IN
(...)`, ở tầng ORM thường gọi là "eager loading" / `JOIN FETCH`.

**Follow-up hay gặp:** "N+1 có phải lúc nào cũng là JOIN sai không?" —
Không, thường là do CODE (ORM lazy-load trong 1 loop), không phải do viết
SQL sai cú pháp — cần sửa ở TẦNG GỌI QUERY, không chỉ ở 1 câu SQL đơn lẻ
(xem [Track A Level 1](../01-queries/level-01-join-inner-left.md) và
[`03_exercises/08_n_plus_one_vs_join.sql`](../../03_exercises/08_n_plus_one_vs_join.sql)).

**Bẫy hay gặp:** Nghĩ N+1 chỉ là vấn đề "chậm nhẹ" — với N lớn (vd hiển thị
danh sách 100 đơn hàng), đây có thể là nguyên nhân CHÍNH gây timeout.

---

## Q5: Đọc EXPLAIN cơ bản — 3 con số/khái niệm quan trọng nhất?
**Trả lời ngắn:** (1) **Loại scan** — Seq Scan (đọc hết bảng) vs Index Scan
/ Bitmap Heap Scan (dùng index). (2) **`cost=start..total`** — ước lượng
TƯƠNG ĐỐI của planner, KHÔNG phải milliseconds. (3) **estimate rows vs
actual rows** (`(cost=... rows=N) (actual ... rows=M)`) — khi 2 số này lệch
xa, statistics của planner đang bị stale, cần `ANALYZE`.

**Follow-up hay gặp:** "`EXPLAIN` thường và `EXPLAIN ANALYZE` khác gì, khi
nào KHÔNG nên dùng ANALYZE?" — `ANALYZE` THỰC SỰ CHẠY câu query (không chỉ
ước lượng) — không nên dùng cho `DELETE`/`UPDATE` production nếu không chắc
(dù có thể bọc trong transaction rồi ROLLBACK để an toàn).

**Bẫy hay gặp:** Chỉ nhìn `cost` mà kết luận query "nhanh hay chậm" — cost
là ước lượng của PLANNER, không phải thời gian thật; phải nhìn `actual
time`.

---

## Q6: `OFFSET` pagination có vấn đề gì với dữ liệu lớn, cách khác?
**Trả lời ngắn:** `OFFSET N` buộc Postgres đọc và BỎ QUA N dòng đầu trước
khi trả kết quả — chi phí tăng TUYẾN TÍNH theo N, dù có index. Giải pháp:
**keyset (cursor) pagination** — dùng điều kiện `WHERE id < :last_seen_id`
dựa trên dòng cuối trang trước, thay vì đếm offset.

**Follow-up hay gặp:** "Đánh đổi của keyset pagination là gì?" — Mất khả
năng nhảy thẳng tới "trang số N" tuỳ ý (chỉ next/previous tuần tự) — chấp
nhận được cho hầu hết UI dạng feed, KHÔNG phù hợp nếu UI có ô nhập "đến
trang số..." (xem [Track B Level 7 tương đương / ticket ECM-306](../../leader-tasks/ticket-06-admin-pagination-slow.md)).

**Bẫy hay gặp:** Đề xuất "thêm index" để fix chậm do OFFSET — index không
giúp được gì ở đây, vấn đề là CHIẾN LƯỢC phân trang, không phải thiếu
index.
