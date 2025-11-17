const LawyerProfile = require('../models/LawyerProfile');
const User = require('../models/User');

// @route   GET /api/lawyers
// @desc    Get all lawyers with filters
// @access  Public (or Private)
exports.getLawyers = async (req, res) => {
  try {
    const { specialization, search, minRating, page = 1, limit = 20 } = req.query;

    const query = { isVerified: true };
    const userQuery = { role: 'LAWYER', isActive: true };

    if (specialization) {
      query.specialization = { $in: [specialization] };
    }

    if (minRating) {
      query.rating = { $gte: parseFloat(minRating) };
    }

    if (search) {
      userQuery.$or = [
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const lawyerProfiles = await LawyerProfile.find(query)
      .populate({
        path: 'user',
        match: userQuery,
        select: 'firstName lastName email phone profilePicture',
      })
      .sort({ rating: -1, totalReviews: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    // Filter out null users
    const filteredLawyers = lawyerProfiles.filter((lp) => lp.user !== null);

    const total = await LawyerProfile.countDocuments(query);

    res.json({
      success: true,
      data: {
        lawyers: filteredLawyers,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (error) {
    console.error('Get lawyers error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// @route   GET /api/lawyers/:id
// @desc    Get lawyer profile by ID
// @access  Public
exports.getLawyerById = async (req, res) => {
  try {
    const lawyerProfile = await LawyerProfile.findOne({ user: req.params.id })
      .populate('user', 'firstName lastName email phone profilePicture');

    if (!lawyerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Lawyer not found',
      });
    }

    res.json({
      success: true,
      data: { lawyer: lawyerProfile },
    });
  } catch (error) {
    console.error('Get lawyer error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// @route   PATCH /api/lawyers/profile
// @desc    Update lawyer profile
// @access  Private (Lawyer only)
exports.updateProfile = async (req, res) => {
  try {
    if (req.user.role !== 'LAWYER') {
      return res.status(403).json({
        success: false,
        message: 'Only lawyers can update their profile',
      });
    }

    const lawyerProfile = await LawyerProfile.findOne({ user: req.user._id });

    if (!lawyerProfile) {
      return res.status(404).json({
        success: false,
        message: 'Lawyer profile not found',
      });
    }

    const allowedUpdates = [
      'specialization',
      'experience',
      'hourlyRate',
      'bio',
      'education',
      'languages',
      'availability',
    ];

    allowedUpdates.forEach((field) => {
      if (req.body[field] !== undefined) {
        lawyerProfile[field] = req.body[field];
      }
    });

    await lawyerProfile.save();
    await lawyerProfile.populate('user', 'firstName lastName email phone profilePicture');

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: { lawyer: lawyerProfile },
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

