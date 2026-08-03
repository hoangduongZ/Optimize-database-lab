# Level 3 — B-tree index cơ bản

## Mục tiêu
Học viên hiểu B-tree index là gì ở mức đủ dùng (không cần cài đặt chi tiết),
và — quan trọng hơn — biết PHÂN BIỆT khi nào 1 điều kiện WHERE "sargable" (có
thể dùng index) và khi nào không.

## Khái niệm cốt lõi
- B-tree: cấu trúc cây cân bằng, dữ liệu được SẮP XẾP theo cột index — tìm 1 giá trị mất `O(log n)` thay vì đọc hết bảng.
- **Leading column**: index đa cột `(a, b, c)` chỉ dùng hiệu quả khi điều kiện WHERE bắt đầu từ cột `a` (giống tra từ điển — phải theo đúng thứ tự chữ cái từ chữ đầu).
- **Sargable vs non-sargable**: bọc hàm lên cột đã index (`WHERE upper(name) = ...`), dùng `LIKE '%...'` (không có prefix cố định), hoặc so sánh kiểu dữ liệu khác (implicit cast) → index KHÔNG dùng được.
- Index không miễn phí: mỗi INSERT/UPDATE/DELETE đều phải cập nhật index — không nên tạo "cho chắc".

## Câu hỏi khởi động
> "Bạn có 1 index trên `(category_id, status, base_price)`. Query
> `WHERE status = 'ACTIVE'` (không có category_id) có dùng được index này
> không? Đoán trước khi học."

## Gợi ý ví dụ đời thường
Index đa cột giống từ điển giấy: sắp theo A-B-C. Muốn tìm từ bắt đầu bằng
"ba" bạn mở đúng phần "B" rất nhanh. Nhưng muốn tìm TẤT CẢ từ có chữ "a" ở vị
trí thứ 2 (bất kể chữ đầu) — từ điển sắp theo A-B-C không giúp được gì, phải
đọc hết từng trang.

## Demo trên lab
Dùng `../../03_exercises/01_missing_fk_index.sql` và
`../../03_exercises/02_composite_index_filter_sort.sql` đã có. Bổ sung minh hoạ non-sargable:
```sql
CREATE INDEX idx_products_name ON products (name);
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM products WHERE name = 'Laptop Gaming 12345';       -- dùng index
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM products WHERE upper(name) = 'LAPTOP GAMING 12345'; -- KHÔNG dùng index
```

## Bài tập biến thể
Cho học viên index `(category_id, status, base_price)` đã tạo ở bài 02. Đưa
ra 3-4 query mới (không có trong `03_exercises`) và yêu cầu học viên phân loại
"dùng được index" hay "không" TRƯỚC khi chạy EXPLAIN kiểm tra, ví dụ:
- `WHERE status = 'ACTIVE' AND base_price > 1000000` (thiếu category_id ở đầu)
- `WHERE category_id = 10` (không có status/base_price)
- `WHERE category_id = 10 AND status = 'ACTIVE'`

## Tiêu chí teach-back
- [ ] Giải thích được "leading column" bằng ví dụ tự nghĩ ra (không lặp lại y nguyên ví dụ từ điển).
- [ ] Tự viết được 1 query sargable và 1 query non-sargable trên CÙNG 1 cột, giải thích vì sao.
- [ ] Giải thích được vì sao không nên tạo index cho mọi cột.

## Lỗi hiểu sai thường gặp
- Nghĩ có index trên cột là chắc query lọc cột đó sẽ dùng được (bỏ qua vị trí trong composite index).
- Nghĩ B-tree dùng được cho `LIKE '%keyword%'` (chỉ dùng được cho prefix `'keyword%'`, phần `%...%` cần trigram — liên hệ Level 5).
- Nghĩ tạo thêm index luôn "an toàn", không có chi phí.
