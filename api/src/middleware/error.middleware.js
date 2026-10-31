module.exports = (err, req, res, next) => {
  console.error(err);
  if (err.code === 11000) {
    return res.status(409).json({ message: 'Dữ liệu đã tồn tại' });
  }
  res.status(500).json({ message: 'Lỗi máy chủ' });
};