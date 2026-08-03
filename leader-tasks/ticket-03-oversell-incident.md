# ECM-303 — [INCIDENT] Bán vượt tồn kho sau flash sale

**Priority:** P0
**Reported by:** Ops
**Ngày báo cáo:** 2026-08-02

## Mô tả

> "Đêm qua chạy flash sale, 1 sản phẩm hot chỉ còn 10 cái trong kho nhưng hệ
> thống báo đã CHỐT ĐƠN 14 khách cho đúng sản phẩm/variant đó — nghĩa là
> bán vượt tồn 4 đơn. Kho đang rất bức xúc vì phải gọi điện xin lỗi khách
> huỷ đơn. Cần: (1) xác nhận nguyên nhân, (2) đảm bảo KHÔNG lặp lại ở lần
> sale tiếp theo (cuối tuần này). Đây là P0, cần trả lời trong hôm nay."
>
> Đính kèm: code xử lý đặt hàng hiện tại (rút gọn, đúng logic đang chạy) —
>
> ```
> qty = db.query("SELECT quantity_available FROM inventory_items WHERE id = ?", item_id)
> if qty >= requested_qty:
>     db.execute("UPDATE inventory_items SET quantity_available = ? WHERE id = ?",
>                qty - requested_qty, item_id)
>     create_order(...)
> else:
>     raise InsufficientStockException()
> ```

## Acceptance Criteria
- [ ] Xác định đúng root cause — chứng minh được bằng cách TÁI HIỆN LẠI được bug này trên lab (không chỉ nói lý thuyết).
- [ ] Đề xuất fix ở tầng SQL (không đổi kiến trúc ứng dụng, không thêm hệ thống lock ngoài như Redis) — atomic, không cần đổi ngôn ngữ/framework hiện tại.
- [ ] Chứng minh fix hoạt động bằng test đồng thời thật (nhiều "khách" cùng lúc tranh mua) — không chỉ chạy 1 luồng rồi kết luận.
- [ ] Nêu được: nếu apply fix này, khách hàng thứ 11-14 (vượt tồn) sẽ nhận phản hồi gì thay vì "chốt đơn thành công rồi báo huỷ sau".

## Ngữ cảnh bổ sung
- Q: "Có dùng cache/Redis cho tồn kho không?" — A: "Không, đọc/ghi thẳng Postgres."
- Q: "14 request đó có đến CÙNG lúc hay rải ra?" — A: "Dồn trong khoảng 3 giây đầu mở sale — gần như đồng thời."

---
## [CHỈ LEAD ĐỌC — KHÔNG lộ cho học viên]

### Root cause thật
Code đính kèm là mẫu "check-then-act" kinh điển: đọc `quantity_available`
bằng 1 câu SELECT KHÔNG lock, rồi mới quyết định ở application code, rồi
UPDATE riêng. Giữa lúc đọc và ghi, nhiều request khác cũng đọc được CÙNG
giá trị "còn hàng" trước khi bất kỳ ai kịp ghi — không ai biết người khác
cũng đang làm y vậy.

### Giải pháp tham khảo
```sql
UPDATE inventory_items
SET quantity_available = quantity_available - :qty,
    quantity_reserved  = quantity_reserved  + :qty,
    version = version + 1
WHERE id = :id AND quantity_available >= :qty;
-- Application check affected rows: 0 dòng -> InsufficientStockException
```
Atomic — điều kiện tồn kho nằm NGAY TRONG WHERE của câu UPDATE, Postgres tự
lock dòng và re-evaluate điều kiện với giá trị MỚI NHẤT cho request đến sau.

### Bậc hint
1. "Bạn tái hiện được bug này trên lab chưa? Thử mở 2 session psql, làm chậm lại bằng `pg_sleep` giữa lúc SELECT và UPDATE."
2. "2 session đó có gì KHÔNG được chia sẻ với nhau giữa lúc đọc và ghi?"
3. "Nếu điều kiện tồn kho (`quantity_available >= qty`) nằm NGAY TRONG câu UPDATE (không phải if ở code) thì điều gì xảy ra khác đi khi 2 session tranh nhau?"

### Rubric chấm
- **Đạt tối thiểu:** đề xuất đúng atomic UPDATE, giải thích được vì sao nó khác "check rồi update riêng".
- **Đạt tốt:** TỰ TAY tái hiện được bug (2 session + `pg_sleep`) TRƯỚC KHI fix, và test lại bằng `pgbench`/nhiều session sau khi fix — có số liệu thật (affected rows) chứng minh.
- **Cờ đỏ:** đề xuất "tăng lock timeout" hoặc "thêm retry ở code" mà KHÔNG đổi sang atomic UPDATE — chỉ giảm tần suất gặp bug, không loại bỏ root cause; nếu học viên dừng ở đây, hỏi tiếp "nếu 100 người tranh mua đúng lúc thì retry có còn cứu được không?" trước khi đóng ticket.
