const router = require("express").Router();
const Note = require("../models/Note");

router.get("/", async (req, res) => {
  res.json(await Note.findAll());
});
router.get("/:id", async (req, res) => {
  res.json(await Note.findByPk(req.params.id));
});
router.post("/", async (req, res) => {
  res.status(201).json(await Note.create(req.body));
});
router.put("/:id", async (req, res) => {
  await Note.update(req.body, { where: { id: req.params.id } });
  res.json(await Note.findByPk(req.params.id));
});
router.delete("/:id", async (req, res) => {
  await Note.destroy({ where: { id: req.params.id } });
  res.json({ message: "Deleted" });
});

module.exports = router;
