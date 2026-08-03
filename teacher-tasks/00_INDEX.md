# Teacher Tasks — 2 Track

Bộ "task card" cho AI đóng vai giáo viên (theo [`../TEACHER_PROMPT.md`](../TEACHER_PROMPT.md)),
chia 2 track rõ ràng theo 2 kỹ năng khác nhau:

| Track | Câu hỏi cốt lõi | Khi nào học |
|---|---|---|
| [**A — Luyện truy vấn**](01-queries/00_INDEX.md) | "Tôi có viết ĐÚNG được truy vấn cho yêu cầu nghiệp vụ này không?" | Học TRƯỚC — nền tảng viết SQL đúng: JOIN, aggregate, subquery, CTE, window function, set operations. |
| [**B — Optimize**](02-optimize/00_INDEX.md) | "Truy vấn ĐÃ ĐÚNG rồi — làm sao cho NHANH?" | Học SAU — query processing: EXPLAIN, index, planner, concurrency, vacuum. |

## Vì sao tách 2 track

Tối ưu 1 câu query mà chưa chắc viết đúng là vô nghĩa — Track B (đặc biệt
Level 4 "Join algorithms" và Level 9 "CTE, window function, subquery vs
join") giả định học viên ĐÃ biết viết các cấu trúc đó, chỉ dạy cách chúng
CHẠY NHANH HAY CHẬM. Nếu học viên chưa từng viết `RANK() OVER (...)` hay
`NOT EXISTS`, hãy hoàn thành Track A trước.

**Thứ tự khuyến nghị:** hoàn thành toàn bộ Track A (8 level) → rồi mới sang
Track B (11 level). Không bắt buộc tuyệt đối — nếu học viên đã vững core SQL
từ trước, có thể bỏ qua thẳng Track B và dùng Track A như tài liệu tra cứu
khi cần.

## Trước khi bắt đầu (cả 2 track)

```bash
cd optimize-database-lab
docker compose up -d
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/00_setup/V0__extensions.sql
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/01_schema/run_all.sql
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/02_seed/run_all.sql
```
Xem chi tiết ở [`../README.md`](../README.md).
