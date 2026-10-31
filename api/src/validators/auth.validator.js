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