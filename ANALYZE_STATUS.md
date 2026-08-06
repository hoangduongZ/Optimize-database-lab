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

