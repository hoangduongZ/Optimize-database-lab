# Level 5 — CTE & Window function

## Mục tiêu
Học viên viết được các bài toán phân tích thường gặp (ranking theo nhóm,
so sánh với dòng trước/sau, tổng tích luỹ) bằng window function — thay vì
cố gói ghém bằng subquery lồng nhau khó đọc.

## Khái niệm cốt lõi
- `WITH ten AS (...)` (CTE): đặt tên cho 1 subquery để query chính đọc dễ hiểu hơn — Ở LEVEL NÀY chỉ quan tâm tính ĐÚNG/dễ đọc, chưa quan tâm hiệu năng (xem Track B Level 9).
- Window function chạy "xuyên qua" từng dòng, KHÔNG gộp dòng lại như `GROUP BY`.
- `ROW_NUMBER()`: đánh số duy nhất 1,2,3,... dù có bằng nhau. `RANK()`: đồng hạng thì cùng số, nhưng NHẢY số sau đó. `DENSE_RANK()`: đồng hạng thì cùng số, KHÔNG nhảy số.
- `PARTITION BY`: chia "cửa sổ" tính toán theo từng nhóm riêng (giống `GROUP BY` nhưng không gộp dòng).
- `LAG()`/`LEAD()`: lấy giá trị của dòng TRƯỚC/SAU (theo `ORDER BY` trong `OVER`) — dùng để so sánh "so với hôm trước".
- `SUM(...) OVER (ORDER BY ...)`: tổng tích luỹ (running total).

## Câu hỏi khởi động
> "3 sản phẩm có `base_price` CAO NHẤT trong 1 category, mà 2 sản phẩm đầu
> giá bằng nhau. `ROW_NUMBER()` và `RANK()` sẽ đánh số 2 sản phẩm đó giống
> hay khác nhau?"

## Gợi ý ví dụ đời thường
Window function giống việc xếp hạng học sinh TRONG TỪNG LỚP (`PARTITION BY`
lớp) mà KHÔNG gộp học sinh cùng lớp thành 1 dòng — mỗi em vẫn có 1 dòng
riêng, chỉ thêm 1 cột "hạng của em trong lớp". `RANK()` giống cách xếp hạng
thi đấu thể thao: 2 người đồng hạng 1 thì người thứ 3 phải nhận hạng... 3
(nhảy qua hạng 2) — còn `DENSE_RANK()` thì người thứ 3 vẫn được hạng 2.

## Demo trên lab
```sql
-- ROW_NUMBER vs RANK vs DENSE_RANK khi có nhiều sản phẩm cùng giá
SELECT id, name, category_id, base_price,
       ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY base_price DESC) AS rn,
       RANK()       OVER (PARTITION BY category_id ORDER BY base_price DESC) AS rk,
       DENSE_RANK() OVER (PARTITION BY category_id ORDER BY base_price DESC) AS drk
FROM products
WHERE category_id = 1
ORDER BY base_price DESC
LIMIT 10;

-- CTE + window: doanh thu theo ngày, tổng tích luỹ, và so với ngày trước
WITH daily AS (
    SELECT placed_at::date AS day, sum(total_amount) AS daily_total
    FROM orders
    GROUP BY placed_at::date
)
SELECT day, daily_total,
       SUM(daily_total) OVER (ORDER BY day)  AS running_total,
       daily_total - LAG(daily_total) OVER (ORDER BY day) AS change_vs_prev_day
FROM daily
ORDER BY day
LIMIT 15;
```

## Bài tập biến thể
Yêu cầu học viên viết: "với mỗi user, tìm ĐÚNG 1 đơn hàng GẦN NHẤT của họ
(mã đơn + ngày đặt)" bằng window function (`ROW_NUMBER() OVER (PARTITION BY
customer_id ORDER BY placed_at DESC)` rồi lọc `= 1`) — đây là pattern
"top-1-per-group" cực kỳ hay dùng trong thực tế, khác với ví dụ "top-3" đã
demo.

## Tiêu chí teach-back
- [ ] Tự giải thích được khác biệt `ROW_NUMBER`/`RANK`/`DENSE_RANK` bằng ví dụ có giá trị trùng, không cần xem lại demo.
- [ ] Giải thích được `PARTITION BY` khác `GROUP BY` ở điểm nào (không gộp dòng).
- [ ] Tự viết đúng bài tập biến thể "top-1-per-group" mà không cần gợi ý cấu trúc.

## Lỗi hiểu sai thường gặp
- Nghĩ window function PHẢI đi kèm `GROUP BY` (không cần — 2 khái niệm độc lập).
- Dùng `RANK()` khi ý muốn thực ra cần số thứ tự DUY NHẤT không trùng (nên dùng `ROW_NUMBER()`).
- Quên rằng muốn lọc theo kết quả window function (`WHERE rn = 1`) thì PHẢI bọc trong subquery/CTE — không thể `WHERE` trực tiếp trên 1 window function ở cùng cấp `SELECT` (giống lý do không dùng aggregate trong `WHERE` ở Level 3).
