const User = require('../models/User');
const LawyerProfile = require('../models/LawyerProfile');
const Appointment = require('../models/Appointment');
const LegalTemplate = require('../models/LegalTemplate');
const Document = require('../models/Document');

// @route   GET /api/admin/stats
// @desc    Get admin dashboard statistics
// @access  Private (Admin only)
exports.getStats = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const totalClients = await User.countDocuments({ role: 'CLIENT' });
    const totalLawyers = await User.countDocuments({ role: 'LAWYER' });
    const totalAppointments = await Appointment.countDocuments();
    const totalTemplates = await LegalTemplate.countDocuments();
    const totalDocuments = await Document.countDocuments();

    const appointmentsByStatus = await Appointment.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
        },
      },
    ]);

    res.json({
      success: true,
      data: {
        stats: {
          totalUsers,
          totalClients,
          totalLawyers,
          totalAppointments,
          totalTemplates,
          totalDocuments,
          appointmentsByStatus,
        },
      },
    });
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// @route   GET /api/admin/users
// @desc    Get all users (Admin)
// @access  Private (Admin only)
exports.getUsers = async (req, res) => {
  try {
    const { role, page = 1, limit = 20 } = req.query;

    const query = {};
    if (role) {
      query.role = role;
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const users = await User.find(query)
      .select('-password')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await User.countDocuments(query);

    res.json({
      success: true,
      data: {
        users,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// @route   PATCH /api/admin/users/:id/status
// @desc    Update user status (Admin)
// @access  Private (Admin only)
exports.updateUserStatus = async (req, res) => {
  try {
    const { isActive } = req.body;
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { isActive },
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    res.json({
      success: true,
      message: 'User status updated',
      data: { user },
    });
  } catch (error) {
    console.error('Update user status error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// @route   PATCH /api/admin/lawyers/:id/verify
// @desc    Verify lawyer (Admin)
// @access  Private (Admin only)
exports.verifyLawyer = async (req, res) => {
  try {
    const lawyerProfile = await LawyerProfile.findOneAndUpdate(
      { user: req.params.id },
      { isVerified: true },
      { new: true }
    ).populate('user', 'firstName lastName email');

    if (!lawyerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Lawyer profile not found',
      });
    }

    res.json({
      success: true,
      message: 'Lawyer verified successfully',
      data: { lawyer: lawyerProfile },
    });
  } catch (error) {
    console.error('Verify lawyer error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

