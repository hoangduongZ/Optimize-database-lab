# Level 4 — Subquery: IN / EXISTS / correlated, và cái trap NULL kinh điển

## Mục tiêu
Học viên biết chọn đúng giữa `IN`, `EXISTS`, `NOT IN`, `NOT EXISTS` — và
đặc biệt phải tự tay va vào lỗi `NOT IN` + NULL ít nhất 1 lần để nhớ mãi,
không chỉ nghe kể.

## Khái niệm cốt lõi
- **Subquery không tương quan** (non-correlated): chạy ĐỘC LẬP 1 lần, không phụ thuộc dòng ngoài — dùng với `IN`/`NOT IN`.
- **Subquery tương quan** (correlated): tham chiếu tới cột của dòng NGOÀI — về mặt logic chạy lại cho MỖI dòng ngoài — dùng với `EXISTS`/`NOT EXISTS`.
- **Trap kinh điển**: nếu tập giá trị trong subquery của `NOT IN` chứa BẤT KỲ 1 NULL nào, `NOT IN` trả UNKNOWN cho MỌI dòng đang so sánh với tập đó → toàn bộ query trả về RỖNG một cách âm thầm (không lỗi, chỉ sai).
- `NOT EXISTS` KHÔNG bị trap này — nó không so sánh giá trị, chỉ hỏi "có dòng nào khớp điều kiện không".

## Câu hỏi khởi động
> "Bảng `carts.customer_id` có thể NULL (giỏ hàng của khách chưa đăng nhập).
> `SELECT * FROM users WHERE id NOT IN (SELECT customer_id FROM carts)` —
> bạn đoán câu này chạy đúng, chạy lỗi, hay chạy ra kết quả... kỳ lạ?"

## Gợi ý ví dụ đời thường
`NOT IN (SELECT ...)` giống việc so "tên bạn có nằm ngoài danh sách này
không" — nhưng nếu danh sách đó có 1 dòng bị NHOÈ MỰC không đọc được
(NULL), bạn không thể chắc "tên tôi có trùng dòng nhoè đó không" — nên với
MỌI cái tên, câu trả lời buộc phải là "không chắc" (UNKNOWN), dù 99% dòng
còn lại đọc rõ ràng và không trùng.

## Demo trên lab
```sql
-- Tạo 1 dòng cart khách (guest, không đăng nhập) để có dữ liệu demo thật
-- (seed gốc không có customer_id NULL nào trong carts)
INSERT INTO carts (customer_id, session_id) VALUES (NULL, 'guest-demo-session');

-- Trap: NOT IN với subquery có chứa NULL
SELECT count(*) FROM users WHERE id NOT IN (SELECT customer_id FROM carts);
-- Kỳ vọng học viên bất ngờ: ra 0 (hoặc rất khác số hợp lý), dù chắc chắn có
-- user chưa từng tạo cart (chỉ 20,000/50,000 user có cart)

-- Sửa đúng bằng NOT EXISTS
SELECT count(*) FROM users u
WHERE NOT EXISTS (SELECT 1 FROM carts c WHERE c.customer_id = u.id);
-- Ra số dương hợp lý, không bị NULL "đầu độc" toàn bộ kết quả

-- Sửa đúng bằng cách loại NULL khỏi subquery của NOT IN (cách 2, ít khuyến khích hơn NOT EXISTS)
SELECT count(*) FROM users
WHERE id NOT IN (SELECT customer_id FROM carts WHERE customer_id IS NOT NULL);
```

## Bài tập biến thể
Yêu cầu học viên viết: "liệt kê sản phẩm CHƯA từng xuất hiện trong bất kỳ
`order_items` nào" — bằng CẢ 2 cách (`NOT IN` và `NOT EXISTS`), rồi tự kiểm
tra `order_items.variant_id` (cột nullable) có gây ra trap tương tự nếu vô
tình dùng nhầm cột đó cho subquery.

## Tiêu chí teach-back
- [ ] Tự giải thích được (không cần xem lại demo) vì sao `NOT IN` với subquery chứa NULL trả về rỗng toàn bộ.
- [ ] Giải thích được vì sao `NOT EXISTS` an toàn hơn `NOT IN` trong trường hợp cột có thể NULL.
- [ ] Phân biệt được correlated vs non-correlated subquery bằng ví dụ tự viết.

## Lỗi hiểu sai thường gặp
- Dùng `NOT IN` như phản xạ mặc định mà không kiểm tra cột trong subquery có thể NULL không.
- Nghĩ `IN` (không phải `NOT IN`) cũng bị trap tương tự (thực ra `IN` với subquery chứa NULL vẫn đúng cho các dòng THỰC SỰ khớp — chỉ `NOT IN` mới nguy hiểm, vì phủ định của UNKNOWN vẫn là UNKNOWN).
- Nghĩ correlated subquery luôn tệ hơn về hiệu năng (đây là chủ đề của Track B, KHÔNG phải trọng tâm ở đây — Level 4 Track A chỉ tập trung vào ĐÚNG, chưa cần lo NHANH).
