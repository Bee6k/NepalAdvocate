require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');
const connectDB = require('./config/database');
const { authenticateJWT } = require('./middlewares/auth');
const { handleSocketMessage } = require('./controllers/chatController');

// Import routes
const authRoutes = require('./routes/auth');
const appointmentRoutes = require('./routes/appointments');
const chatRoutes = require('./routes/chat');
const documentRoutes = require('./routes/documents');
const lawyerRoutes = require('./routes/lawyers');
const templateRoutes = require('./routes/templates');
const notificationRoutes = require('./routes/notifications');
const adminRoutes = require('./routes/admin');

// Connect to database
connectDB();

// Initialize Express app
const app = express();
const server = http.createServer(app);

// Initialize Socket.IO
const io = new Server(server, {
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST'],
  },
});

// Make io available to routes via req.io
app.use((req, res, next) => {
  req.io = io;
  next();
});

// Middlewares
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true,
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/documents', documentRoutes);
app.use('/api/lawyers', lawyerRoutes);
app.use('/api/templates', templateRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin', adminRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'NepalAdvocate API is running' });
});

// Socket.IO authentication middleware
io.use(async (socket, next) => {
  try {
    const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.substring(7);

    if (!token) {
      return next(new Error('Authentication error: No token provided'));
    }

    const { verifyToken } = require('./config/jwt');
    const User = require('./models/User');

    const decoded = verifyToken(token);
    const user = await User.findById(decoded.userId).select('-password');

    if (!user || !user.isActive) {
      return next(new Error('Authentication error: Invalid user'));
    }

    socket.userId = user._id.toString();
    socket.userRole = user.role;
    next();
  } catch (error) {
    next(new Error('Authentication error: Invalid token'));
  }
});

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log(`User connected: ${socket.userId}`);

  // Join user-specific room
  socket.join(`user:${socket.userId}`);

  // Handle joining conversation rooms
  socket.on('joinConversation', async (conversationId) => {
    const Conversation = require('./models/Conversation');
    const conversation = await Conversation.findById(conversationId);

    if (conversation && conversation.participants.includes(socket.userId)) {
      socket.join(`conversation:${conversationId}`);
      socket.emit('joinedConversation', { conversationId });
    } else {
      socket.emit('error', { message: 'Invalid conversation or access denied' });
    }
  });

  // Handle leaving conversation rooms
  socket.on('leaveConversation', (conversationId) => {
    socket.leave(`conversation:${conversationId}`);
  });

  // Handle sending messages
  socket.on('sendMessage', async (data) => {
    await handleSocketMessage(io, socket, data);
  });

  // Handle typing indicator
  socket.on('typing', (data) => {
    socket.to(`conversation:${data.conversationId}`).emit('userTyping', {
      userId: socket.userId,
      isTyping: data.isTyping,
    });
  });

  // Handle disconnection
  socket.on('disconnect', () => {
    console.log(`User disconnected: ${socket.userId}`);
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal Server Error',
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
  });
});

const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

