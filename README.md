# Case Study 2 - Ứng dụng quản lý và giao công việc nhóm

## Thông tin cá nhân

- **MSSV:** KHMT2411040
- **Họ tên:** Thái Nhựt Minh
## Giới thiệu

Task Manager là ứng dụng quản lý công việc nhóm, gồm backend `api` (Node.js, Express, MongoDB Atlas) và ứng dụng di động `TaskManager` (Flutter).

Chức năng chính:

- Đăng ký, đăng nhập bằng JWT, xem và cập nhật hồ sơ, đổi mật khẩu, đăng xuất
- Tạo, xem, sửa, xóa công việc; tìm kiếm, lọc theo trạng thái, mức ưu tiên, vai trò; sắp xếp
- Giao việc cho nhiều người, đặt người phụ trách chính
- Chia sẻ công việc với quyền viewer hoặc editor, kiểm tra quyền ở backend
- Lịch sử hoạt động của từng công việc
- Thông báo trong ứng dụng (đánh dấu đã đọc, số chưa đọc)
- Gửi email khi giao việc, chia sẻ, hoàn thành, đổi hạn; ghi nhật ký email; thử gửi lại email thất bại
- Thống kê công việc theo trạng thái, việc được giao, việc sắp đến hạn và quá hạn

## Cấu trúc thư mục

- `api/`: backend Node.js (Express, Mongoose)
- `TaskManager/`: ứng dụng Flutter

## Chạy backend

Yêu cầu: Node.js và tài khoản MongoDB Atlas.

    cd api
    npm install

Tạo file `api/.env` (file này không được commit) theo mẫu `api/.env.example`:

    PORT=3000
    MONGODB_URI=<chuỗi kết nối MongoDB Atlas>
    JWT_SECRET=<chuỗi bí mật ngẫu nhiên>
    JWT_EXPIRES_IN=7d
    SMTP_HOST=<máy chủ SMTP>
    SMTP_PORT=587
    SMTP_USER=<tài khoản SMTP>
    SMTP_PASS=<mật khẩu SMTP>
    MAIL_FROM="Task Manager <no-reply@taskmanager.local>"

Chạy server:

    npm run dev

Nếu không cấu hình SMTP, việc gửi email được ghi nhận là thất bại trong nhật ký email, các chức năng khác vẫn hoạt động bình thường.

## Chạy ứng dụng Flutter

    cd TaskManager
    flutter pub get
    flutter run

Địa chỉ backend được đặt trong `TaskManager/lib/utils/constants.dart`. Với máy ảo Android dùng địa chỉ `10.0.2.2`; với điện thoại thật dùng địa chỉ IP của máy chạy backend trong cùng mạng.

## API chính

| Nhóm | Đường dẫn |
|---|---|
| Xác thực | `/api/auth/register`, `/api/auth/login`, `/api/auth/me`, `/api/auth/change-password` |
| Công việc | `/api/tasks`, `/api/tasks/:id`, `/api/tasks/:id/status` |
| Lịch sử | `/api/tasks/:id/activities` |
| Giao việc | `/api/tasks/:id/assignees` |
| Chia sẻ | `/api/tasks/:id/shares` |
| Người dùng | `/api/users/search`, `/api/users/:id` |
| Thông báo | `/api/notifications`, `/api/notifications/unread-count`, `/api/notifications/:id/read`, `/api/notifications/read-all` |
| Thống kê | `/api/statistics/tasks`, `/api/statistics/assignments`, `/api/statistics/deadlines` |
| Email | `/api/tasks/:id/email-logs`, `/api/email-logs/:id/retry` |

## Quy trình làm việc

Mỗi nhóm chức năng lớn làm trên một nhánh riêng (A: tài khoản, B: công việc, C: giao việc và chia sẻ, D: thông báo và email). Mỗi chức năng nhỏ làm xong thì commit và push một lần.

