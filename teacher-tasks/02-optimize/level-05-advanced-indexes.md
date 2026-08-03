# Level 5 — Index nâng cao

## Mục tiêu
Học viên biết chọn ĐÚNG loại index cho đúng bài toán: partial, covering
(`INCLUDE`), và GIN (jsonb/trgm/tsvector) — thay vì chỉ biết B-tree đơn giản.

## Khái niệm cốt lõi
- **Partial index**: chỉ index 1 tập con thoả `WHERE` cố định — nhỏ hơn, ghi rẻ hơn, nhưng CHỈ dùng được khi điều kiện query "implies" được predicate của index.
- **Covering index (`INCLUDE`)**: nhồi thêm cột không dùng để tìm kiếm nhưng cần đọc, để đạt Index Only Scan — miễn heap page đã "all-visible" (visibility map, xem Level 8).
- **GIN**: index cho dữ liệu "nhiều giá trị trong 1 dòng" — jsonb (containment `@>`), trigram (LIKE/ILIKE `%...%`), tsvector (full-text search).
- Mỗi loại index giải quyết đúng 1 lớp bài toán — KHÔNG có loại "tốt nhất cho mọi trường hợp".

## Câu hỏi khởi động
> "Bạn có partial index `ON orders (placed_at) WHERE order_status =
> 'PENDING'`. Query `WHERE order_status IN ('PENDING', 'CONFIRMED')` có dùng
> được index này không? Vì sao?"

## Gợi ý ví dụ đời thường
Partial index giống 1 quyển sổ ghi CHỈ riêng "khách VIP" — tra cứu khách VIP
rất nhanh vì sổ nhỏ, nhưng hỏi "khách VIP HOẶC khách thường" thì quyển sổ đó
không đủ, phải lục sổ tổng.

## Demo trên lab
Dùng đúng 4 file trong `../../03_exercises/` (`03_fulltext_search_vs_like.sql`,
`04_jsonb_gin_variant_attributes.sql`, `05_partial_index_hot_status.sql`,
`06_covering_index_inventory.sql`) — chạy lần lượt: trigram, full-text
search, JSONB GIN, partial index, covering index. Đây là level có nhiều nội
dung nhất — có thể chia thành 2 buổi nếu học viên cần thời gian tiêu hoá.

Minh hoạ thêm cho câu hỏi khởi động:
```sql
CREATE INDEX idx_orders_pending_placed_at ON orders (placed_at) WHERE order_status = 'PENDING';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE order_status = 'PENDING' AND placed_at < now();
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE order_status IN ('PENDING', 'CONFIRMED') AND placed_at < now();
```

## Bài tập biến thể
Yêu cầu học viên tự thiết kế 1 partial index cho 1 tình huống nghiệp vụ MỚI
(gợi ý: "sản phẩm hết hàng cần nhập thêm" — `status = 'OUT_OF_STOCK'` trên
`products`), rồi viết 2 query: 1 query DÙNG ĐƯỢC index đó, 1 query KHÔNG DÙNG
ĐƯỢC — tự giải thích vì sao trước khi verify bằng EXPLAIN.

## Tiêu chí teach-back
- [ ] Giải thích được điều kiện để partial index được dùng (predicate của WHERE phải "implies" predicate của index).
- [ ] Giải thích được Index Only Scan cần gì ngoài "index có đủ cột" (liên hệ trước tới visibility map, sẽ học sâu ở Level 8).
- [ ] Phân biệt được khi nào dùng trigram, khi nào dùng full-text search (tsvector) — không phải lúc nào cũng thay thế nhau được.

## Lỗi hiểu sai thường gặp
- Nghĩ GIN index thay thế hoàn toàn B-tree (GIN không tốt cho equality/range đơn giản trên cột thường).
- Nghĩ covering index luôn nên dùng "cho chắc" (mỗi cột thêm vào `INCLUDE` đều tăng dung lượng + chi phí ghi).
- Nghĩ partial index tự động "mở rộng" áp dụng cho điều kiện superset (`IN` nhiều giá trị hơn predicate gốc).
