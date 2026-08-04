# Level 1 — Khoá & quan hệ (1-1, 1-n, n-n)

## Mục tiêu
Học viên nhận diện đúng LOẠI quan hệ giữa 2 thực thể trước khi vẽ bảng — lỗi
mô hình hoá quan hệ sai là nguyên nhân số 1 khiến schema phải sửa lại sau
này (không phải lỗi cú pháp SQL).

## Khái niệm cốt lõi
- **1-1**: 1 dòng bảng A khớp ĐÚNG 1 dòng bảng B (vd `users` — `user_profiles`). Thường tách bảng riêng khi: nhóm cột ít dùng, hoặc access pattern khác nhau (bảo mật, tần suất đọc/ghi khác).
- **1-n**: 1 dòng bảng A khớp NHIỀU dòng bảng B, nhưng ngược lại chỉ 1 (vd `categories` — `products`). FK đặt ở bảng "nhiều" (`products.category_id`).
- **n-n**: nhiều dòng A khớp nhiều dòng B — CẦN 1 bảng trung gian (junction table) chứa 2 FK (vd `attribute_templates` — `attribute_definitions` qua `template_attributes`).
- **Self-reference**: bảng tự tham chiếu chính nó (vd `categories.parent_id`) — biểu diễn cây/phân cấp.
- Chọn SAI loại quan hệ ban đầu (vd tưởng 1-n nhưng thực ra n-n) buộc phải MIGRATE schema sau này — tốn chi phí lớn hơn nhiều so với việc hỏi kỹ ngay từ đầu.

## Câu hỏi khởi động
> "1 đơn hàng có thể áp dụng NHIỀU coupon không, và 1 coupon có thể dùng cho
> NHIỀU đơn hàng của NHIỀU khách khác nhau không? Đây là quan hệ 1-n hay n-n?"

## Gợi ý ví dụ đời thường
1-n giống 1 giáo viên chủ nhiệm — nhiều học sinh (n) chỉ có ĐÚNG 1 giáo viên
chủ nhiệm (1). n-n giống sinh viên và môn học — 1 sinh viên học nhiều môn,
1 môn có nhiều sinh viên — không thể nhồi "mã môn" vào 1 cột của bảng sinh
viên, PHẢI có 1 bảng riêng ghi "sinh viên nào học môn nào".

## Demo trên lab
Soi lại đúng schema thật đã dùng suốt các track trước — chỉ ra loại quan hệ
của TỪNG cặp bảng:
```sql
-- 1-n: 1 category có nhiều product, product chỉ thuộc 1 category
\d products   -- category_id là FK trỏ 1 chiều

-- n-n qua junction table: 1 promotion áp dụng nhiều product, 1 product có
-- thể trong nhiều promotion khác nhau
\d promotion_products   -- 2 FK: promotion_id + product_id

-- self-reference: categories cha-con
\d categories   -- parent_id trỏ lại chính bảng categories
```

## Bài tập biến thể
Cho 4 cặp thực thể MỚI (không có trong schema lab), yêu cầu học viên xác
định đúng loại quan hệ và vẽ ra (bằng text) cấu trúc bảng cần thiết:
1. "Bác sĩ" — "Bệnh nhân" (qua các buổi khám — 1 bác sĩ khám nhiều bệnh nhân,
   1 bệnh nhân có thể khám nhiều bác sĩ khác nhau theo thời gian).
2. "Tài xế" — "Xe" (tại 1 thời điểm).
3. "Bài viết" — "Hashtag".
4. "Người dùng" — "Người dùng" (quan hệ follow trên mạng xã hội — chú ý: quan hệ này có ĐỐI XỨNG không?).

## Tiêu chí teach-back
- [ ] Xác định đúng cả 4 loại quan hệ ở bài tập biến thể, giải thích được VÌ SAO (không chỉ đoán đúng).
- [ ] Tự nhận ra case #1 (bác sĩ-bệnh nhân) thực chất là quan hệ n-n THEO THỜI GIAN — cần bảng trung gian có thêm cột `thời điểm khám`, không chỉ 2 FK đơn giản.
- [ ] Tự nhận ra case #4 (follow) là self-reference n-n KHÔNG đối xứng (A follow B không có nghĩa B follow A) — khác với "bạn bè" (đối xứng).

## Lỗi hiểu sai thường gặp
- Mặc định mọi quan hệ là 1-n vì đó là trường hợp dễ nghĩ nhất — không tự hỏi "ngược lại thì sao?" trước khi kết luận.
- Với n-n, quên rằng bảng trung gian có thể cần thêm CỘT RIÊNG của chính nó (không chỉ 2 FK) — vd `template_attributes.sort_order`, hoặc case "bác sĩ khám bệnh nhân" cần cột thời điểm.
- Nhầm self-reference với việc phải tạo 2 bảng riêng (self-reference chỉ cần 1 bảng, 1 cột FK trỏ về chính bảng đó).
