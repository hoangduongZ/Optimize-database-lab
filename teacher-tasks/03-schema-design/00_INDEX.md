# Track C — Schema Design (từ yêu cầu → schema, không phải ngược lại)

> Track A và B đều xuất phát từ 1 schema CÓ SẴN (schema e-commerce của lab).
> Track này NGƯỢC LẠI: xuất phát từ 1 yêu cầu nghiệp vụ CHƯA CÓ GÌ, tự thiết
> kế schema — đúng dạng câu hỏi "design database cho hệ thống X" rất hay gặp
> khi interview. Tổng quan: [`../00_INDEX.md`](../00_INDEX.md).

Level 0-3: khái niệm nền (normalization, khoá, quan hệ, đánh đổi
denormalize) — DÙNG LẠI schema e-commerce đã quen để học khái niệm trước khi
áp dụng vào cái mới. Level 4-7: design challenge với domain HOÀN TOÀN MỚI
(không phải e-commerce) — đúng tinh thần "chưa từng thấy đề này".

## Theo dõi tiến độ

- [ ] Level 0 — [Normalization cơ bản (1NF/2NF/3NF)](level-00-normalization-basics.md)
- [ ] Level 1 — [Khoá & quan hệ (1-1, 1-n, n-n)](level-01-keys-and-relationships.md)
- [ ] Level 2 — [Khi nào KHÔNG chuẩn hoá (denormalization trade-offs)](level-02-denormalization-tradeoffs.md)
- [ ] Level 3 — [Thiết kế index/constraint đi cùng schema](level-03-index-constraint-design.md)
- [ ] Level 4 — [Design Challenge: URL Shortener](level-04-challenge-url-shortener.md)
- [ ] Level 5 — [Design Challenge: Hệ thống đặt phòng (Booking)](level-05-challenge-booking-system.md)
- [ ] Level 6 — [Design Challenge: Social feed (mơ hồ, tự hỏi lại scope)](level-06-challenge-social-feed.md)
- [ ] Level 7 — [Capstone: Live design review (mô phỏng đúng áp lực interview)](level-07-capstone-live-design-review.md)

## Khác biệt với Track A/B khi chấm

Không có "SOLUTION" đúng-sai tuyệt đối như Track A/B — schema design luôn có
NHIỀU cách đúng, khác nhau về đánh đổi. Tiêu chí teach-back ở đây tập trung
vào: có XÁC ĐỊNH ĐÚNG các quan hệ/ràng buộc quan trọng không, có GIẢI THÍCH
ĐƯỢC đánh đổi đã chọn không — không phải "khớp đúng schema mẫu".
