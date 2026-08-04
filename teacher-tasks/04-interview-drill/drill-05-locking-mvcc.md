# Drill 05 — Locking, Deadlock & MVCC

## Q1: MVCC là gì, giải quyết vấn đề gì?
**Trả lời ngắn:** Multi-Version Concurrency Control — mỗi thay đổi (UPDATE)
tạo ra 1 PHIÊN BẢN MỚI của dòng dữ liệu (kèm `xmin`/`xmax` đánh dấu transaction
tạo/xoá phiên bản đó), thay vì sửa tại chỗ. Giải quyết: READERS và WRITERS
KHÔNG CHẶN NHAU — 1 transaction đang đọc không cần chờ transaction khác
đang ghi (và ngược lại), vì mỗi bên thấy đúng phiên bản phù hợp với snapshot
của mình.

**Follow-up hay gặp:** "Vậy UPDATE có chặn ai không?" — UPDATE VẪN cần lock
ở CẤP DÒNG với transaction khác cũng đang UPDATE/DELETE ĐÚNG dòng đó (không
chặn SELECT thường) (xem [Track B Level 0](../02-optimize/level-00-storage-mvcc.md)).

**Bẫy hay gặp:** Nghĩ MVCC nghĩa là "không bao giờ có lock nào cả" — vẫn có
lock ở cấp dòng khi 2 WRITE đụng nhau, chỉ là READ không bị chặn bởi WRITE.

---

## Q2: Deadlock là gì? Cho ví dụ đơn giản nhất.
**Trả lời ngắn:** 2 (hoặc nhiều) transaction cùng CHỜ LOCK của nhau theo
1 CHU TRÌNH KHÉP KÍN — không ai có thể tiếp tục. Ví dụ: Transaction A khoá
dòng 1, muốn khoá dòng 2. Transaction B khoá dòng 2, muốn khoá dòng 1 — cả
2 cùng chờ nhau vô thời hạn.

**Follow-up hay gặp:** "Làm sao TRÁNH deadlock từ tầng thiết kế code?" —
Luôn khoá các resource theo 1 THỨ TỰ CỐ ĐỊNH nhất quán ở MỌI luồng code (vd
luôn khoá theo `id` tăng dần) — nếu mọi transaction đều xin lock theo cùng
thứ tự, không thể tạo thành chu trình chờ khép kín.

**Bẫy hay gặp:** Nghĩ deadlock chỉ xảy ra với các bảng KHÁC NHAU — deadlock
hoàn toàn có thể xảy ra giữa 2 transaction cùng update NHIỀU DÒNG trong
CÙNG 1 bảng, theo thứ tự ngược nhau.

---

## Q3: Postgres xử lý deadlock thế nào khi nó xảy ra?
**Trả lời ngắn:** Postgres có 1 "deadlock detector" chạy theo chu kỳ (mặc
định 1 giây) — phát hiện chu trình chờ khép kín, CHỌN 1 transaction (thường
là transaction gây phát hiện) để CHỦ ĐỘNG abort, trả lỗi
`ERROR: deadlock detected` cho ứng dụng. Transaction còn lại được tiếp tục.

**Follow-up hay gặp:** "Ứng dụng nên xử lý lỗi này thế nào?" — Bắt lỗi cụ
thể (deadlock detected / serialization failure) và RETRY transaction đó
(thường retry được ngay vì lock đã giải phóng) — không nên coi là lỗi
nghiêm trọng cần dừng hệ thống.

**Bẫy hay gặp:** Nghĩ deadlock là bug/crash của Postgres — đây là hành vi
ĐÚNG THIẾT KẾ (an toàn hơn treo vô thời hạn), vấn đề thật nằm ở LOGIC ứng
dụng khoá tài nguyên không theo thứ tự nhất quán.

---

## Q4: Optimistic locking vs Pessimistic locking khác gì, khi nào dùng cái nào?
**Trả lời ngắn:** **Pessimistic** (`SELECT ... FOR UPDATE`) — khoá dòng
NGAY LÚC ĐỌC, các transaction khác phải CHỜ. Dùng khi khả năng xung đột
CAO (nhiều request tranh cùng 1 dòng, vd sản phẩm hot). **Optimistic**
(cột `version`, so sánh khi UPDATE: `WHERE id=? AND version=?`) — KHÔNG
khoá lúc đọc, chỉ kiểm tra khi GHI xem có ai đổi trước mình chưa; nếu có,
từ chối/retry. Dùng khi xung đột HIẾM — tránh chi phí giữ lock không cần
thiết phần lớn thời gian.

**Follow-up hay gặp:** "Cách nào phù hợp cho bài toán 'trừ tồn kho sản phẩm
hot, nhiều người tranh mua'?" — Thực ra atomic `UPDATE ... WHERE qty >= :n`
(xem [Track B Level 7](../02-optimize/level-07-concurrency-mvcc.md)) đã giải quyết mà KHÔNG cần chọn hẳn 1 trong 2
kiểu trên — nó tận dụng đúng cơ chế row-lock tự nhiên của UPDATE, đơn giản
hơn cả 2 pattern optimistic/pessimistic kinh điển.

**Bẫy hay gặp:** Nghĩ phải chọn DUY NHẤT 1 kiểu cho toàn hệ thống — thực tế
2 kiểu được dùng cho 2 bài toán khác nhau trong CÙNG 1 hệ thống, tuỳ mức độ
xung đột dự kiến của từng luồng nghiệp vụ.
