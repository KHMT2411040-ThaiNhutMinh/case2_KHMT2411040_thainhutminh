const nodemailer = require('nodemailer');
const EmailLog = require('../models/emailLog.model');
const User = require('../models/user.model');

const MAX_ATTEMPTS = 3;
let transporter = null;

// Chỉ tạo khi đã cấu hình SMTP trong .env
function getTransporter() {
  if (!process.env.SMTP_HOST) return null;
  if (!transporter) {
    const port = Number(process.env.SMTP_PORT) || 587;
    transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port,
      secure: port === 465,
      auth: process.env.SMTP_USER
        ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
        : undefined,
      connectionTimeout: 10000,
      socketTimeout: 15000,
    });
  }
  return transporter;
}

// Thử gửi một email theo bản ghi nhật ký, luôn cập nhật status và attempts
async function deliver(log) {
  log.attempts += 1;
  const mailer = getTransporter();
  if (!mailer) {
    log.status = 'failed';
    log.errorMessage = 'Chưa cấu hình SMTP';
    await log.save();
    return log;
  }
  try {
    await mailer.sendMail({
      from: process.env.MAIL_FROM || 'Task Manager <no-reply@taskmanager.local>',
      to: log.recipientEmail,
      subject: log.subject,
      text: `${log.body}\n\nMở ứng dụng Task Manager để xem chi tiết.`,
    });
    log.status = 'sent';
    log.sentAt = new Date();
    log.errorMessage = '';
  } catch (err) {
    log.status = 'failed';
    log.errorMessage = String(err.message).slice(0, 300);
  }
  await log.save();
  return log;
}

// Tạo nhật ký (pending) rồi gửi cho từng người. Không bao giờ throw ra ngoài.
async function sendTaskEmails({ userIds, taskId, type, subject, text }) {
  const users = await User.find({ _id: { $in: userIds } });
  await Promise.allSettled(
    users.map(async (u) => {
      const log = await EmailLog.create({
        taskId,
        recipientEmail: u.email,
        eventType: type,
        subject,
        body: text,
        status: 'pending',
        attempts: 0,
      });
      await deliver(log);
    })
  );
}

module.exports = { sendTaskEmails, deliver, MAX_ATTEMPTS };