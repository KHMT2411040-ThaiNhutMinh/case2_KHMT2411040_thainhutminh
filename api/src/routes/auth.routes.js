const router = require('express').Router();
const { register, login, getMe } = require('../controllers/auth.controller');
const { registerRules, loginRules } = require('../validators/auth.validator');
const validate = require('../middleware/validate.middleware');
const auth = require('../middleware/auth.middleware');

router.post('/register', registerRules, validate, register);
router.post('/login', loginRules, validate, login);
router.get('/me', auth, getMe);

module.exports = router;