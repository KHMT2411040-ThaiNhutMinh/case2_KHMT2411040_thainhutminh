module.exports = (err, req, res, next) => {
  console.error(err);

  // Trùng dữ liệu duy nhất (ví dụ email)
  if (err.code === 11000) {
    return res.status(409).json({ message: 'Dữ liệu đã tồn tại' });
  }

  // JSON gửi lên bị hỏng hoặc dữ liệu không hợp lệ
  if (
    err.type === 'entity.parse.failed' ||
    err.name === 'CastError' ||
    err.name === 'ValidationError'
  ) {
    return res.status(400).json({ message: 'Dữ liệu gửi lên không hợp lệ' });
  }

  // Các lỗi 4xx khác do thư viện đặt sẵn
  const status = err.status || err.statusCode;
  if (status >= 400 && status < 500) {
    return res.status(status).json({ message: 'Yêu cầu không hợp lệ' });
  }

  // Lỗi còn lại: không lộ chi tiết nội bộ
  res.status(500).json({ message: 'Lỗi máy chủ' });
};