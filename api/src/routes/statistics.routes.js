const express = require('express');
const Task = require('../models/task.model');
const TaskShare = require('../models/taskShare.model');
const auth = require('../middleware/auth.middleware');

const router = express.Router();
router.use(auth);

const sameId = (a, b) => String(a) === String(b);

const countByStatus = (tasks) => {
  const c = { total: 0, todo: 0, in_progress: 0, completed: 0 };
  tasks.forEach((t) => {
    c.total += 1;
    if (c[t.status] !== undefined) c[t.status] += 1;
  });
  return c;
};

// Mọi công việc người dùng nhìn thấy: tự tạo, được giao, được chia sẻ
async function visibleTasks(userId) {
  const shares = await TaskShare.find({ userId }).select('taskId');
  return Task.find({
    $or: [
      { createdBy: userId },
      { assigneeIds: userId },
      { _id: { $in: shares.map((s) => s.taskId) } },
    ],
  }).select('title status priority dueDate assigneeIds primaryAssigneeId');
}

// Thống kê theo trạng thái
router.get('/tasks', async (req, res) => {
  const tasks = await visibleTasks(req.user._id);
  res.json(countByStatus(tasks));
});

// Việc được giao cho tôi và việc tôi đang phụ trách chính
router.get('/assignments', async (req, res) => {
  const me = req.user._id;
  const tasks = await visibleTasks(me);
  const assigned = tasks.filter((t) => t.assigneeIds.some((id) => sameId(id, me)));
  const primary = tasks.filter((t) => t.primaryAssigneeId && sameId(t.primaryAssigneeId, me));
  res.json({ assigned: countByStatus(assigned), primary: countByStatus(primary) });
});

// Việc quá hạn và sắp đến hạn: ?days=7 (1 đến 60)
router.get('/deadlines', async (req, res) => {
  const days = Math.min(Math.max(parseInt(req.query.days, 10) || 7, 1), 60);
  const now = new Date();
  const limit = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);

  const tasks = await visibleTasks(req.user._id);
  const open = tasks.filter((t) => t.status !== 'completed');
  const withDue = open.filter((t) => t.dueDate);

  const brief = (t) => ({
    _id: t._id,
    title: t.title,
    status: t.status,
    priority: t.priority,
    dueDate: t.dueDate,
  });
  const nearestFirst = (a, b) => a.dueDate - b.dueDate;

  const overdue = withDue.filter((t) => t.dueDate < now).sort(nearestFirst);
  const dueSoon = withDue
    .filter((t) => t.dueDate >= now && t.dueDate <= limit)
    .sort(nearestFirst);

  res.json({
    days,
    overdue: { count: overdue.length, items: overdue.slice(0, 5).map(brief) },
    dueSoon: { count: dueSoon.length, items: dueSoon.slice(0, 5).map(brief) },
    noDueDate: open.filter((t) => !t.dueDate).length,
  });
});

module.exports = router;