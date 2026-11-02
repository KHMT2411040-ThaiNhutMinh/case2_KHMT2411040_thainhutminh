const TaskActivity = require('../models/taskActivity.model');

// Ghi lịch sử không được làm hỏng thao tác chính nếu bị lỗi
async function logActivity(taskId, userId, action, details = {}) {
  try {
    await TaskActivity.create({ taskId, userId, action, details });
  } catch (err) {
    console.error('Không ghi được lịch sử hoạt động:', err.message);
  }
}

module.exports = { logActivity };