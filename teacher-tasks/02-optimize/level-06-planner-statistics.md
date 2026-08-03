# Level 6 — Planner statistics

## Mục tiêu
Học viên hiểu planner "đoán" số dòng dựa trên statistics đã lưu (không phải
đọc bảng thật mỗi lần), và biết vì sao đoán sai xảy ra — nền tảng để tự debug
khi gặp plan bất thường trong công việc thật.

## Khái niệm cốt lõi
- `pg_stats`: bảng hệ thống lưu `n_distinct`, `most_common_vals`, `most_common_freqs`, `histogram_bounds` cho mỗi cột.
- `ANALYZE`: lệnh CẬP NHẬT statistics — không tự động chạy realtime, phụ thuộc autovacuum hoặc chạy tay.
- `correlation`: dữ liệu trên đĩa có "cùng thứ tự" với giá trị cột không — ảnh hưởng cost của Index Scan (đọc tuần tự vs đọc rải rác).
- `default_statistics_target`: độ chi tiết của histogram (mặc định 100 "bucket") — có thể tăng cho cột hay bị đoán sai.

## Câu hỏi khởi động
> "Bạn vừa INSERT 500,000 dòng mới rất lệch phân bố (skewed) vào 1 bảng,
> nhưng CHƯA chạy ANALYZE. Query cũ vẫn dùng plan cũ — plan đó còn đáng tin
> không?"

## Gợi ý ví dụ đời thường
Statistics giống bản đồ dân số bạn tra cứu để ước lượng "quán này giờ này
đông không" — nếu bản đồ đó là dữ liệu từ NĂM NGOÁI mà khu vực vừa xây thêm 1
khu chung cư lớn, ước lượng của bạn sẽ sai xa thực tế cho tới khi bạn cập
nhật lại bản đồ (ANALYZE).

## Demo trên lab
```sql
SELECT attname, n_distinct, most_common_vals, histogram_bounds
FROM pg_stats WHERE tablename = 'orders' AND attname = 'order_status';

-- Gây lệch phân bố có kiểm soát rồi so sánh estimate TRƯỚC/SAU khi ANALYZE
INSERT INTO orders (order_number, customer_id, subtotal, total_amount, payment_method,
                     shipping_address_id, billing_address_id)
SELECT 'SKEW-' || gs, 1, 100000, 100000, 'COD', 1, 1
FROM generate_series(1, 50000) AS gs;

EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE customer_id = 1; -- estimate lệch xa actual
ANALYZE orders;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders WHERE customer_id = 1; -- estimate chính xác lại
```

## Bài tập biến thể
Yêu cầu học viên chọn 1 cột khác (ví dụ `category_id` trong `products`), tự
gây lệch phân bố bằng INSERT có chủ đích (ví dụ nhồi 90% dòng mới vào đúng 1
category), dự đoán estimate sẽ sai theo hướng nào trước khi ANALYZE, rồi
verify.

## Tiêu chí teach-back
- [ ] Giải thích được vì sao 2 giá trị filter khác nhau trên CÙNG 1 cột có thể ra 2 plan khác nhau (do phân bố tần suất khác nhau trong histogram/most_common_vals).
- [ ] Giải thích được `ANALYZE` khác `VACUUM` ở điểm nào (ANALYZE cập nhật statistics cho planner, VACUUM dọn dead tuple — 2 việc độc lập, `VACUUM ANALYZE` làm cả 2).
- [ ] Tự đề xuất được hành động đúng khi thấy estimate và actual rows lệch xa nhau trong 1 EXPLAIN thật.

## Lỗi hiểu sai thường gặp
- Nghĩ Postgres tự cập nhật statistics ngay sau mỗi INSERT/UPDATE (chỉ autovacuum analyze theo threshold, có độ trễ).
- Nhầm `ANALYZE` với `VACUUM ANALYZE` — nghĩ chạy 1 trong 2 là đủ cho mọi mục đích.
- Nghĩ statistics càng chi tiết (`default_statistics_target` cao) càng luôn tốt — bỏ qua chi phí ANALYZE lâu hơn + planning time tăng nhẹ.
