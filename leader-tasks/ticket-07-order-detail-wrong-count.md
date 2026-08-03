# ECM-307 — [BUG] Trang chi tiết đơn hiển thị sai số lượng sản phẩm

**Priority:** P0
**Reported by:** QA
**Ngày báo cáo:** 2026-08-02

## Mô tả

> "Test trang chi tiết đơn hàng, phát hiện: đơn có đúng 2 `order_items`
> nhưng trang hiển thị 'Tổng 4 sản phẩm' — đúng gấp đôi. Test thêm vài đơn
> khác thì thấy con số hiển thị LUÔN LUÔN là số thật × số dòng lịch sử trạng
> thái của đơn đó (đơn có 3 lần đổi trạng thái thì số item bị nhân 3). Query
> BE đang dùng:
>
> ```sql
> SELECT o.id, o.order_number,
>        count(oi.id) AS item_count,
>        sum(oi.quantity) AS total_qty
> FROM orders o
> JOIN order_items oi ON oi.order_id = o.id
> JOIN order_status_history osh ON osh.order_id = o.id
> WHERE o.id = :order_id
> GROUP BY o.id, o.order_number;
> ```
>
> Bug này BLOCKER cho release — không thể ship trang chi tiết đơn hiển thị
> sai số lượng."

## Acceptance Criteria
- [ ] Giải thích ĐÚNG root cause bằng cách chứng minh trên 1 đơn hàng cụ thể (đếm tay số `order_items` thật, số `order_status_history` thật, đối chiếu với con số sai hiển thị).
- [ ] Fix query để `item_count` và `total_qty` ra ĐÚNG số thật, dù đơn hàng có bao nhiêu dòng lịch sử trạng thái.
- [ ] Nếu trang chi tiết đơn CÒN CẦN hiển thị thêm thông tin từ `order_status_history` (ví dụ trạng thái gần nhất), giải pháp phải vẫn lấy được thông tin đó mà không làm sai lại số lượng sản phẩm.

## Ngữ cảnh bổ sung
- Q: "Trang chi tiết đơn có cần hiển thị lịch sử trạng thái không?" — A: "Có — cần hiển thị trạng thái GẦN NHẤT (1 dòng), không cần hiện cả lịch sử trên khung đó."

---
## [CHỈ LEAD ĐỌC — KHÔNG lộ cho học viên]

### Root cause thật
Fan-out kép: `orders` 1-nhiều với CẢ `order_items` VÀ `order_status_history`
CÙNG LÚC trong 1 câu JOIN. Với 1 đơn có `m` order_items và `n` dòng lịch sử
trạng thái, kết quả JOIN có `m × n` dòng (cartesian giữa 2 nhánh 1-nhiều độc
lập) — `count(oi.id)` đếm `m × n` thay vì `m`, `sum(oi.quantity)` cũng cộng
lặp mỗi item `n` lần.

### Giải pháp tham khảo
Tách 2 nhánh 1-nhiều thành 2 subquery/CTE ĐỘC LẬP trước khi join với
`orders`, tránh join trực tiếp 2 bảng "nhiều" với nhau qua bảng "1":
```sql
SELECT o.id, o.order_number,
       items.item_count, items.total_qty,
       latest_status.status AS current_status
FROM orders o
JOIN (
    SELECT order_id, count(*) AS item_count, sum(quantity) AS total_qty
    FROM order_items
    GROUP BY order_id
) items ON items.order_id = o.id
LEFT JOIN (
    SELECT DISTINCT ON (order_id) order_id, status
    FROM order_status_history
    ORDER BY order_id, changed_at DESC
) latest_status ON latest_status.order_id = o.id
WHERE o.id = :order_id;
```
(`DISTINCT ON` là cách Postgres-idiomatic để lấy "1 dòng mới nhất mỗi
nhóm" — nếu học viên chưa học, chấp nhận cách thay thế bằng
`ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY changed_at DESC) = 1`.)

### Bậc hint
1. "Đếm tay: đơn này có mấy `order_items` thật? Mấy dòng `order_status_history` thật? Số hiển thị sai có liên quan gì tới 2 số đó không?"
2. "Query đang JOIN CÙNG LÚC 2 bảng mà cả 2 đều 'nhiều dòng trên 1 đơn'. Nếu JOIN riêng từng bảng với `orders` (không JOIN cả 2 cùng lúc), kết quả có khác không?"
3. "Thử tính `item_count` bằng 1 subquery ĐỘC LẬP (không JOIN gì khác), xem có đổi kết quả không."

### Rubric chấm
- **Đạt tối thiểu:** nhận diện đúng đây là fan-out do JOIN 2 quan hệ 1-nhiều cùng lúc (không phải lỗi ở `count`/`sum` hay ở dữ liệu).
- **Đạt tốt:** fix bằng cách tách subquery ĐỘC LẬP cho từng nhánh 1-nhiều, VẪN giữ được thông tin trạng thái gần nhất theo đúng yêu cầu bổ sung.
- **Cờ đỏ:** "fix" bằng cách đổi `count(oi.id)` thành `count(DISTINCT oi.id)` — ra đúng SỐ LƯỢNG item, nhưng `sum(oi.quantity)` VẪN SAI (không có `DISTINCT` tương đương cho `sum` khi dòng đã bị nhân bản theo giá trị khác nhau mỗi dòng) — chỉ fix được 1 trong 2 acceptance criteria, cần chỉ ra ngay.
