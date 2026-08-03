# ECM-304 — Tìm kiếm sản phẩm không ra đúng kết quả

**Priority:** P2
**Reported by:** CSKH
**Ngày báo cáo:** 2026-07-30

## Mô tả

> "Có vài khách phản hồi qua chat: gõ tìm 'Laptop Gaming' thì ra kết quả,
> nhưng gõ 'Gaming Laptop' (đảo từ) thì KHÔNG ra gì, dù họ đang nhìn thấy
> đúng sản phẩm đó trên trang chủ. Bên mình xem giúp API search có vấn đề
> gì không. Không gấp lắm nhưng khách hàng bắt đầu để ý."
>
> Query hiện tại team dev gửi:
> ```sql
> SELECT id, name FROM products WHERE name ILIKE '%' || :keyword || '%';
> ```

## Acceptance Criteria
- [ ] Giải thích được vì sao "Laptop Gaming" ra kết quả nhưng "Gaming Laptop" thì không, bằng dữ liệu thật (không suy đoán).
- [ ] Đề xuất 1 giải pháp để tìm kiếm không phụ thuộc thứ tự từ khách gõ.
- [ ] Giải pháp phải chạy nhanh trên ~100k sản phẩm (không chấp nhận quay lại Seq Scan).
- [ ] Không yêu cầu khách hàng gõ đúng dấu cách/thứ tự — đây là hành vi tìm kiếm thực tế của người dùng.

## Ngữ cảnh bổ sung
- Q: "Có cần sửa lỗi chính tả (gõ sai 1-2 ký tự) không?" — A: "Không cần trong ticket này — chỉ cần xử lý đúng trường hợp đảo thứ tự từ trước, việc sửa lỗi chính tả để ticket khác."
- Q: "Đổi hẳn engine search (Elasticsearch...) có được không?" — A: "Không trong phạm vi ticket này — muốn giải pháp trong Postgres trước, đổi engine là quyết định lớn hơn, để sau."

---
## [CHỈ LEAD ĐỌC — KHÔNG lộ cho học viên]

### Root cause thật
`ILIKE '%Gaming Laptop%'` tìm ĐÚNG CHUỖI CON liên tiếp — dữ liệu thật lưu
tên dạng `"Laptop Gaming ..."` (đúng thứ tự này), nên tìm ngược thứ tự
không khớp bất kể có index hay không — đây là vấn đề LOGIC tìm kiếm, không
phải hiệu năng thuần.

### Giải pháp tham khảo
Full-text search với `tsvector`/`tsquery` — mỗi từ là 1 "token" độc lập,
`to_tsquery('Gaming & Laptop')` khớp bất kể thứ tự:
```sql
ALTER TABLE products ADD COLUMN search_vector tsvector
    GENERATED ALWAYS AS (to_tsvector('simple', coalesce(name, '') || ' ' || coalesce(description, ''))) STORED;
CREATE INDEX idx_products_search_vector ON products USING GIN (search_vector);

SELECT id, name, ts_rank(search_vector, query) AS rank
FROM products, to_tsquery('simple', 'Gaming & Laptop') AS query
WHERE search_vector @@ query
ORDER BY rank DESC
LIMIT 20;
```
(Giải pháp thay thế hợp lệ nếu học viên chọn: trigram `pg_trgm` + tách từ
khách gõ thành nhiều điều kiện `ILIKE` AND riêng — chạy được nhưng không xử
lý tốt bằng full-text cho trường hợp nhiều từ; chấp nhận nếu học viên giải
thích đúng đánh đổi.)

### Bậc hint
1. "Thử in ra đúng chuỗi `name` thật của sản phẩm đó trong DB — thứ tự từ có giống thứ tự khách gõ không?"
2. "`ILIKE '%A B%'` có khớp được chuỗi `'B A'` không? Vì sao?"
3. "Có cách tìm kiếm nào coi mỗi TỪ là 1 đơn vị độc lập, không quan tâm thứ tự, thay vì so khớp CHUỖI liên tiếp?"

### Rubric chấm
- **Đạt tối thiểu:** xác định đúng root cause là thứ tự chuỗi con, không phải thiếu index.
- **Đạt tốt:** implement full-text search, verify bằng cả 2 chiều từ khoá ("Laptop Gaming" và "Gaming Laptop") đều ra CÙNG kết quả.
- **Cờ đỏ:** chỉ thêm trigram index mà GIỮ NGUYÊN query `ILIKE '%Gaming Laptop%'` — chạy nhanh hơn nhưng VẪN ra 0 kết quả cho trường hợp đảo từ, không giải quyết đúng triệu chứng khách báo. Đây là dấu hiệu học viên nhầm "chậm" với "sai" — 2 vấn đề khác nhau.
