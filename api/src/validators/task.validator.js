const { body } = require('express-validator');

const PRIORITIES = ['low', 'medium', 'high'];
const STATUSES = ['todo', 'in_progress', 'completed'];

const info = [
  body('title').trim().notEmpty().withMessage('Tên công việc không được để trống'),
  body('description').optional().isString().withMessage('Mô tả không hợp lệ'),
  body('priority').optional().isIn(PRIORITIES).withMessage('Mức ưu tiên không hợp lệ'),
  body('startDate')
    .optional({ values: 'null' })
    .isISO8601()
    .withMessage('Ngày bắt đầu không hợp lệ'),
  body('dueDate')
    .optional({ values: 'null' })
    .isISO8601()
    .withMessage('Hạn hoàn thành không hợp lệ'),
  body('dueDate').custom((value, { req }) => {
    if (value && req.body.startDate && new Date(value) < new Date(req.body.startDate)) {
      throw new Error('Hạn hoàn thành phải sau ngày bắt đầu');
    }
    return true;
  }),
];

// POST /tasks (trạng thái ban đầu là tùy chọn)
exports.createTaskRules = [
  ...info,
  body('status').optional().isIn(STATUSES).withMessage('Trạng thái không hợp lệ'),
];

// PUT /tasks/:id (không đổi trạng thái ở đây)
exports.updateTaskRules = info;

// PATCH /tasks/:id/status
exports.statusRules = [
  body('status').isIn(STATUSES).withMessage('Trạng thái không hợp lệ'),
];

exports.PRIORITIES = PRIORITIES;
exports.STATUSES = STATUSES;