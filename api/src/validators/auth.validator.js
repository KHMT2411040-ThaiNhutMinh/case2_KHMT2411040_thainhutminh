const { body } = require('express-validator');

exports.registerRules = [
  body('fullName').trim().notEmpty().withMessage('Họ tên không được để trống'),
  body('email').trim().isEmail().withMessage('Email không hợp lệ'),
  body('password').isLength({ min: 6 }).withMessage('Mật khẩu tối thiểu 6 ký tự'),
];
exports.loginRules = [
  body('email').trim().isEmail().withMessage('Email không hợp lệ'),
  body('password').notEmpty().withMessage('Vui lòng nhập mật khẩu'),
];
exports.updateProfileRules = [
  body('fullName').trim().notEmpty().withMessage('Họ tên không được để trống'),
  body('avatarUrl')
    .optional({ values: 'falsy' })
    .trim()
    .isURL()
    .withMessage('Đường dẫn ảnh không hợp lệ'),
];
exports.changePasswordRules = [
  body('currentPassword').notEmpty().withMessage('Vui lòng nhập mật khẩu hiện tại'),
  body('newPassword').isLength({ min: 6 }).withMessage('Mật khẩu mới tối thiểu 6 ký tự'),
];