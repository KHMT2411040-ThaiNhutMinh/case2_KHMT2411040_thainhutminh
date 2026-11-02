const express = require('express');
const mongoose = require('mongoose');
const { body } = require('express-validator');
const User = require('../models/user.model');
const validate = require('../middleware/validate.middleware');
const requireTaskAccess = require('../middleware/taskAccess.middleware');
const { publicUser } = require('../utils/access');
const { logActivity } = require('../utils/activity');

const router = express.Router({ mergeParams: true });

const serialize = async (task) => {
  const users = await User.find({ _id: { $in: task.assigneeIds } });
  return users.map((u) => ({
    user: publicUser(u),
    isPrimary: String(task.primaryAssigneeId) === String(u._id),
  }));
};

const assignRules = [
  body('userIds').isArray({ min: 1 }).withMessage('Danh sách người dùng không hợp lệ'),
  body('userIds.*')
    .custom((v) => mongoose.isValidObjectId(v))
    .withMessage('Mã người dùng không hợp lệ'),
];

// Danh sách người được giao
router.get('/', requireTaskAccess(), async (req, res) => {
  res.json(await serialize(req.task));
});

// Giao việc cho một hoặc nhiều người
router.post('/', requireTaskAccess('canManage'), assignRules, validate, async (req, res) => {
  const ids = [...new Set(req.body.userIds.map(String))];
  const found = await User.countDocuments({ _id: { $in: ids } });
  if (found !== ids.length) {
    return res.status(400).json({ message: 'Có người dùng không tồn tại' });
  }

  const task = req.task;
  const before = new Set(task.assigneeIds.map(String));
  const added = ids.filter((id) => !before.has(id));

  const current = new Set(before);
  ids.forEach((id) => current.add(id));
  task.assigneeIds = [...current];
  // Người đầu tiên được giao tự động là người phụ trách chính
  if (!task.primaryAssigneeId && task.assigneeIds.length > 0) {
    task.primaryAssigneeId = task.assigneeIds[0];
  }
  await task.save();

  if (added.length > 0) {
    await logActivity(task._id, req.user._id, 'task_assigned', { userIds: added });
  }
  res.status(201).json(await serialize(task));
});

// Chỉ định hoặc bỏ chỉ định người phụ trách chính
router.patch(
  '/:userId',
  requireTaskAccess('canManage'),
  body('isPrimary').isBoolean().withMessage('Giá trị isPrimary không hợp lệ'),
  validate,
  async (req, res) => {
    const task = req.task;
    const { userId } = req.params;
    if (!task.assigneeIds.some((id) => String(id) === userId)) {
      return res.status(404).json({ message: 'Người này chưa được giao việc' });
    }
    if (req.body.isPrimary === true) {
      task.primaryAssigneeId = userId;
    } else if (String(task.primaryAssigneeId) === userId) {
      task.primaryAssigneeId = undefined;
    }
    await task.save();
    await logActivity(task._id, req.user._id, 'primary_changed', {
      userId,
      isPrimary: req.body.isPrimary === true,
    });
    res.json(await serialize(task));
  }
);

// Hủy giao việc cho một người
router.delete('/:userId', requireTaskAccess('canManage'), async (req, res) => {
  const task = req.task;
  const { userId } = req.params;
  if (!task.assigneeIds.some((id) => String(id) === userId)) {
    return res.status(404).json({ message: 'Người này chưa được giao việc' });
  }
  task.assigneeIds = task.assigneeIds.filter((id) => String(id) !== userId);
  if (String(task.primaryAssigneeId) === userId) {
    task.primaryAssigneeId = task.assigneeIds[0]; // người kế tiếp, hoặc rỗng nếu hết
  }
  await task.save();
  await logActivity(task._id, req.user._id, 'assignee_removed', { userId });
  res.json(await serialize(task));
});

module.exports = router;