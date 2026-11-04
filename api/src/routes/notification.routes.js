const express = require('express');
const mongoose = require('mongoose');
const Notification = require('../models/notification.model');
const auth = require('../middleware/auth.middleware');

const router = express.Router();
router.use(auth);

// Danh sách thông báo của tôi: ?unread=true &limit=50
router.get('/', async (req, res) => {
  const filter = { userId: req.user._id };
  if (req.query.unread === 'true') filter.isRead = false;
  const limit = Math.min(parseInt(req.query.limit, 10) || 50, 100);
  const items = await Notification.find(filter).sort({ createdAt: -1 }).limit(limit);
  res.json(items);
});

// Đếm thông báo chưa đọc
router.get('/unread-count', async (req, res) => {
  const count = await Notification.countDocuments({ userId: req.user._id, isRead: false });
  res.json({ count });
});

// Đánh dấu tất cả đã đọc
router.patch('/read-all', async (req, res) => {
  const result = await Notification.updateMany(
    { userId: req.user._id, isRead: false },
    { $set: { isRead: true } }
  );
  res.json({ message: 'Đã đánh dấu tất cả đã đọc', modified: result.modifiedCount });
});

// Đánh dấu một thông báo đã đọc (chỉ của chính mình)
router.patch('/:id/read', async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: 'Mã thông báo không hợp lệ' });
  }
  const item = await Notification.findOneAndUpdate(
    { _id: req.params.id, userId: req.user._id },
    { $set: { isRead: true } },
    { new: true }
  );
  if (!item) return res.status(404).json({ message: 'Không tìm thấy thông báo' });
  res.json(item);
});

module.exports = router;