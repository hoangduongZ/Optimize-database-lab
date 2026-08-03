# Level 2 — Đọc EXPLAIN

## Mục tiêu
Học viên đọc được output `EXPLAIN (ANALYZE, BUFFERS)` một cách chính xác —
kỹ năng nền cho TẤT CẢ level sau. Đây là level quan trọng nhất trong lộ trình.

## Khái niệm cốt lõi
- `cost=0.42..8.44` — đơn vị TƯƠNG ĐỐI (arbitrary units), không phải milliseconds. Số đầu = startup cost, số sau = total cost.
- `rows=N` trong cost là ƯỚC LƯỢNG (estimate) của planner — khác với `rows=M` trong `actual time=... rows=M` (số THẬT sau khi chạy).
- Đọc plan tree: node CON chạy trước, kết quả "chảy" lên node CHA — nên đọc từ trong/dưới ra ngoài/trên.
- `Buffers: shared hit=X read=Y` — `hit` = đọc từ cache (RAM), `read` = đọc thật từ đĩa.

## Câu hỏi khởi động
> "Trong `cost=0.42..8.44 rows=1 width=47`, con số `8.44` có đơn vị là gì —
> milliseconds, số trang đĩa, hay thứ gì khác?"

## Gợi ý ví dụ đời thường
Cost giống "độ khó ước lượng" của Google Maps trước khi bạn chạy xe — nó dựa
trên khoảng cách + loại đường (ước lượng), không phải đồng hồ bấm giờ thật.
`actual time` mới là đồng hồ bấm giờ thật sau khi bạn ĐÃ đi xong.

## Demo trên lab
Dùng nguyên `../../03_exercises/09_explain_analyze_practice.sql` — chạy từng câu hỏi
Q1-Q4 trong đó, để học viên tự trả lời trước khi bạn xác nhận.

Bổ sung minh hoạ buffers cache hit vs read:
```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM products WHERE category_id = 25;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM products WHERE category_id = 25; -- chạy lại lần 2
```

## Bài tập biến thể
Đưa học viên 1 câu query MỚI (khác với 09_explain_analyze_practice.sql, ví dụ
lọc theo `brand_id` hoặc join `orders`+`order_items`), yêu cầu họ ĐOÁN trước:
(a) Seq Scan hay Index Scan, (b) rows estimate có gần đúng thực tế không — rồi
mới chạy để verify.

## Tiêu chí teach-back
- [ ] Giải thích đúng cost là gì (đơn vị tương đối, không phải thời gian).
- [ ] Đọc plan tree đúng thứ tự (node trong cùng chạy trước).
- [ ] Giải thích được sự khác biệt `shared hit` và `shared read`, vì sao chạy lại query lần 2 thường nhanh hơn.
- [ ] Tự chỉ ra được 1 chỗ estimate rows và actual rows lệch nhau trong ví dụ của chính họ, và giải thích khả năng vì sao (thường do statistics chưa cập nhật — link sang Level 6).

## Lỗi hiểu sai thường gặp
- Coi cost = thời gian thực thi (mili giây).
- Đọc plan tree từ trên xuống dưới theo thứ tự xuất hiện trong output (thực ra phải đọc ngược, từ node lá).
- Nghĩ `Buffers: read` luôn nghĩa là "chậm" — trên SSD hiện đại, chênh lệch hit/read nhỏ hơn nhiều so với ổ cứng cơ, nhưng vẫn có ý nghĩa quan trọng khi so sánh 2 plan.
