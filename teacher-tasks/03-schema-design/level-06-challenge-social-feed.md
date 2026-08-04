# Level 6 — Design Challenge: Social Feed (đề bài mơ hồ có chủ đích)

## Mục tiêu
Khác 2 challenge trước — đề bài này CỐ Ý thiếu chi tiết, giống thật khi 1
interviewer đưa đề mở để xem candidate có hỏi đúng câu hỏi trước khi thiết
kế không, hơn là để kiểm tra kiến thức thuần.

## Đề bài (đọc ĐÚNG NHƯ VẦY, không thêm chi tiết)
> "Thiết kế database cho 1 tính năng social feed — kiểu người dùng đăng bài,
> người khác xem, like, comment."

Đúng vậy — hết. **Không tự suy diễn phạm vi.** Việc đầu tiên là hỏi lại,
giống ticket ECM-309 ở `leader-tasks/`.

## Câu hỏi làm rõ gợi ý cho AI khi đóng vai trả lời (KHÔNG đọc cho học viên — dùng để ỨNG BIẾN khi bị hỏi)
- Nếu hỏi "bài viết chỉ có text hay có ảnh/video?" → "Có ảnh, video để sau."
- Nếu hỏi "feed hiển thị theo thứ tự gì — mới nhất, hay có thuật toán ranking?" → "Mới nhất trước, thuật toán để sau — đơn giản hoá cho bài này."
- Nếu hỏi "comment có reply lồng nhau (nested) không?" → "Có, tối đa 1 cấp reply (không lồng vô hạn)."
- Nếu hỏi "like có cho unlike không, hay chỉ tăng?" → "Có unlike."
- Nếu hỏi "feed của user gồm bài của AI VIẾT, hay bài của người AI FOLLOW?" → (đây là câu hỏi QUAN TRỌNG NHẤT, nếu học viên tự hỏi, khen ngay) "Bài của người mình follow — đúng là social feed thật."
- Nếu học viên hỏi về follow (n-n self-reference, giống Level 1 bài tập) → xác nhận đúng, follow không đối xứng.
- Nếu học viên KHÔNG hỏi gì về quy mô (feed 1000 user khác feed 100 triệu user) → chủ động gợi "bạn nghĩ thiết kế này có khác gì nếu app có 1 triệu user không?" (không bắt buộc trả lời sâu ở track này — đó là chủ đề Track B/hệ thống phân tán, chỉ cần học viên Ý THỨC được câu hỏi này tồn tại).

---
## [Tham khảo — chỉ xem SAU khi tự làm xong]

### Schema tham khảo (sau khi đã làm rõ scope như trên)
```sql
CREATE TABLE users (
    id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL
);

-- n-n self-reference, KHÔNG đối xứng (giống Level 1 bài tập follow)
CREATE TABLE follows (
    follower_id BIGINT NOT NULL REFERENCES users(id),
    followee_id BIGINT NOT NULL REFERENCES users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (follower_id, followee_id),
    CHECK (follower_id <> followee_id)  -- không tự follow chính mình
);

CREATE TABLE posts (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    author_id  BIGINT NOT NULL REFERENCES users(id),
    content    TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    like_count BIGINT NOT NULL DEFAULT 0  -- denormalize có chủ đích (Level 2)
);

CREATE TABLE likes (
    post_id    BIGINT NOT NULL REFERENCES posts(id),
    user_id    BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (post_id, user_id)  -- 1 user chỉ like 1 lần / post -> "unlike" = DELETE dòng này
);

-- Comment tối đa 1 cấp reply: parent_comment_id self-reference NHƯNG chỉ cho phép sâu 1 cấp
-- (ràng buộc "không lồng quá 1 cấp" khó thể hiện bằng CHECK constraint đơn giản
-- -- thường xử lý ở tầng application; ghi chú lại đây là 1 hạn chế thật của SQL).
CREATE TABLE comments (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id           BIGINT NOT NULL REFERENCES posts(id),
    author_id         BIGINT NOT NULL REFERENCES users(id),
    parent_comment_id BIGINT REFERENCES comments(id),
    content           TEXT NOT NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### Điểm mạnh cần có
- Đã HỎI trước khi thiết kế `feed` — nhận ra feed KHÔNG PHẢI 1 bảng riêng, mà là 1 QUERY (join `follows` + `posts`, sắp theo `created_at`) — nhiều học viên nhầm tưởng cần 1 bảng `feed_items` ngay từ đầu.
- Nhận ra `likes` dùng composite PK `(post_id, user_id)` vừa đóng vai trò UNIQUE constraint (1 user 1 like/post) vừa là cách tự nhiên biểu diễn quan hệ n-n.
- Chủ động NHẬN RA (không cần giải quyết) rằng feed kiểu "JOIN follows realtime" sẽ chậm khi user follow rất nhiều người hoặc app có nhiều user — đây chính là bài toán thật các hệ thống lớn giải bằng "feed fan-out" (denormalize feed_items lúc post, không tính lúc đọc) — KHÔNG cần implement ở track này, chỉ cần Ý THỨC được đánh đổi.

### Câu hỏi mở rộng interviewer thường hỏi tiếp
- "Feed hiện tại JOIN sống mỗi lần load — nếu 1 user follow 10,000 người, query này sẽ thế nào?" (liên hệ Track B: cần EXPLAIN thật để trả lời, không suy đoán).
- "Muốn thêm 'repost' (chia sẻ lại bài của người khác) — sửa schema thế nào?"

### Lỗi thường gặp
- BẮT ĐẦU VIẾT SCHEMA NGAY mà không hỏi gì — dấu hiệu quan trọng nhất cần feedback, độc lập với việc schema cuối cùng có "đúng" hay không.
- Tạo bảng `feeds`/`feed_items` NGAY TỪ ĐẦU khi chưa có lý do (chưa biết app quy mô bao lớn) — nhồi tối ưu sớm (premature optimization) vào bước thiết kế.
