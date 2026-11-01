const { body } = require('express-validator');

const PRIORITIES = ['low', 'medium', 'high'];
const STATUSES = ['todo', 'in_progress', 'completed'];

const common = [
  body('description').optional().isString().withMessage('Mô tả không hợp lệ'),
  body('priority').optional().isIn(PRIORITIES).withMessage('Mức ưu tiên không hợp lệ'),
  body('status').optional().isIn(STATUSES).withMessage('Trạng thái không hợp lệ'),
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

exports.createTaskRules = [
  body('title').trim().notEmpty().withMessage('Tên công việc không được để trống'),
  ...common,
];

exports.updateTaskRules = [
  body('title').optional().trim().notEmpty().withMessage('Tên công việc không được để trống'),
  ...common,
];