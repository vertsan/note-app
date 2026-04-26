const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();
const { sequelize } = require('./config/database');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Serve uploaded files statically
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
app.use('/notes', require('./routes/notes'));
app.use('/upload', require('./routes/upload'));

// Health check
app.get('/', (req, res) => {
  res.json({ status: 'Notes API is running', version: '1.0.0' });
});

// Sync DB then start server
sequelize.sync().then(() => {
  app.listen(PORT, () => {
    console.log(`✅ Server running on http://localhost:${PORT}`);
    console.log(`📁 Uploads served at http://localhost:${PORT}/uploads`);
  });
}).catch((err) => {
  console.error('❌ Failed to sync database:', err);
  process.exit(1);
});
