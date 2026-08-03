# Level 0 — SELECT/WHERE/ORDER BY & NULL cơ bản

## Mục tiêu
Học viên viết đúng điều kiện lọc nhiều mệnh đề (không sai vì độ ưu tiên toán
tử) và hiểu NULL không phải "giá trị" mà là "không biết" — nguồn gốc của rất
nhiều bug SQL tưởng chừng đơn giản.

## Khái niệm cốt lõi
- So sánh với `NULL` (`= `, `>`, `<`, `!=`) luôn ra `UNKNOWN`, không phải
  `TRUE`/`FALSE` — dòng có `UNKNOWN` bị loại khỏi `WHERE` giống như `FALSE`.
- `IS NULL` / `IS NOT NULL` — cách DUY NHẤT đúng để kiểm tra NULL.
- `COALESCE(a, b)` — trả giá trị đầu tiên không NULL.
- Độ ưu tiên toán tử: `AND` được tính TRƯỚC `OR` nếu không có dấu ngoặc —
  lỗi kinh điển khi viết điều kiện nhiều mệnh đề.
- `ORDER BY` nhiều cột: thứ tự cột quyết định "sort theo cột nào trước".

## Câu hỏi khởi động
> "`WHERE status = 'ACTIVE' AND category_id = 10 OR category_id = 20` — câu
> này có nghĩa là 'ACTIVE và (category 10 hoặc 20)', hay nghĩa khác? Đoán
> trước khi học."

## Gợi ý ví dụ đời thường
NULL giống câu trả lời "không biết" khi được hỏi "sản phẩm này có đang giảm
giá không, giảm bao nhiêu?" — không phải "giảm 0đ" (đó là giá trị 0, biết rõ
ràng), mà là "chưa có thông tin gì cả". Hỏi "giá giảm > 0 không?" cho 1 sản
phẩm "không biết" → câu trả lời cũng phải là "không biết" (UNKNOWN), không
thể ép thành có/không.

## Demo trên lab
```sql
-- Trap độ ưu tiên toán tử: AND chạy trước OR
SELECT count(*) FROM products
WHERE status = 'ACTIVE' AND category_id = 10 OR category_id = 20;
-- ^ thực chất là: (status='ACTIVE' AND category_id=10) OR category_id=20
--   -> LẤY NHẦM cả sản phẩm INACTIVE nếu nó thuộc category_id=20

SELECT count(*) FROM products
WHERE status = 'ACTIVE' AND (category_id = 10 OR category_id = 20);
-- ^ đúng ý muốn ban đầu: ACTIVE, và thuộc 1 trong 2 category

-- Trap NULL: sale_price NULL nghĩa là "không giảm giá", không phải giảm 0đ
SELECT count(*) FROM products WHERE sale_price > 0;      -- có giảm giá
SELECT count(*) FROM products WHERE sale_price IS NULL;  -- KHÔNG giảm giá
SELECT count(*) FROM products;                            -- tổng, phải khớp 2 số trên cộng lại
```

## Bài tập biến thể
Yêu cầu học viên tự viết query "sản phẩm ACTIVE, thuộc brand_id = 5 hoặc
brand_id = 8, VÀ có sale_price" — cố ý không nhắc về dấu ngoặc, xem học viên
có tự phát hiện cần ngoặc hay viết sai rồi tự debug bằng cách so sánh
`count(*)` với/không ngoặc.

## Tiêu chí teach-back
- [ ] Giải thích được vì sao so sánh với NULL không ra TRUE/FALSE mà ra UNKNOWN.
- [ ] Tự viết đúng 1 điều kiện nhiều mệnh đề AND/OR có dùng ngoặc đúng chỗ, không cần nhắc.
- [ ] Giải thích được `COALESCE` dùng khi nào, cho ví dụ tự nghĩ trên schema (gợi ý: `sale_price` hay `price_override` của variant).

## Lỗi hiểu sai thường gặp
- Nghĩ NULL là 1 giá trị đặc biệt có thể so sánh bằng `=` (`WHERE sale_price = NULL` KHÔNG BAO GIỜ đúng, dù ý muốn đúng).
- Nghĩ `AND`/`OR` được tính từ trái sang phải theo thứ tự viết (thực ra `AND` luôn được nhóm trước).
- Nhầm `ORDER BY a, b` với `ORDER BY a` rồi `ORDER BY b` riêng (thứ tự multi-column sort là ưu tiên từ trái sang phải, không phải 2 lần sort độc lập).
