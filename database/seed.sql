-- =====================================================================
-- APEX GYM - Datos iniciales (seed)
-- Ejecutar despues de schema.sql
-- =====================================================================

USE apex_gym;

-- ---------------------------------------------------------------------
-- ROLES
-- ---------------------------------------------------------------------
INSERT INTO roles (nombre_rol, descripcion) VALUES
  ('Administrador', 'Acceso total al sistema'),
  ('Recepcionista', 'Gestion de clientes, membresias, pagos y POS'),
  ('Entrenador', 'Gestion de sus clases, reservas y asistencia'),
  ('Cliente', 'Portal web: membresia, pagos y reservas propias');

-- ---------------------------------------------------------------------
-- PERMISOS (por modulo)
-- ---------------------------------------------------------------------
INSERT INTO permisos (nombre_permiso, modulo, descripcion) VALUES
  ('usuarios.gestionar',    'seguridad',   'Crear, editar y desactivar usuarios y roles'),
  ('clientes.gestionar',    'clientes',    'CRUD de clientes'),
  ('membresias.gestionar',  'membresias',  'CRUD de membresias, asignacion y renovacion'),
  ('pagos.gestionar',       'pagos',       'Registrar pagos y ver historial'),
  ('entrenadores.gestionar','entrenadores','CRUD de entrenadores'),
  ('clases.gestionar',      'clases',      'CRUD de clases y reservas'),
  ('asistencia.gestionar',  'asistencia',  'Registrar y consultar asistencia'),
  ('pos.vender',            'pos',         'Realizar ventas en el punto de venta'),
  ('inventario.gestionar',  'inventario',  'CRUD de productos, categorias y marcas'),
  ('compras.gestionar',     'compras',     'CRUD de compras y proveedores'),
  ('cuentas_cobrar.gestionar', 'finanzas', 'Gestionar cuentas por cobrar y abonos'),
  ('reportes.ver',          'reportes',    'Ver reportes y dashboard'),
  ('configuracion.gestionar','sistema',    'Editar configuracion general del sistema'),
  ('portal.propio',         'portal',      'Ver su propia membresia, pagos y reservas (cliente)');

-- ---------------------------------------------------------------------
-- ROL_PERMISO
-- ---------------------------------------------------------------------
-- Administrador: todos los permisos
INSERT INTO rol_permiso (id_rol, id_permiso)
SELECT 1, id_permiso FROM permisos;

-- Recepcionista: operacion diaria (sin seguridad ni configuracion)
INSERT INTO rol_permiso (id_rol, id_permiso)
SELECT 2, id_permiso FROM permisos
WHERE nombre_permiso IN (
  'clientes.gestionar','membresias.gestionar','pagos.gestionar',
  'clases.gestionar','asistencia.gestionar','pos.vender',
  'inventario.gestionar','compras.gestionar','cuentas_cobrar.gestionar','reportes.ver'
);

-- Entrenador: su modulo y asistencia
INSERT INTO rol_permiso (id_rol, id_permiso)
SELECT 3, id_permiso FROM permisos
WHERE nombre_permiso IN ('clases.gestionar','asistencia.gestionar','reportes.ver');

-- Cliente: solo su portal
INSERT INTO rol_permiso (id_rol, id_permiso)
SELECT 4, id_permiso FROM permisos
WHERE nombre_permiso = 'portal.propio';

-- ---------------------------------------------------------------------
-- USUARIO ADMINISTRADOR POR DEFECTO
-- Correo: admin@apexgym.do | Contrasena: Admin123!
-- IMPORTANTE: cambiar esta contrasena en el primer inicio de sesion.
-- ---------------------------------------------------------------------
INSERT INTO usuarios (nombre, apellido, correo, contrasena_hash, id_rol, estado) VALUES
  ('Admin', 'Principal', 'admin@apexgym.do',
   '$2a$10$XfANmbQiXz0Cif60kQH67OAcB8DTjxQPQTLmL1oEk7BPZQyZaizBu',
   1, 'Activo');

-- ---------------------------------------------------------------------
-- MEMBRESIAS (catalogo, igual a los planes mostrados en la landing page)
-- ---------------------------------------------------------------------
INSERT INTO membresias (nombre, descripcion, precio, duracion_dias) VALUES
  ('Basico',   'Acceso a sala de pesas y cardio, horario estandar', 1500.00, 30),
  ('Premium',  'Acceso ilimitado 24/7, clases grupales incluidas',  2500.00, 30),
  ('VIP Elite','Entrenador personal dedicado, zona VIP',            4200.00, 30);

-- ---------------------------------------------------------------------
-- CATEGORIAS Y MARCAS (inventario POS)
-- ---------------------------------------------------------------------
INSERT INTO categorias (nombre, descripcion) VALUES
  ('Suplementos', 'Proteinas, creatina, aminoacidos'),
  ('Bebidas', 'Hidratacion y bebidas energeticas'),
  ('Accesorios', 'Guantes, cinturones, straps'),
  ('Ropa Deportiva', 'Uniformes y ropa de entrenamiento');

INSERT INTO marcas (nombre) VALUES
  ('Optimum Nutrition'), ('Gatorade'), ('Under Armour'), ('Genérica');

-- ---------------------------------------------------------------------
-- CONFIGURACION GENERAL
-- ---------------------------------------------------------------------
INSERT INTO configuracion (clave, valor, descripcion) VALUES
  ('nombre_gimnasio',      'APEX GYM',                 'Nombre comercial mostrado en el sistema'),
  ('moneda',               'RD$',                      'Simbolo de moneda utilizado en POS y pagos'),
  ('impuesto_porcentaje',  '18',                       'ITBIS aplicado en ventas (%)'),
  ('horario_apertura',     '06:00',                    'Hora de apertura'),
  ('horario_cierre',       '22:00',                    'Hora de cierre'),
  ('dias_gracia_vencimiento', '3',                      'Dias de gracia antes de marcar membresia como vencida');
