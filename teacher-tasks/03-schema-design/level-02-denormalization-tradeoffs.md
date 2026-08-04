# Level 2 — Khi nào KHÔNG chuẩn hoá (denormalization trade-offs)

## Mục tiêu
Học viên hiểu chuẩn hoá KHÔNG phải mục tiêu tối thượng — schema thật (kể cả
schema của chính lab này) luôn có vài chỗ CHỦ ĐỘNG denormalize, và phải giải
thích được ĐÚNG lý do, không phải "cho nhanh".

## Khái niệm cốt lõi
- **Snapshot pattern**: lưu LẠI 1 bản sao dữ liệu tại thời điểm xảy ra sự kiện, dù dữ liệu gốc có thể đổi sau đó — dùng khi cần TÍNH BẤT BIẾN theo thời gian (lịch sử/pháp lý), không phải khi cần tối ưu tốc độ.
- **EAV (Entity-Attribute-Value)**: 1 bảng generic `(entity_id, attribute_id, value)` thay vì 1 cột riêng cho mỗi thuộc tính — đánh đổi: linh hoạt thêm thuộc tính mới KHÔNG CẦN migration, nhưng khó ràng buộc kiểu dữ liệu, query lọc phức tạp hơn.
- **JSONB/semi-structured**: linh hoạt hơn EAV (không cần bảng riêng), nhưng mất khả năng ràng buộc CHECK/FK trên từng field bên trong.
- Câu hỏi đúng KHÔNG phải "chuẩn hoá hay không" mà là "đánh đổi này có xứng đáng với bài toán CỤ THỂ này không".

## Câu hỏi khởi động
> "`order_items` lưu `product_name_snapshot`, `sku_snapshot`, `price_snapshot`
> — nghĩa là LẶP LẠI dữ liệu đã có ở bảng `products`/`product_variants`. Đây
> có phải lỗi thiết kế (vi phạm 3NF) không? Vì sao có/không?"

## Gợi ý ví dụ đời thường
Hoá đơn giấy khi mua hàng ghi RÕ tên sản phẩm + giá TẠI THỜI ĐIỂM MUA, in
sẵn, không đổi được — dù cửa hàng có đổi tên sản phẩm hay giá vào ngày mai,
hoá đơn cũ vẫn phải hiển thị ĐÚNG những gì bạn đã thấy lúc mua. Nếu hoá đơn
"tham chiếu sống" tới giá hiện tại của sản phẩm, kế toán/pháp lý sẽ không
chấp nhận được.

## Demo trên lab
```sql
-- Chứng minh vì sao snapshot cần thiết: đổi giá sản phẩm SAU KHI đã có đơn hàng cũ
SELECT price_snapshot FROM order_items WHERE product_id = 1 LIMIT 1;
UPDATE products SET base_price = base_price * 2 WHERE id = 1;
-- order_items.price_snapshot của đơn CŨ có đổi theo không? Kiểm tra lại:
SELECT price_snapshot FROM order_items WHERE product_id = 1 LIMIT 1;
-- Nếu KHÔNG snapshot (chỉ JOIN sống tới products.base_price), toàn bộ đơn
-- hàng CŨ sẽ bị hiển thị SAI giá ngay khi giá sản phẩm đổi -- vi phạm tính
-- bất biến của hoá đơn.

-- So sánh 2 cách lưu thuộc tính biến thể: EAV (product_attribute_values) vs JSONB (product_variants.attribute_values)
\d product_attribute_values
SELECT * FROM product_variants LIMIT 1;
```

## Bài tập biến thể
Yêu cầu học viên tự đánh giá 2 tình huống MỚI, quyết định chuẩn hoá hay
denormalize, giải thích lý do:
1. "Bảng `blog_posts` cần hiển thị 'số lượt like' trên mọi trang danh sách
   bài viết — tính `count(*)` từ bảng `likes` mỗi lần load trang có ổn
   không, hay nên lưu 1 cột `like_count` ngay trên `blog_posts`?"
2. "Hệ thống chat cần lưu 'tên hiển thị' của người gửi tại thời điểm gửi —
   nên tham chiếu sống tới `users.display_name`, hay snapshot lại?"

## Tiêu chí teach-back
- [ ] Giải thích ĐÚNG lý do `order_items` cần snapshot (tính bất biến lịch sử), không nhầm với lý do hiệu năng.
- [ ] Ở bài tập biến thể #1, nhận ra đây là đánh đổi ĐỌC NHIỀU/GHI ÍT (denormalize `like_count` hợp lý, kèm điều kiện: phải cập nhật đúng mỗi khi like/unlike, có nguy cơ lệch nếu code cập nhật sai — tương tự race condition ở Track B Level 7).
- [ ] Ở bài tập biến thể #2, nhận ra đây LẠI là bài toán snapshot giống `order_items` (tên hiển thị lúc gửi tin nhắn phải bất biến, dù sau đó user đổi tên).

## Lỗi hiểu sai thường gặp
- Nghĩ denormalize LUÔN vì lý do "tăng tốc" — bỏ lỡ lý do QUAN TRỌNG HƠN trong nhiều case thật: tính bất biến/lịch sử.
- Denormalize "cho chắc" ở mọi nơi khi không chắc — quên rằng mỗi chỗ denormalize là 1 nơi CÓ THỂ BỊ LỆCH dữ liệu nếu code cập nhật không đồng bộ đúng.
- Nhầm EAV và JSONB là "giống nhau" — EAV vẫn là quan hệ (query bằng SQL thường, dễ ràng buộc `attribute_id` FK), JSONB là semi-structured (không FK được vào field bên trong).
