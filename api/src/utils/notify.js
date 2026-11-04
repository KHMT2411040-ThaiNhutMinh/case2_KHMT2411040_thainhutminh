const Notification = require('../models/notification.model');
const Task = require('../models/task.model');
const TaskShare = require('../models/taskShare.model');
const User = require('../models/user.model');
const { sendTaskEmails } = require('./mailer');

const STATUS_TEXT = {
  todo: 'Chưa thực hiện',
  in_progress: 'Đang thực hiện',
  completed: 'Đã hoàn thành',
};
const PERMISSION_TEXT = { viewer: 'chỉ xem', editor: 'chỉnh sửa' };

// Loại sự kiện có gửi email (đổi trạng thái thường chỉ thông báo trong app)
const EMAIL_TYPES = new Set([
  'task_assigned',
  'task_shared',
  'task_completed',
  'due_date_changed',
]);

// Chủ việc + người được giao + người được chia sẻ
async function participantIds(task) {
  const shares = await TaskShare.find({ taskId: task._id }).select('userId');
  const ids = new Set([
    String(task.createdBy),
    ...task.assigneeIds.map(String),
    ...shares.map((s) => String(s.userId)),
  ]);
  return [...ids];
}

// Tạo thông báo (và email) cho nhiều người, bỏ qua chính người thực hiện
async function createMany(userIds, actorId, task, type, title, message) {
  const targets = [...new Set(userIds.map(String))].filter(
    (id) => id !== String(actorId)
  );
  if (targets.length === 0) return;
  await Notification.insertMany(
    targets.map((userId) => ({ userId, taskId: task._id, type, title, message }))
  );

  if (EMAIL_TYPES.has(type)) {
    // Gửi nền, không chờ, để SMTP chậm hay lỗi không ảnh hưởng thao tác chính
    sendTaskEmails({
      userIds: targets,
      taskId: task._id,
      type,
      subject: title,
      text: message,
    }).catch((err) => console.error('Gửi email thất bại:', err.message));
  }
}

async function notifyForActivity(taskId, actorId, action, details = {}) {
  const task = await Task.findById(taskId);
  if (!task) return;
  const actor = await User.findById(actorId);
  const who = actor ? actor.fullName : 'Ai đó';

  switch (action) {
    case 'task_assigned':
      return createMany(
        details.userIds || [],
        actorId,
        task,
        'task_assigned',
        'Bạn được giao việc mới',
        `${who} đã giao cho bạn công việc "${task.title}"`
      );

    case 'task_shared':
      return createMany(
        details.userIds || [],
        actorId,
        task,
        'task_shared',
        'Bạn được chia sẻ công việc',
        `${who} đã chia sẻ công việc "${task.title}" cho bạn (${
          PERMISSION_TEXT[details.permission] || details.permission
        })`
      );

    case 'status_changed': {
      const done = details.to === 'completed';
      return createMany(
        await participantIds(task),
        actorId,
        task,
        done ? 'task_completed' : 'status_changed',
        done ? 'Công việc đã hoàn thành' : 'Trạng thái công việc thay đổi',
        done
          ? `${who} đã hoàn thành công việc "${task.title}"`
          : `${who} đã đổi trạng thái công việc "${task.title}" sang "${
              STATUS_TEXT[details.to] || details.to
            }"`
      );
    }

    case 'task_updated':
      if (details.changes && details.changes.dueDate) {
        return createMany(
          await participantIds(task),
          actorId,
          task,
          'due_date_changed',
          'Hạn hoàn thành thay đổi',
          `${who} đã đổi hạn hoàn thành của công việc "${task.title}"`
        );
      }
      return;

    default:
      return;
  }
}

module.exports = { notifyForActivity };