const express = require('express');
const router = express.Router();
const {
  getLawyers,
  getLawyerById,
  updateProfile,
} = require('../controllers/lawyerController');
const { authenticateJWT, authorizeRoles } = require('../middlewares/auth');

router.get('/', getLawyers);
router.get('/:id', getLawyerById);
router.patch('/profile', authenticateJWT, authorizeRoles('LAWYER'), updateProfile);

module.exports = router;

