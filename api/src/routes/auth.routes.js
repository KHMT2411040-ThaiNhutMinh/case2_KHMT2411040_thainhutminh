const router = require('express').Router();
const { register, login, getMe, updateMe } = require('../controllers/auth.controller');
const { registerRules, loginRules, updateProfileRules } = require('../validators/auth.validator');
const validate = require('../middleware/validate.middleware');
const auth = require('../middleware/auth.middleware');

router.post('/register', registerRules, validate, register);
router.post('/login', loginRules, validate, login);
router.get('/me', auth, getMe);
router.put('/me', auth, updateProfileRules, validate, updateMe);

module.exports = router;