# ECM-301 — Trang danh mục sản phẩm load chậm khi traffic tăng

**Priority:** P1
**Reported by:** Support Lead
**Ngày báo cáo:** 2026-08-01

## Mô tả

> "Từ hôm qua, bên CSKH nhận nhiều phản hồi là trang danh mục (category
> listing) load rất lâu, có khách chờ 2-3 giây mới thấy sản phẩm. Team dev
> nói query đứng sau trang đó là:
>
> ```sql
> SELECT id, name, base_price, sale_price
> FROM products
> WHERE status = 'ACTIVE' AND category_id = :category_id
> ORDER BY base_price ASC
> LIMIT 20 OFFSET :offset;
> ```
>
> Không rõ query có vấn đề gì không, hay do traffic tăng thật. Nhờ team
> backend kiểm tra và fix nếu là vấn đề ở DB, deadline: trước cuối tuần."

## Acceptance Criteria
- [ ] Xác định được nguyên nhân THẬT (đo bằng số liệu, không suy đoán).
- [ ] Query trang danh mục chạy dưới 50ms trên dữ liệu hiện tại (~100k sản phẩm), với `category_id` và `offset` bất kỳ trong khoảng hợp lý (`OFFSET` nhỏ, trang đầu — trang sâu là vấn đề của ticket khác).
- [ ] Giải pháp không phá vỡ tính đúng của kết quả (vẫn đúng thứ tự, đúng bộ lọc).
- [ ] Nêu được đánh đổi của giải pháp (chi phí ghi thêm nếu có, dung lượng thêm nếu có).

## Ngữ cảnh bổ sung
- Q: "Traffic tăng bao nhiêu?" — A: "Gấp khoảng 3 lần so với tuần trước, nhưng các trang khác không bị chậm tương ứng — chỉ trang category là bị kêu nhiều."
- Q: "Có log slow query không?" — A: "Có, đính kèm được nếu cần — nhưng team tin là bạn tự `EXPLAIN` được, nhanh hơn."
- Q: "Bảng `products` có bao nhiêu dòng?" — A: "~100,000, và tăng dần theo thời gian."

---
## [CHỈ LEAD ĐỌC — KHÔNG lộ cho học viên]

### Root cause thật
`products` không có index nào trên `(category_id, status, base_price)` —
mọi query trang category đều Seq Scan + Sort toàn bảng con khớp
`category_id`, chỉ lấy 20 dòng cuối cùng. Traffic tăng làm số lượng Seq Scan
đồng thời tăng, cạnh tranh I/O/CPU rõ hơn — không phải do dữ liệu tăng bất
thường.

### Giải pháp tham khảo
```sql
CREATE INDEX idx_products_category_status_price
    ON products (category_id, status, base_price);
```
Thứ tự cột: cột filter bằng `=` (`category_id`, `status`) đứng trước, cột
`ORDER BY` (`base_price`) đứng sau — index trả kết quả đã đúng thứ tự, không
cần Sort riêng.

### Bậc hint (dùng tăng dần nếu học viên bế tắc)
1. "Bạn đã chạy `EXPLAIN (ANALYZE, BUFFERS)` cho đúng câu query production chưa?"
2. "Trong plan, node nào chiếm phần lớn thời gian — Seq Scan hay Sort?"
3. "`products` có index nào chứa cả `category_id`, `status`, VÀ `base_price` không? Thử tạo 1 cái, theo đúng thứ tự nào cho hợp lý."

### Rubric chấm
- **Đạt tối thiểu:** tạo đúng composite index, đo lại bằng EXPLAIN ANALYZE cho thấy cải thiện rõ (loại bỏ Seq Scan + Sort).
- **Đạt tốt:** giải thích được TẠI SAO thứ tự cột trong index phải như vậy (không chỉ "tạo index là được"), và nêu được chi phí ghi tăng thêm khi INSERT/UPDATE products.
- **Cờ đỏ:** đề xuất tạo index riêng lẻ trên từng cột (`category_id`, `status`, `base_price` — 3 index riêng) — vẫn có cải thiện nhưng KHÔNG loại được node Sort, vì planner không tận dụng được thứ tự đã sort của 1 index đơn lẻ cho cả 2 mục đích filter+sort cùng lúc. Nếu học viên dừng ở đây mà không nhận ra Sort vẫn còn, đây là dấu hiệu cần quay lại Track B Level 3 (leading column) trước khi đóng ticket.
