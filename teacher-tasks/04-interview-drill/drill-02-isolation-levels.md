# Drill 02 — Isolation Levels & Concurrency Phenomena

## Q1: 4 isolation level chuẩn SQL, theo thứ tự chặt dần?
**Trả lời ngắn:** Read Uncommitted → Read Committed (**mặc định của
Postgres**) → Repeatable Read → Serializable.

**Follow-up hay gặp:** "Postgres có thực sự chạy Read Uncommitted khi set
level đó không?" — Không. Postgres map Read Uncommitted thành Read
Committed — nhờ kiến trúc MVCC, Postgres KHÔNG BAO GIỜ cho dirty read xảy
ra, bất kể set level nào.

**Bẫy hay gặp:** Nghĩ 4 level này hoạt động GIỐNG NHAU ở mọi hệ quản trị —
mỗi DB implement khác nhau (vd MySQL/InnoDB Repeatable Read khác Postgres
Repeatable Read về cách chặn phantom read).

---

## Q2: Dirty read / non-repeatable read / phantom read khác nhau thế nào?
**Trả lời ngắn:**
- **Dirty read**: đọc dữ liệu transaction KHÁC CHƯA COMMIT (có thể bị rollback sau) — Postgres KHÔNG BAO GIỜ cho phép, ở mọi isolation level.
- **Non-repeatable read**: đọc CÙNG 1 dòng 2 lần trong 1 transaction, ra 2 giá trị khác nhau (vì transaction khác đã UPDATE+COMMIT giữa 2 lần đọc).
- **Phantom read**: chạy lại CÙNG 1 query (theo điều kiện, không phải 1 dòng cụ thể) 2 lần, ra SỐ DÒNG khác nhau (vì transaction khác đã INSERT/DELETE dòng khớp điều kiện).

**Follow-up hay gặp:** "Read Committed của Postgres chặn được cái nào trong
3 cái trên?" — Chỉ chặn dirty read. Non-repeatable read và phantom read VẪN
xảy ra được ở Read Committed (mỗi CÂU LỆNH lấy snapshot mới, nhưng giữa 2
câu lệnh khác nhau trong transaction, dữ liệu có thể đã đổi).

**Bẫy hay gặp:** Nghĩ Read Committed "an toàn" cho mọi bài toán vì đó là
default — quên rằng non-repeatable/phantom read vẫn xảy ra, đủ để gây bug
trong logic nghiệp vụ phức tạp (báo cáo tính 2 lần trong 1 transaction dài).

---

## Q3: Read Committed vs Repeatable Read trong Postgres khác nhau CHÍNH XÁC ở đâu?
**Trả lời ngắn:** Read Committed — MỖI CÂU LỆNH lấy 1 snapshot MỚI (thấy
mọi thay đổi đã commit trước lúc câu đó chạy). Repeatable Read — TOÀN BỘ
transaction dùng 1 SNAPSHOT DUY NHẤT, chụp tại lúc câu lệnh ĐẦU TIÊN chạy —
mọi câu sau đó thấy CÙNG 1 bức tranh dữ liệu dù ai khác có commit gì mới.

**Follow-up hay gặp:** "Vậy 2 transaction Repeatable Read cùng update 1 dòng
thì sao?" — Postgres phát hiện xung đột (serialization conflict), 1 trong 2
transaction bị lỗi `could not serialize access` khi COMMIT, ứng dụng cần
bắt lỗi này và RETRY.

**Bẫy hay gặp:** Nghĩ Repeatable Read "lock" dữ liệu để không ai đổi được —
SAI, đây là MVCC snapshot (không lock), transaction khác VẪN update/commit
bình thường, chỉ là transaction Repeatable Read không THẤY thay đổi đó, và
nếu 2 bên đụng nhau lúc ghi thì 1 bên bị abort.

---

## Q4: Serializable trong Postgres implement bằng cơ chế gì?
**Trả lời ngắn:** SSI (Serializable Snapshot Isolation) — Postgres theo dõi
pattern đọc/ghi giữa các transaction đang chạy để phát hiện khi kết quả
THỰC TẾ không thể nào tương đương với BẤT KỲ thứ tự chạy TUẦN TỰ (serial)
nào — nếu phát hiện, abort 1 transaction, buộc ứng dụng retry.

**Follow-up hay gặp:** "Có nên dùng Serializable cho MỌI thứ để an toàn?" —
Không. Overhead cao hơn, tỷ lệ phải retry tăng khi traffic lớn. Bài toán đơn
giản như "trừ tồn kho" chỉ cần atomic `UPDATE ... WHERE qty >= :n` ở Read
Committed đã đủ an toàn và RẺ HƠN NHIỀU (xem [Track B Level 7](../02-optimize/level-07-concurrency-mvcc.md)) — chỉ dùng Serializable khi
logic nghiệp vụ thực sự phức tạp, nhiều bước phụ thuộc qua lại.

**Bẫy hay gặp:** Coi Serializable là "khoá cứng, chậm chắc chắn" — thực ra
nó KHÔNG lock trước (optimistic), chỉ abort SAU KHI phát hiện xung đột thật
— hiệu năng tốt khi ít xung đột, tệ khi xung đột nhiều (nhiều retry).
