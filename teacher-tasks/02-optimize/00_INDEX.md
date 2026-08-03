# Track B — Optimize: Lộ trình PostgreSQL Query Processing

> Track này giả định học viên đã VIẾT ĐÚNG được truy vấn (JOIN, GROUP BY,
> subquery, CTE, window function...). Nếu chưa chắc, hoàn thành
> [Track A — Luyện truy vấn](../01-queries/00_INDEX.md) trước. Xem tổng quan 2
> track tại [`../00_INDEX.md`](../00_INDEX.md).

Đây là bộ "task card" cho AI đóng vai giáo viên (theo
[`../../TEACHER_PROMPT.md`](../../TEACHER_PROMPT.md)) — mỗi file `level-NN-*.md` là
kịch bản đầy đủ cho 1 buổi học: mục tiêu, câu hỏi khởi động, gợi ý ví dụ đời
thường, demo trên lab thật, bài tập biến thể (tạo tại chỗ, không lộ sẵn), tiêu
chí teach-back, và lỗi hiểu sai thường gặp cần soi khi học viên trả lời.

**Nguyên tắc dùng file:** AI đọc file của level hiện tại làm kịch bản dạy —
KHÔNG đọc trước cho học viên, KHÔNG copy nguyên phần "gợi ý" thành lời giải
sẵn. Phần "Bài tập biến thể" chỉ ghi YÊU CẦU, AI phải tự soạn số liệu/query cụ
thể lúc dạy (khác với bài mẫu trong `03_exercises/`) để tránh học vẹt.

## Theo dõi tiến độ

Tick khi học viên đã teach-back đạt yêu cầu của level đó (không tự tick khi
chỉ mới làm xong bài tập — phải qua được bước "giải thích lại bằng lời của
mình").

- [ ] Level 0 — [Storage & MVCC nền tảng](level-00-storage-mvcc.md)
- [ ] Level 1 — [Query lifecycle](level-01-query-lifecycle.md)
- [ ] Level 2 — [Đọc EXPLAIN](level-02-explain-basics.md)
- [ ] Level 3 — [B-tree index cơ bản](level-03-btree-index.md)
- [ ] Level 4 — [Join algorithms](level-04-join-algorithms.md)
- [ ] Level 5 — [Index nâng cao](level-05-advanced-indexes.md)
- [ ] Level 6 — [Planner statistics](level-06-planner-statistics.md)
- [ ] Level 7 — [Concurrency & MVCC thực chiến](level-07-concurrency-mvcc.md)
- [ ] Level 8 — [VACUUM & bloat](level-08-vacuum-bloat.md)
- [ ] Level 9 — [CTE, window function, subquery vs join](level-09-cte-window-subquery.md)
- [ ] Level 10 — [Capstone: tối ưu 1 query thật end-to-end](level-10-capstone.md)

## Trước khi bắt đầu Level 0

Đảm bảo lab đã chạy (xem [`../../README.md`](../../README.md)):
```bash
docker compose up -d
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/00_setup/V0__extensions.sql
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/01_schema/run_all.sql
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/02_seed/run_all.sql
```
