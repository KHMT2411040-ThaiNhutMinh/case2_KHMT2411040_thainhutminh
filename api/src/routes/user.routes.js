const express = require('express');
const mongoose = require('mongoose');
const User = require('../models/user.model');
const auth = require('../middleware/auth.middleware');
const { publicUser } = require('../utils/access');

const router = express.Router();
router.use(auth);

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// Tìm theo tên hoặc email (không trả về chính mình)
router.get('/search', async (req, res) => {
  const q = typeof req.query.q === 'string' ? req.query.q.trim() : '';
  if (q.length < 2) {
    return res.status(400).json({ message: 'Nhập ít nhất 2 ký tự để tìm' });
  }
  const rx = new RegExp(escapeRegex(q), 'i');
  const users = await User.find({
    _id: { $ne: req.user._id },
    $or: [{ fullName: rx }, { email: rx }],
  }).limit(10);
  res.json(users.map(publicUser));
});

// Thông tin công khai của một người dùng
router.get('/:id', async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: 'Mã người dùng không hợp lệ' });
  }
  const user = await User.findById(req.params.id);
  if (!user) return res.status(404).json({ message: 'Không tìm thấy người dùng' });
  res.json(publicUser(user));
});

module.exports = router;