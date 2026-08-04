# Lộ trình tổng — Chuẩn bị interview Database/Backend (junior → middle)

Bản đồ TOÀN BỘ lab: 4 track kỹ năng + 1 bộ backlog thực chiến + 3 vai AI
khác nhau. Dùng file này để biết ĐANG Ở ĐÂU và TIẾP THEO LÀM GÌ — chi tiết
từng phần nằm ở file riêng, file này chỉ điều hướng.

## 3 vai AI — dùng đúng vai cho đúng mục đích

| Vai | File prompt | Dùng khi | KHÔNG dùng khi |
|---|---|---|---|
| **Teacher** | [`TEACHER_PROMPT.md`](TEACHER_PROMPT.md) | Học khái niệm MỚI lần đầu, cần giải thích sâu, không giới hạn thời gian | Đã hiểu rồi, chỉ cần luyện phản xạ/áp lực |
| **Leader** | [`LEADER_PROMPT.md`](LEADER_PROMPT.md) | Áp dụng cái đã học vào "ticket thật", luyện chẩn đoán từ triệu chứng (không lộ tên kỹ thuật) | Chưa nắm khái niệm nền — sẽ bế tắc vì không được dạy |
| **Interviewer** | [`INTERVIEWER_PROMPT.md`](INTERVIEWER_PROMPT.md) | Mô phỏng ĐÚNG áp lực phỏng vấn thật (time-box, chấm cuối buổi, follow-up xoáy) | Buổi đầu tiên học 1 chủ đề — nên Teacher trước |

Thứ tự dùng hợp lý cho MỖI chủ đề: **Teacher (hiểu) → Leader (áp dụng) →
Interviewer (luyện phản xạ dưới áp lực)**.

## 4 track kỹ năng

| Track | Thư mục | Câu hỏi cốt lõi | Số level |
|---|---|---|---|
| **A — Luyện truy vấn** | [`teacher-tasks/01-queries/`](teacher-tasks/01-queries/00_INDEX.md) | Tôi viết ĐÚNG SQL cho yêu cầu nghiệp vụ không? | 8 (0-7) |
| **B — Optimize** | [`teacher-tasks/02-optimize/`](teacher-tasks/02-optimize/00_INDEX.md) | SQL đúng rồi — sao cho NHANH? | 11 (0-10) |
| **C — Schema Design** | [`teacher-tasks/03-schema-design/`](teacher-tasks/03-schema-design/00_INDEX.md) | Từ yêu cầu TRỐNG, tự thiết kế schema thế nào? | 8 (0-7) |
| **D — Interview Drill** | [`teacher-tasks/04-interview-drill/`](teacher-tasks/04-interview-drill/00_INDEX.md) | Trả lời NHANH-ĐÚNG-NGẮN các câu hay bị hỏi miệng? | 6 drill |

Ngoài 4 track, còn [`leader-tasks/`](leader-tasks/00_BACKLOG.md) — 9 ticket
mô phỏng công việc thật (không phải "học", mà "làm"), và
[`03_exercises/`](03_exercises/) + [`04_concurrency/`](04_concurrency/) —
bài tập gốc dùng chung làm demo cho nhiều track.

## Lộ trình theo giai đoạn (gợi ý — không bắt buộc tuyệt đối)

```
Giai đoạn 1 — Nền tảng viết đúng SQL
    Track A (0-7, Teacher mode)
    -> Đạt: tự viết đúng JOIN/aggregate/subquery/CTE/window cho 1 yêu cầu mới

Giai đoạn 2 — Optimize + Schema design cơ bản (có thể học SONG SONG)
    Track B (0-10, Teacher mode)  +  Track C Level 0-3 (khái niệm nền)
    -> Đạt: đọc đúng EXPLAIN, chọn đúng loại index; phân biệt được
       chuẩn hoá/denormalize có chủ đích

Giai đoạn 3 — Áp dụng thực chiến
    leader-tasks/ (Leader mode, làm hết 9 ticket, ưu tiên P0 trước)
    +  Track C Level 4-6 (design challenge, Teacher mode trước, Leader mode sau nếu muốn thêm áp lực)
    -> Đạt: tự chẩn đoán được vấn đề từ TRIỆU CHỨNG, không cần ai chỉ tên kỹ thuật

Giai đoạn 4 — Drill phản xạ + mô phỏng interview thật
    Track D (tự drill nhanh, không cần AI)
    +  Track C Level 7 (capstone design, Interviewer mode)
    +  Vài vòng Interviewer mode ghép đủ 3 loại round (concept/design/query)
    -> Đạt: trả lời trôi chảy dưới áp lực thời gian, không chỉ đúng khi có thời gian nghĩ
```

Nếu gấp thời gian: **Track A → Track B → leader-tasks P0/P1 → Track D drill
2-3 lượt → 1 buổi Interviewer mode tổng hợp** là lộ trình rút gọn tối thiểu.

## Tự đánh giá readiness (không cần AI chấm, tự soi)

- [ ] Đưa 1 bảng phẳng lạ, tự chỉ ra vi phạm chuẩn hoá + tự tách bảng đúng trong < 5 phút.
- [ ] Đưa 1 query JOIN/subquery lạ, tự đoán ĐÚNG kết quả trước khi chạy (không bị bất ngờ vì NULL/fan-out).
- [ ] Đưa 1 `EXPLAIN ANALYZE` lạ, tự đọc ra được node nào tốn nhất trong < 1 phút, không cần dò từng dòng.
- [ ] Tự làm được 1 design challenge domain HOÀN TOÀN MỚI trong 20-25 phút, có hỏi làm rõ scope trước khi vẽ bảng.
- [ ] Trả lời được > 80% câu ở Track D trong đúng 30-45 giây/câu, không cần xem lại đáp án.
- [ ] Kể được ít nhất 2-3 "war story" cụ thể từ `leader-tasks/` khi được hỏi hành vi ("kể 1 lần bạn debug production issue").

Đạt hết 6 dòng trên: sẵn sàng cho interview junior→middle. Thiếu dòng nào,
quay lại đúng track được ghi ở dòng đó.

## Chạy lab

```bash
docker compose up -d
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/00_setup/V0__extensions.sql
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/01_schema/run_all.sql
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/02_seed/run_all.sql
```
Chi tiết đầy đủ: [`README.md`](README.md).
