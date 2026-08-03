# Optimize Database Lab

Lab PostgreSQL để luyện tối ưu query/index, dựa trên schema e-commerce trong
[`02-database-design.md`](../e-commerce-docs/docs/backend-plan/02-database-design.md).
Dữ liệu seed đủ lớn (~2.3 triệu dòng) để thấy khác biệt thật giữa Seq Scan và
Index Scan — thay vì demo trên vài trăm dòng không nói lên điều gì.

## Yêu cầu

- Docker + Docker Compose. Không cần cài PostgreSQL hay `psql` trên máy host —
  mọi thứ chạy trong container, kể cả client `psql`.

## Thứ tự chạy

```bash
cd optimize-database-lab
docker compose up -d
docker compose exec db pg_isready -U postgres -d optimize_lab   # chờ tới khi "accepting connections"

docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/00_setup/V0__extensions.sql
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/01_schema/run_all.sql
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/02_seed/run_all.sql   # ~1-3 phút, tuỳ máy
```

Toàn bộ thư mục lab được mount vào `/lab` trong container (xem
`docker-compose.yml`), nên mọi file `.sql` ở đây đều gọi được qua `-f /lab/...`.

Muốn vào session `psql` tương tác (chạy từng câu EXPLAIN ở `03_exercises/`,
dùng `\d`, `\di+`,...):
```bash
docker compose exec db psql -U postgres -d optimize_lab
```

Muốn làm lại từ đầu: chạy `docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/reset.sql`
rồi chạy lại 3 lệnh ở trên. Dừng hẳn lab (xoá luôn volume dữ liệu):
`docker compose down -v`.

Seed data quá chậm trên máy yếu? Giảm số liệu trong các file
`02_seed/V3__products_catalog.sql` (100,000 products) và
`02_seed/V6__orders.sql` (150,000 orders) — giữ nguyên các phép ánh xạ số học
(`ceil(gs / 2.0)`, ...), chỉ đổi số trong `generate_series(1, N)`.

## Danh sách bài lab (`03_exercises/`)

Mỗi file có 3 phần: `PROBLEM` (query chưa tối ưu + EXPLAIN), `TỰ LÀM` (gợi ý,
không cho lời giải), `SOLUTION` (comment sẵn — chỉ mở sau khi tự thử).

| # | Bài | Chủ đề |
|---|---|---|
| 01 | `01_missing_fk_index.sql` | Postgres không tự index FK — seq scan trên bảng lớn |
| 02 | `02_composite_index_filter_sort.sql` | Composite index cho filter + ORDER BY cùng lúc |
| 03 | `03_fulltext_search_vs_like.sql` | `LIKE '%...%'` vô hiệu B-tree — trigram vs full-text search |
| 04 | `04_jsonb_gin_variant_attributes.sql` | GIN index cho containment query trên JSONB |
| 05 | `05_partial_index_hot_status.sql` | Partial index cho tập con "nóng" (đơn PENDING) |
| 06 | `06_covering_index_inventory.sql` | Covering index (`INCLUDE`) — Index Only Scan |
| 07 | `07_pagination_offset_vs_keyset.sql` | OFFSET càng sâu càng chậm — keyset pagination |
| 08 | `08_n_plus_one_vs_join.sql` | N+1 query (lazy-load kiểu ORM) vs 1 JOIN |
| 09 | `09_explain_analyze_practice.sql` | Đọc EXPLAIN: cost/actual rows, buffers, planner threshold |
| 10 | `10_index_only_scan_and_vacuum.sql` | Visibility map, vì sao UPDATE làm mất Index Only Scan |

## Lab concurrency (`04_concurrency/`)

Tái hiện đúng yêu cầu ở §4 của tài liệu thiết kế: N request đồng thời mua sản
phẩm còn 1 cái, chỉ 1 đơn được thành công.

- `01_oversell_bug_manual_demo.sql` — tái hiện lỗi oversell (check-then-act), chạy tay bằng 2 terminal, mỗi terminal 1 session:
  `docker compose exec db psql -U postgres -d optimize_lab`.
- `02_safe_reserve_manual_demo.sql` — cách sửa đúng: 1 câu `UPDATE ... WHERE quantity_available >= :qty`.
- `03_pgbench_concurrent_reserve.sql` — test tự động bằng `pgbench`, chạy ngay trong container:
  ```bash
  docker compose exec db psql -U postgres -d optimize_lab -c \
    "UPDATE inventory_items SET quantity_available = 1, quantity_reserved = 0, version = 0 WHERE id = 1;"
  docker compose exec db pgbench -U postgres -n -c 20 -j 20 -t 1 -f /lab/04_concurrency/03_pgbench_concurrent_reserve.sql optimize_lab
  docker compose exec db psql -U postgres -d optimize_lab -c \
    "SELECT quantity_available, quantity_reserved, version FROM inventory_items WHERE id=1;"
  ```
  Kỳ vọng: dù 20 client đồng thời tranh mua, cuối cùng `quantity_reserved = 1` — không bị oversell.

## Mẹo dùng EXPLAIN

- Luôn `EXPLAIN (ANALYZE, BUFFERS)`, không chỉ `EXPLAIN` — cần số liệu THẬT (actual time, actual rows, buffers), không chỉ ước lượng của planner.
- Chạy `ANALYZE <table>;` sau khi seed/sửa dữ liệu lớn — planner statistics stale sẽ chọn sai chiến lược.
- `\di+ <table>` trong psql để xem index nào tồn tại và kích thước từng index.
- Muốn quay lại trạng thái "chưa tối ưu" cho 1 bài cụ thể: `DROP INDEX <tên_index>;`
