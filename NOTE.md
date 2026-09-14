---
Mục đích: đây là note liên quan tới kiến thức về postgres
---
Source:
```Buffers: shared hit=18056 read=151922```
1 page hoặc block có dung lượng cố định là 8kb
! sự thật dù có lấy 4 bytes dữ liệu, người thủ thư vẫn phải mang cái hộp 8kb lên, điều này là rule

- psql là command-line client (CLI) của PostgreSQL
-> chương trình dùng để nói chuyện với PostgreSQL bằng terminal.

- pgbench là công cụ tự động chạy nhiều giao dịch trên PostgreSQL để kiểm tra hiệu năng và khả năng xử lý đồng thời.
-> Nó có thể chạy kịch bản SQL bạn viết, rồi đo tốc độ và thời gian xử lý
