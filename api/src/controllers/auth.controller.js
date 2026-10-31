const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/user.model');

const signToken = (user) =>
  jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });

exports.register = async (req, res) => {
  const { fullName, email, password } = req.body;

  const existing = await User.findOne({ email: email.toLowerCase() });
  if (existing) {
    return res.status(409).json({ message: 'Email đã được sử dụng' });
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const user = await User.create({ fullName, email, passwordHash });

  res.status(201).json({
    message: 'Đăng ký thành công',
    token: signToken(user),
    user,
  });
};
exports.login = async (req, res) => {
  const { email, password } = req.body;

  const user = await User.findOne({ email: email.toLowerCase() });
  const ok = user && (await bcrypt.compare(password, user.passwordHash));

  // Cùng một thông báo cho cả "sai email" và "sai mật khẩu"
  if (!ok) {
    return res.status(401).json({ message: 'Email hoặc mật khẩu không đúng' });
  }

  res.json({
    message: 'Đăng nhập thành công',
    token: signToken(user),
    user,
  });
};