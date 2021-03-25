const express = require('express');
const router = express.Router();
const workerProfileController = require('../controller/workerProfile.controller');
router.post('/getAttribute',workerProfileController.getAttribute);


module.exports = router;
