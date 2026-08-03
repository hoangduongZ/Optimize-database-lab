# Backlog — Leader Tasks

> Đọc [`../LEADER_PROMPT.md`](../LEADER_PROMPT.md) trước khi bắt đầu. Đây là
> backlog thật, không phải lộ trình học tuần tự — làm theo priority như 1
> sprint, hoặc chọn ticket bất kỳ nếu chỉ muốn luyện 1 kỹ năng cụ thể.

Không đọc phần "gợi ý kỹ năng" trong bảng dưới nếu muốn tự chẩn đoán 100%
như thật — cột này chỉ để bạn tự chọn ticket theo nhu cầu ôn luyện.

| Ticket | Priority | Reporter | Triệu chứng (rút gọn) | (Gợi ý kỹ năng — tự che nếu muốn) |
|---|---|---|---|---|
| [ECM-301](ticket-01-category-page-slow.md) | P1 | Support Lead | Trang danh mục load chậm khi traffic tăng | composite index |
| [ECM-302](ticket-02-top-spender-report.md) | P2 | Marketing Manager | Cần báo cáo top khách chi tiêu nhiều nhất | join + aggregate + window |
| [ECM-303](ticket-03-oversell-incident.md) | P0 | Ops / Incident | Bán vượt tồn kho sau flash sale | concurrency / race condition |
| [ECM-304](ticket-04-search-not-found.md) | P2 | CSKH | Tìm kiếm sản phẩm không ra đúng kết quả | full-text search / trigram |
| [ECM-305](ticket-05-never-purchased-users.md) | P2 | CRM / Kế toán | Cần list khách chưa từng mua để remarketing | subquery NULL trap |
| [ECM-306](ticket-06-admin-pagination-slow.md) | P1 | Vận hành / Admin | Trang quản trị đơn hàng càng vào sâu càng chậm | offset vs keyset pagination |
| [ECM-307](ticket-07-order-detail-wrong-count.md) | P0 | QA | Trang chi tiết đơn hiển thị sai số lượng sản phẩm | JOIN fan-out |
| [ECM-308](ticket-08-pending-order-sla.md) | P1 | Vận hành kho | Job tự huỷ đơn PENDING quá hạn đang trễ SLA | partial index |
| [ECM-309](ticket-09-ops-dashboard-ambiguous.md) | P2 | Giám đốc vận hành | "Làm cho anh 1 dashboard tổng hợp" (yêu cầu mơ hồ) | tổng hợp + đặt câu hỏi làm rõ scope |

## Trước khi bắt đầu

```bash
docker compose up -d
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/00_setup/V0__extensions.sql
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/01_schema/run_all.sql
docker compose exec -T db psql -U postgres -d optimize_lab -f /lab/02_seed/run_all.sql
```
