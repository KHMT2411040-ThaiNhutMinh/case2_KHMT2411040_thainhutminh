const express = require('express');
const cors = require('cors'); // MỚI
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const authRoutes = require('./routes/auth.routes'); // MỚI
const errorMiddleware = require('./middleware/error.middleware'); // MỚI

dotenv.config();

const app = express();

app.use(cors()); // MỚI
app.use(express.json());

mongoose
  .connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('MongoDB connected');
  })
  .catch((error) => {
    console.error('MongoDB connection error:', error);
  });

app.get('/', (req, res) => {
  res.json({
    message: 'Task Manager API is running',
  });
});

app.use('/api/auth', authRoutes); // MỚI

app.use(errorMiddleware); // MỚI (luôn đặt sau cùng các route)

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});