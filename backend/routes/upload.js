const router = require('express').Router();
const multer = require('multer');
const path = require('path');

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename:    (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
  fileFilter: (req, file, cb) => {
    console.log('Incoming file:', file.originalname, 'MIME:', file.mimetype);
    // Accept all files for now to debug the Android physical device issue
    cb(null, true);
  },
});

router.post('/', upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'Upload failed. No file received.' });
  }
  const PORT = process.env.PORT || 3000;
  res.json({ file_url: `http://localhost:${PORT}/uploads/${req.file.filename}` });
});

module.exports = router;
