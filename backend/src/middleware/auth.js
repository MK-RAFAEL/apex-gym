const jwt = require("jsonwebtoken");

function authenticate(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;

  if (!token) {
    return res.status(401).json({ error: "Token no proporcionado" });
  }

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch (err) {
    return res.status(401).json({ error: "Token invalido o expirado" });
  }
}

function authorize(...permisosRequeridos) {
  return (req, res, next) => {
    const permisosUsuario = req.user?.permisos || [];
    const tienePermiso = permisosRequeridos.some((p) => permisosUsuario.includes(p));
    if (!tienePermiso) {
      return res.status(403).json({ error: "No tienes permiso para esta accion" });
    }
    next();
  };
}

module.exports = { authenticate, authorize };
