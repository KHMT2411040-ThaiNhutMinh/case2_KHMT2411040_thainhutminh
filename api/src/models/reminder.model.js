const mongoose = require('mongoose');

const reminderSchema = new mongoose.Schema(
  {
    taskId: { type: mongoose.Schema.Types.ObjectId, ref: 'Task', required: true },
    dueDate: { type: Date, required: true },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

// Mỗi (công việc, hạn) chỉ được nhắc một lần
reminderSchema.index({ taskId: 1, dueDate: 1 }, { unique: true });

module.exports = mongoose.model('Reminder', reminderSchema);