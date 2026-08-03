# ECM-309 — "Làm cho anh 1 dashboard tổng hợp"

**Priority:** P2
**Reported by:** Giám đốc vận hành
**Ngày báo cáo:** 2026-08-03

## Mô tả

> "Anh cần 1 dashboard tổng hợp cho buổi họp sáng mai: doanh thu, khách
> hàng, và sản phẩm. Em làm giúp anh nhé, càng sớm càng tốt."

Đúng vậy — mô tả CHỈ có vậy. Đây là ticket thật kiểu này vẫn xảy ra: yêu cầu
mơ hồ, không có acceptance criteria rõ, deadline gấp. **Không tự suy diễn
scope** — việc ĐẦU TIÊN cần làm là hỏi lại, giống 1 kỹ sư thật sẽ làm trước
khi viết bất kỳ dòng SQL nào.

## Acceptance Criteria
- [ ] KHÔNG bắt đầu viết SQL trước khi đã hỏi rõ scope (tối thiểu: khoảng thời gian, đơn vị đo "doanh thu" tính trên trạng thái đơn nào, "khách hàng" nghĩa là gì trong context này, "sản phẩm" là top bán chạy hay tồn kho thấp hay gì khác).
- [ ] Sau khi scope rõ, đưa ra được danh sách CỤ THỂ các chỉ số sẽ làm — và deadline "sáng mai" có khả thi với scope đó không (nếu không khả thi, phải NÓI RA, không âm thầm cắt giảm).
- [ ] Từng chỉ số phải có 1 query cụ thể, ĐÚNG, và chạy đủ nhanh để "xem trực tiếp trong buổi họp" (không phải batch job chạy nền).
- [ ] Trình bày lại được cho "giám đốc" (lead) hiểu — không dùng thuật ngữ kỹ thuật khi giải thích Ý NGHĨA từng số liệu.

## Ngữ cảnh bổ sung (LEAD tự ứng biến nếu học viên hỏi thêm, không có sẵn "đáp án đúng" — đây là 1 con người bận, trả lời ngắn, đôi khi mâu thuẫn nhẹ)
Gợi ý cho LEAD khi đóng vai trả lời (không đọc nguyên văn cho học viên,
dùng để ỨNG BIẾN câu trả lời hợp lý khi bị hỏi):
- Nếu hỏi "khoảng thời gian nào?" → "Tháng này, so với tháng trước nữa cho có so sánh."
- Nếu hỏi "doanh thu tính đơn nào?" → nghĩ 1 lúc rồi: "Đơn đã giao thành công thôi, đơn huỷ tính gì được."
- Nếu hỏi "khách hàng nghĩa là gì — tổng số, khách mới, khách VIP?" → "À... khách MỚI trong tháng, với cả top khách chi nhiều luôn nếu được."
- Nếu hỏi "sản phẩm là gì?" → "Sản phẩm bán chạy nhất, để biết nên nhập thêm hàng gì."
- Nếu học viên hỏi "vậy còn hàng tồn kho thấp thì sao?" (tự đề xuất thêm) → "Ồ, ý hay, thêm luôn đi" (khen chủ động mở rộng scope hợp lý, nhưng lưu ý học viên phải tự cân đối thời gian/deadline).
- Nếu học viên hỏi dồn quá nhiều câu 1 lúc mà không tổng hợp lại → "Em tổng hợp lại giúp anh xem cần làm gì, list ra đi, khỏi hỏi từng câu."

---
## [CHỈ LEAD ĐỌC — KHÔNG lộ cho học viên]

### Bản chất bài toán
Đây KHÔNG phải bug hay bài toán kỹ thuật khó — là bài kiểm tra kỹ năng
LÀM RÕ YÊU CẦU trước khi code, thứ nhiều kỹ sư giỏi kỹ thuật vẫn bỏ qua.
Nếu học viên lập tức viết SQL mà không hỏi gì, đây là tín hiệu quan trọng
cần feedback ngay, kể cả nếu SQL họ viết ra "đúng" theo 1 cách diễn giải nào
đó.

### Scope hợp lý sau khi làm rõ (dùng để chấm, không phải để đọc cho học viên)
- **Doanh thu:** tổng `total_amount` của đơn `DELIVERED`, tháng hiện tại vs tháng trước (2 số, có % thay đổi).
- **Khách hàng:** số khách MỚI đăng ký trong tháng (từ `users.created_at`) + top 5-10 khách chi tiêu nhiều nhất (như ECM-302, có thể tái dùng).
- **Sản phẩm:** top N sản phẩm bán chạy nhất theo `sum(order_items.quantity)` trong tháng, join `order_items` → `orders` (lọc DELIVERED, trong tháng) → `products`.
- Toàn bộ query nên chạy < 1-2 giây mỗi cái (dashboard xem trực tiếp, không phải báo cáo offline) — nếu chậm, đây là cơ hội áp lại Track B (index phù hợp).

### Bậc hint
1. (Nếu học viên bắt đầu viết SQL ngay) — "Trước khi viết, bạn có chắc hiểu đúng ý anh Giám đốc muốn gì chưa? Thử hỏi lại xem."
2. (Nếu học viên hỏi 1 câu rồi bắt tay code ngay) — "Bạn mới rõ 1 phần — 'khách hàng' và 'sản phẩm' còn mơ hồ, chắc chưa hỏi hết?"
3. (Nếu học viên đã hỏi đủ nhưng chưa tổng hợp lại thành scope rõ) — "Trước khi code, thử liệt kê ra: sẽ làm ĐÚNG BAO NHIÊU chỉ số, mỗi chỉ số định nghĩa thế nào — để anh confirm 1 lần, tránh làm xong lại phải sửa."

### Rubric chấm
- **Đạt tối thiểu:** có hỏi làm rõ scope trước khi viết SQL (dù chỉ hỏi 1-2 câu), sau đó viết đúng các query đã thống nhất.
- **Đạt tốt:** hỏi đủ để làm rõ CẢ 3 mảng (doanh thu/khách hàng/sản phẩm) TRƯỚC khi code, tổng hợp lại thành 1 danh sách ngắn để leader xác nhận, chủ động cảnh báo nếu deadline "sáng mai" không khả thi với scope đã mở rộng, và query đủ nhanh cho dashboard trực tiếp.
- **Cờ đỏ:** viết SQL ngay từ câu trả lời đầu tiên của leader mà không hỏi thêm gì — kể cả nếu kết quả "chạy được", đây là dấu hiệu cần feedback về kỹ năng làm rõ yêu cầu, không phải kỹ năng SQL.
