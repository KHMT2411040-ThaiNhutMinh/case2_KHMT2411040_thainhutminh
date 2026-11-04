const TaskActivity = require('../models/taskActivity.model');
const { notifyForActivity } = require('./notify');

// Ghi lịch sử và tạo thông báo; lỗi ở đây không được làm hỏng thao tác chính
async function logActivity(taskId, userId, action, details = {}) {
  try {
    await TaskActivity.create({ taskId, userId, action, details });
  } catch (err) {
    console.error('Không ghi được lịch sử hoạt động:', err.message);
  }
  try {
    await notifyForActivity(taskId, userId, action, details);
  } catch (err) {
    console.error('Không tạo được thông báo:', err.message);
  }
}

module.exports = { logActivity };