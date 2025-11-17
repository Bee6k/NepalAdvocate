const express = require('express');
const router = express.Router();
const {
  uploadDocument,
  getMyDocuments,
  getDocument,
  downloadDocument,
  deleteDocument,
} = require('../controllers/documentController');
const { authenticateJWT } = require('../middlewares/auth');
const upload = require('../middlewares/upload');

router.post('/upload', authenticateJWT, upload.single('file'), uploadDocument);
router.get('/mine', authenticateJWT, getMyDocuments);
router.get('/:id', authenticateJWT, getDocument);
router.get('/:id/download', authenticateJWT, downloadDocument);
router.delete('/:id', authenticateJWT, deleteDocument);

module.exports = router;

