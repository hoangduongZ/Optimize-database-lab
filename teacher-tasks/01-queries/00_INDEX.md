# Track A — Luyện truy vấn (Query Writing)

> Track này KHÔNG dạy tối ưu — dạy dịch đúng yêu cầu nghiệp vụ thành SQL
> đúng. Muốn học tối ưu, sang [Track B](../02-optimize/00_INDEX.md) sau khi
> xong track này. Tổng quan 2 track: [`../00_INDEX.md`](../00_INDEX.md).

Mỗi file `level-NN-*.md` là 1 buổi học đầy đủ, cùng format với Track B: mục
tiêu, câu hỏi khởi động, gợi ý ví dụ đời thường, demo trên lab thật, bài tập
biến thể (AI tự soạn lúc dạy, không lộ sẵn), tiêu chí teach-back, lỗi hiểu
sai thường gặp.

## Theo dõi tiến độ

- [ ] Level 0 — [SELECT/WHERE/ORDER BY & NULL cơ bản](level-00-select-where-null.md)
- [ ] Level 1 — [JOIN cơ bản: INNER vs LEFT, fan-out](level-01-join-inner-left.md)
- [ ] Level 2 — [Multi-table JOIN & self-join](level-02-multi-join-self-join.md)
- [ ] Level 3 — [Aggregate: GROUP BY / HAVING](level-03-aggregate-group-having.md)
- [ ] Level 4 — [Subquery: IN / EXISTS / correlated](level-04-subquery-exists-in.md)
- [ ] Level 5 — [CTE & Window function](level-05-cte-window-functions.md)
- [ ] Level 6 — [Set operations & CASE WHEN](level-06-set-operations-case.md)
- [ ] Level 7 — [Capstone: dịch 1 yêu cầu nghiệp vụ phức hợp thành query đúng](level-07-capstone-business-query.md)

## Trước khi bắt đầu

Đảm bảo lab đã chạy (xem [`../../README.md`](../../README.md)) — Track A chỉ
cần schema + seed, không cần thêm gì khác:
```bash
docker compose up -d
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/00_setup/V0__extensions.sql
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/01_schema/run_all.sql
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/02_seed/run_all.sql
```
