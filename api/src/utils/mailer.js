const nodemailer = require('nodemailer');
const EmailLog = require('../models/emailLog.model');
const User = require('../models/user.model');

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

async function saveLog(data) {
  try {
    await EmailLog.create(data);
  } catch (err) {
    console.error('Không ghi được email_logs:', err.message);
  }
}

// Gửi email cho nhiều người, mỗi email ghi một dòng nhật ký. Không bao giờ throw.
async function sendTaskEmails({ userIds, taskId, type, subject, text }) {
  const users = await User.find({ _id: { $in: userIds } });
  const mailer = getTransporter();
  const from = process.env.MAIL_FROM || 'Task Manager <no-reply@taskmanager.local>';

  await Promise.allSettled(
    users.map(async (u) => {
      const base = { userId: u._id, taskId, type, to: u.email, subject };

      if (!mailer) {
        return saveLog({ ...base, status: 'skipped', error: 'Chưa cấu hình SMTP' });
      }
      try {
        await mailer.sendMail({
          from,
          to: u.email,
          subject,
          text: `${text}\n\nMở ứng dụng Task Manager để xem chi tiết.`,
        });
        await saveLog({ ...base, status: 'sent', sentAt: new Date() });
      } catch (err) {
        await saveLog({ ...base, status: 'failed', error: String(err.message).slice(0, 300) });
      }
    })
  );
}

module.exports = { sendTaskEmails };