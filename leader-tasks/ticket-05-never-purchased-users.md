# ECM-305 — Cần list khách hàng chưa từng mua hàng để remarketing

**Priority:** P2
**Reported by:** CRM / Kế toán
**Ngày báo cáo:** 2026-07-29

## Mô tả

> "Bên mình muốn gửi email khuyến mãi 'chào mừng trở lại' cho các tài khoản
> ĐÃ ĐĂNG KÝ nhưng CHƯA TỪNG đặt đơn hàng nào (kể cả đơn bị huỷ — chưa từng
> có bất kỳ đơn nào trong hệ thống). Bạn dev trước có gửi cho mình 1 câu
> query, nhưng khi mình chạy thử thì ra 0 kết quả — chắc chắn là sai vì em
> biết ít nhất vài chục khách chưa mua gì cả. Query đó là:
>
> ```sql
> SELECT id, email FROM users
> WHERE id NOT IN (SELECT customer_id FROM carts);
> ```
>
> (Lưu ý: query này vô tình dùng nhầm bảng `carts` thay vì `orders` — CRM
> chỉ quan tâm 'chưa từng ĐẶT ĐƠN', không phải 'chưa từng tạo giỏ hàng' —
> nhưng bug '0 kết quả' vẫn xảy ra y hệt nếu sửa sang đúng bảng mà không
> sửa cách viết.)"

## Acceptance Criteria
- [ ] Giải thích được vì sao query gốc luôn ra 0 kết quả (dù không sửa gì khác).
- [ ] Query đúng: khách CHƯA TỪNG có bất kỳ đơn hàng nào (đúng bảng `orders`, không phải `carts`).
- [ ] Kết quả phải ra số dương hợp lý, verify được bằng cách đối chiếu tổng: (số khách có đơn) + (số khách chưa có đơn) = tổng số khách.

## Ngữ cảnh bổ sung
- Q: "Đơn CANCELLED có tính là 'đã mua' không?" — A: "Không quan trọng ở ticket này — chỉ cần 'chưa từng có ĐƠN NÀO', bất kể trạng thái gì."

---
## [CHỈ LEAD ĐỌC — KHÔNG lộ cho học viên]

### Root cause thật
Đây LÀ trap `NOT IN` + NULL kinh điển. Bảng bị dùng nhầm (`carts`) có cột
`customer_id` NULLABLE (giỏ hàng khách chưa đăng nhập) — chỉ CẦN 1 dòng NULL
trong subquery, `NOT IN` trả `UNKNOWN` cho MỌI so sánh, toàn bộ query ra 0
dòng một cách ÂM THẦM (không lỗi). Ngay cả khi sửa đúng sang bảng `orders`
(không có NULL ở `customer_id` vì NOT NULL), nếu học viên GIỮ NGUYÊN cấu
trúc `NOT IN` thì lần này sẽ CHẠY ĐÚNG (vì orders.customer_id không NULL) —
đây là điểm dễ gây hiểu lầm "vậy `NOT IN` không có vấn đề gì" trong khi thực
ra chỉ đang MAY vì bảng khác không có NULL. Cần học viên nhận ra rủi ro tiềm
ẩn đó, không chỉ sửa cho ra đúng số ngay lúc này.

### Giải pháp tham khảo
```sql
SELECT count(*) FROM users u
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = u.id);
```
An toàn bất kể cột có NULL hay không — không dựa vào "may rủi" của dữ liệu
hiện tại.

### Bậc hint
1. "Query gốc dùng bảng nào để kiểm tra 'đã mua hàng chưa'? Đúng bảng nghiệp vụ chưa?"
2. "Thử chạy riêng `SELECT customer_id FROM carts` — có dòng nào NULL không?"
3. "`NOT IN` với 1 tập giá trị có NULL trong đó — bạn nghĩ Postgres trả UNKNOWN hay FALSE cho các dòng không khớp?"

### Rubric chấm
- **Đạt tối thiểu:** sửa đúng sang bảng `orders`, ra số dương hợp lý.
- **Đạt tốt:** giải thích ĐÚNG root cause là NULL trong subquery (không phải chỉ "sai bảng"), VÀ chủ động đổi sang `NOT EXISTS` để an toàn về lâu dài — không chỉ sửa vừa đủ để ra số đúng NGAY LÚC NÀY.
- **Cờ đỏ:** chỉ sửa `carts` → `orders`, giữ nguyên `NOT IN`, thấy ra số đúng rồi dừng — không nhận ra đây là "may" vì `orders.customer_id` tình cờ NOT NULL. Nếu học viên dừng ở đây, hỏi tiếp: "nếu sau này có thêm đơn hàng guest (customer_id NULL) thì query này còn đúng không?"
