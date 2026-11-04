const express = require('express');
const mongoose = require('mongoose');
const EmailLog = require('../models/emailLog.model');
const Task = require('../models/task.model');
const auth = require('../middleware/auth.middleware');
const requireTaskAccess = require('../middleware/taskAccess.middleware');
const { deliver, MAX_ATTEMPTS } = require('../utils/mailer');

const router = express.Router();

const serialize = (l) => ({
  _id: l._id,
  taskId: l.taskId,
  recipientEmail: l.recipientEmail,
  eventType: l.eventType,
  subject: l.subject,
  status: l.status,
  attempts: l.attempts,
  errorMessage: l.errorMessage,
  sentAt: l.sentAt,
  createdAt: l.createdAt,
});

// Lịch sử gửi email của một công việc (chỉ chủ việc xem)
router.get('/tasks/:id/email-logs', auth, requireTaskAccess('canManage'), async (req, res) => {
  const logs = await EmailLog.find({ taskId: req.task._id })
    .sort({ createdAt: -1 })
    .limit(100);
  res.json(logs.map(serialize));
});

// Thử gửi lại email thất bại (chỉ chủ việc, tối đa MAX_ATTEMPTS lần)
router.post('/email-logs/:id/retry', auth, async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: 'Mã nhật ký không hợp lệ' });
  }
  const notFound = () => res.status(404).json({ message: 'Không tìm thấy nhật ký email' });

  const log = await EmailLog.findById(req.params.id);
  if (!log) return notFound();
  const task = log.taskId ? await Task.findById(log.taskId) : null;
  if (!task || String(task.createdBy) !== String(req.user._id)) return notFound();

  if (log.status !== 'failed') {
    return res.status(409).json({ message: 'Chỉ có thể gửi lại email thất bại' });
  }
  if (log.attempts >= MAX_ATTEMPTS) {
    return res.status(409).json({ message: `Đã thử ${MAX_ATTEMPTS} lần, không gửi lại nữa` });
  }
  await deliver(log);
  res.json(serialize(log));
});

module.exports = router;