const express = require('express');
const mongoose = require('mongoose');
const Task = require('../models/task.model');
const auth = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');
const {
  createTaskRules,
  updateTaskRules,
  statusRules,
  PRIORITIES,
  STATUSES,
} = require('../validators/task.validator');

const router = express.Router();

// Mọi route công việc đều yêu cầu đăng nhập
router.use(auth);

const checkId = (req, res, next) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: 'Mã công việc không hợp lệ' });
  }
  next();
};

const INFO_FIELDS = ['title', 'description', 'priority', 'startDate', 'dueDate'];
const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const PRIORITY_RANK = { low: 1, medium: 2, high: 3 };

const findMine = (req) =>
  Task.findOne({ _id: req.params.id, createdBy: req.user._id });

// Danh sách: ?q=tên &status= &priority= &sort=createdAt|dueDate|priority &order=asc|desc
router.get('/', async (req, res) => {
  const { q, status, priority, sort, order } = req.query;

  const filter = { createdBy: req.user._id };
  if (typeof q === 'string' && q.trim()) {
    filter.title = { $regex: escapeRegex(q.trim()), $options: 'i' };
  }
  if (STATUSES.includes(status)) filter.status = status;
  if (PRIORITIES.includes(priority)) filter.priority = priority;

  const tasks = await Task.find(filter);

  const sortKey = ['dueDate', 'priority', 'createdAt'].includes(sort) ? sort : 'createdAt';
  // Mặc định: hạn gần nhất trước, ưu tiên cao trước, công việc mới nhất trước
  const defaultDir = sortKey === 'dueDate' ? 1 : -1;
  const dir = order === 'asc' ? 1 : order === 'desc' ? -1 : defaultDir;

  const keyOf = (t) => {
    if (sortKey === 'priority') return PRIORITY_RANK[t.priority];
    if (sortKey === 'dueDate') return t.dueDate ? t.dueDate.getTime() : null;
        return (t.createdAt || t._id.getTimestamp()).getTime();
  };

  tasks.sort((a, b) => {
    const ka = keyOf(a);
    const kb = keyOf(b);
    if (ka === null && kb === null) return 0;
    if (ka === null) return 1; // công việc chưa có hạn luôn nằm cuối
    if (kb === null) return -1;
    return (ka - kb) * dir;
  });

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
  const task = await findMine(req);
  if (!task) return res.status(404).json({ message: 'Không tìm thấy công việc' });
  res.status(200).json(task);
});

// Cập nhật thông tin công việc
router.put('/:id', checkId, updateTaskRules, validate, async (req, res) => {
  const task = await findMine(req);
  if (!task) return res.status(404).json({ message: 'Không tìm thấy công việc' });
  INFO_FIELDS.forEach((f) => {
    if (req.body[f] !== undefined) task[f] = req.body[f];
  });
  await task.save();
  res.status(200).json(task);
});

// Cập nhật trạng thái
router.patch('/:id/status', checkId, statusRules, validate, async (req, res) => {
  const task = await findMine(req);
  if (!task) return res.status(404).json({ message: 'Không tìm thấy công việc' });
  task.status = req.body.status;
  await task.save();
  res.status(200).json(task);
});

// Xóa công việc
router.delete('/:id', checkId, async (req, res) => {
  const task = await Task.findOneAndDelete({ _id: req.params.id, createdBy: req.user._id });
  if (!task) return res.status(404).json({ message: 'Không tìm thấy công việc' });
  res.status(200).json({ message: 'Đã xóa công việc' });
});

module.exports = router;