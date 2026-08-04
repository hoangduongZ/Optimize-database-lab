# Level 4 — Design Challenge: URL Shortener

## Mục tiêu
Design challenge ĐẦU TIÊN, phạm vi nhỏ, có lời giải tương đối rõ ràng — làm
quen với QUY TRÌNH (không phải kết quả) trước khi vào challenge mơ hồ hơn.

## Đề bài (đọc cho học viên, giọng điệu đề interview thật)
> "Thiết kế database cho 1 dịch vụ rút gọn URL (giống bit.ly). Người dùng
> nhập 1 URL dài, hệ thống trả về 1 URL ngắn. Khi ai đó truy cập URL ngắn,
> hệ thống redirect tới URL gốc. Cần theo dõi được URL nào được click bao
> nhiều lần."

## Quy trình thực hiện (bắt buộc theo thứ tự — đúng thứ tự 1 buổi interview thật)
1. Liệt kê ENTITY chính trước (chưa vội viết cột).
2. Xác định quan hệ giữa các entity.
3. Với MỖI entity, hỏi: cột nào NOT NULL, cột nào cần UNIQUE.
4. Viết DDL.
5. Tự review: có chỗ nào nên denormalize không (liên hệ Level 2)? Có access pattern nào ĐÃ BIẾT TRƯỚC sẽ cần tối ưu không (ghi chú lại cho Track B, không tự tối ưu vội)?

## Câu hỏi làm rõ gợi ý (nếu học viên hỏi — nếu KHÔNG hỏi gì, đây là dấu hiệu cần nhắc nhẹ)
- Có cần cho phép user chọn "custom alias" (vd `bit.ly/my-brand`) không, hay chỉ auto-generate?
- URL có hết hạn không?
- Click cần track chi tiết (thời điểm, referrer, IP) hay chỉ cần TỔNG số lượt?
- Có cần hệ thống user/tài khoản không, hay ai cũng tạo được URL ẩn danh?

---
## [Tham khảo — chỉ xem SAU khi tự làm xong]

### Schema tham khảo (1 trong nhiều cách đúng)
```sql
CREATE TABLE users (
    id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE short_urls (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    short_code    VARCHAR(20) NOT NULL UNIQUE,
    original_url  TEXT NOT NULL,
    created_by    BIGINT REFERENCES users(id),  -- nullable: cho phép tạo ẩn danh
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at    TIMESTAMPTZ,                  -- nullable: không phải URL nào cũng hết hạn
    click_count   BIGINT NOT NULL DEFAULT 0      -- denormalize có chủ đích, xem bên dưới
);

-- Click chi tiết tách bảng riêng: ghi rất nhiều (mỗi lượt truy cập), đọc
-- theo pattern khác hẳn short_urls (append-only, gần như không UPDATE).
CREATE TABLE click_events (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    short_url_id BIGINT NOT NULL REFERENCES short_urls(id),
    clicked_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    referrer     TEXT,
    ip_hash      VARCHAR(64)   -- hash, không lưu IP thô (privacy)
);
```

### Điểm mạnh cần có (chấm nếu học viên tự đề xuất)
- **`click_count` denormalize có chủ đích**: nếu chỉ cần hiển thị TỔNG số click ở trang danh sách URL, `count(*) FROM click_events` mỗi lần load trang rất tốn khi data lớn — đúng đánh đổi Level 2 (đọc nhiều, tăng dần bằng 1 câu UPDATE riêng khi có click mới, không tính lại từ đầu).
- **Tách `click_events` khỏi `short_urls`**: khác access pattern (ghi liên tục, gần như không sửa) — tương tự lý do tách `stock_movements` khỏi `inventory_items` trong schema chính của lab.
- **`expires_at` nullable + gợi ý job dọn URL hết hạn**: liên hệ đúng Track B Level 5 (partial index `WHERE expires_at IS NOT NULL AND expires_at < now()`).
- **`short_code` UNIQUE, xử lý va chạm ở tầng ứng dụng**: sinh code ngẫu nhiên, catch lỗi unique violation, retry — KHÔNG cần transaction phức tạp vì đây không phải race condition kiểu "đếm số lượng" (không có khái niệm "hết code").

### Câu hỏi mở rộng interviewer thường hỏi tiếp
- "Nếu 1 URL được click 1 triệu lần/giây (viral), thiết kế này có vấn đề gì?" (gợi hướng: `UPDATE click_count` liên tục trên 1 dòng là hot row, cân nhắc queue/batch update — liên hệ Track B Level 8 vacuum/bloat).
- "Làm sao đảm bảo `short_code` sinh ra không trùng mà không cần retry loop?" (gợi hướng: base62 encode từ chính `id` tăng dần, thay vì random).

### Lỗi thường gặp
- Bỏ qua `click_events`, chỉ có `click_count` — mất khả năng phân tích chi tiết (theo thời gian, theo referrer) sau này, dù ĐỦ cho yêu cầu "tổng số lượt" ban đầu — cần hỏi rõ yêu cầu TRƯỚC khi bỏ qua.
- Không hỏi về "custom alias" rồi thiết kế `short_code` không đủ linh hoạt (vd giới hạn độ dài quá ngắn để chứa alias tuỳ ý).
