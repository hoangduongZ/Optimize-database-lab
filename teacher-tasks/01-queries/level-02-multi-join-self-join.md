# Level 2 — Multi-table JOIN & self-join

## Mục tiêu
Học viên nối được 3+ bảng đúng thứ tự logic, và hiểu self-join — kỹ thuật
join 1 bảng với chính nó để biểu diễn quan hệ cha-con/phân cấp.

## Khái niệm cốt lõi
- Join chain: mỗi `JOIN` thêm 1 bảng, điều kiện `ON` phải đúng cặp FK — thiếu điều kiện `ON` (hoặc sai) tạo ra cartesian product (nhân tích, số dòng bùng nổ).
- Alias (`AS`, hoặc chỉ đặt tên ngắn) BẮT BUỘC khi self-join — dùng để phân biệt "vai" của bảng trong từng lượt join (ở đây là "dòng con" và "dòng cha").
- Self-join: join 1 bảng với chính nó qua 1 cột tự tham chiếu (`parent_id` trỏ về `id` của cùng bảng).

## Câu hỏi khởi động
> "Bảng `categories` có cột `parent_id` tự tham chiếu tới `categories.id`.
> Muốn liệt kê 'tên category con — tên category cha', bạn join bảng này với
> bảng nào?"

## Gợi ý ví dụ đời thường
Self-join giống việc lấy 2 bản photocopy của CÙNG 1 sơ đồ tổ chức công ty,
đặt cạnh nhau, rồi nối "dòng ghi tên nhân viên" ở bản 1 với "dòng ghi tên
QUẢN LÝ của nhân viên đó" ở bản 2 — vẫn là 1 sơ đồ duy nhất, chỉ cần 2 "vai"
khác nhau để so khớp.

## Demo trên lab
```sql
-- 3-bảng: sản phẩm + category + brand
SELECT p.name, c.name AS category, b.name AS brand
FROM products p
JOIN categories c ON c.id = p.category_id
JOIN brands b ON b.id = p.brand_id
LIMIT 10;

-- Seed gốc không có category cha-con (parent_id toàn NULL) -- tạo dữ liệu demo:
UPDATE categories SET parent_id = 1 WHERE id IN (2, 3, 4);

-- Self-join: liệt kê category con kèm tên category cha
SELECT child.name AS child_category, parent.name AS parent_category
FROM categories child
JOIN categories parent ON parent.id = child.parent_id;

-- Đối chứng lỗi cartesian product: bỏ sót điều kiện ON (KHÔNG chạy thật trên
-- bảng lớn, chỉ minh hoạ trên categories nhỏ để an toàn)
SELECT count(*) FROM categories c1, categories c2;  -- 50 x 50 = 2500, không phải 50
```

## Bài tập biến thể
Yêu cầu học viên viết query 4 bảng: `orders` + `users` + `order_items` +
`products` — liệt kê email khách hàng, tên sản phẩm, số lượng đã mua, cho 1
đơn hàng cụ thể (`order_id` do bạn chỉ định tại chỗ). Yêu cầu học viên tự xác
định ĐÚNG THỨ TỰ join hợp lý và alias rõ ràng.

## Tiêu chí teach-back
- [ ] Giải thích được cartesian product xảy ra khi nào (thiếu/sai điều kiện `ON`).
- [ ] Tự viết đúng 1 self-join khác trên schema (gợi ý: nếu có thêm bảng nhân viên quản lý nhân viên — hoặc dùng lại categories với ví dụ khác) mà không cần xem lại ví dụ cũ.
- [ ] Giải thích được vì sao self-join BẮT BUỘC phải dùng alias khác nhau cho 2 lần xuất hiện của cùng 1 bảng.

## Lỗi hiểu sai thường gặp
- Quên điều kiện `ON` hoặc dùng `WHERE` thay `ON` cho điều kiện join phụ (khác biệt quan trọng khi join có LEFT JOIN — điều kiện đặt trong `ON` vs `WHERE` cho kết quả khác nhau với LEFT JOIN, xem lại Level 1 nếu cần).
- Nghĩ self-join cần cấu trúc SQL đặc biệt khác JOIN thường (thực ra chỉ là JOIN thường, với origin và target là CÙNG 1 bảng vật lý — chỉ khác ở việc phải đặt tên alias).
- Join nhiều bảng mà không kiểm tra `count(*)` trung gian sau mỗi lần thêm JOIN — dễ không phát hiện fan-out/cartesian product cho tới khi kết quả cuối sai lệch khó truy ngược.
