# Drill 01 — ACID & Transactions

## Q1: ACID là gì?
**Trả lời ngắn:** 4 tính chất transaction phải đảm bảo — **A**tomicity (tất
cả các thay đổi trong transaction thành công CÙNG LÚC, hoặc không gì xảy ra
cả), **C**onsistency (dữ liệu luôn thoả các ràng buộc/invariant nghiệp vụ
trước và sau transaction), **I**solation (các transaction chạy đồng thời
không thấy trạng thái "nửa chừng" của nhau), **D**urability (sau khi commit,
dữ liệu tồn tại vĩnh viễn dù hệ thống crash ngay sau đó).

**Follow-up hay gặp:** "Cho ví dụ Atomicity thực tế?" — Chuyển tiền giữa 2
tài khoản: trừ A, cộng B phải THÀNH CÔNG CÙNG LÚC hoặc CÙNG rollback — không
thể có trạng thái "đã trừ A, chưa cộng B" tồn tại vĩnh viễn.

**Bẫy hay gặp:** Nhầm "Consistency" trong ACID với "Consistency" trong CAP
theorem — 2 khái niệm KHÁC NHAU (ACID Consistency = dữ liệu đúng invariant
ứng dụng; CAP Consistency = mọi node/replica thấy cùng dữ liệu tại 1 thời
điểm). Nói lẫn 2 cái sẽ bị interviewer bắt lỗi ngay.

*(Gốc: chưa có track riêng dạy ACID lý thuyết — thực hành Atomicity/Isolation trực tiếp ở [Track B Level 7](../02-optimize/level-07-concurrency-mvcc.md).)*

---

## Q2: Transaction là gì, khi nào THỰC SỰ cần dùng (không phải mọi query)?
**Trả lời ngắn:** 1 nhóm câu lệnh SQL được coi là 1 đơn vị công việc — commit
hết hoặc rollback hết. Cần dùng khi có NHIỀU thay đổi PHẢI nhất quán cùng
lúc (vd: tạo order + trừ tồn kho + tạo payment — 3 việc này phải cùng thành
công, không thể chỉ 2/3).

**Follow-up hay gặp:** "1 câu UPDATE đơn lẻ có cần BEGIN/COMMIT không?" —
Không, Postgres tự coi mỗi statement đơn lẻ là 1 transaction riêng
(autocommit) — chỉ cần `BEGIN` rõ ràng khi có NHIỀU câu lệnh phải đi cùng
nhau.

**Bẫy hay gặp:** Nghĩ transaction làm mọi thứ "an toàn hơn" nên nên bọc
TRANSACTION quanh MỌI đoạn code — transaction giữ lock lâu hơn cần thiết
nếu bọc cả những việc không liên quan (vd gọi API ngoài) vào giữa
BEGIN/COMMIT — đây là lỗi thật hay gặp gây nghẽn hệ thống.

---

## Q3: Điều gì xảy ra nếu 1 câu lệnh giữa transaction bị lỗi (vd lỗi ở câu thứ 3 trong 5 câu)?
**Trả lời ngắn:** Trong Postgres, ngay khi 1 câu lệnh lỗi, TOÀN BỘ
transaction chuyển trạng thái "aborted" — MỌI câu lệnh tiếp theo trong cùng
transaction đó bị từ chối ngay (`ERROR: current transaction is aborted`)
cho tới khi `ROLLBACK`. Không có khái niệm "bỏ qua lỗi, chạy tiếp" như 1 số
DB khác.

**Follow-up hay gặp:** "Vậy muốn rollback 1 PHẦN mà không huỷ cả transaction
thì sao?" — Dùng `SAVEPOINT` — đánh dấu 1 điểm, có thể `ROLLBACK TO
SAVEPOINT` để lùi về đúng điểm đó mà transaction vẫn tiếp tục sống.

**Bẫy hay gặp:** Tưởng hành vi này giống MySQL (mà theo mặc định thường
KHÔNG abort cả transaction khi 1 câu lỗi, tuỳ engine/config) — trả lời dựa
theo kinh nghiệm ở DB khác mà không biết Postgres có hành vi riêng.

---

## Q4: Durability đảm bảo bằng cơ chế nào ở tầng vật lý?
**Trả lời ngắn:** WAL (Write-Ahead Log) — trước khi báo transaction đã
COMMIT thành công, Postgres đảm bảo đã ghi (và `fsync`) log thay đổi xuống
đĩa. Nếu crash ngay sau đó, lúc khởi động lại, Postgres REPLAY WAL để phục
hồi đúng các thay đổi đã commit — không mất dữ liệu đã xác nhận.

**Follow-up hay gặp:** "`fsync` là gì, sao không ghi thẳng data file luôn
cho nhanh?" — `fsync` đảm bảo dữ liệu THỰC SỰ nằm trên đĩa, không chỉ trong
OS page cache (có thể mất khi mất điện/crash). Ghi WAL trước (tuần tự,
nhanh) rồi mới áp dụng vào data file THẬT (ngẫu nhiên, chậm hơn) sau — đây
chính là ý nghĩa "write-AHEAD".

**Bẫy hay gặp:** Nhầm WAL là nơi LƯU DỮ LIỆU CHÍNH — WAL chỉ để phục hồi
sau crash / replication, dữ liệu thật vẫn nằm ở heap/data file (đã học ở
[Track B Level 0](../02-optimize/level-00-storage-mvcc.md)).
