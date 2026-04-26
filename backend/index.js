const express = require('express');
const cors    = require('cors');
const path    = require('path');
require('dotenv').config();
const { sequelize } = require('./config/database');

const app  = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.use('/notes',  require('./routes/notes'));
app.use('/upload', require('./routes/upload'));

app.get('/', (req, res) => res.json({ status: 'Notes API running', version: '1.0.0' }));

sequelize.sync().then(() => {
  app.listen(PORT, () => {
    console.log(`✅ Server running on http://localhost:${PORT}`);
    console.log(`📁 Uploads at  http://localhost:${PORT}/uploads`);
  });
}).catch(err => {
  console.error('❌ DB sync failed:', err.message);
  process.exit(1);
});
