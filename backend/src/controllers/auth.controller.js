const crypto = require("crypto");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const pool = require("../config/db");

async function getPermisosDeRol(id_rol) {
  const [rows] = await pool.query(
    `SELECT p.nombre_permiso
     FROM rol_permiso rp
     JOIN permisos p ON p.id_permiso = rp.id_permiso
     WHERE rp.id_rol = ?`,
    [id_rol]
  );
  return rows.map((r) => r.nombre_permiso);
}

function firmarToken(usuario, permisos) {
  return jwt.sign(
    {
      id_usuario: usuario.id_usuario,
      nombre: usuario.nombre,
      apellido: usuario.apellido,
      correo: usuario.correo,
      id_rol: usuario.id_rol,
      nombre_rol: usuario.nombre_rol,
      permisos,
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || "8h" }
  );
}

async function login(req, res) {
  const { correo, contrasena } = req.body;
  if (!correo || !contrasena) {
    return res.status(400).json({ error: "Correo y contrasena son requeridos" });
  }

  const [rows] = await pool.query(
    `SELECT u.*, r.nombre_rol
     FROM usuarios u
     JOIN roles r ON r.id_rol = u.id_rol
     WHERE u.correo = ?`,
    [correo]
  );
  const usuario = rows[0];

  if (!usuario || usuario.estado !== "Activo") {
    return res.status(401).json({ error: "Credenciales invalidas" });
  }

  const contrasenaValida = await bcrypt.compare(contrasena, usuario.contrasena_hash);
  if (!contrasenaValida) {
    return res.status(401).json({ error: "Credenciales invalidas" });
  }

  const permisos = await getPermisosDeRol(usuario.id_rol);
  const token = firmarToken(usuario, permisos);

  await pool.query("UPDATE usuarios SET ultimo_acceso = NOW() WHERE id_usuario = ?", [
    usuario.id_usuario,
  ]);

  res.json({
    token,
    usuario: {
      id_usuario: usuario.id_usuario,
      nombre: usuario.nombre,
      apellido: usuario.apellido,
      correo: usuario.correo,
      rol: usuario.nombre_rol,
      permisos,
    },
  });
}

async function me(req, res) {
  res.json({ usuario: req.user });
}

async function solicitarRecuperacion(req, res) {
  const { correo } = req.body;
  if (!correo) return res.status(400).json({ error: "Correo requerido" });

  const [rows] = await pool.query("SELECT id_usuario FROM usuarios WHERE correo = ?", [correo]);
  const usuario = rows[0];

  // Respuesta generica: no revelamos si el correo existe o no.
  if (usuario) {
    const token = crypto.randomBytes(32).toString("hex");
    const expira = new Date(Date.now() + 30 * 60 * 1000); // 30 minutos

    await pool.query(
      "UPDATE usuarios SET token_recuperacion = ?, token_expira = ? WHERE id_usuario = ?",
      [token, expira, usuario.id_usuario]
    );

    // NOTA: aqui se integraria un servicio de correo (SMTP) para enviar el enlace.
    // Por ahora se registra en consola para pruebas locales del equipo.
    console.log(`[recuperacion] Enlace para ${correo}: /restablecer?token=${token}`);

    if (process.env.NODE_ENV !== "production") {
      return res.json({
        mensaje: "Si el correo existe, se enviara un enlace de recuperacion.",
        _dev_token: token,
      });
    }
  }

  res.json({ mensaje: "Si el correo existe, se enviara un enlace de recuperacion." });
}

async function restablecerContrasena(req, res) {
  const { token, nueva_contrasena } = req.body;
  if (!token || !nueva_contrasena) {
    return res.status(400).json({ error: "Token y nueva contrasena son requeridos" });
  }

  const [rows] = await pool.query(
    "SELECT id_usuario FROM usuarios WHERE token_recuperacion = ? AND token_expira > NOW()",
    [token]
  );
  const usuario = rows[0];
  if (!usuario) {
    return res.status(400).json({ error: "Token invalido o expirado" });
  }

  const hash = await bcrypt.hash(nueva_contrasena, 10);
  await pool.query(
    "UPDATE usuarios SET contrasena_hash = ?, token_recuperacion = NULL, token_expira = NULL WHERE id_usuario = ?",
    [hash, usuario.id_usuario]
  );

  res.json({ mensaje: "Contrasena actualizada correctamente" });
}

async function cambiarContrasena(req, res) {
  const { contrasena_actual, contrasena_nueva } = req.body;
  if (!contrasena_actual || !contrasena_nueva) {
    return res.status(400).json({ error: "Ambas contrasenas son requeridas" });
  }

  const [rows] = await pool.query("SELECT contrasena_hash FROM usuarios WHERE id_usuario = ?", [
    req.user.id_usuario,
  ]);
  const usuario = rows[0];

  const valida = await bcrypt.compare(contrasena_actual, usuario.contrasena_hash);
  if (!valida) {
    return res.status(401).json({ error: "La contrasena actual es incorrecta" });
  }

  const hash = await bcrypt.hash(contrasena_nueva, 10);
  await pool.query("UPDATE usuarios SET contrasena_hash = ? WHERE id_usuario = ?", [
    hash,
    req.user.id_usuario,
  ]);

  res.json({ mensaje: "Contrasena cambiada correctamente" });
}

module.exports = {
  login,
  me,
  solicitarRecuperacion,
  restablecerContrasena,
  cambiarContrasena,
};
