const cron = require('node-cron');
const Task = require('../models/task.model');
const Reminder = require('../models/reminder.model');
const { createMany } = require('../utils/notify');

const hours = () => Number(process.env.REMINDER_HOURS) || 24;

const fmt = (d) =>
  new Date(d).toLocaleString('vi-VN', {
    timeZone: 'Asia/Ho_Chi_Minh',
    hour12: false,
  });

// Tìm công việc sắp đến hạn và nhắc người phụ trách. Trả về số công việc đã nhắc.
async function runReminders() {
  await Reminder.init(); // bảo đảm chỉ mục duy nhất đã sẵn sàng

  const now = new Date();
  const limit = new Date(now.getTime() + hours() * 60 * 60 * 1000);

  const tasks = await Task.find({
    status: { $ne: 'completed' },
    dueDate: { $gt: now, $lte: limit },
  });

  let count = 0;
  for (const task of tasks) {
    // Ghi nhận trước; nếu đã có (cùng công việc, cùng hạn) thì bỏ qua để không nhắc trùng
    try {
      await Reminder.create({ taskId: task._id, dueDate: task.dueDate });
    } catch (err) {
      if (err.code === 11000) continue;
      console.error('Không ghi được nhắc việc:', err.message);
      continue;
    }

    const recipients =
      task.assigneeIds.length > 0 ? task.assigneeIds : [task.createdBy];

    try {
      await createMany(
        recipients,
        null, // hệ thống tự nhắc nên không có người thực hiện để loại trừ
        task,
        'due_reminder',
        'Công việc sắp đến hạn',
        `Công việc "${task.title}" sẽ đến hạn lúc ${fmt(task.dueDate)}`
      );
      count += 1;
    } catch (err) {
      console.error('Không tạo được thông báo nhắc việc:', err.message);
    }
  }
  return count;
}

function startReminderJob() {
  const expr = process.env.REMINDER_CRON || '*/5 * * * *';
  if (!cron.validate(expr)) {
    console.error('REMINDER_CRON không hợp lệ:', expr);
    return;
  }
  cron.schedule(expr, () => {
    runReminders()
      .then((n) => {
        if (n > 0) console.log(`Đã nhắc ${n} công việc sắp đến hạn`);
      })
      .catch((err) => console.error('Lỗi nhắc việc:', err.message));
  });
  console.log(`Nhắc việc: lịch "${expr}", trước hạn ${hours()} giờ`);
}

module.exports = { startReminderJob, runReminders };