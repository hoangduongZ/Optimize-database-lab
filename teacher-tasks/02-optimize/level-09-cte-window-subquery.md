# Level 9 — CTE, window function, subquery vs join

## Mục tiêu
Học viên biết viết truy vấn phân tích (top-N theo nhóm, ranking) đúng cách
bằng window function, và hiểu CTE không phải lúc nào cũng là "hộp đen tối ưu
riêng" như nhiều người tưởng.

## Khái niệm cốt lõi
- **Window function** (`ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)`): tính toán "xuyên qua" các dòng trong 1 nhóm mà KHÔNG gộp dòng lại như `GROUP BY` — chạy sau `WHERE`/`GROUP BY`, trước `ORDER BY`/`LIMIT` cuối cùng.
- **CTE (`WITH ...`)**: từ Postgres 12, planner có thể INLINE CTE vào query chính (tối ưu như subquery thường) nếu CTE không đệ quy và không bị ép `MATERIALIZED`. Trước đó (≤ 11), CTE luôn là "optimization fence" (chặn tối ưu, luôn vật chất hoá).
- **Correlated subquery**: subquery tham chiếu tới cột của bảng ngoài — có thể bị chạy LẶP LẠI cho mỗi dòng của bảng ngoài, khác với JOIN (thường được gộp thành 1 lượt quét).

## Câu hỏi khởi động
> "Bạn viết `WITH top_orders AS (SELECT ... ) SELECT * FROM top_orders WHERE
> customer_id = 5`. Bạn nghĩ Postgres luôn tính TOÀN BỘ `top_orders` trước,
> rồi mới lọc `customer_id = 5`, hay có thể lọc sớm hơn?"

## Gợi ý ví dụ đời thường
Window function giống việc xếp hạng học sinh TRONG TỪNG LỚP (partition) mà
vẫn giữ nguyên danh sách học sinh đầy đủ (không gộp thành 1 dòng/lớp như
`GROUP BY` làm) — mỗi học sinh vẫn có 1 dòng riêng, chỉ thêm 1 cột "hạng của
em trong lớp".

## Demo trên lab
```sql
-- Top 3 sản phẩm có sale_price cao nhất mỗi category, bằng window function
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM (
    SELECT id, name, category_id, base_price,
           ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY base_price DESC) AS rnk
    FROM products
) ranked
WHERE rnk <= 3;

-- So sánh CTE inline (mặc định) vs ép MATERIALIZED
EXPLAIN (ANALYZE, BUFFERS)
WITH order_totals AS (
    SELECT customer_id, sum(total_amount) AS total FROM orders GROUP BY customer_id
)
SELECT * FROM order_totals WHERE customer_id = 5;

EXPLAIN (ANALYZE, BUFFERS)
WITH order_totals AS MATERIALIZED (
    SELECT customer_id, sum(total_amount) AS total FROM orders GROUP BY customer_id
)
SELECT * FROM order_totals WHERE customer_id = 5;
```
Học viên phải tự thấy: bản không ép MATERIALIZED có thể đẩy điều kiện
`customer_id = 5` VÀO TRONG CTE trước khi group by (nhanh hơn nhiều); bản ép
MATERIALIZED buộc tính toàn bộ `GROUP BY` cho MỌI customer trước, rồi mới lọc.

## Bài tập biến thể
Yêu cầu học viên viết lại "top 3 sản phẩm mỗi category" bằng correlated
subquery (không dùng window function), so sánh EXPLAIN với bản window
function — tự giải thích vì sao 1 trong 2 cách có thể chạy chậm hơn hẳn khi
số category tăng lên.

## Tiêu chí teach-back
- [ ] Giải thích được vì sao window function khác `GROUP BY` (không gộp dòng).
- [ ] Giải thích được khi nào CTE được inline, khi nào bị vật chất hoá (mặc định vs `MATERIALIZED`/đệ quy).
- [ ] Chỉ ra được điểm khác biệt trong EXPLAIN giữa bản CTE inline và bản MATERIALIZED của chính bài tập họ vừa làm.

## Lỗi hiểu sai thường gặp
- Nghĩ CTE luôn là "optimization fence" (chỉ đúng với Postgres cũ ≤ 11, hoặc khi ép `MATERIALIZED`/CTE đệ quy).
- Nghĩ window function cần `GROUP BY` đi kèm (không cần — window function hoạt động độc lập với GROUP BY).
- Nghĩ correlated subquery luôn tệ hơn JOIN (planner Postgres nhiều khi tự biến đổi subquery thành join tương đương — không phải lúc nào cũng chậm, nhưng cần kiểm chứng bằng EXPLAIN thay vì đoán).
