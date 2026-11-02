const TaskShare = require('../models/taskShare.model');

const sameId = (a, b) => String(a) === String(b);

// Tính quyền của một người trên một công việc
function buildAccess(task, userId, sharePermission) {
  const isOwner = sameId(task.createdBy, userId);
  const isAssignee = (task.assigneeIds || []).some((id) => sameId(id, userId));

  let role = null;
  if (isOwner) role = 'owner';
  else if (sharePermission === 'editor') role = 'editor';
  else if (isAssignee) role = 'assignee';
  else if (sharePermission === 'viewer') role = 'viewer';

  return {
    role,
    canView: role !== null,
    canEditInfo: isOwner || sharePermission === 'editor',
    canChangeStatus: isOwner || sharePermission === 'editor' || isAssignee,
    canDelete: isOwner,
    canManage: isOwner,
  };
}

async function resolveAccess(task, userId) {
  const share = await TaskShare.findOne({ taskId: task._id, userId });
  return buildAccess(task, userId, share ? share.permission : undefined);
}

// Chỉ trả các trường công khai của người dùng
const publicUser = (u) => ({
  _id: u._id,
  fullName: u.fullName,
  email: u.email,
  avatarUrl: u.avatarUrl,
});

module.exports = { buildAccess, resolveAccess, publicUser };