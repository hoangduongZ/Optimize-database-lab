# Level 0 — Storage & MVCC nền tảng

## Mục tiêu
Học viên hiểu vì sao Postgres không "sửa tại chỗ" khi UPDATE, và MVCC (đa
phiên bản) là cơ chế nền cho MỌI thứ học ở các level sau (index-only scan,
vacuum, concurrency...).

## Khái niệm cốt lõi
- Heap page (8KB), tuple, tuple header (`xmin`, `xmax`, `ctid`).
- Transaction ID (xid) — mỗi transaction có 1 số thứ tự tăng dần.
- UPDATE = tuple cũ đánh dấu "dead" (ghi `xmax`) + tuple mới được chèn thêm.
- WAL (Write-Ahead Log) — ghi log TRƯỚC khi ghi data page, để phục hồi khi crash.

## Câu hỏi khởi động
> "Khi bạn chạy `UPDATE users SET email = ... WHERE id = 1`, Postgres có ghi
> đè lên đúng chỗ ổ đĩa đang chứa dòng cũ không? Đoán trước khi học."

## Gợi ý ví dụ đời thường (dùng ở bước giải thích Feynman #1)
Sổ kế toán truyền thống: không ai tẩy xoá số cũ, mà gạch ngang rồi ghi số mới
bên dưới, kèm ngày/version. Muốn biết "số dư đúng vào ngày X", chỉ cần đọc
dòng nào còn hiệu lực TẠI thời điểm đó — không cần dòng bị gạch biến mất ngay.
Đó chính là ý tưởng `xmin`/`xmax`.

## Demo trên lab
Dùng bảng `reviews` (KHÔNG dùng `inventory_items`/`orders`/`products` — các
bảng đó bị FK từ bảng khác tham chiếu tới, nên Postgres đã âm thầm gán
`xmax` là 1 MultiXactId ngay từ lúc seed do share-lock kiểm tra FK, dù chưa
ai UPDATE — dễ gây hiểu lầm ở bài học đầu tiên này):
```sql
SELECT ctid, xmin, xmax, rating FROM reviews WHERE id = 1;
UPDATE reviews SET rating = rating WHERE id = 1;
SELECT ctid, xmin, xmax, rating FROM reviews WHERE id = 1;
```
Học viên phải tự thấy: `ctid` đổi (vị trí vật lý mới), `xmin` của dòng MỚI
đổi thành xid của transaction vừa UPDATE, `xmax` của dòng đang thấy vẫn là 0
(chưa ai xoá/sửa dòng MỚI này). Dòng CŨ không hiện ra nữa khi query theo `id`
(vì đã dead với transaction hiện tại) nhưng vẫn còn tồn tại trong data file
cho tới khi VACUUM dọn (liên hệ trước với Level 8).

Nếu muốn cho học viên thấy rõ hơn: chạy `SELECT txid_current();` trước và sau
để đối chiếu xid với `xmin` mới.

> Mở rộng cho học viên tò mò (không bắt buộc): thử lại demo này trên
> `inventory_items` — `xmax` sẽ khác 0 ngay cả TRƯỚC khi UPDATE. Đây là dịp
> giới thiệu khái niệm MultiXactId (share-lock do FK check từ `stock_movements`
> trỏ tới), không phải dấu hiệu dòng đã bị xoá/sửa.

## Bài tập biến thể
Yêu cầu học viên tự chọn 1 bảng KHÁC không bị FK nào trỏ tới (gợi ý:
`order_items`, `payments`, `cart_items`), tự dự đoán `ctid` có đổi không
trước khi UPDATE, rồi verify. Nếu học viên chọn đúng 1 dòng rồi UPDATE 2 lần
liên tiếp trong 2 transaction riêng — hỏi họ dự đoán "dòng cũ nhất còn tồn
tại trong data file không?" trước khi trả lời.

## Tiêu chí teach-back
- [ ] Giải thích được vì sao UPDATE tạo ra dead tuple thay vì sửa tại chỗ.
- [ ] Giải thích được vai trò của `xmin`/`xmax` trong việc xác định "dòng này còn hiệu lực với transaction của tôi không".
- [ ] Giải thích được WAL đảm bảo điều gì khi Postgres bị crash giữa lúc ghi.

## Lỗi hiểu sai thường gặp
- Nghĩ UPDATE luôn ghi đè tại chỗ (đúng với 1 số DB khác, SAI với Postgres MVCC — trừ HOT update tối ưu riêng, không cần đi sâu ở level này).
- Nhầm WAL là nơi lưu dữ liệu chính (WAL chỉ để phục hồi/replicate, data thật nằm ở heap page).
- Nhầm "transaction id" với "id" (primary key) của dòng dữ liệu.
