const express = require("express");
const { authenticate } = require("../middleware/auth");
const asyncHandler = require("../utils/asyncHandler");
const {
  login,
  me,
  solicitarRecuperacion,
  restablecerContrasena,
  cambiarContrasena,
} = require("../controllers/auth.controller");

const router = express.Router();

router.post("/login", asyncHandler(login));
router.post("/recuperar", asyncHandler(solicitarRecuperacion));
router.post("/restablecer", asyncHandler(restablecerContrasena));

router.get("/me", authenticate, asyncHandler(me));
router.post("/cambiar-contrasena", authenticate, asyncHandler(cambiarContrasena));

module.exports = router;
