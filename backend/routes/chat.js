const express = require('express');
const router = express.Router();
const {
  getConversations,
  getMessages,
} = require('../controllers/chatController');
const { authenticateJWT } = require('../middlewares/auth');

router.get('/conversations', authenticateJWT, getConversations);
router.get('/conversations/:conversationId/messages', authenticateJWT, getMessages);

module.exports = router;

