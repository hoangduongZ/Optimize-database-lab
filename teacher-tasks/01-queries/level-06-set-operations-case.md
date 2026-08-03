# Level 6 — Set operations & CASE WHEN

## Mục tiêu
Học viên biết dùng `UNION`/`UNION ALL`/`INTERSECT`/`EXCEPT` đúng chỗ thay vì
luôn quy về `JOIN`/`subquery`, và dùng `CASE WHEN` để phân loại/gộp nhóm dữ
liệu theo điều kiện tuỳ ý (kiểu "pivot" đơn giản).

## Khái niệm cốt lõi
- `UNION`: nối kết quả 2 query CÙNG SỐ CỘT/kiểu dữ liệu, rồi LOẠI TRÙNG (cần bước dedupe/sort ngầm — có chi phí).
- `UNION ALL`: nối kết quả, GIỮ TRÙNG — rẻ hơn `UNION`, dùng khi chắc chắn không trùng hoặc không quan tâm trùng.
- `INTERSECT`: chỉ giữ dòng xuất hiện ở CẢ HAI query. `EXCEPT`: giữ dòng có ở query 1 mà KHÔNG có ở query 2 (giống "trừ tập hợp").
- `CASE WHEN ... THEN ... ELSE ... END`: biểu thức điều kiện dùng được trong `SELECT`, `WHERE`, `GROUP BY`, `ORDER BY` — công cụ chính để "phân khúc" dữ liệu theo tiêu chí tuỳ ý.

## Câu hỏi khởi động
> "Bạn nối 2 danh sách user_id bằng `UNION` thay vì `UNION ALL` 'cho chắc,
> khỏi trùng'. Nếu 2 danh sách đó chắc chắn không thể trùng nhau (ví dụ 1
> danh sách là ADMIN, 1 danh sách là CUSTOMER), dùng `UNION` có tốn gì
> không cần thiết không?"

## Gợi ý ví dụ đời thường
`UNION` giống việc gộp 2 danh sách khách mời rồi CỬ 1 NGƯỜI đứng soát lại
từ đầu để gạch tên trùng — tốn công dù đôi khi bạn đã BIẾT chắc 2 danh sách
không ai trùng ai. `EXCEPT` giống "ai có trong danh sách A mà KHÔNG có trong
danh sách điểm danh B" — dùng để tìm người vắng mặt.

## Demo trên lab
```sql
-- UNION (loại trùng) vs UNION ALL (giữ trùng) -- user vừa là customer, vừa từng review
SELECT count(*) FROM (
    SELECT id FROM users WHERE role = 'CUSTOMER'
    UNION
    SELECT user_id FROM reviews
) x;

SELECT count(*) FROM (
    SELECT id FROM users WHERE role = 'CUSTOMER'
    UNION ALL
    SELECT user_id FROM reviews
) x;
-- 2 số này khác nhau -- vì sao? (gợi ý: 1 user có thể vừa là CUSTOMER vừa có nhiều review)

-- EXCEPT: user có tài khoản nhưng CHƯA từng đặt hàng
SELECT id FROM users
EXCEPT
SELECT customer_id FROM orders;

-- CASE WHEN: phân khúc sản phẩm theo khung giá (pivot-like)
SELECT
    CASE
        WHEN base_price < 1000000  THEN 'duoi_1tr'
        WHEN base_price < 10000000 THEN '1tr_toi_10tr'
        ELSE 'tren_10tr'
    END AS price_bucket,
    count(*) AS total
FROM products
GROUP BY 1
ORDER BY 1;
```

## Bài tập biến thể
Yêu cầu học viên viết: "liệt kê `order_id` xuất hiện trong CẢ 2 tập: đơn có
`payment_method = 'COD'` VÀ đơn có `order_status = 'CANCELLED'`" bằng
`INTERSECT` — rồi viết LẠI cùng câu hỏi bằng `WHERE ... AND ...` thường,
đối chiếu 2 cách cho cùng kết quả, tự nhận xét cách nào dễ đọc hơn trong
trường hợp này.

## Tiêu chí teach-back
- [ ] Giải thích được khi nào nên dùng `UNION ALL` thay `UNION` (biết chắc không trùng, hoặc trùng không quan trọng).
- [ ] Tự viết đúng 1 câu `EXCEPT` mới (không phải ví dụ đã demo) diễn đạt đúng ý "có ở A mà không có ở B".
- [ ] Viết đúng `CASE WHEN` với thứ tự điều kiện hợp lý (nhắc: `CASE WHEN` chạy điều kiện THEO THỨ TỰ, dừng ở điều kiện ĐẦU TIÊN đúng — thứ tự viết quan trọng).

## Lỗi hiểu sai thường gặp
- Luôn dùng `UNION` mặc định mà không cân nhắc `UNION ALL` khi biết chắc không trùng.
- Viết `CASE WHEN` với điều kiện sai thứ tự (ví dụ đặt `base_price < 10000000` TRƯỚC `base_price < 1000000` — mọi dòng dưới 10tr đều rơi vào nhóm đó trước khi kịp so điều kiện hẹp hơn).
- Nghĩ `INTERSECT`/`EXCEPT` yêu cầu 2 bảng giống nhau hoàn toàn (chỉ cần SỐ CỘT và KIỂU DỮ LIỆU tương thích, không cần cùng bảng gốc).
