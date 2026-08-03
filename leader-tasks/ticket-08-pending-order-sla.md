# ECM-308 — Job tự huỷ đơn PENDING quá hạn đang trễ SLA

**Priority:** P1
**Reported by:** Vận hành kho
**Ngày báo cáo:** 2026-08-01

## Mô tả

> "Có 1 job chạy mỗi phút để tìm các đơn đang PENDING quá 30 phút (khách bỏ
> giữa đường, chưa thanh toán) để tự huỷ và giải phóng tồn kho đã giữ. Gần
> đây job này bắt đầu chạy quá 1 phút (có lúc 2-3 phút) — nghĩa là lần chạy
> sau chồng lên lần chạy trước, kho phàn nàn tồn kho bị giữ lâu hơn dự kiến.
> Query của job:
>
> ```sql
> SELECT id, customer_id, placed_at
> FROM orders
> WHERE order_status = 'PENDING' AND placed_at < now() - interval '30 minutes';
> ```
>
> Bảng `orders` hiện ~150k dòng và tăng dần mỗi ngày. Cần fix để job chạy
> ổn định dưới 1 giây, không ảnh hưởng tần suất chạy (vẫn mỗi phút)."

## Acceptance Criteria
- [ ] Query của job chạy dưới 50ms trên dữ liệu hiện tại.
- [ ] Giải pháp phải TIẾP TỤC hiệu quả khi bảng `orders` tăng lên hàng triệu dòng (không phải fix tạm chỉ đúng với 150k dòng hiện tại) — đơn PENDING luôn là thiểu số so với tổng số đơn.
- [ ] Không ảnh hưởng tới các query KHÁC đang chạy trên bảng `orders` (không đổi cấu trúc bảng theo cách phá query khác).
- [ ] Nêu được: nếu sau này có thêm 1 job khác quét theo `order_status IN ('PENDING', 'CONFIRMED')`, giải pháp hiện tại còn phát huy tác dụng cho job đó không.

## Ngữ cảnh bổ sung
- Q: "Đơn PENDING chiếm bao nhiêu % tổng đơn?" — A: "Ước chừng 10-15%, hầu hết đơn chuyển trạng thái khác trong vài phút."
- Q: "Có thể đổi tần suất job (vd 5 phút/lần) không?" — A: "Không nên — SLA giữ tồn kho phụ thuộc job chạy đúng mỗi phút, đổi tần suất là thay đổi SLA, ngoài phạm vi ticket."

---
## [CHỈ LEAD ĐỌC — KHÔNG lộ cho học viên]

### Root cause thật
Không có index nào hỗ trợ filter `order_status = 'PENDING' AND placed_at <
...` — Seq Scan toàn bảng `orders` mỗi phút. Bảng tăng dần theo thời gian
→ thời gian Seq Scan tăng dần → tới lúc vượt 1 phút, các lần chạy chồng lấn
nhau.

### Giải pháp tham khảo
Partial index — vì PENDING luôn là THIỂU SỐ cố định trong 1 tập giá trị
enum nhỏ, không phải điều kiện range/tuỳ biến:
```sql
CREATE INDEX idx_orders_pending_placed_at
    ON orders (placed_at)
    WHERE order_status = 'PENDING';
```
Trả lời câu hỏi bổ sung: index này CHỈ hỗ trợ query có `WHERE order_status =
'PENDING'` (điều kiện ĐÚNG BẰNG, không phải superset) — nếu sau này có job
quét `IN ('PENDING', 'CONFIRMED')`, index này KHÔNG được dùng cho job đó
(cần đánh giá lại, có thể cần thêm 1 partial index khác hoặc composite
index thường tuỳ tỷ lệ dữ liệu lúc đó).

### Bậc hint
1. "Query lọc theo 2 điều kiện, nhưng chỉ áp dụng cho 1 tập giá trị enum nhỏ và LUÔN CỐ ĐỊNH ('PENDING'). Có loại index nào tối ưu riêng cho use case 'chỉ cần đúng 1 giá trị filter, không cần toàn bảng' không?"
2. "So sánh kích thước giữa: index thường trên `(order_status, placed_at)` cho TOÀN BẢNG, và 1 index CHỈ chứa các dòng PENDING. Cái nào nhỏ hơn?"
3. "Thử tạo cả 2 loại, dùng `\\di+` xem kích thước, và `EXPLAIN ANALYZE` xem cái nào nhanh hơn cho ĐÚNG query của job."

### Rubric chấm
- **Đạt tối thiểu:** tạo đúng partial index, đo được cải thiện, giải thích được vì sao nhỏ/rẻ hơn index thường.
- **Đạt tốt:** trả lời đúng câu hỏi "còn tác dụng với job `IN (...)` không" — nhận ra hạn chế của partial index, không quảng bá nó như giải pháp vạn năng.
- **Cờ đỏ:** đề xuất composite index thường `(order_status, placed_at)` mà không so sánh với partial index — VẪN giải quyết được acceptance criteria hiện tại (chạy nhanh), nhưng bỏ lỡ tối ưu về kích thước/chi phí ghi lâu dài; chấp nhận NHƯNG phải hỏi thêm "bạn có cân nhắc partial index chưa, và vì sao chọn cách này" trước khi đóng ticket ở mức "đạt tốt".
