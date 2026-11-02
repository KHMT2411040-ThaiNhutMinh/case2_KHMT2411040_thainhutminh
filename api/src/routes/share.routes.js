const express = require('express');
const mongoose = require('mongoose');
const { body } = require('express-validator');
const User = require('../models/user.model');
const TaskShare = require('../models/taskShare.model');
const validate = require('../middleware/validate.middleware');
const requireTaskAccess = require('../middleware/taskAccess.middleware');
const { publicUser } = require('../utils/access');
const { logActivity } = require('../utils/activity');

const router = express.Router({ mergeParams: true });

const serialize = async (taskId) => {
  const shares = await TaskShare.find({ taskId }).populate('userId');
  return shares
    .filter((s) => s.userId)
    .map((s) => ({
      _id: s._id,
      user: publicUser(s.userId),
      permission: s.permission,
      createdAt: s.createdAt,
    }));
};

const permissionRule = body('permission')
  .isIn(['viewer', 'editor'])
  .withMessage('Quyền chia sẻ không hợp lệ');

const shareRules = [
  body('userIds').isArray({ min: 1 }).withMessage('Danh sách người dùng không hợp lệ'),
  body('userIds.*')
    .custom((v) => mongoose.isValidObjectId(v))
    .withMessage('Mã người dùng không hợp lệ'),
  permissionRule,
];

const checkShareId = (req, res, next) => {
  if (!mongoose.isValidObjectId(req.params.shareId)) {
    return res.status(400).json({ message: 'Mã chia sẻ không hợp lệ' });
  }
  next();
};

// Danh sách người được chia sẻ
router.get('/', requireTaskAccess(), async (req, res) => {
  res.json(await serialize(req.task._id));
});

// Chia sẻ cho một hoặc nhiều người (đã chia sẻ rồi thì cập nhật quyền)
router.post('/', requireTaskAccess('canManage'), shareRules, validate, async (req, res) => {
  const ids = [...new Set(req.body.userIds.map(String))];
  const found = await User.countDocuments({ _id: { $in: ids } });
  if (found !== ids.length) {
    return res.status(400).json({ message: 'Có người dùng không tồn tại' });
  }

  const targets = ids.filter((id) => id !== String(req.task.createdBy)); // không chia sẻ cho chính chủ
  for (const uid of targets) {
    await TaskShare.findOneAndUpdate(
      { taskId: req.task._id, userId: uid },
      {
        $set: { permission: req.body.permission },
        $setOnInsert: { sharedBy: req.user._id },
      },
      { upsert: true }
    );
  }
  if (targets.length > 0) {
    await logActivity(req.task._id, req.user._id, 'task_shared', {
      userIds: targets,
      permission: req.body.permission,
    });
  }
  res.status(201).json(await serialize(req.task._id));
});

// Đổi quyền viewer/editor
router.patch(
  '/:shareId',
  checkShareId,
  requireTaskAccess('canManage'),
  permissionRule,
  validate,
  async (req, res) => {
    const share = await TaskShare.findOne({ _id: req.params.shareId, taskId: req.task._id });
    if (!share) return res.status(404).json({ message: 'Không tìm thấy bản ghi chia sẻ' });

    const from = share.permission;
    share.permission = req.body.permission;
    await share.save();
    if (from !== share.permission) {
      await logActivity(req.task._id, req.user._id, 'share_changed', {
        userId: share.userId,
        from,
        to: share.permission,
      });
    }
    res.json(await serialize(req.task._id));
  }
);

// Thu hồi quyền
router.delete('/:shareId', checkShareId, requireTaskAccess('canManage'), async (req, res) => {
  const share = await TaskShare.findOneAndDelete({
    _id: req.params.shareId,
    taskId: req.task._id,
  });
  if (!share) return res.status(404).json({ message: 'Không tìm thấy bản ghi chia sẻ' });
  await logActivity(req.task._id, req.user._id, 'share_revoked', { userId: share.userId });
  res.json({ message: 'Đã thu hồi quyền chia sẻ' });
});

module.exports = router;