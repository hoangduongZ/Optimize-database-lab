# Teacher Tasks — 4 Track

> Xem lộ trình tổng (cả 4 track + leader-tasks + 3 vai AI) ở [`../ROADMAP.md`](../ROADMAP.md).
> File này chỉ mô tả riêng phần "học" (Teacher mode).

Bộ "task card" cho AI đóng vai giáo viên (theo [`../TEACHER_PROMPT.md`](../TEACHER_PROMPT.md)),
chia 4 track theo 4 kỹ năng khác nhau:

| Track | Câu hỏi cốt lõi | Khi nào học |
|---|---|---|
| [**A — Luyện truy vấn**](01-queries/00_INDEX.md) | "Tôi có viết ĐÚNG được truy vấn cho yêu cầu nghiệp vụ này không?" | Học ĐẦU TIÊN — nền tảng viết SQL đúng: JOIN, aggregate, subquery, CTE, window function, set operations. |
| [**B — Optimize**](02-optimize/00_INDEX.md) | "Truy vấn ĐÃ ĐÚNG rồi — làm sao cho NHANH?" | Học SAU Track A — query processing: EXPLAIN, index, planner, concurrency, vacuum. |
| [**C — Schema Design**](03-schema-design/00_INDEX.md) | "Từ yêu cầu nghiệp vụ TRỐNG, tự thiết kế schema thế nào?" | Học SONG SONG hoặc SAU Track B (Level 0-3 dùng lại schema đã quen, Level 4-7 là domain mới hoàn toàn). |
| [**D — Interview Drill**](04-interview-drill/00_INDEX.md) | "Trả lời NHANH-ĐÚNG-NGẮN các câu hay bị hỏi miệng?" | Dùng SAU KHI đã hiểu sâu ở A/B/C — đây là luyện PHẢN XẠ, không phải luyện hiểu. |

## Vì sao tách 4 track (không phải 1 track lớn)

Mỗi track kiểm tra 1 KỸ NĂNG KHÁC NHAU, không phải 1 "độ khó khác nhau" của
cùng 1 kỹ năng:
- Track B giả định ĐÃ viết đúng SQL (Track A) — tối ưu 1 câu chưa chắc đúng là vô nghĩa.
- Track C là kỹ năng NGƯỢC với A/B (từ yêu cầu → schema, không phải từ schema có sẵn → query).
- Track D không dạy gì mới — chỉ luyện TỐC ĐỘ DIỄN ĐẠT cái đã hiểu, khác hẳn cách chấm của A/B/C (xem [teach-back] vs [drill] trong từng track's INDEX).

**Thứ tự khuyến nghị:** A (8 level) → B (11 level) → C Level 0-3 (khái niệm,
có thể học song song B) → C Level 4-7 (design challenge) → D (drill, dùng
lại nhiều lần, không phải học 1 lần xong). Không bắt buộc tuyệt đối — nếu đã
vững 1 track từ trước, dùng như tài liệu tra cứu.

## Trước khi bắt đầu (mọi track)

```bash
cd optimize-database-lab
docker compose up -d
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/00_setup/V0__extensions.sql
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/01_schema/run_all.sql
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/02_seed/run_all.sql
```
Xem chi tiết ở [`../README.md`](../README.md).
