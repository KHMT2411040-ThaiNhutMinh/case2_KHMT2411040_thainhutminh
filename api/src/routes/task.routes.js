const express = require('express');
const Task = require('../models/task.model');
const User = require('../models/user.model');
const TaskShare = require('../models/taskShare.model');
const TaskActivity = require('../models/taskActivity.model');
const auth = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');
const requireTaskAccess = require('../middleware/taskAccess.middleware');
const { buildAccess, publicUser } = require('../utils/access');
const { logActivity } = require('../utils/activity');
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

router.use('/:id/assignees', require('./assignee.routes'));
router.use('/:id/shares', require('./share.routes'));

const INFO_FIELDS = ['title', 'description', 'priority', 'startDate', 'dueDate'];
const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const PRIORITY_RANK = { low: 1, medium: 2, high: 3 };

// Chuẩn hóa giá trị để so sánh trước và sau khi sửa
const norm = (field, v) => {
  if (v === undefined || v === null || v === '') return null;
  return field === 'startDate' || field === 'dueDate'
    ? new Date(v).toISOString()
    : String(v);
};

// Danh sách: ?q= &status= &priority= &role=created|assigned|shared
//            &sort=createdAt|dueDate|priority &order=asc|desc
router.get('/', async (req, res) => {
  const { q, status, priority, role, sort, order } = req.query;
  const me = req.user._id;

  const shares = await TaskShare.find({ userId: me }).select('taskId permission');
  const shareMap = new Map(shares.map((s) => [String(s.taskId), s.permission]));

  const byRole = {
    created: { createdBy: me },
    assigned: { assigneeIds: me },
    shared: { _id: { $in: [...shareMap.keys()] } },
  };
  const filter = { $or: byRole[role] ? [byRole[role]] : Object.values(byRole) };

  if (typeof q === 'string' && q.trim()) {
    filter.title = { $regex: escapeRegex(q.trim()), $options: 'i' };
  }
  if (STATUSES.includes(status)) filter.status = status;
  if (PRIORITIES.includes(priority)) filter.priority = priority;

  const tasks = await Task.find(filter);

  const sortKey = ['dueDate', 'priority', 'createdAt'].includes(sort) ? sort : 'createdAt';
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
    if (ka === null) return 1;
    if (kb === null) return -1;
    return (ka - kb) * dir;
  });

  res.status(200).json(
    tasks.map((t) => ({
      ...t.toObject(),
      access: buildAccess(t, me, shareMap.get(String(t._id))),
    }))
  );
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
  await logActivity(task._id, req.user._id, 'task_created', { title: task.title });
  res.status(201).json(task);
});

// Lịch sử hoạt động (ai có quyền xem công việc thì xem được)
router.get('/:id/activities', requireTaskAccess(), async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit, 10) || 50, 100);
  const items = await TaskActivity.find({ taskId: req.task._id })
    .sort({ createdAt: -1 })
    .limit(limit)
    .populate('userId');

  res.json(
    items.map((a) => ({
      _id: a._id,
      action: a.action,
      details: a.details,
      createdAt: a.createdAt,
      user: a.userId ? publicUser(a.userId) : null,
    }))
  );
});

// Chi tiết (cần quyền xem)
router.get('/:id', requireTaskAccess(), async (req, res) => {
  const creator = await User.findById(req.task.createdBy);
  res.status(200).json({
    ...req.task.toObject(),
    createdByUser: creator ? publicUser(creator) : null,
    access: req.access,
  });
});

// Cập nhật thông tin (owner hoặc editor)
router.put('/:id', requireTaskAccess('canEditInfo'), updateTaskRules, validate, async (req, res) => {
  const changes = {};
  INFO_FIELDS.forEach((f) => {
    if (req.body[f] === undefined) return;
    const before = norm(f, req.task[f]);
    const after = norm(f, req.body[f]);
    if (before !== after) changes[f] = { from: before, to: after };
    req.task[f] = req.body[f];
  });
  await req.task.save();
  if (Object.keys(changes).length > 0) {
    await logActivity(req.task._id, req.user._id, 'task_updated', { changes });
  }
  res.status(200).json(req.task);
});

// Cập nhật trạng thái (owner, editor hoặc người được giao)
router.patch(
  '/:id/status',
  requireTaskAccess('canChangeStatus'),
  statusRules,
  validate,
  async (req, res) => {
    const from = req.task.status;
    req.task.status = req.body.status;
    await req.task.save();
    if (from !== req.task.status) {
      await logActivity(req.task._id, req.user._id, 'status_changed', {
        from,
        to: req.task.status,
      });
    }
    res.status(200).json(req.task);
  }
);

// Xóa công việc (chỉ owner), kèm chia sẻ và lịch sử
router.delete('/:id', requireTaskAccess('canDelete'), async (req, res) => {
  await TaskShare.deleteMany({ taskId: req.task._id });
  await TaskActivity.deleteMany({ taskId: req.task._id });
  await req.task.deleteOne();
  res.status(200).json({ message: 'Đã xóa công việc' });
});

module.exports = router;