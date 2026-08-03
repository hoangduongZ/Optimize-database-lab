# Level 1 — JOIN cơ bản: INNER vs LEFT, fan-out

## Mục tiêu
Học viên chọn đúng loại JOIN theo ý nghĩa nghiệp vụ ("chỉ lấy cái có khớp"
vs "lấy hết, kể cả chưa có liên kết"), và nhận ra khi nào 1 dòng bị "nhân
bản" (fan-out) do quan hệ 1-nhiều — nguyên nhân số 1 gây sai kết quả đếm/tổng
sau khi JOIN.

## Khái niệm cốt lõi
- **INNER JOIN**: chỉ giữ dòng có khớp ở CẢ HAI bên.
- **LEFT JOIN**: giữ TOÀN BỘ bên trái; nếu không khớp bên phải, các cột bên phải là NULL.
- **Fan-out**: JOIN quan hệ 1-nhiều làm dòng bên "1" bị lặp lại nhiều lần (1 lần cho mỗi dòng khớp bên "nhiều") — `COUNT(*)` sau JOIN dễ bị sai nếu không ý thức điều này.
- Pattern "tìm cái CHƯA có liên kết": `LEFT JOIN ... WHERE <cột_bên_phải> IS NULL`.

## Câu hỏi khởi động
> "`SELECT count(*) FROM products p JOIN reviews r ON r.product_id = p.id`
> — kết quả có bằng đúng số dòng của bảng `products` không? Vì sao có/không?"

## Gợi ý ví dụ đời thường
INNER JOIN giống "chỉ mời những ai CÓ tên trong CẢ 2 danh sách khách mời".
LEFT JOIN giống "mời hết danh sách A, ai có mặt trong danh sách B thì ghi
thêm thông tin, ai không có thì để trống — không loại ai khỏi danh sách A cả".

## Demo trên lab
```sql
SELECT count(*) FROM products;                                          -- 100,000 (mốc so sánh)

SELECT count(*) FROM products p JOIN reviews r ON r.product_id = p.id;  -- KHÁC 100,000 -- vì sao?
SELECT count(DISTINCT p.id) FROM products p JOIN reviews r ON r.product_id = p.id;  -- số SẢN PHẨM (không trùng) có review

-- Pattern "chưa có liên kết": sản phẩm CHƯA có review nào
SELECT count(*) FROM products p
LEFT JOIN reviews r ON r.product_id = p.id
WHERE r.id IS NULL;
```
Học viên phải tự đối chiếu: `count(DISTINCT p.id)` (sản phẩm có review) +
`count(*)` ở câu LEFT JOIN...IS NULL (sản phẩm chưa có review) phải CỘNG LẠI
ĐÚNG BẰNG 100,000.

## Bài tập biến thể
Yêu cầu học viên viết: "liệt kê user CHƯA từng tạo cart nào" (dùng bảng
`users` + `carts`), và ngược lại "user ĐÃ từng tạo ít nhất 1 cart" — tự chọn
đúng loại JOIN cho mỗi câu, tự verify bằng cách cộng 2 kết quả lại phải khớp
tổng số user.

## Tiêu chí teach-back
- [ ] Giải thích được vì sao `count(*)` sau INNER JOIN có thể khác số dòng bảng gốc.
- [ ] Tự viết đúng pattern "tìm dòng CHƯA có liên kết" bằng LEFT JOIN + IS NULL, không cần xem lại ví dụ.
- [ ] Giải thích được khi nào cần `DISTINCT` sau JOIN (khi quan hệ 1-nhiều và chỉ cần biết "có/không", không cần đếm số lần khớp).

## Lỗi hiểu sai thường gặp
- Coi `count(*)` sau JOIN luôn phản ánh đúng số lượng thực thể ở bảng gốc (bỏ qua fan-out).
- Nghĩ LEFT JOIN + `WHERE <cột_bên_phải> = <giá_trị>` cho kết quả giống INNER JOIN + cùng điều kiện — thực ra ĐÚNG trong TH này (WHERE lọc sau join biến LEFT thành INNER), nhưng SAI hoàn toàn nếu ai đó nhầm dùng để tìm "chưa có liên kết" bằng `= NULL` thay vì `IS NULL` (không bao giờ đúng, xem lại Level 0).
- Nghĩ phải luôn dùng LEFT JOIN "cho an toàn" — INNER JOIN đúng và rẻ hơn khi ý nghĩa nghiệp vụ là "chỉ lấy cái chắc chắn có liên kết".
