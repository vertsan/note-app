const express = require("express");
const cors = require("cors");
const path = require("path");
require("dotenv").config();
const { sequelize } = require("./config/database");

const app = express();
app.use(cors());
app.use(express.json());
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

app.use("/notes", require("./routes/notes"));
app.use("/upload", require("./routes/upload"));

sequelize.sync().then(() => {
  app.listen(3000, () => console.log("Server running on port 3000"));
});
