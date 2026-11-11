const { body } = require('express-validator');

exports.registerRules = [
  body('fullName')
    .trim()
    .notEmpty()
    .withMessage('Họ tên không được để trống')
    .isLength({ max: 100 })
    .withMessage('Họ tên tối đa 100 ký tự'),
  body('email').trim().isEmail().withMessage('Email không hợp lệ'),
  body('password')
    .notEmpty()
    .withMessage('Mật khẩu không được để trống')
    .bail()
    .isString()
    .withMessage('Mật khẩu không hợp lệ')
    .bail()
    .isLength({ min: 6 })
    .withMessage('Mật khẩu tối thiểu 6 ký tự')
    .bail()
    .isLength({ max: 72 })
    .withMessage('Mật khẩu tối đa 72 ký tự'),
];

exports.loginRules = [
  body('email').trim().isEmail().withMessage('Email không hợp lệ'),
  body('password')
    .notEmpty()
    .withMessage('Vui lòng nhập mật khẩu')
    .bail()
    .isString()
    .withMessage('Mật khẩu không hợp lệ'),
];

exports.updateProfileRules = [
  body('fullName')
    .trim()
    .notEmpty()
    .withMessage('Họ tên không được để trống')
    .isLength({ max: 100 })
    .withMessage('Họ tên tối đa 100 ký tự'),
  body('avatarUrl')
    .optional({ values: 'falsy' })
    .trim()
    .isURL()
    .withMessage('Đường dẫn ảnh không hợp lệ'),
];

exports.changePasswordRules = [
  body('currentPassword')
    .notEmpty()
    .withMessage('Vui lòng nhập mật khẩu hiện tại')
    .bail()
    .isString()
    .withMessage('Mật khẩu hiện tại không hợp lệ'),
  body('newPassword')
    .notEmpty()
    .withMessage('Vui lòng nhập mật khẩu mới')
    .bail()
    .isString()
    .withMessage('Mật khẩu mới không hợp lệ')
    .bail()
    .isLength({ min: 6 })
    .withMessage('Mật khẩu mới tối thiểu 6 ký tự')
    .bail()
    .isLength({ max: 72 })
    .withMessage('Mật khẩu mới tối đa 72 ký tự'),
];