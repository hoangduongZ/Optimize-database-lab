# Level 10 — Capstone: tối ưu 1 query thật end-to-end

## Mục tiêu
Học viên tự chạy TOÀN BỘ quy trình (đọc EXPLAIN → chẩn đoán → chọn đúng loại
index/rewrite → verify) trên 1 bài toán nghiệp vụ phức hợp, KHÔNG có gợi ý
từng bước như các level trước — đây là bài kiểm tra tổng hợp cho cả lộ trình.

## Điều kiện vào level này
Học viên đã teach-back đạt Level 0-9. Nếu chưa, KHÔNG bắt đầu level này —
quay lại level còn thiếu.

## Đề bài gốc (giáo viên tự diễn giải, không đọc nguyên văn cho học viên)
Trang admin cần API: "Liệt kê 20 đơn hàng gần nhất đang ở trạng thái PENDING
quá 30 phút, của khách hàng đã từng mua ít nhất 1 sản phẩm thuộc category cụ
thể, kèm theo tổng số order_items của mỗi đơn" — sắp xếp theo thời gian đặt
hàng.

Đây là đề bài CÓ CHỦ ĐÍCH phức hợp — cần: partial index (Level 5) + join
nhiều bảng (Level 4) + có thể cần CTE hoặc window function (Level 9) +
statistics đúng (Level 6) để planner chọn đúng chiến lược.

## Quy trình bắt buộc học viên phải tự thực hiện (không làm hộ)
1. Học viên tự viết baseline query (chưa tối ưu).
2. Chạy `EXPLAIN (ANALYZE, BUFFERS)`, tự xác định node nào tốn nhất.
3. Học viên tự đề xuất 1 thay đổi (index hoặc viết lại query) — bạn CHỈ hỏi
   dẫn dắt ("bạn nghĩ node nào đang tốn nhất? vì sao?"), không gợi ý giải pháp.
4. Áp thay đổi, đo lại, lặp lại bước 2-3 cho tới khi học viên tự thấy đủ tốt.
5. Học viên tổng kết: giải thích TOÀN BỘ quyết định như đang thuyết trình cho
   team — từng bước đã đổi gì, vì sao, và số liệu trước/sau.

## Bài tập biến thể (đánh giá cuối)
Sau khi xong đề bài gốc, đưa 1 đề bài nghiệp vụ KHÁC tương tự độ khó (ví dụ:
"top 5 khách hàng chi tiêu nhiều nhất trong 90 ngày qua, kèm số coupon đã
dùng") mà học viên CHƯA từng thấy, yêu cầu tự áp dụng toàn bộ quy trình mà
KHÔNG có bất kỳ gợi ý nào từ bạn ngoài câu hỏi Socratic tối thiểu.

## Tiêu chí hoàn thành (đạt = coi như hoàn thành lộ trình)
- [ ] Tự đọc đúng EXPLAIN, xác định đúng node tốn nhất mà không cần trợ giúp.
- [ ] Tự chọn đúng loại index (không phải index "cho chắc" — biện luận được vì sao chọn loại này).
- [ ] Tự nhận ra khi nào cần `ANALYZE` lại, khi nào plan bất thường do statistics.
- [ ] Trình bày lại toàn bộ case như thuyết trình — mạch lạc, có số liệu trước/sau, không cần bạn nhắc từng bước.
- [ ] Với bài tập đánh giá cuối (đề bài mới), tự làm được ít nhất 80% quy trình không cần gợi ý.

## Lỗi hiểu sai cần soi lại ở level tổng hợp này
Đây là lúc phát hiện các lỗ hổng CỘNG GỘP từ các level trước còn sót lại —
nếu học viên vướng ở bước nào, quay lại ĐÚNG level tương ứng (đừng giải thích
lại từ đầu ở đây), để đảm bảo lỗ hổng được vá tại nguồn.
