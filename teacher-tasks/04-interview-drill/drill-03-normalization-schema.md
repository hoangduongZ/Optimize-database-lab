# Drill 03 — Normalization & Schema Design

## Q1: 1NF/2NF/3NF định nghĩa ngắn gọn?
**Trả lời ngắn:** **1NF** — mỗi cột chỉ chứa 1 giá trị đơn (không nhồi
list/CSV vào 1 cột). **2NF** — (chỉ áp dụng khi PK composite) mọi cột
không-khoá phụ thuộc vào TOÀN BỘ PK, không chỉ 1 phần. **3NF** — mọi cột
không-khoá phụ thuộc TRỰC TIẾP vào PK, không qua 1 cột không-khoá khác
(transitive dependency).

**Follow-up hay gặp:** "Cho ví dụ vi phạm 3NF?" — Bảng `orders(id,
customer_id, customer_city, customer_country)` — `customer_country` phụ
thuộc vào `customer_city` (qua 1 cột không-khoá khác), không phụ thuộc trực
tiếp `id` — vi phạm 3NF, nên tách `customer_city`/`country` sang bảng
riêng theo khách hàng.

**Bẫy hay gặp:** Học thuộc định nghĩa nhưng không nhận ra vi phạm khi nhìn
1 bảng thật (xem thực hành ở [Track C Level 0](../03-schema-design/level-00-normalization-basics.md)).

---

## Q2: Khi nào NÊN chủ động denormalize (không phải lỗi thiết kế)?
**Trả lời ngắn:** 2 lý do chính đáng: (1) **Tính bất biến lịch sử** — cần
snapshot dữ liệu tại 1 thời điểm, dù dữ liệu gốc đổi sau đó (vd giá sản phẩm
trong hoá đơn). (2) **Đọc nhiều/ghi ít** — 1 giá trị tổng hợp (like_count,
tổng tồn kho) được ĐỌC rất thường xuyên, tính lại từ đầu mỗi lần đọc quá
tốn, chấp nhận lưu 1 cột tổng hợp, cập nhật khi có thay đổi.

**Follow-up hay gặp:** "Rủi ro của denormalize là gì?" — Dữ liệu có thể bị
LỆCH nếu code cập nhật cột tổng hợp không đúng ở MỌI nơi có thể thay đổi
(vd quên cập nhật `like_count` ở 1 luồng xoá comment nào đó).

**Bẫy hay gặp:** Nghĩ denormalize LUÔN vì lý do "tăng tốc" — bỏ qua lý do
QUAN TRỌNG hơn trong nhiều case thật: tính bất biến (xem [Track C Level 2](../03-schema-design/level-02-denormalization-tradeoffs.md)).

---

## Q3: EAV (Entity-Attribute-Value) pattern là gì, ưu/nhược điểm?
**Trả lời ngắn:** Thay vì 1 cột riêng cho mỗi thuộc tính, dùng 1 bảng
generic `(entity_id, attribute_id, value)`. Ưu điểm: thêm thuộc tính mới
KHÔNG CẦN migration schema (hợp lý khi thuộc tính biến động theo từng loại
sản phẩm, vd điện tử có hàng trăm loại thông số kỹ thuật khác nhau). Nhược
điểm: khó ràng buộc KIỂU DỮ LIỆU cho từng thuộc tính, query lọc theo nhiều
thuộc tính cùng lúc phức tạp hơn (cần nhiều self-join).

**Follow-up hay gặp:** "JSONB có giải quyết được vấn đề tương tự không, khác
EAV ở đâu?" — Có, nhưng JSONB lưu trong 1 CỘT của chính dòng đó (không cần
bảng riêng), linh hoạt hơn nhưng KHÔNG ràng buộc FK/CHECK được vào field bên
trong — EAV vẫn là quan hệ thường (dễ ràng buộc `attribute_id` là FK hợp
lệ).

**Bẫy hay gặp:** Coi EAV và JSONB là "2 cách viết khác nhau của CÙNG 1 thứ"
— chúng khác nhau về khả năng ràng buộc và cách query (SQL thường vs
JSON operator).

---

## Q4: Cho 1 cặp thực thể, làm sao xác định đúng loại quan hệ (1-1/1-n/n-n)?
**Trả lời ngắn:** Tự hỏi CẢ 2 CHIỀU: "1 [A] có thể có nhiều [B] không?" VÀ
"1 [B] có thể có nhiều [A] không?". Cả 2 chiều đều "có nhiều" → n-n (cần
bảng trung gian). Chỉ 1 chiều "có nhiều" → 1-n (FK đặt ở bên "nhiều"). Cả 2
chiều đều "chỉ 1" → 1-1.

**Follow-up hay gặp:** "Bảng trung gian cho n-n có cần thêm cột riêng không,
hay chỉ 2 FK?" — Tuỳ bài toán — nếu quan hệ đó có THUỘC TÍNH RIÊNG (vd thời
điểm, số lượng, trạng thái của CHÍNH quan hệ đó, không thuộc về A hay B) thì
cần thêm cột (xem ví dụ "bác sĩ khám bệnh nhân" ở [Track C Level 1](../03-schema-design/level-01-keys-and-relationships.md)).

**Bẫy hay gặp:** Mặc định kết luận 1-n vì đó là case dễ nghĩ nhất, không tự
hỏi chiều ngược lại — sai với các quan hệ tưởng đơn giản nhưng thực ra n-n
(vd "bác sĩ - bệnh nhân" qua các lượt khám, không phải 1-n).
