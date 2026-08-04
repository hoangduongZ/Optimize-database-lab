# Level 5 — Design Challenge: Hệ thống đặt phòng (Booking)

## Mục tiêu
Design challenge có 1 bài toán RACE CONDITION kiểu mới (không phải "trừ số
lượng" như Track B Level 7, mà là "chặn 2 khoảng NGÀY chồng nhau") — buộc
học viên tổng hợp cả tư duy schema VÀ tư duy concurrency.

## Đề bài
> "Thiết kế database cho hệ thống đặt phòng khách sạn. Mỗi phòng có giá theo
> đêm. Khách chọn ngày check-in/check-out để đặt. Ràng buộc quan trọng nhất:
> KHÔNG được có 2 booking khác nhau cùng phòng mà khoảng ngày bị TRÙNG
> (overlap), kể cả khi 2 khách đặt gần như đồng thời."

## Quy trình thực hiện
1. Entity + quan hệ trước.
2. Thiết kế cột, đặc biệt: `check_in`/`check_out` kiểu dữ liệu gì, ràng buộc gì cho hợp lý (`check_out > check_in`)?
3. **Trọng tâm bài này**: ràng buộc "không chồng khoảng ngày" — nghĩ trước: đây là việc CODE tự kiểm tra (SELECT rồi check), hay có cách để DATABASE tự đảm bảo?
4. Viết DDL + thử nghĩ cách TEST ràng buộc đó (2 request đặt phòng cùng lúc, cùng phòng, ngày chồng nhau).

## Câu hỏi làm rõ gợi ý
- Có cho phép "đặt tạm giữ chỗ" (hold) trước khi thanh toán không, hay đặt là chốt luôn?
- Huỷ booking thì phòng có mở lại ngay cho ngày đó không?

---
## [Tham khảo — chỉ xem SAU khi tự làm xong]

### Schema tham khảo — cách 1: dùng Postgres range type + EXCLUDE constraint
```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;  -- cần cho EXCLUDE với cột bigint thường

CREATE TABLE rooms (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_number     VARCHAR(20) NOT NULL UNIQUE,
    price_per_night NUMERIC(10, 2) NOT NULL
);

CREATE TABLE bookings (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    room_id      BIGINT NOT NULL REFERENCES rooms(id),
    guest_email  VARCHAR(255) NOT NULL,
    check_in     DATE NOT NULL,
    check_out    DATE NOT NULL,
    status       VARCHAR(20) NOT NULL DEFAULT 'CONFIRMED'
                 CHECK (status IN ('CONFIRMED', 'CANCELLED')),
    stay_range   daterange GENERATED ALWAYS AS (daterange(check_in, check_out)) STORED,
    CHECK (check_out > check_in),
    -- Chặn overlap NGAY TẦNG DATABASE, chỉ áp dụng cho booking còn CONFIRMED
    -- (booking đã CANCELLED không tính là chiếm phòng nữa).
    EXCLUDE USING gist (room_id WITH =, stay_range WITH &&) WHERE (status = 'CONFIRMED')
);
```
`EXCLUDE USING gist` là ràng buộc Postgres CHUYÊN DÙNG cho bài toán "không
cho 2 dòng có [khoá] giống nhau VÀ [range] chồng nhau" — atomic, đúng ngay cả
khi 2 transaction insert gần như đồng thời (Postgres tự dùng GiST index để
phát hiện chồng chéo và reject 1 trong 2, không cần code tự SELECT-check).

### Cách 2 (nếu học viên chưa biết EXCLUDE constraint — vẫn chấp nhận, kèm điều kiện)
Check overlap bằng điều kiện thường + transaction có lock:
```sql
BEGIN;
SELECT 1 FROM bookings
WHERE room_id = :room_id AND status = 'CONFIRMED'
  AND NOT (check_out <= :new_check_in OR check_in >= :new_check_out)
FOR UPDATE;  -- lock các dòng liên quan, chặn transaction khác insert chồng lên
-- nếu không có dòng nào trả về -> an toàn để INSERT booking mới
INSERT INTO bookings (...) VALUES (...);
COMMIT;
```
Chấp nhận cách này NẾU học viên giải thích được vì sao cần `FOR UPDATE`
hoặc mức isolation cao hơn — KHÔNG chấp nhận nếu chỉ "SELECT rồi INSERT"
không có gì khoá giữa 2 bước (đúng lỗi check-then-act ở Track B Level 7 /
ticket ECM-303, giờ áp dụng cho date range thay vì số lượng).

### Câu hỏi mở rộng interviewer thường hỏi tiếp
- "Nếu khách sạn có 500 phòng cùng loại, không quan tâm phòng CỤ THỂ nào, chỉ cần 'còn phòng loại X trống ngày Y' — thiết kế có cần đổi không?" (gợi hướng: tách khái niệm "loại phòng" và "phòng cụ thể", có thể cần bảng inventory theo ngày kiểu khác hẳn).
- "Muốn cho giữ chỗ (hold) 15 phút rồi tự hết hạn nếu không thanh toán — thiết kế thêm gì?" (liên hệ trực tiếp Track B Level 7/8: cần cột hết hạn + job quét, giống luồng reserve/release tồn kho).

### Lỗi thường gặp
- Chỉ thêm `CHECK (check_out > check_in)` mà KHÔNG có gì chặn overlap giữa các booking khác nhau — đây là thiếu SÓT LỚN NHẤT, vì đề bài nói rõ đây là ràng buộc "quan trọng nhất".
- Nếu chọn cách 2 (check bằng code), quên `FOR UPDATE`/transaction phù hợp — lặp lại đúng lỗi oversell đã học, chỉ đổi ngữ cảnh.
