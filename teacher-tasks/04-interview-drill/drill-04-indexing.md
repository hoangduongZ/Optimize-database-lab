# Drill 04 — Indexing

## Q1: B-tree index hoạt động thế nào ở mức khái niệm?
**Trả lời ngắn:** Cấu trúc cây CÂN BẰNG, dữ liệu được SẮP XẾP theo giá trị
cột được index. Tìm 1 giá trị mất `O(log n)` (đi từ gốc cây xuống lá) thay
vì đọc tuần tự toàn bảng `O(n)`. Vì đã sắp xếp sẵn, cũng hỗ trợ tốt cho
`ORDER BY`, range query (`>`, `<`, `BETWEEN`).

**Follow-up hay gặp:** "Vậy sao không index MỌI cột luôn cho nhanh?" — Mỗi
index tốn: (1) dung lượng đĩa riêng, (2) chi phí GHI THÊM mỗi khi
INSERT/UPDATE/DELETE (phải cập nhật MỌI index liên quan, không chỉ bảng
chính).

**Bẫy hay gặp:** Nghĩ index luôn giúp — quên rằng planner có thể CHỌN KHÔNG
DÙNG index dù có sẵn, nếu Seq Scan rẻ hơn (xem Q2).

---

## Q2: Khi nào Postgres KHÔNG dùng 1 index dù nó tồn tại?
**Trả lời ngắn:** (1) Selectivity thấp — điều kiện khớp PHẦN LỚN bảng (vd
>20-30%), Seq Scan đọc tuần tự rẻ hơn Index Scan đọc rải rác từng dòng. (2)
Hàm bọc lên cột đã index (`WHERE upper(name) = ...` trong khi index trên
`name` thường) — non-sargable. (3) Composite index nhưng điều kiện WHERE
không bắt đầu từ cột ĐẦU (leading column). (4) Bảng quá nhỏ — chi phí mở
index còn đắt hơn đọc thẳng vài trang dữ liệu.

**Follow-up hay gặp:** "Làm sao biết CHÍNH XÁC vì sao planner chọn Seq Scan
thay Index Scan?" — Chạy `EXPLAIN (ANALYZE, BUFFERS)`, so sánh cost/actual
rows, không suy đoán (xem [Track B Level 2](../02-optimize/level-02-explain-basics.md)).

**Bẫy hay gặp:** Thấy Seq Scan trong EXPLAIN rồi VỘI kết luận "thiếu index"
— nhiều khi Seq Scan là lựa chọn ĐÚNG (selectivity thấp), tạo thêm index
không giúp gì, chỉ tốn chi phí ghi.

---

## Q3: Composite index — thứ tự cột ảnh hưởng thế nào?
**Trả lời ngắn:** Index `(a, b, c)` giống tra từ điển sắp theo A-B-C — dùng
hiệu quả khi điều kiện WHERE bắt đầu từ cột `a` (leading column). Query chỉ
lọc theo `b` (không có `a`) KHÔNG dùng được index này hiệu quả. Nguyên tắc
đặt thứ tự: cột lọc bằng `=` đặt trước, cột dùng `ORDER BY` đặt cuối — để
index vừa lọc vừa trả kết quả ĐÃ ĐÚNG THỨ TỰ, tránh phải `Sort` riêng.

**Follow-up hay gặp:** "Tạo 3 index đơn lẻ cho `a`, `b`, `c` riêng có thay
thế được 1 composite index không?" — CÓ THỂ giúp phần LỌC (Postgres kết hợp
bằng `BitmapAnd`), nhưng KHÔNG loại bỏ được bước `Sort` riêng cho
`ORDER BY` — composite index đúng thứ tự vẫn tốt hơn (xem [ticket ECM-301](../../leader-tasks/ticket-01-category-page-slow.md)).

**Bẫy hay gặp:** Nghĩ thứ tự cột trong composite index "không quan trọng,
Postgres tự tối ưu" — SAI, thứ tự quyết định index có dùng được hay không
cho 1 query cụ thể.

---

## Q4: Covering index (`INCLUDE`) và Index Only Scan là gì?
**Trả lời ngắn:** Covering index nhồi thêm cột KHÔNG dùng để tìm kiếm nhưng
cần ĐỌC vào chính index đó (`INCLUDE (col)`) — nếu index đã chứa ĐỦ mọi cột
cần trả về, Postgres có thể trả kết quả mà KHÔNG cần ghé "heap" (bảng
chính) — gọi là Index Only Scan.

**Follow-up hay gặp:** "Chỉ cần index đủ cột là chắc có Index Only Scan?" —
KHÔNG, còn cần "visibility map" xác nhận page đó ALL-VISIBLE (không có dead
tuple chưa dọn) — nếu bảng vừa bị UPDATE nhiều, cần `VACUUM` lại trước khi
Index Only Scan hoạt động đúng (`Heap Fetches: 0` trong EXPLAIN) (xem
[Track B Level 6+8](../02-optimize/level-06-covering-index-inventory.md)).

**Bẫy hay gặp:** Nghĩ covering index luôn nên dùng "cho chắc" — mỗi cột
thêm vào `INCLUDE` vẫn tốn dung lượng + chi phí ghi, chỉ nên thêm cột THỰC
SỰ hay được SELECT cùng điều kiện lọc đó.

---

## Q5: Partial index là gì, khi nào dùng?
**Trả lời ngắn:** Index chỉ chứa các dòng THOẢ 1 điều kiện `WHERE` cố định
(vd `WHERE status = 'PENDING'`) — nhỏ hơn, rẻ hơn index toàn bảng, dùng khi
chỉ cần tối ưu cho 1 tập con "nóng" nhỏ trong 1 bảng lớn.

**Follow-up hay gặp:** "Query dùng `status IN ('PENDING', 'CONFIRMED')` có
dùng được partial index `WHERE status = 'PENDING'` không?" — KHÔNG, điều
kiện query phải "implies" được predicate của index — superset không hợp lệ.

**Bẫy hay gặp:** Quảng bá partial index như giải pháp vạn năng — chỉ hợp lý
khi tập con filter đó CỐ ĐỊNH và thực sự nhỏ so với toàn bảng.
