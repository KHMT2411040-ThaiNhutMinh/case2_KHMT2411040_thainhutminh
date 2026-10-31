const router = require('express').Router();
const { register } = require('../controllers/auth.controller');
const { registerRules } = require('../validators/auth.validator');
const validate = require('../middleware/validate.middleware');

router.post('/register', registerRules, validate, register);

module.exports = router;