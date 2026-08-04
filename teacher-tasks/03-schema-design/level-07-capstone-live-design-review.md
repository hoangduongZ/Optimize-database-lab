# Level 7 — Capstone: Live Design Review (mô phỏng đúng áp lực interview)

## Mục tiêu
Không dạy thêm khái niệm mới — mô phỏng ĐÚNG điều kiện 1 buổi interview
design thật: có time-box, phải NÓI RA THÀNH LỜI (không chỉ viết SQL âm
thầm), và bị hỏi xoáy giữa buổi (curveball) như interviewer thật hay làm.

## Điều kiện vào level này
Đã qua Level 0-6. Nếu học viên còn phải dừng lại tra cứu khái niệm cơ bản
(1NF, loại quan hệ) giữa buổi, đây là dấu hiệu quay lại level tương ứng
trước, không nên tiếp tục capstone.

## Quy trình (đúng thứ tự, có time-box)
1. **Chọn 1 đề bài học viên CHƯA từng thấy** — không dùng lại URL shortener/
   booking/social feed đã làm. Gợi ý domain mới: hệ thống đặt lịch khám bệnh,
   app chia sẻ chi phí nhóm (kiểu Splitwise), hệ thống quản lý thư viện, app
   gọi xe. Đọc đề, giống 1 câu interview thật (1-2 câu, không chi tiết).
2. **5 phút đầu**: học viên PHẢI hỏi làm rõ scope trước khi viết bất kỳ dòng
   nào — nếu hết 5 phút mà chưa hỏi gì, NHẮC (đây là tín hiệu quan trọng,
   không phải luật cứng — mục đích là hình thành phản xạ).
3. **15-20 phút**: học viên vừa thiết kế VỪA NÓI RA THÀNH LỜI lý do từng
   quyết định (không im lặng rồi đưa ra schema hoàn chỉnh cuối cùng) — đúng
   mô phỏng cách 1 buổi interview thật diễn ra.
4. **Giữa buổi, chèn 1 CURVEBALL** — 1 yêu cầu mới đột ngột (vd đang thiết kế
   hệ thống đặt lịch khám bệnh, giữa buổi thêm: "À, quên nói — 1 bác sĩ có
   thể làm ở NHIỀU phòng khám khác nhau, lịch làm việc khác nhau theo từng
   nơi"). Quan sát: học viên PATCH schema đang có, hay phải THIẾT KẾ LẠI TỪ
   ĐẦU (dấu hiệu thiết kế ban đầu quá cứng, không có "khoảng thở" cho thay
   đổi)?
5. **5 phút cuối**: học viên tự tổng kết — trade-off nào đã chọn, nếu có
   thêm thời gian sẽ cải thiện gì.

## Tiêu chí hoàn thành (đạt = sẵn sàng cho interview thật)
- [ ] Hỏi làm rõ scope TRƯỚC KHI thiết kế, không cần nhắc.
- [ ] Nói ra thành lời được lý do (không chỉ đưa ra schema câm lặng) — đây là kỹ năng KHÁC với việc thiết kế đúng, và interviewer chấm cả 2.
- [ ] Xử lý được curveball bằng cách PATCH hợp lý (thêm bảng/cột), không phải hoảng loạn viết lại từ đầu — hoặc nếu THỰC SỰ cần viết lại, giải thích được vì sao thiết kế cũ không đủ linh hoạt.
- [ ] Tự nhận ra được ít nhất 1 điểm mình sẽ làm khác nếu có thêm thời gian — tín hiệu của tư duy phản tư (self-review), thứ interviewer đánh giá cao.

## Lỗi hiểu sai cần soi lại
Nếu học viên: (a) không hỏi gì → quay lại tinh thần Level 6. (b) viết đúng
schema nhưng không giải thích được lý do khi được hỏi trực tiếp → có thể
đang follow template có sẵn mà chưa thật hiểu — quay lại Level 0-2 kiểm tra
lại phần lý luận (WHY), không chỉ phần cấu trúc (WHAT). (c) hoảng loạn/viết
lại toàn bộ khi gặp curveball → dấu hiệu cần luyện thêm phản xạ "mở rộng
thay vì đập lại" — có thể lặp lại capstone với domain khác sau vài ngày.
