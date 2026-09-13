Chạy truy vấn 1 order không đánh index
- Điều kiện: customer_id = 5.000.000
- Chi tiết: chưa đánh index cho customer_id
- Time: 5.4s
- Điều kiện: customer_id = 3
- Chi tiết: chưa đánh index cho customer_id
- Time: 600ms

Chạy truy vấn 1 order có đánh index
- Điều kiện: id = 10.000.000
- Chi tiết: pk đã có index
- Time: 3ms ~ 20ms

Chạy 1 truy vấn product nhiều điệu kiện và có sort
- Điều kiện:
    status = 'ACTIVE' AND category_id = 10
    base_price ASC
- Chi tiết: chưa đánh index
- Time: 90ms

Chạy truy vấn product nhiều điệu kiện và có sort đánh index 1 cột category_id
- Time: lần đầu 100ms các lần tiếp theo ~20ms

Chạy truy vấn product nhiều điệu kiện và có sort đã đánh coposite index
- Chi tiết: đánh 3 trường điều kiện và sort: status, category_id, base_price
- Time: lần đầu 30ms lần tiếp theo 3ms

05_partial_index_hot_status
Chạy index partial bình thường (order_status, placed_at)
- tạo index hết tầm 11s
- Sau khi tạo index, chạy lại câu lệnh chính lần đầu hết tầm 5.4s
    - Cụ thể planing time 1.6s
    - Row bỏ qua rất nhiều hơn 10tr dòng
    - read hơn 273k block
Chạy index partial có điều kiện
... ON orders (placed_at) WHERE order_status = 'PENDING';
    - Vẫn seq scan, time vẫn thế

07_pagination_offset_vs_keyset
select tại offset OFFSET 6000000 LIMIT 20;
- thời gian chạy khá lâu tầm 5s
- postgres gọi các JIT functions của nó lên để tối ưu
