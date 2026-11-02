const mongoose = require('mongoose');
const Task = require('../models/task.model');
const { resolveAccess } = require('../utils/access');

// requireTaskAccess()            : chỉ cần xem được
// requireTaskAccess('canDelete') : cần thêm quyền cụ thể
module.exports = (capability) => async (req, res, next) => {
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(400).json({ message: 'Mã công việc không hợp lệ' });
  }
  const task = await Task.findById(req.params.id);
  if (!task) {
    return res.status(404).json({ message: 'Không tìm thấy công việc' });
  }

  const access = await resolveAccess(task, req.user._id);
  if (!access.canView) {
    // Không tiết lộ công việc có tồn tại hay không
    return res.status(404).json({ message: 'Không tìm thấy công việc' });
  }
  if (capability && !access[capability]) {
    return res.status(403).json({ message: 'Bạn không có quyền thực hiện thao tác này' });
  }

  req.task = task;
  req.access = access;
  next();
};