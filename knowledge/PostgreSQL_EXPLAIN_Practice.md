# Bài Tập Thực Hành: Bắt Bệnh Kế Hoạch Thủ Kho (EXPLAIN)

**Bối cảnh:** Bạn là giám đốc nhà kho. Anh thủ kho vừa trình lên bản báo cáo sau khi tìm các đơn hàng có trạng thái 'DA_HUY' (Đã hủy).

Bản báo cáo ghi:
```text
->  Seq Scan on don_hang  (cost=0.00..15432.00 rows=1000 width=120) 
      (actual time=0.120..450.000 rows=5 loops=1)
      Filter: (trang_thai = 'DA_HUY')
      Rows Removed by Filter: 999995
      Buffers: shared hit=50 read=12000
```

Dựa vào mô hình "Nhà kho khổng lồ", hãy trả lời các câu hỏi dưới đây bằng ngôn ngữ đời thường (như thùng hàng, sổ mục lục, bàn làm việc...).

---

### Câu hỏi 1: Về khả năng lập kế hoạch
Anh thủ kho đoán sẽ tìm được bao nhiêu đơn, và thực tế anh ta lấy ra được mấy đơn? Sự chênh lệch này nói lên điều gì về "cuốn sổ thống kê" của nhà kho?

**Phần trả lời của bạn:**
> *(Điền câu trả lời của bạn vào đây)*
Anh thủ kho đoán tìm được 1000 đơn, thực tế lấy được 5 đơn
Sự chênh lệch này nói lên có sai lệch lớn so với thống kê ở kho, cần ANALYZE TABLE để xử lí, còn ANALYZE TABLE làm gì thì tôi chưa biết

**Đánh giá của Thầy Feynman:**
Đúng rồi, anh bạn! Cậu nhìn rất chuẩn ở chỗ thấy ngay sự chênh lệch (đoán 1000 mà vác ra có 5). Điều này đúng là do cuốn "sổ thống kê" (statistics) của nhà kho đang bị lỗi thời.
Nhưng cậu bảo chưa biết `ANALYZE TABLE` làm gì à? Tưởng tượng thế này nhé: `ANALYZE TABLE` giống như cậu cử một nhân viên đi dạo một vòng quanh các dãy kệ, đếm ngẫu nhiên xem mỗi loại hàng hóa đang chiếm bao nhiêu chỗ, rồi ghi chú lại vào cuốn sổ thống kê đó. Nếu không có bước này, anh thủ kho cứ đinh ninh theo số liệu cũ rích từ năm ngoái, nên mới đoán sai bét nhè (1000 vs 5). Nhờ có số liệu mới, anh ta sẽ biết liệu có nên lật sổ mục lục hay cứ đi bộ quét cả kho (Seq Scan).



---

### Câu hỏi 2: Về sức lực bưng bê (Buffers)
Nhìn vào dòng cuối cùng, anh ta đã phải lội vào "kho lạnh" (Disk) bưng bao nhiêu thùng hàng, và chỉ tìm thấy bao nhiêu thùng trên "bàn làm việc" (RAM)? Tại sao cách làm này lại khiến hệ thống chậm chạp? (Gợi ý nhìn vào con số 999995).

**Phần trả lời của bạn:**
> *(Điền câu trả lời của bạn vào đây)*
Vào kho lạnh lấy 12000 thùng hàng, trên bàn làm việc 50 thùng
Cách này làm chậm vì nó phải tuần tự đi qua 999995 món hàng

**Đánh giá của Thầy Feynman:**
Rất chính xác về con số! Cậu đã thấy được sự mệt mỏi của anh thủ kho: phải chạy tít vào "kho lạnh" (Disk read=12000) để khuân đồ, trong khi trên "bàn làm việc" (RAM/shared hit) chỉ có sẵn 50 thùng. Lội vào kho lạnh bao giờ cũng chậm hơn rất nhiều so với vơ đồ ngay trên bàn, đúng không?
Cậu cũng nhìn trúng tim đen của vấn đề: anh ta đã phải lật từng món hàng, ngó xem nó có phải 'DA_HUY' không, rồi vứt toẹt đi 999995 món (Rows Removed by Filter). Đó chính là nhược điểm chí mạng của "Seq Scan" (đi tuần tự từng kệ hàng). Anh ta bê cả vạn thùng từ kho lạnh ra chỉ để vứt đi gần 1 triệu món không cần thiết. Thật là một sự lãng phí mồ hôi công sức khủng khiếp!


---

### Câu hỏi 3: Về cách giải quyết
Nhìn vào phương pháp tìm kiếm (Scan) và sự vất vả của anh ta, bạn (với tư cách là giám đốc) sẽ yêu cầu thủ kho trang bị thêm công cụ/phương pháp gì để lần sau có người hỏi đơn 'DA_HUY', anh ta có thể làm cực nhanh mà không phải vất vả bưng bê nữa?

**Phần trả lời của bạn:**
> *(Điền câu trả lời của bạn vào đây)*
Tôi sẽ dùng index scan để xử lí hộ anh ta
Tạo 1 cuốn sổ thống kê index theo trạng thái, lần đầu thì hơi chậm 1 chút sau khi đánh index, nhưng lần tiếp theo các thùng hàng đã có trên bàn làm việc rồi, tôi đã kiểm chứng lần đầu truy vấn sau khi đánh index hơi chậm so với các lần tiếp theo

**Đánh giá của Thầy Feynman:**
Tuyệt vời! Giải pháp "sổ mục lục" (Index) chính xác là cứu tinh ở đây. 
Cậu hiểu rất đúng việc tạo Index. Thay vì bắt anh ta chạy dọc kho, ta cấp cho anh ta một cuốn sổ nhỏ ghi rõ: "Hàng 'DA_HUY' nằm ở kệ số mấy, ngách nào". Lần sau, anh ta chỉ việc lật sổ, nhìn địa chỉ và chạy thẳng đến đúng cái ngách đó nhặt ra đúng 5 đơn. Bùm! Xong việc.
Tuy nhiên, có một chút nhầm lẫn nhỏ ở đây cậu ạ. Cuốn sổ Index và "sổ thống kê" (statistics) là hai thứ khác nhau. Index là cuốn mục lục chỉ điểm chính xác vị trí hàng. Còn cái chuyện "lần đầu chậm, lần sau nhanh" mà cậu nhận thấy, thực chất không phải do bản thân cái Index nhanh lên đâu! Đó là do "bàn làm việc" (RAM/Buffers) đấy. Lần đầu tiên chạy, anh ta phải chui vào kho lạnh (Disk) lôi các thùng hàng và lôi luôn cả cái Index đặt lên bàn làm việc. Lần thứ hai hỏi lại, cuốn sổ Index và mấy cái thùng hàng đó đã nằm chễm chệ trên bàn (RAM) rồi, nên anh ta nhặt luôn, cực nhanh (toàn là shared hit). Đó gọi là cơ chế Cache đấy anh bạn trẻ ạ!