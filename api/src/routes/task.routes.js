const express = require('express');
const mongoose = require('mongoose');
const Task = require('../models/task.model');
const auth = require('../middleware/auth.middleware');

const router = express.Router();

// Mọi route công việc đều yêu cầu đăng nhập
router.use(auth);

// Danh sách công việc của chính người đăng nhập
router.get('/', async (req, res) => {
  const tasks = await Task.find({ createdBy: req.user._id }).sort({ createdAt: -1 });
  res.status(200).json(tasks);
});

// Chi tiết một công việc
router.get('/:id', async (req, res) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: 'Mã công việc không hợp lệ' });
  }
  const task = await Task.findOne({ _id: req.params.id, createdBy: req.user._id });
  if (!task) {
    return res.status(404).json({ message: 'Không tìm thấy công việc' });
  }
  res.status(200).json(task);
});

module.exports = router;