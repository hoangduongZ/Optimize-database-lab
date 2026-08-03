# Level 7 — Concurrency & MVCC thực chiến

## Mục tiêu
Học viên tự tay tái hiện lỗi oversell kinh điển, rồi tự sửa bằng atomic
UPDATE — hiểu MVCC không tự động ngăn race condition ở tầng LOGIC nghiệp vụ,
chỉ đảm bảo tính nhất quán ở tầng READ.

## Khái niệm cốt lõi
- READ COMMITTED (mặc định của Postgres): mỗi câu lệnh trong transaction thấy dữ liệu đã commit tại THỜI ĐIỂM câu lệnh đó chạy — SELECT thường KHÔNG giữ lock.
- UPDATE tạo row lock tại dòng bị sửa — transaction khác UPDATE cùng dòng phải CHỜ.
- Khi 1 UPDATE bị block rồi được tiếp tục (sau khi transaction giữ lock COMMIT), nó RE-EVALUATE điều kiện WHERE với dữ liệu MỚI NHẤT — đây là chìa khoá của "safe reserve".
- "Check-then-act" (đọc riêng rồi tính ở app rồi ghi riêng) luôn có nguy cơ race condition — vì không có gì giữ lock giữa 2 bước đó.

## Câu hỏi khởi động
> "2 người cùng bấm 'Mua ngay' sản phẩm chỉ còn 1 cái, cách nhau 0.5 giây.
> Nếu code chỉ đơn giản là `SELECT quantity` rồi `if quantity > 0` rồi
> `UPDATE quantity = quantity - 1`, bạn nghĩ có luôn AN TOÀN không?"

## Gợi ý ví dụ đời thường
2 nhân viên bán hàng cùng xem tấm bảng "còn 1 áo" treo ở kho (SELECT không
lock), cả 2 đều thấy "còn 1", cả 2 đều báo khách "còn hàng, tôi giữ cho bạn"
— không ai biết người kia cũng đang làm y vậy, cho tới khi cả 2 cùng ra kho
lấy áo và phát hiện chỉ có 1 áo thật. Atomic UPDATE giống việc BẮT BUỘC mỗi
người phải tự cầm ổ khóa kho, ai vào trước khoá cửa, người sau phải đứng chờ
NGOÀI CỬA rồi tự nhìn lại bảng SAU KHI người trước ra — không nhìn bảng cũ.

## Demo trên lab
Chạy đúng theo kịch bản 2-terminal trong `../../04_concurrency/01_oversell_bug_manual_demo.sql`
(tái hiện bug) rồi `../../04_concurrency/02_safe_reserve_manual_demo.sql` (bản sửa đúng). Cho học
viên tự bấm Enter theo đúng thứ tự A1/B1/A2/B2 ghi trong file — đừng làm hộ,
để họ tự thấy `UPDATE 1` ở cả 2 session trong bản lỗi, và `UPDATE 0` ở session
B trong bản đã sửa.

## Bài tập biến thể
Yêu cầu học viên tự viết 1 kịch bản tương tự nhưng cho tình huống KHÁC: 2
người cùng dùng 1 coupon có `usage_limit = 1` (bảng `coupons` +
`coupon_redemptions`). Học viên phải tự xác định: atomic UPDATE ở đâu, điều
kiện WHERE nào cần thêm để tránh 2 người cùng redeem thành công.

## Tiêu chí teach-back
- [ ] Giải thích được vì sao SELECT thường không ngăn được race condition (không giữ lock).
- [ ] Giải thích được UPDATE re-evaluate WHERE sau khi có lock là điều gì cứu được bài toán oversell.
- [ ] Tự viết đúng được câu UPDATE an toàn cho bài tập coupon ở trên, không cần xem lại ví dụ inventory.

## Lỗi hiểu sai thường gặp
- Nghĩ bọc `BEGIN...COMMIT` quanh SELECT+UPDATE là đã "an toàn" (transaction boundary không tự tạo lock cho SELECT ở READ COMMITTED).
- Nhầm optimistic locking (`version` column, dùng khi ứng dụng đọc trước rồi so sánh version lúc ghi) với pessimistic locking (`SELECT ... FOR UPDATE`, giữ lock ngay từ lúc đọc) — cả 2 đều đúng tuỳ tình huống, không phải 1 đúng 1 sai.
- Nghĩ tăng isolation level lên `SERIALIZABLE` là cách sửa "dễ nhất" mà không cần đổi code — thực tế `SERIALIZABLE` yêu cầu code phải retry khi gặp serialization failure, phức tạp hơn atomic UPDATE cho bài toán đơn giản này.
