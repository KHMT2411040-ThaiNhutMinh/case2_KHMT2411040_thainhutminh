const express = require('express');
const mongoose = require('mongoose');
const Task = require('../models/task.model');
const auth = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');
const { createTaskRules, updateTaskRules } = require('../validators/task.validator');

const router = express.Router();

// Mọi route công việc đều yêu cầu đăng nhập
router.use(auth);

const checkId = (req, res, next) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: 'Mã công việc không hợp lệ' });
  }
  next();
};

const EDITABLE = ['title', 'description', 'priority', 'status', 'startDate', 'dueDate'];

// Danh sách công việc của chính người đăng nhập
router.get('/', async (req, res) => {
  const tasks = await Task.find({ createdBy: req.user._id }).sort({ createdAt: -1 });
  res.status(200).json(tasks);
});

// Tạo công việc
router.post('/', createTaskRules, validate, async (req, res) => {
  const { title, description, priority, status, startDate, dueDate } = req.body;
  const task = await Task.create({
    title,
    description,
    priority,
    status,
    startDate,
    dueDate,
    createdBy: req.user._id,
  });
  res.status(201).json(task);
});

// Chi tiết một công việc
router.get('/:id', checkId, async (req, res) => {
  const task = await Task.findOne({ _id: req.params.id, createdBy: req.user._id });
  if (!task) {
    return res.status(404).json({ message: 'Không tìm thấy công việc' });
  }
  res.status(200).json(task);
});

// Cập nhật công việc (chỉ gửi các trường cần đổi)
router.patch('/:id', checkId, updateTaskRules, validate, async (req, res) => {
  const task = await Task.findOne({ _id: req.params.id, createdBy: req.user._id });
  if (!task) {
    return res.status(404).json({ message: 'Không tìm thấy công việc' });
  }
  EDITABLE.forEach((f) => {
    if (req.body[f] !== undefined) task[f] = req.body[f];
  });
  await task.save();
  res.status(200).json(task);
});

// Xóa công việc
router.delete('/:id', checkId, async (req, res) => {
  const task = await Task.findOneAndDelete({ _id: req.params.id, createdBy: req.user._id });
  if (!task) {
    return res.status(404).json({ message: 'Không tìm thấy công việc' });
  }
  res.status(200).json({ message: 'Đã xóa công việc' });
});

module.exports = router;