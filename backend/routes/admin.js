const express = require('express');
const router = express.Router();
const {
  getStats,
  getUsers,
  updateUserStatus,
  verifyLawyer,
} = require('../controllers/adminController');
const { authenticateJWT, authorizeRoles } = require('../middlewares/auth');

// All admin routes require authentication and ADMIN role
router.use(authenticateJWT);
router.use(authorizeRoles('ADMIN'));

router.get('/stats', getStats);
router.get('/users', getUsers);
router.patch('/users/:id/status', updateUserStatus);
router.patch('/lawyers/:id/verify', verifyLawyer);

module.exports = router;

