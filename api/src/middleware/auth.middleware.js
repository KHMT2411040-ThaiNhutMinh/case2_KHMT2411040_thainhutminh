const jwt = require('jsonwebtoken');
const User = require('../models/user.model');

module.exports = async (req, res, next) => {
  const header = req.headers.authorization || '';
  const [type, token] = header.split(' ');

  if (type !== 'Bearer' || !token) {
    return res.status(401).json({ message: 'Chưa đăng nhập' });
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(payload.id);
    if (!user) {
      return res.status(401).json({ message: 'Tài khoản không tồn tại' });
    }
    req.user = user; // các hàm phía sau dùng req.user để biết ai đang gọi
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Token không hợp lệ hoặc đã hết hạn' });
  }
};