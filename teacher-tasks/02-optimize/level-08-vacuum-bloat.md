# Level 8 — VACUUM & bloat

## Mục tiêu
Học viên nối lại được Level 0 (dead tuple sinh ra từ UPDATE) với hậu quả thực
tế: bảng phình to (bloat), Index Only Scan chậm lại, và vai trò của VACUUM.

## Khái niệm cốt lõi
- Dead tuple không biến mất ngay — tồn tại cho tới khi KHÔNG còn transaction nào (đang chạy) có thể cần thấy nó, rồi VACUUM mới đánh dấu "có thể ghi đè".
- **Visibility map**: bản đồ đánh dấu page nào "all-visible" (mọi tuple trong page đều visible với mọi transaction) — Index Only Scan chỉ tránh được việc đọc heap khi page đã all-visible.
- **Bloat**: bảng/index phình to vì nhiều dead tuple chưa được dọn/tái sử dụng.
- `autovacuum` chạy tự động theo threshold (% dòng thay đổi) — có thể "theo không kịp" trên bảng ghi liên tục tần suất cao (hot table).
- `VACUUM` (thường) đánh dấu chỗ trống để TÁI SỬ DỤNG (không trả lại OS); `VACUUM FULL` viết lại toàn bộ bảng để trả dung lượng thật cho OS — nhưng khoá bảng (ACCESS EXCLUSIVE), không nên chạy tuỳ tiện trên production.

## Câu hỏi khởi động
> "Bạn chạy `DELETE FROM stock_movements WHERE created_at < '2020-01-01'` xoá
> 1 triệu dòng. Dung lượng đĩa của bảng đó có giảm ngay sau khi DELETE xong
> không?"

## Gợi ý ví dụ đời thường
Dead tuple giống ghế trống trong rạp chiếu phim sau khi khách đã ra về —
ghế không "biến mất", chỉ là có thể dùng lại cho buổi chiếu SAU. Nhân viên dọn
dẹp (VACUUM) phải đi kiểm tra và đánh dấu "ghế này trống, có thể xếp khách
mới" — nếu nhân viên dọn dẹp không đến kịp (autovacuum theo không kịp), ghế
trống cứ tăng dần mà rạp vẫn phải "xây thêm phòng mới" (bloat) vì tưởng hết
chỗ.

## Demo trên lab
Dùng đúng `../../03_exercises/10_index_only_scan_and_vacuum.sql`. Bổ sung góc nhìn
"bloat" bằng cách đo kích thước bảng trước/sau:
```sql
SELECT pg_size_pretty(pg_total_relation_size('inventory_items'));

UPDATE inventory_items SET version = version + 1; -- update toàn bảng, tạo 200,000 dead tuple

SELECT pg_size_pretty(pg_total_relation_size('inventory_items')); -- to hơn
SELECT n_live_tup, n_dead_tup FROM pg_stat_user_tables WHERE relname = 'inventory_items';

VACUUM inventory_items;
SELECT n_live_tup, n_dead_tup FROM pg_stat_user_tables WHERE relname = 'inventory_items';
SELECT pg_size_pretty(pg_total_relation_size('inventory_items')); -- KHÔNG nhỏ lại (VACUUM thường không trả dung lượng cho OS)
```

## Bài tập biến thể
Yêu cầu học viên tự làm tương tự trên bảng `order_items` (UPDATE toàn bảng 1
cột không quan trọng để tạo dead tuple có kiểm soát), tự đọc `n_dead_tup`
trước/sau VACUUM, và tự trả lời: "Nếu muốn dung lượng đĩa giảm THẬT, phải
dùng lệnh gì, và cái giá phải trả là gì?"

## Tiêu chí teach-back
- [ ] Giải thích được vì sao DELETE/UPDATE không giảm dung lượng đĩa ngay lập tức.
- [ ] Giải thích được sự khác biệt `VACUUM` và `VACUUM FULL` — cả về hiệu quả và cái giá phải trả (lock).
- [ ] Nối lại được với Level 5: giải thích vì sao Index Only Scan cần visibility map, không chỉ cần "index có đủ cột".

## Lỗi hiểu sai thường gặp
- Nghĩ VACUUM xoá dữ liệu người dùng (VACUUM chỉ dọn dead tuple — bản đã "chết" theo MVCC, không đụng tới dữ liệu sống).
- Nghĩ DELETE/UPDATE giải phóng dung lượng đĩa ngay lập tức.
- Nghĩ autovacuum luôn đủ nhanh cho mọi bảng — không biết rằng bảng ghi liên tục tần suất rất cao có thể cần tinh chỉnh riêng (`autovacuum_vacuum_scale_factor` thấp hơn cho bảng đó).
