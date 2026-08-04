# Level 3 — Thiết kế index/constraint đi CÙNG schema, không phải thêm sau

## Mục tiêu
Học viên tập thói quen nghĩ về constraint (ràng buộc TOÀN VẸN dữ liệu) và
index NGAY khi thiết kế bảng — không phải "tạo bảng trước, tối ưu sau" (đó
là tư duy của Track B, ở ĐÂY là tư duy lúc THIẾT KẾ ban đầu).

## Khái niệm cốt lõi
- **Constraint bảo vệ TÍNH ĐÚNG, index bảo vệ TỐC ĐỘ** — 2 mục tiêu khác nhau, dễ nhầm là "cùng 1 việc".
- `UNIQUE` constraint: ràng buộc nghiệp vụ ("email không trùng"), KHÔNG PHẢI chỉ để tăng tốc tra cứu (tăng tốc là tác dụng PHỤ, không phải mục đích chính).
- `CHECK` constraint: ràng buộc miền giá trị NGAY TẦNG DATABASE (vd `rating BETWEEN 1 AND 5`) — không dựa hoàn toàn vào validate ở tầng application (app có thể có bug, DB là lớp bảo vệ cuối).
- `NOT NULL` PHẢI được quyết định khi thiết kế, dựa trên NGHĨA nghiệp vụ ("cột này có BẮT BUỘC luôn có giá trị không"), không phải quyết định tuỳ hứng.
- FK không tự có index (Postgres) — nhưng đây là quyết định ở Track B; ở Track NÀY, câu hỏi ĐÚNG là: "cột này có chắc sẽ bị JOIN/filter thường xuyên không" — quyết định TỪ LÚC THIẾT KẾ, không phải chờ users complain đã chậm.

## Câu hỏi khởi động
> "Thiết kế bảng `reviews (product_id, user_id, rating, ...)` — bạn có nên
> thêm `UNIQUE (product_id, user_id)` không? Đây là quyết định về TỐC ĐỘ hay
> về TÍNH ĐÚNG nghiệp vụ?"

## Gợi ý ví dụ đời thường
Constraint giống LUẬT ("mỗi người chỉ được review 1 sản phẩm 1 lần") — luật
này ĐÚNG bất kể hệ thống có 10 hay 10 triệu review. Index giống XA LỘ thêm
để đi nhanh — không có xa lộ vẫn tới được, chỉ chậm hơn. Thiết kế thiếu luật
(constraint) gây ra DỮ LIỆU SAI. Thiết kế thiếu xa lộ (index) chỉ gây CHẬM,
sửa sau vẫn được, không mất dữ liệu.

## Demo trên lab
```sql
-- Chứng minh CHECK constraint bảo vệ tại tầng DB, dù app có bug
INSERT INTO reviews (product_id, user_id, rating) VALUES (1, 1, 99);
-- Postgres tự chặn: ERROR - violates check constraint "reviews_rating_check"
-- Nếu KHÔNG có CHECK này, 1 bug ở tầng app (quên validate) sẽ ghi được rating=99 vào DB.

-- Soi lại 1 quyết định NOT NULL thật trong schema: vì sao order_items.variant_id
-- được phép NULL nhưng order_items.product_id thì KHÔNG?
\d order_items
```

## Bài tập biến thể
Thiết kế bảng `event_registrations (event_id, user_id, registered_at,
status)` cho 1 hệ thống đăng ký sự kiện — yêu cầu học viên tự quyết định VÀ
GIẢI THÍCH:
1. Ràng buộc UNIQUE nào cần có (gợi ý nghĩ: 1 user đăng ký 1 event được mấy lần?).
2. `status` nên NOT NULL hay nullable, có cần CHECK giới hạn giá trị không?
3. Cột nào SẼ chắc chắn bị filter/join thường xuyên (dù CHƯA đo hiệu năng thật) — ghi chú lại để Track B xử lý sau, KHÔNG tự tạo index vội ở bước thiết kế này nếu chưa chắc.

## Tiêu chí teach-back
- [ ] Phân biệt rõ ràng: quyết định nào ở bài tập biến thể là "bảo vệ tính đúng" (BẮT BUỘC nghĩ ngay), quyết định nào là "tối ưu tốc độ" (CÓ THỂ để Track B xử lý sau).
- [ ] Tự viết đúng CHECK constraint hợp lý cho `status`, giải thích được vì sao đặt ở tầng DB không chỉ ở app.
- [ ] Giải thích được vì sao KHÔNG nên vội tạo index "cho chắc" ngay ở bước thiết kế khi chưa biết access pattern thật.

## Lỗi hiểu sai thường gặp
- Nhầm UNIQUE constraint là "chỉ để tăng tốc" — quên rằng mục đích CHÍNH là ràng buộc nghiệp vụ, dù nó có tạo index kèm theo.
- Nghĩ validate ở tầng application (code) là ĐỦ, không cần CHECK/NOT NULL ở DB — bỏ qua rủi ro bug code, multiple services cùng viết vào 1 DB không qua chung 1 tầng validate.
- Tạo index "phòng trước" cho MỌI cột ngay lúc thiết kế — trái với nguyên tắc Track B (chỉ index cột thực sự cần, dựa trên access pattern THẬT, không phải suy đoán).
