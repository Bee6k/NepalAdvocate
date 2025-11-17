const Document = require('../models/Document');
const createNotification = require('../utils/createNotification');
const path = require('path');
const fs = require('fs');

// @route   POST /api/documents/upload
// @desc    Upload a document
// @access  Private
exports.uploadDocument = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded',
      });
    }

    const { appointmentId, description, category } = req.body;

    const document = await Document.create({
      owner: req.user._id,
      appointment: appointmentId || null,
      fileName: req.file.filename,
      originalName: req.file.originalname,
      filePath: req.file.path,
      fileSize: req.file.size,
      mimeType: req.file.mimetype,
      description: description || '',
      category: category || 'other',
    });

    // If document is related to appointment, notify the other party
    if (appointmentId) {
      const Appointment = require('../models/Appointment');
      const appointment = await Appointment.findById(appointmentId);
      if (appointment) {
        const otherPartyId =
          appointment.client.toString() === req.user._id.toString()
            ? appointment.lawyer
            : appointment.client;

        await createNotification(
          otherPartyId,
          'DOCUMENT_UPLOADED',
          'New Document Uploaded',
          `${req.user.firstName} ${req.user.lastName} uploaded a document`,
          document._id,
          'document'
        );

        req.io.emit(`document:${otherPartyId}`, {
          type: 'DOCUMENT_UPLOADED',
          document: document,
        });
      }
    }

    res.status(201).json({
      success: true,
      message: 'Document uploaded successfully',
      data: { document },
    });
  } catch (error) {
    console.error('Upload document error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// @route   GET /api/documents/mine
// @desc    Get user's documents
// @access  Private
exports.getMyDocuments = async (req, res) => {
  try {
    const { appointmentId, category, page = 1, limit = 20 } = req.query;
    const query = { owner: req.user._id };

    if (appointmentId) {
      query.appointment = appointmentId;
    }

    if (category) {
      query.category = category;
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const documents = await Document.find(query)
      .populate('appointment')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Document.countDocuments(query);

    res.json({
      success: true,
      data: {
        documents,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (error) {
    console.error('Get documents error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// @route   GET /api/documents/:id
// @desc    Get single document
// @access  Private
exports.getDocument = async (req, res) => {
  try {
    const document = await Document.findById(req.params.id).populate('appointment');

    if (!document) {
      return res.status(404).json({
        success: false,
        message: 'Document not found',
      });
    }

    // Check authorization
    const isOwner = document.owner.toString() === req.user._id.toString();
    const isShared = document.isShared && document.sharedWith.includes(req.user._id);
    const isAdmin = req.user.role === 'ADMIN';

    if (!isOwner && !isShared && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Access denied',
      });
    }

    res.json({
      success: true,
      data: { document },
    });
  } catch (error) {
    console.error('Get document error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// @route   GET /api/documents/:id/download
// @desc    Download document file
// @access  Private
exports.downloadDocument = async (req, res) => {
  try {
    const document = await Document.findById(req.params.id);

    if (!document) {
      return res.status(404).json({
        success: false,
        message: 'Document not found',
      });
    }

    // Check authorization
    const isOwner = document.owner.toString() === req.user._id.toString();
    const isShared = document.isShared && document.sharedWith.includes(req.user._id);
    const isAdmin = req.user.role === 'ADMIN';

    if (!isOwner && !isShared && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Access denied',
      });
    }

    // Check if file exists
    if (!fs.existsSync(document.filePath)) {
      return res.status(404).json({
        success: false,
        message: 'File not found on server',
      });
    }

    res.download(document.filePath, document.originalName);
  } catch (error) {
    console.error('Download document error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// @route   DELETE /api/documents/:id
// @desc    Delete document
// @access  Private
exports.deleteDocument = async (req, res) => {
  try {
    const document = await Document.findById(req.params.id);

    if (!document) {
      return res.status(404).json({
        success: false,
        message: 'Document not found',
      });
    }

    // Check authorization
    const isOwner = document.owner.toString() === req.user._id.toString();
    const isAdmin = req.user.role === 'ADMIN';

    if (!isOwner && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Access denied',
      });
    }

    // Delete file from filesystem
    if (fs.existsSync(document.filePath)) {
      fs.unlinkSync(document.filePath);
    }

    await Document.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Document deleted successfully',
    });
  } catch (error) {
    console.error('Delete document error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

