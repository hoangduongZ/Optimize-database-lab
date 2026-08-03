# Level 3 — Aggregate: GROUP BY / HAVING

## Mục tiêu
Học viên phân biệt rõ `WHERE` (lọc DÒNG trước khi nhóm) và `HAVING` (lọc
NHÓM sau khi đã aggregate), và hiểu `COUNT(*)` khác `COUNT(cột)` ở điểm nào.

## Khái niệm cốt lõi
- `GROUP BY`: gộp các dòng có cùng giá trị (các) cột chỉ định thành 1 nhóm, mỗi nhóm ra 1 dòng kết quả.
- `WHERE` chạy TRƯỚC `GROUP BY` (lọc dòng thô); `HAVING` chạy SAU (lọc nhóm dựa trên kết quả aggregate) — không thể dùng hàm aggregate trong `WHERE`.
- `COUNT(*)` đếm SỐ DÒNG (kể cả NULL ở mọi cột); `COUNT(cột)` đếm số dòng có `cột` KHÁC NULL.
- Mọi cột xuất hiện trong `SELECT` (mà không nằm trong hàm aggregate) PHẢI có trong `GROUP BY`.

## Câu hỏi khởi động
> "Muốn tìm các category có TRÊN 1900 sản phẩm, bạn lọc điều kiện đó bằng
> `WHERE count(*) > 1900` hay cách khác? Thử đoán trước khi chạy."

## Gợi ý ví dụ đời thường
`WHERE` giống việc chọn lọc TỪNG học sinh trước khi chia vào lớp (theo tiêu
chí của riêng học sinh đó, ví dụ điểm đầu vào). `HAVING` giống việc, SAU KHI
đã chia xong các lớp, chỉ giữ lại NHỮNG LỚP có sĩ số trên 30 — tiêu chí này
chỉ có ý nghĩa ở cấp độ LỚP (nhóm), không phải cấp độ từng học sinh.

## Demo trên lab
```sql
-- Lỗi cú pháp kinh điển: dùng aggregate trong WHERE
SELECT category_id, count(*) FROM products WHERE count(*) > 1900 GROUP BY category_id;
-- Postgres báo lỗi: "aggregate functions are not allowed in WHERE clause"
-- -> phải dùng HAVING:
SELECT category_id, count(*) AS total
FROM products
GROUP BY category_id
HAVING count(*) > 1900
ORDER BY total DESC;

-- COUNT(*) vs COUNT(cột): sale_price có nhiều NULL (sản phẩm không giảm giá)
SELECT category_id,
       count(*)        AS total_products,
       count(sale_price) AS products_on_sale
FROM products
GROUP BY category_id
ORDER BY category_id
LIMIT 5;

-- Kết hợp WHERE (lọc dòng trước) + HAVING (lọc nhóm sau)
SELECT category_id, count(*) AS active_total
FROM products
WHERE status = 'ACTIVE'
GROUP BY category_id
HAVING count(*) > 1800;
```

## Bài tập biến thể
Yêu cầu học viên viết: "liệt kê những khách hàng (customer_id) có tổng chi
tiêu (`sum(total_amount)`) trên 100,000,000đ, CHỈ tính đơn hàng có
`order_status = 'DELIVERED'`" — buộc phải kết hợp đúng `WHERE` (lọc đơn
DELIVERED) và `HAVING` (lọc theo tổng sau khi group).

## Tiêu chí teach-back
- [ ] Tự giải thích được vì sao không thể viết `WHERE count(*) > N` (thứ tự thực thi: WHERE chạy trước khi có kết quả aggregate).
- [ ] Tự viết đúng bài tập biến thể ở trên, dùng đúng cả `WHERE` và `HAVING` mà không lẫn lộn.
- [ ] Giải thích được khi nào `COUNT(*)` và `COUNT(cột)` cho kết quả khác nhau.

## Lỗi hiểu sai thường gặp
- Nghĩ `WHERE` và `HAVING` có thể dùng thay thế nhau tuỳ ý (chỉ đổi được khi điều kiện không liên quan tới hàm aggregate).
- Quên đưa cột không-aggregate vào `GROUP BY`, gây lỗi "column must appear in the GROUP BY clause".
- Nghĩ `COUNT(cột)` đếm số dòng giống `COUNT(*)` (quên rằng nó bỏ qua NULL).
