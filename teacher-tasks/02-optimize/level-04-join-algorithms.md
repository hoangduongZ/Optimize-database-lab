# Level 4 — Join algorithms

## Mục tiêu
Học viên hiểu 3 chiến lược join chính của Postgres và biết vì sao planner
chọn cái này thay vì cái khác tuỳ vào kích thước bảng, index có sẵn, và có cần
sort hay không.

## Khái niệm cốt lõi
- **Nested Loop**: với mỗi dòng bảng ngoài, quét/lookup bảng trong tương ứng — rẻ khi bảng ngoài NHỎ và bảng trong có index tốt cho điều kiện join.
- **Hash Join**: build hash table từ bảng nhỏ hơn (thường), probe bằng bảng lớn — không cần input đã sort, tốt khi cả 2 bảng khá lớn và không có index phù hợp.
- **Merge Join**: cần CẢ 2 input đã sort theo cột join — tốt cho join trên range hoặc khi dữ liệu đã sort sẵn (từ index).
- Planner chọn dựa trên COST ước lượng, không phải "luật cố định" — đổi kích thước bảng có thể đổi cả chiến lược.

## Câu hỏi khởi động
> "Join giữa 1 bảng chỉ có 30 dòng (`brands`) và 1 bảng có 100,000 dòng
> (`products`) — bạn đoán Postgres sẽ dùng Nested Loop, Hash Join, hay Merge
> Join?"

## Gợi ý ví dụ đời thường
- Nested Loop: tra từng tên trong 30 cuốn sổ nhỏ — với MỖI tên, bạn lục tìm trong 1 cuốn sổ lớn đã có mục lục (index) sẵn.
- Hash Join: chia toàn bộ 30 cái tên vào các ô ngăn tủ theo chữ đầu (hash) trước, sau đó chỉ cần liếc qua ngăn tương ứng khi xử lý từng dòng của bảng lớn — không cần mục lục có sẵn.
- Merge Join: nếu CẢ 2 danh sách đã được xếp theo thứ tự A-Z từ trước, chỉ cần 2 người cùng lướt song song từ đầu tới cuối, không ai phải quay lại.

## Demo trên lab
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.name, b.name FROM products p JOIN brands b ON b.id = p.brand_id;

-- Buộc planner đổi chiến lược để so sánh (chỉ dùng để HỌC, không dùng trong production)
SET enable_hashjoin = off;
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.name, b.name FROM products p JOIN brands b ON b.id = p.brand_id;
RESET enable_hashjoin;
```

> Lưu ý khi dạy: sau `SET enable_hashjoin = off`, plan có thể xuất hiện thêm
> node `Memoize` phía trên Nested Loop (Postgres 14+ tự cache kết quả lookup
> lặp lại cho các giá trị `brand_id` hay gặp). Đây là 1 tối ưu PHỤ, không
> phải trọng tâm bài này — chỉ cần nói ngắn "Postgres cache lại kết quả tra
> cứu lặp lại để đỡ query trùng nhiều lần", không cần đi sâu.

## Bài tập biến thể
Yêu cầu học viên tự chọn 1 cặp join khác trong schema (ví dụ `orders` join
`order_items`, hoặc `products` join `product_variants`), dự đoán chiến lược
join TRƯỚC khi chạy EXPLAIN, sau đó thử `SET enable_nestloop/hashjoin/mergejoin
= off` từng cái để xem chiến lược dự phòng của planner là gì.

## Tiêu chí teach-back
- [ ] Giải thích đúng 3 chiến lược join bằng lời của mình, không cần thuật ngữ chính xác nhưng phải đúng ý tưởng.
- [ ] Giải thích được vì sao planner đổi chiến lược khi kích thước 1 trong 2 bảng thay đổi đáng kể.
- [ ] Giải thích được vì sao Merge Join cần input đã sort — liên hệ lại với B-tree index ở Level 3 (index vốn đã sort sẵn).

## Lỗi hiểu sai thường gặp
- Nghĩ Nested Loop luôn là "tệ" (nó rất tốt khi bảng ngoài nhỏ + có index).
- Nghĩ Hash Join luôn là lựa chọn tốt nhất (tốn RAM để build hash table, có thể spill ra disk nếu bảng quá lớn — `work_mem` không đủ).
- Nhầm "thứ tự viết trong câu SQL" (`A JOIN B`) quyết định thứ tự thực thi — planner có thể đảo chiều, chọn bảng nào build hash trước dựa trên cost, không theo thứ tự viết.
