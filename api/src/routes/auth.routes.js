const router = require('express').Router();
const {
  register, login, getMe, updateMe, changePassword,
} = require('../controllers/auth.controller');
const {
  registerRules, loginRules, updateProfileRules, changePasswordRules,
} = require('../validators/auth.validator');
const validate = require('../middleware/validate.middleware');
const auth = require('../middleware/auth.middleware');

router.post('/register', registerRules, validate, register);
router.post('/login', loginRules, validate, login);
router.get('/me', auth, getMe);
router.put('/me', auth, updateProfileRules, validate, updateMe);
router.put('/change-password', auth, changePasswordRules, validate, changePassword);

module.exports = router;