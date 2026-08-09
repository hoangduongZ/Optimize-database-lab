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

