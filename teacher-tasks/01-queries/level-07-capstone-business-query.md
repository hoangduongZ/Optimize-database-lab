# Level 7 — Capstone: dịch 1 yêu cầu nghiệp vụ phức hợp thành query đúng

## Mục tiêu
Học viên tự tổng hợp TOÀN BỘ kỹ năng Level 0-6 (JOIN, aggregate, subquery,
CTE, window function, set operations) để giải 1 bài toán nghiệp vụ nhiều
bước — CHỈ tập trung vào ĐÚNG, chưa cần tối ưu (đó là việc của Track B).
Đây là cầu nối: xong level này mới nên sang Track B.

## Điều kiện vào level này
Học viên đã teach-back đạt Level 0-6 của Track A. Nếu chưa, quay lại level
còn thiếu trước.

## Đề bài gốc (giáo viên tự diễn giải, không đọc nguyên văn cho học viên)
"Liệt kê top 20 khách hàng chi tiêu nhiều nhất (tổng `total_amount` của các
đơn `DELIVERED`), kèm: email, tổng số đơn DELIVERED, đơn hàng GẦN NHẤT (mã +
ngày, bất kể trạng thái gì), và đánh dấu 'VIP' nếu tổng chi tiêu > mức trung
bình của toàn bộ top 20 đó."

Đề bài này CÓ CHỦ ĐÍCH cần phối hợp: JOIN (`users`+`orders`), aggregate có
điều kiện (`SUM` chỉ tính đơn DELIVERED — dùng `CASE WHEN` bên trong
aggregate hoặc lọc riêng), window function (đơn gần nhất — top-1-per-group
từ Level 5), và 1 giá trị tổng hợp so sánh lại với từng dòng (trung bình của
top 20 — cần 1 window function KHÔNG có `PARTITION BY`, hoặc 1 CTE tính
trước).

## Quy trình bắt buộc học viên phải tự thực hiện (không làm hộ)
1. Học viên tự chia đề bài thành các "cụm nhỏ" (tổng chi tiêu theo khách,
   đơn gần nhất theo khách, so với trung bình) — bạn chỉ hỏi "bạn nghĩ có
   mấy phần trong yêu cầu này?", không tự chia hộ.
2. Học viên tự viết TỪNG cụm nhỏ thành 1 CTE riêng, tự verify từng CTE bằng
   cách `SELECT * FROM ten_cte LIMIT 10` trước khi ghép lại.
3. Ghép các CTE lại bằng JOIN, tự kiểm tra số dòng cuối cùng có hợp lý không
   (đúng 20 dòng, không bị fan-out).
4. Tổng kết: giải thích lại được TỪNG mảnh đã ghép vào query cuối cùng để
   làm gì — không có mảnh nào "copy mà không hiểu".

## Bài tập biến thể (đánh giá cuối)
Đưa 1 đề bài nghiệp vụ KHÁC, chưa từng thấy, độ khó tương đương (ví dụ: "top
10 sản phẩm có tỷ lệ review 5 sao cao nhất, tối thiểu 5 review, kèm tên
category và đánh dấu 'best_seller' nếu số lượng đã bán qua `order_items` >
trung bình toàn category") — yêu cầu tự làm không có gợi ý cấu trúc.

## Tiêu chí hoàn thành (đạt = sẵn sàng sang Track B)
- [ ] Tự chia được đề bài phức hợp thành các cụm nhỏ hơn mà không cần gợi ý.
- [ ] Viết đúng từng CTE, tự verify độc lập trước khi ghép.
- [ ] Query cuối cùng ra ĐÚNG số dòng kỳ vọng, không bị fan-out do JOIN.
- [ ] Với đề bài đánh giá cuối, tự hoàn thành được không cần gợi ý cấu trúc (có thể hỏi nghiệp vụ, không hỏi "viết thế nào").
- [ ] Tự nhận biết: query này ĐÃ ĐÚNG nhưng CHƯA BIẾT nó có nhanh hay không — đây chính là lý do cần học Track B tiếp theo.

## Lỗi hiểu sai cần soi lại ở level tổng hợp này
Nếu học viên vướng ở phần nào (aggregate có điều kiện, window function,
ghép CTE), quay lại ĐÚNG level tương ứng (Level 3 hoặc Level 5) để vá tại
nguồn — đừng giải thích lại từ đầu ở đây.
