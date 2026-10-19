# Chính sách quyền riêng tư – Vườn Nhà

Phiên bản: 2026-10 · Có hiệu lực từ: 19/10/2026 · Liên hệ: `<EMAIL_LIÊN_HỆ>`

"Vườn Nhà" (sau đây gọi là "ứng dụng", "chúng tôi") là ứng dụng miễn phí giúp bạn lên lịch và theo dõi việc chăm sóc cây trồng tại nhà. Văn bản này giải thích chúng tôi thu thập dữ liệu gì, dùng để làm gì, lưu ở đâu, chia sẻ với ai và bạn có những quyền nào, theo Nghị định 13/2023/NĐ-CP về bảo vệ dữ liệu cá nhân và chính sách của Google Play.

Bên kiểm soát và xử lý dữ liệu: chủ sở hữu ứng dụng Vườn Nhà (cá nhân), liên hệ qua `<EMAIL_LIÊN_HỆ>`.

## 1. Dữ liệu chúng tôi thu thập

| Nhóm dữ liệu | Chi tiết | Bắt buộc? |
|---|---|---|
| Tài khoản | Địa chỉ email (đăng nhập bằng Google hoặc mã OTP gửi qua email), mã định danh người dùng | Có |
| Hồ sơ | Tên hiển thị, ảnh đại diện (tuỳ chọn), ngôn ngữ, múi giờ, mức kinh nghiệm, quỹ thời gian chăm cây, tuỳ chọn hữu cơ, trong nhà có trẻ em / thú cưng hay không, giờ yên tĩnh | Tên hiển thị: có; còn lại tuỳ chọn |
| Vị trí mức tỉnh/thành | Tỉnh/thành bạn chọn thủ công và vùng khí hậu suy ra (Bắc/Trung/Nam). Chúng tôi **không** thu thập vị trí GPS hay vị trí chính xác | Có (để gợi ý lịch theo mùa) |
| Dự án cây | Loại cây, ngày bắt đầu, không gian trồng, mức nắng, kế hoạch chăm sóc, mốc phát triển | Có khi dùng tính năng |
| Ảnh cây | Ảnh bạn chụp hoặc chọn khi check-in, ảnh bìa dự án, kèm nhãn tình trạng và ghi chú (tối đa 200 ký tự) bạn nhập | Tuỳ chọn |
| Nhật ký công việc | Việc đã làm / bỏ qua / hoãn, thời điểm, lý do, ghi chú, điểm kinh nghiệm, huy hiệu, chuỗi ngày | Có khi dùng tính năng |
| Gia đình (chia sẻ) | Tên gia đình, danh sách thành viên và vai trò, mã mời, hoạt động chung | Tuỳ chọn |
| Thiết bị | Mã thông báo đẩy (push token) của Firebase Cloud Messaging, loại nền tảng (Android) | Chỉ khi bạn cho phép thông báo |
| Đồng ý | Bản ghi bạn đã chấp nhận điều khoản, chính sách và việc xử lý dữ liệu, kèm phiên bản và thời điểm | Có |
| Dữ liệu kỹ thuật | Nhật ký lỗi và nhật ký máy chủ ở mức tối thiểu (địa chỉ IP, thời điểm, mã lỗi) do nhà cung cấp hạ tầng tạo ra | Tự động |

Ứng dụng **không** chứa quảng cáo, **không** có SDK theo dõi quảng cáo, **không** bán dữ liệu cá nhân và không thu thập danh bạ, vị trí GPS, micro hay dữ liệu tài chính.

## 2. Mục đích xử lý

- Tạo và bảo vệ tài khoản, đăng nhập.
- Lập kế hoạch và nhắc việc chăm sóc cây phù hợp mùa, vùng và không gian của bạn.
- Phân tích ảnh cây bằng AI để ước lượng giai đoạn phát triển, dấu hiệu bệnh/thiếu chất và đề xuất điều chỉnh kế hoạch (bạn luôn là người duyệt thay đổi).
- Tính điểm kinh nghiệm, huy hiệu, chuỗi ngày.
- Chia sẻ dự án và công việc với các thành viên gia đình bạn mời.
- Gửi thông báo nhắc việc và thông báo hoạt động trong gia đình.
- Bảo mật, chống lạm dụng (ví dụ giới hạn số lần gọi AI mỗi ngày), khắc phục lỗi.
- Tuân thủ pháp luật.

Cơ sở xử lý: sự đồng ý của bạn (ghi nhận khi đăng nhập lần đầu), việc thực hiện dịch vụ bạn yêu cầu và nghĩa vụ pháp lý. Bạn có thể rút lại sự đồng ý bất cứ lúc nào (mục 8).

## 3. Xử lý ảnh bằng AI (Anthropic – Claude API)

Khi bạn bấm phân tích một check-in, ứng dụng tải ảnh (đã thu nhỏ) lên máy chủ của chúng tôi (Supabase). Máy chủ gọi **Claude API của Anthropic PBC** (Hoa Kỳ) và gửi:

- ảnh cây bạn đã chụp;
- thông tin cây và dự án cần thiết (loại cây, giai đoạn, mùa, vùng khí hậu, không gian, mức nắng);
- nhãn tình trạng và ghi chú ngắn bạn nhập;
- cờ "nhà có trẻ em / thú cưng" để gợi ý an toàn.

Chúng tôi **không** gửi cho Anthropic email, tên hiển thị, ảnh đại diện hay mã người dùng. Khoá API chỉ nằm trên máy chủ, không nằm trong ứng dụng. Theo điều khoản thương mại của Anthropic, dữ liệu gửi qua API không được dùng để huấn luyện mô hình và có thể được Anthropic lưu giữ tạm thời theo chính sách của họ (xem https://www.anthropic.com/legal/privacy). Vì vậy dữ liệu của bạn có thể được chuyển ra ngoài lãnh thổ Việt Nam (Hoa Kỳ). Chúng tôi chỉ gửi mức tối thiểu cần thiết, bạn có thể không dùng tính năng check-in bằng ảnh mà vẫn dùng các chức năng còn lại. Kết quả AI chỉ là gợi ý tham khảo, không phải tư vấn nông học chuyên nghiệp.

## 4. Nơi lưu trữ và bảo mật

- Dữ liệu được lưu trên **Supabase** (cơ sở dữ liệu PostgreSQL và kho tệp), máy chủ đặt tại khu vực **Singapore**.
- Ảnh nằm trong kho riêng tư, chỉ truy cập qua đường dẫn có chữ ký tạm thời. Mọi bảng dữ liệu bật kiểm soát truy cập theo dòng (RLS): bạn chỉ thấy dữ liệu của mình và của gia đình bạn tham gia.
- Truyền tải qua HTTPS. Dữ liệu tạm trên máy (bộ nhớ ngoại tuyến) nằm trong vùng lưu trữ riêng của ứng dụng và không được sao lưu lên đám mây của Android.
- Thông báo đẩy dùng **Firebase Cloud Messaging (Google)** và đăng nhập Google dùng dịch vụ của Google; Google xử lý theo chính sách của họ.
- Email OTP được gửi qua nhà cung cấp email giao dịch do chúng tôi cấu hình.

Dù áp dụng các biện pháp kỹ thuật và tổ chức hợp lý, không hệ thống nào an toàn tuyệt đối. Nếu xảy ra vi phạm dữ liệu cá nhân, chúng tôi sẽ thông báo cho bạn và cơ quan có thẩm quyền theo quy định.

## 5. Thời gian lưu giữ

- Dữ liệu tài khoản, dự án, nhật ký và ảnh được lưu đến khi bạn xoá hoặc xoá tài khoản.
- Khi bạn xoá tài khoản, toàn bộ dữ liệu cá nhân và ảnh của bạn bị xoá khỏi cơ sở dữ liệu và kho tệp ngay lập tức; bản sao lưu hạ tầng (nếu có) bị ghi đè trong tối đa 30 ngày.
- Bản ghi đồng ý và nhật ký kỹ thuật tối thiểu có thể được giữ lâu hơn trong phạm vi pháp luật yêu cầu.
- Token thông báo bị xoá khi xoá tài khoản hoặc khi không còn hợp lệ.

## 6. Chia sẻ trong gia đình

Khi bạn tạo hoặc tham gia một gia đình và chia sẻ dự án, các thành viên khác sẽ thấy: tên hiển thị, ảnh đại diện, cấp độ và điểm của bạn, các dự án được chia sẻ cùng ảnh check-in và công việc của dự án đó, và hoạt động chung (ví dụ "A đã tưới cây"). Người tạo gia đình (Chủ nhà) có thể mời hoặc mời ra thành viên. Bạn có thể rời gia đình bất cứ lúc nào; dự án bạn chia sẻ sẽ chuyển về riêng tư. Chúng tôi không chia sẻ dữ liệu của bạn cho người ngoài gia đình.

## 7. Chia sẻ với bên thứ ba

Chúng tôi không bán dữ liệu. Dữ liệu chỉ được xử lý bởi các nhà cung cấp dịch vụ cần thiết để vận hành ứng dụng: Supabase (lưu trữ, xác thực), Anthropic (phân tích ảnh bằng AI, mục 3), Google (đăng nhập Google, Firebase Cloud Messaging), nhà cung cấp email giao dịch (gửi mã OTP), GitHub (lưu mã nguồn, không chứa dữ liệu người dùng). Chúng tôi cũng có thể cung cấp dữ liệu khi cơ quan nhà nước có thẩm quyền yêu cầu theo pháp luật.

## 8. Quyền của bạn (Điều 9 Nghị định 13/2023/NĐ-CP)

Bạn có quyền: được biết về việc xử lý; đồng ý hoặc không đồng ý; truy cập, xem và chỉnh sửa dữ liệu; rút lại sự đồng ý; xoá dữ liệu; hạn chế xử lý; phản đối xử lý; yêu cầu cung cấp dữ liệu; khiếu nại, tố cáo, khởi kiện và yêu cầu bồi thường theo pháp luật.

Cách thực hiện:
- **Chỉnh sửa**: trong ứng dụng, mục Hồ sơ / Cài đặt.
- **Xoá tài khoản và toàn bộ dữ liệu trong ứng dụng**: Cài đặt > "Xóa tài khoản và toàn bộ dữ liệu" (xác nhận hai lần). Xoá ngay và không thể hoàn tác.
- **Xoá qua web (không cần cài ứng dụng)**: xem trang "Yêu cầu xoá tài khoản" (`delete-account.html`) hoặc gửi email đến `<EMAIL_LIÊN_HỆ>` từ địa chỉ email đã dùng đăng ký, tiêu đề "Yêu cầu xoá tài khoản Vườn Nhà". Chúng tôi phản hồi trong 72 giờ và hoàn tất xoá trong tối đa 30 ngày.
- **Các quyền khác** (truy cập, sao chép, rút đồng ý, hạn chế, phản đối): gửi email đến `<EMAIL_LIÊN_HỆ>`; chúng tôi xử lý trong 72 giờ kể từ khi xác minh được danh tính.

## 9. Trẻ em

Ứng dụng không hướng đến trẻ em dưới 16 tuổi. Người từ 16 tuổi trở lên dùng được; trẻ dưới 16 tuổi chỉ dùng khi có sự đồng ý của cha mẹ hoặc người giám hộ theo Nghị định 13/2023/NĐ-CP. Nếu phát hiện đã thu thập dữ liệu của trẻ mà không có sự đồng ý hợp lệ, chúng tôi sẽ xoá.

## 10. Thay đổi chính sách

Khi có thay đổi quan trọng, chúng tôi cập nhật phiên bản và ngày hiệu lực ở đầu trang, và thông báo trong ứng dụng; có thể yêu cầu bạn đồng ý lại.

## 11. Liên hệ

Email: `<EMAIL_LIÊN_HỆ>` (chủ sở hữu ứng dụng Vườn Nhà, Việt Nam).
