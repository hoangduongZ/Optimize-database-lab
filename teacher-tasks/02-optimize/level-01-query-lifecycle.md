# Level 1 — Query lifecycle: Parse → Rewrite → Plan → Execute

## Mục tiêu
Học viên hiểu 1 câu SQL không "chạy thẳng" mà đi qua 4 tầng riêng biệt, và
biết tầng nào chịu trách nhiệm cho việc gì — nền tảng để hiểu Level 2 (EXPLAIN)
và Level 9 (view/CTE rewrite).

## Khái niệm cốt lõi
- **Parse**: kiểm tra cú pháp + đối chiếu catalog (bảng/cột có tồn tại không).
- **Rewrite**: mở rộng view, áp rule — SQL của bạn có thể bị "biến hình" trước khi tới planner.
- **Plan (Planner/Optimizer)**: sinh nhiều plan khả thi, ước lượng cost, chọn plan rẻ nhất.
- **Execute**: chạy plan đã chọn theo mô hình iterator (node cha "kéo" dữ liệu từ node con).

## Câu hỏi khởi động
> "Nếu tôi query qua 1 VIEW, Postgres có lưu sẵn kết quả của view đó ở đâu để
> đọc nhanh không, hay làm gì khác?"

## Gợi ý ví dụ đời thường
Nhà hàng: bạn gọi món theo tên trên menu (SQL) → lễ tân kiểm tra món có tồn
tại không (Parse) → nếu bạn gọi "set trưa" (VIEW), bếp tự nội bộ "dịch" thành
danh sách nguyên liệu thật cần nấu (Rewrite) → bếp trưởng chọn cách nấu nhanh
nhất tuỳ nguyên liệu đang có sẵn trong kho hôm đó (Plan) → đầu bếp thực sự nấu
(Execute).

## Demo trên lab
```sql
-- Planning Time vs Execution Time là 2 con số khác nhau trong EXPLAIN ANALYZE
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM products WHERE category_id = 10;

-- Minh chứng Rewrite: tạo 1 view rồi query qua view, xem plan có "biến mất" view không
CREATE VIEW active_products AS SELECT * FROM products WHERE status = 'ACTIVE';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM active_products WHERE category_id = 10;
-- Plan phải cho thấy filter status='ACTIVE' ĐƯỢC GỘP vào cùng 1 Seq/Index Scan
-- với category_id=10 -- chứng minh view chỉ là "định nghĩa được rewrite vào",
-- không phải bảng vật lý riêng.
```

## Bài tập biến thể
Yêu cầu học viên tự tạo 1 view khác (ví dụ view join `orders` + `users`), rồi
tự dự đoán: "plan có xuất hiện chữ CREATE VIEW hay chữ 'active_products' nào
không?" trước khi chạy EXPLAIN để verify dự đoán.

## Tiêu chí teach-back
- [ ] Kể đúng thứ tự 4 tầng và vai trò từng tầng bằng lời của mình (không cần thuật ngữ tiếng Anh chuẩn xác, nhưng phải đúng ý).
- [ ] Giải thích được vì sao query qua VIEW không hề "chậm hơn" ở tầng Execute — vì nó đã bị rewrite thành query gốc từ trước đó.
- [ ] Phân biệt được Planning Time và Execution Time trong output EXPLAIN ANALYZE.

## Lỗi hiểu sai thường gặp
- Nghĩ VIEW là 1 bảng có lưu data riêng (đó là MATERIALIZED VIEW, khác hoàn toàn — không dạy ở level này, chỉ cần học viên KHÔNG nhầm 2 khái niệm).
- Nghĩ Planning Time luôn nhỏ không đáng kể (với query phức tạp nhiều join, planning time có thể chiếm phần đáng kể).
- Nghĩ Parse có thể phát hiện query "chạy sai logic" — Parse chỉ bắt lỗi cú pháp/catalog, không bắt lỗi logic nghiệp vụ.
