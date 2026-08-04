# Level 0 — Normalization cơ bản (1NF/2NF/3NF)

## Mục tiêu
Học viên nhận diện được vi phạm chuẩn hoá trong 1 bảng "phẳng" (denormalized)
thật, hiểu 3 dạng anomaly (insert/update/delete) — không phải học thuộc định
nghĩa 1NF/2NF/3NF suông.

## Khái niệm cốt lõi
- **1NF**: mỗi cột chỉ chứa 1 giá trị đơn (không mảng/list nhồi trong 1 cột dạng CSV).
- **2NF**: (áp dụng khi PK là composite) mọi cột không-khoá phải phụ thuộc vào TOÀN BỘ PK, không chỉ 1 phần.
- **3NF**: mọi cột không-khoá phải phụ thuộc TRỰC TIẾP vào PK, không phụ thuộc qua 1 cột không-khoá khác (transitive dependency).
- **3 loại anomaly** khi vi phạm chuẩn hoá: Insert anomaly (không thêm được A nếu chưa có B), Update anomaly (sửa 1 chỗ phải sửa nhiều dòng, dễ sai lệch), Delete anomaly (xoá 1 dòng vô tình mất luôn thông tin khác không liên quan).

## Câu hỏi khởi động
> "Bảng sau có gì SAI, dù vẫn 'chạy được' và trả đúng dữ liệu?
> ```
> order_id | product_name | product_category | customer_name | customer_email
> 1        | Laptop X     | Electronics       | Nguyen Van A   | a@mail.com
> 2        | Laptop X     | Electronics       | Nguyen Van A   | a@mail.com
> ```
> "

## Gợi ý ví dụ đời thường
Bảng phẳng giống việc mỗi lần khách quay lại mua hàng, bạn viết TAY LẠI toàn
bộ thông tin khách (tên, email, địa chỉ) vào 1 sổ mới — thay vì lưu 1 lần
trong "sổ khách hàng" rồi chỉ ghi SỐ THỨ TỰ khách vào đơn hàng mới. Viết lại
nhiều lần thì chỉ cần 1 lần bạn ghi sai email là dữ liệu KHÔNG CÒN NHẤT QUÁN
giữa các dòng.

## Demo trên lab
Dùng chính bảng phẳng ở câu hỏi khởi động (tạo tạm để minh hoạ, không đụng
tới schema chính của lab):
```sql
CREATE TEMP TABLE flat_orders (
    order_id INT, product_name TEXT, product_category TEXT,
    customer_name TEXT, customer_email TEXT
);
INSERT INTO flat_orders VALUES
    (1, 'Laptop X', 'Electronics', 'Nguyen Van A', 'a@mail.com'),
    (2, 'Laptop X', 'Electronics', 'Nguyen Van A', 'a@mail.com');

-- Update anomaly: khách đổi email -> phải UPDATE ĐÚNG MỌI dòng của khách đó
UPDATE flat_orders SET customer_email = 'a-new@mail.com' WHERE customer_name = 'Nguyen Van A';
-- Nếu quên WHERE đủ điều kiện, hoặc có 1 dòng bị lệch chính tả 'Nguyen Van A ' (dư space)
-- -> dữ liệu khách hàng KHÔNG CÒN LÀ 1 SỰ THẬT DUY NHẤT nữa.
```
Đối chiếu với schema THẬT của lab (`users`, `products`, `orders`,
`order_items` — đã tách bảng đúng chuẩn hoá) để thấy vì sao tách vậy tránh
được anomaly trên.

## Bài tập biến thể
Đưa 1 bảng phẳng KHÁC (gợi ý: bảng "nhân viên - phòng ban - trưởng phòng"
kiểu `emp_id, emp_name, dept_name, dept_manager`), yêu cầu học viên tự chỉ ra
anomaly nào có thể xảy ra, và tự tách lại thành 2-3 bảng đúng chuẩn hoá.

## Tiêu chí teach-back
- [ ] Tự chỉ ra được ít nhất 2 trong 3 loại anomaly trên 1 bảng phẳng MỚI (không phải ví dụ đã demo).
- [ ] Giải thích được 3NF bằng lời của mình, không cần đọc định nghĩa.
- [ ] Tự tách đúng bảng ở bài tập biến thể, xác định đúng PK/FK sau khi tách.

## Lỗi hiểu sai thường gặp
- Học thuộc định nghĩa 1NF/2NF/3NF nhưng không nhận ra vi phạm khi nhìn 1 bảng thật.
- Nghĩ chuẩn hoá luôn là "đúng nhất", không biết có lúc CHỦ ĐỘNG denormalize là quyết định đúng (xem Level 2).
- Nhầm 2NF/3NF khi PK chỉ có 1 cột đơn (2NF luôn tự động thoả nếu PK không phải composite key — không cần áp dụng máy móc).
