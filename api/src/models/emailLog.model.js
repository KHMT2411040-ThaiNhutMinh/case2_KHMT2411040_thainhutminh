const mongoose = require('mongoose');

const emailLogSchema = new mongoose.Schema(
  {
    taskId: { type: mongoose.Schema.Types.ObjectId, ref: 'Task', default: null },
    recipientEmail: { type: String, required: true },
    eventType: { type: String, required: true },
    subject: { type: String, required: true },
    body: { type: String, default: '' },
    status: { type: String, enum: ['pending', 'sent', 'failed'], default: 'pending' },
    attempts: { type: Number, default: 0 },
    errorMessage: { type: String, default: '' },
    sentAt: { type: Date },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

emailLogSchema.index({ taskId: 1, createdAt: -1 });

module.exports = mongoose.model('EmailLog', emailLogSchema);