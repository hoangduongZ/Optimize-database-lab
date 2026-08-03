# ECM-306 — Trang quản trị đơn hàng càng vào sâu càng chậm

**Priority:** P1
**Reported by:** Vận hành / Admin
**Ngày báo cáo:** 2026-08-01

## Mô tả

> "Trang quản trị đơn hàng (admin xem toàn bộ đơn, sort theo mới nhất) —
> trang 1-2 load bình thường, nhưng nhân viên vận hành nào cứ bấm 'trang
> sau' liên tục để tìm 1 đơn cũ thì tới khoảng trang 100+ là load rất lâu,
> đôi khi timeout. Query hiện tại:
>
> ```sql
> SELECT id, order_number, order_status, placed_at
> FROM orders
> ORDER BY id DESC
> LIMIT 20 OFFSET :page * 20;
> ```
>
> Bên vận hành hỏi có cách nào để tìm đơn cũ mà không cần bấm next 100 lần
> không, tiện thể luôn."

## Acceptance Criteria
- [ ] Giải thích được vì sao trang đầu nhanh nhưng trang sâu chậm — bằng số liệu `EXPLAIN ANALYZE` thật, không suy đoán.
- [ ] Đề xuất giải pháp giữ tốc độ ỔN ĐỊNH bất kể đang ở "trang" nào.
- [ ] Nêu rõ đánh đổi của giải pháp (nếu có) — đặc biệt nếu giải pháp làm mất khả năng "nhảy thẳng tới trang số N" của UI hiện tại.
- [ ] Đề xuất phải tương thích với việc UI vận hành muốn "tìm đơn cũ" — tức cần đi được xa, không chỉ tối ưu 2 trang đầu.

## Ngữ cảnh bổ sung
- Q: "UI hiện tại có ô nhập 'đến trang số...' không?" — A: "Không, chỉ có nút Next/Previous — đây là điểm quan trọng, hỏi kỹ trước khi chọn giải pháp."
- Q: "Có cần giữ nguyên URL dạng `?page=N` không?" — A: "Không bắt buộc, chỉ cần UX Next/Previous mượt — đổi cách truyền tham số (vd dùng `last_id` thay `page`) là ĐƯỢC PHÉP."

---
## [CHỈ LEAD ĐỌC — KHÔNG lộ cho học viên]

### Root cause thật
`OFFSET N` buộc Postgres phải ĐỌC và BỎ hết N dòng đầu trước khi trả 20
dòng tiếp theo — dù mỗi dòng đọc "rẻ" (có index trên `id`), tổng chi phí
vẫn tăng TUYẾN TÍNH theo số trang. Ở trang 100 (`OFFSET 2000`), Postgres đã
phải xử lý qua 2020 dòng chỉ để trả 20 dòng cuối.

### Giải pháp tham khảo
Keyset (cursor) pagination — không dùng `OFFSET`, dùng điều kiện so sánh
trên giá trị dòng CUỐI của trang trước:
```sql
-- Trang đầu
SELECT id, order_number, order_status, placed_at
FROM orders ORDER BY id DESC LIMIT 20;

-- Trang tiếp theo, biết id nhỏ nhất đã thấy ở trang trước là :last_seen_id
SELECT id, order_number, order_status, placed_at
FROM orders
WHERE id < :last_seen_id
ORDER BY id DESC
LIMIT 20;
```
Vì đã hỏi kỹ ngữ cảnh — UI chỉ có Next/Previous, không có "nhảy tới trang
N" — đánh đổi "mất khả năng nhảy trang tuỳ ý" của keyset là HOÀN TOÀN CHẤP
NHẬN ĐƯỢC cho ticket này.

### Bậc hint
1. "Trang 1 và trang 100 khác nhau ở tham số nào trong query? `OFFSET` đó ảnh hưởng gì tới việc Postgres phải đọc bao nhiêu dòng?"
2. "Nếu UI không cần nhảy thẳng tới trang số N (chỉ Next/Previous), bạn có cần biết CHÍNH XÁC mình đang ở 'trang thứ mấy' không, hay chỉ cần biết 'tiếp theo id nào'?"
3. "Thử viết lại query KHÔNG dùng `OFFSET`, dùng điều kiện `WHERE id < ...` dựa trên dòng cuối trang trước."

### Rubric chấm
- **Đạt tối thiểu:** đề xuất đúng keyset pagination, đo được cải thiện rõ ở "trang sâu" (không còn tăng chi phí theo độ sâu).
- **Đạt tốt:** CHỦ ĐỘNG hỏi/xác nhận UI có cần "nhảy tới trang N" không TRƯỚC KHI chọn keyset — vì đây là đánh đổi thật, không phải giải pháp "luôn đúng trong mọi trường hợp".
- **Cờ đỏ:** đề xuất "thêm index" trên `id` mà không nhận ra `orders.id` (PK) đã có index sẵn từ đầu — vấn đề không nằm ở thiếu index, mà ở CHIẾN LƯỢC phân trang.
