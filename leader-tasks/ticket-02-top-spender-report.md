# ECM-302 — Báo cáo Top khách hàng chi tiêu nhiều nhất

**Priority:** P2
**Reported by:** Marketing Manager
**Ngày báo cáo:** 2026-07-28

## Mô tả

> "Bên mình đang lên kế hoạch chương trình khách hàng VIP. Nhờ team lấy
> giúp: Top 20 khách hàng chi tiêu nhiều nhất trong 90 ngày qua, kèm email,
> tổng số đơn đã đặt, và ngày đặt hàng gần nhất của họ. Chỉ tính đơn đã
> **DELIVERED** (đơn huỷ/đang xử lý không tính vào chi tiêu). Cần trước thứ
> 5 để họp team marketing."

## Acceptance Criteria
- [ ] Kết quả đúng 20 dòng (hoặc ít hơn nếu không đủ 20 khách thoả điều kiện), sắp theo tổng chi tiêu giảm dần.
- [ ] Tổng chi tiêu CHỈ tính đơn `order_status = 'DELIVERED'`.
- [ ] Có đủ 4 cột: email, tổng chi tiêu, tổng số đơn DELIVERED, ngày đặt hàng gần nhất (bất kể trạng thái đơn đó là gì — khách vẫn có thể vừa đặt 1 đơn mới đang PENDING).
- [ ] Chỉ tính đơn có `placed_at` trong 90 ngày gần nhất (tính từ lúc chạy báo cáo).

## Ngữ cảnh bổ sung
- Q: "'Ngày đặt gần nhất' tính trên đơn DELIVERED hay mọi đơn?" — A: "Mọi đơn — muốn biết khách còn hoạt động hay không, không chỉ đơn đã giao."
- Q: "Nếu khách chưa từng có đơn DELIVERED nào trong 90 ngày thì sao?" — A: "Không cần xuất hiện trong báo cáo — đây là báo cáo TOP chi tiêu, không phải toàn bộ khách hàng."

---
## [CHỈ LEAD ĐỌC — KHÔNG lộ cho học viên]

### Root cause / bản chất bài toán
Không phải bug — đây là yêu cầu viết ĐÚNG 1 truy vấn tổng hợp nhiều điều
kiện: aggregate có lọc theo trạng thái CHỈ cho phần "tổng chi tiêu", nhưng
"ngày gần nhất" KHÔNG lọc theo trạng thái đó — 2 điều kiện lọc khác nhau
trên CÙNG 1 khách hàng, dễ bị gộp nhầm thành 1 nếu không tách rõ.

### Giải pháp tham khảo
```sql
SELECT u.email,
       spend.total_spent,
       spend.delivered_order_count,
       last_order.last_placed_at
FROM users u
JOIN (
    SELECT customer_id, sum(total_amount) AS total_spent, count(*) AS delivered_order_count
    FROM orders
    WHERE order_status = 'DELIVERED' AND placed_at >= now() - interval '90 days'
    GROUP BY customer_id
) spend ON spend.customer_id = u.id
JOIN (
    SELECT customer_id, max(placed_at) AS last_placed_at
    FROM orders
    WHERE placed_at >= now() - interval '90 days'
    GROUP BY customer_id
) last_order ON last_order.customer_id = u.id
ORDER BY spend.total_spent DESC
LIMIT 20;
```
Lỗi thường gặp: gộp cả 2 điều kiện lọc (`order_status='DELIVERED'` và
"90 ngày") vào 1 `WHERE` duy nhất rồi tính `max(placed_at)` trên CÙNG tập đã
lọc DELIVERED — khi đó "ngày gần nhất" sẽ SAI nếu đơn gần nhất của khách
đang ở trạng thái khác (PENDING/CANCELLED...).

### Bậc hint
1. "Thử tách yêu cầu thành 2 câu hỏi con: (a) tổng chi tiêu DELIVERED theo khách, (b) đơn gần nhất bất kỳ trạng thái theo khách. Viết riêng từng câu trước."
2. "2 câu con đó có dùng CHUNG 1 điều kiện `WHERE order_status='DELIVERED'` được không?"
3. "Ghép 2 kết quả con lại bằng JOIN theo `customer_id`, đừng cố nhồi hết vào 1 `GROUP BY` duy nhất."

### Rubric chấm
- **Đạt tối thiểu:** ra đúng 20 dòng, tổng chi tiêu đúng (chỉ DELIVERED).
- **Đạt tốt:** "ngày gần nhất" ĐÚNG dù đơn gần nhất không phải DELIVERED — chứng minh học viên hiểu 2 điều kiện lọc độc lập.
- **Cờ đỏ:** dùng 1 `WHERE order_status = 'DELIVERED'` áp cho CẢ 2 cột tổng hợp — sai theo đúng acceptance criteria dòng 2, dấu hiệu cần quay lại Track A Level 3 (WHERE lọc dòng trước GROUP BY, ảnh hưởng TOÀN BỘ các cột aggregate sau đó, không lọc riêng được từng cột).
