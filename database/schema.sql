-- =====================================================================
-- APEX GYM - Sistema de Gestion de Gimnasio
-- Script SQL de creacion de base de datos
-- Motor: MySQL 8.0 | Charset: utf8mb4 | Engine: InnoDB
-- Normalizado hasta Tercera Forma Normal (3FN)
-- =====================================================================

CREATE DATABASE IF NOT EXISTS apex_gym
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE apex_gym;

SET FOREIGN_KEY_CHECKS = 0;

-- =====================================================================
-- SEGURIDAD: usuarios, roles, permisos
-- =====================================================================

-- Catalogo de roles del sistema (Administrador, Recepcionista, Entrenador, Cliente...)
CREATE TABLE roles (
  id_rol       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_rol   VARCHAR(50)  NOT NULL UNIQUE,
  descripcion  VARCHAR(255) NULL,
  estado       ENUM('Activo','Inactivo') NOT NULL DEFAULT 'Activo',
  creado_en    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Catalogo de permisos granulares por modulo (clientes.crear, pos.vender, reportes.ver...)
CREATE TABLE permisos (
  id_permiso     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_permiso VARCHAR(80)  NOT NULL UNIQUE,
  modulo         VARCHAR(50)  NOT NULL,
  descripcion    VARCHAR(255) NULL
) ENGINE=InnoDB;

-- Relacion N:M entre roles y permisos
CREATE TABLE rol_permiso (
  id_rol     INT UNSIGNED NOT NULL,
  id_permiso INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_rol, id_permiso),
  CONSTRAINT fk_rolpermiso_rol     FOREIGN KEY (id_rol)     REFERENCES roles(id_rol)       ON DELETE CASCADE,
  CONSTRAINT fk_rolpermiso_permiso FOREIGN KEY (id_permiso) REFERENCES permisos(id_permiso) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Cuentas de acceso al sistema (staff y clientes con portal web)
CREATE TABLE usuarios (
  id_usuario         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre             VARCHAR(80)  NOT NULL,
  apellido           VARCHAR(80)  NOT NULL,
  correo             VARCHAR(120) NOT NULL UNIQUE,
  contrasena_hash    VARCHAR(255) NOT NULL,
  id_rol             INT UNSIGNED NOT NULL,
  estado             ENUM('Activo','Inactivo','Suspendido') NOT NULL DEFAULT 'Activo',
  token_recuperacion VARCHAR(255) NULL,
  token_expira       DATETIME NULL,
  ultimo_acceso      DATETIME NULL,
  fecha_creacion     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES roles(id_rol)
) ENGINE=InnoDB;

CREATE INDEX idx_usuarios_rol ON usuarios(id_rol);

-- =====================================================================
-- CLIENTES
-- =====================================================================

CREATE TABLE clientes (
  id_cliente      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_usuario      INT UNSIGNED NULL UNIQUE,
  nombre          VARCHAR(80)  NOT NULL,
  apellido        VARCHAR(80)  NOT NULL,
  cedula          VARCHAR(20)  NOT NULL UNIQUE,
  telefono        VARCHAR(20)  NULL,
  correo          VARCHAR(120) NULL,
  direccion       VARCHAR(255) NULL,
  fecha_nacimiento DATE NULL,
  sexo            ENUM('M','F','Otro') NULL,
  foto            VARCHAR(255) NULL,
  fecha_registro  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado          ENUM('Activo','Inactivo') NOT NULL DEFAULT 'Activo',
  CONSTRAINT fk_cliente_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_clientes_nombre ON clientes(nombre, apellido);

-- =====================================================================
-- MEMBRESIAS
-- =====================================================================

-- Catalogo de planes de membresia (Basico, Premium, VIP Elite...)
CREATE TABLE membresias (
  id_membresia   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre         VARCHAR(60)  NOT NULL,
  descripcion    VARCHAR(255) NULL,
  precio         DECIMAL(10,2) NOT NULL CHECK (precio >= 0),
  duracion_dias  SMALLINT UNSIGNED NOT NULL,
  estado         ENUM('Activo','Inactivo') NOT NULL DEFAULT 'Activo'
) ENGINE=InnoDB;

-- Historial de asignacion/renovacion de membresias por cliente
CREATE TABLE cliente_membresia (
  id_cliente_membresia INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_cliente     INT UNSIGNED NOT NULL,
  id_membresia   INT UNSIGNED NOT NULL,
  fecha_inicio   DATE NOT NULL,
  fecha_fin      DATE NOT NULL,
  estado         ENUM('Activa','Vencida','Cancelada') NOT NULL DEFAULT 'Activa',
  fecha_renovacion TIMESTAMP NULL,
  CONSTRAINT fk_climemb_cliente   FOREIGN KEY (id_cliente)   REFERENCES clientes(id_cliente),
  CONSTRAINT fk_climemb_membresia FOREIGN KEY (id_membresia) REFERENCES membresias(id_membresia),
  CONSTRAINT chk_climemb_fechas CHECK (fecha_fin >= fecha_inicio)
) ENGINE=InnoDB;

CREATE INDEX idx_climemb_cliente ON cliente_membresia(id_cliente);
CREATE INDEX idx_climemb_estado  ON cliente_membresia(estado);

-- =====================================================================
-- ENTRENADORES, CLASES, RESERVAS, ASISTENCIA
-- =====================================================================

CREATE TABLE entrenadores (
  id_entrenador     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_usuario        INT UNSIGNED NULL UNIQUE,
  nombre            VARCHAR(80)  NOT NULL,
  apellido          VARCHAR(80)  NOT NULL,
  cedula            VARCHAR(20)  NOT NULL UNIQUE,
  telefono          VARCHAR(20)  NULL,
  correo            VARCHAR(120) NULL,
  especialidad      VARCHAR(100) NULL,
  fecha_contratacion DATE NULL,
  estado            ENUM('Activo','Inactivo') NOT NULL DEFAULT 'Activo',
  CONSTRAINT fk_entrenador_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE clases (
  id_clase        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre          VARCHAR(80)  NOT NULL,
  descripcion     VARCHAR(255) NULL,
  id_entrenador   INT UNSIGNED NOT NULL,
  capacidad_maxima SMALLINT UNSIGNED NOT NULL DEFAULT 20,
  dia_semana      ENUM('Lunes','Martes','Miercoles','Jueves','Viernes','Sabado','Domingo') NOT NULL,
  hora_inicio     TIME NOT NULL,
  hora_fin        TIME NOT NULL,
  estado          ENUM('Activa','Cancelada') NOT NULL DEFAULT 'Activa',
  CONSTRAINT fk_clase_entrenador FOREIGN KEY (id_entrenador) REFERENCES entrenadores(id_entrenador),
  CONSTRAINT chk_clase_horas CHECK (hora_fin > hora_inicio)
) ENGINE=InnoDB;

CREATE INDEX idx_clases_entrenador ON clases(id_entrenador);

CREATE TABLE reservas (
  id_reserva    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_clase      INT UNSIGNED NOT NULL,
  id_cliente    INT UNSIGNED NOT NULL,
  fecha_reserva TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_clase   DATE NOT NULL,
  estado        ENUM('Reservada','Cancelada','Asistio','No Asistio') NOT NULL DEFAULT 'Reservada',
  CONSTRAINT fk_reserva_clase   FOREIGN KEY (id_clase)   REFERENCES clases(id_clase),
  CONSTRAINT fk_reserva_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
  CONSTRAINT uq_reserva_unica UNIQUE (id_clase, id_cliente, fecha_clase)
) ENGINE=InnoDB;

CREATE INDEX idx_reservas_cliente ON reservas(id_cliente);

-- Registro de asistencia general al gimnasio (check-in/check-out), opcionalmente ligado a una clase reservada
CREATE TABLE asistencia (
  id_asistencia INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_cliente    INT UNSIGNED NOT NULL,
  id_reserva    INT UNSIGNED NULL,
  fecha         DATE NOT NULL,
  hora_entrada  TIME NOT NULL,
  hora_salida   TIME NULL,
  CONSTRAINT fk_asistencia_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
  CONSTRAINT fk_asistencia_reserva FOREIGN KEY (id_reserva) REFERENCES reservas(id_reserva) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE INDEX idx_asistencia_cliente_fecha ON asistencia(id_cliente, fecha);

-- =====================================================================
-- PAGOS (membresias, servicios)
-- =====================================================================

CREATE TABLE pagos (
  id_pago              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_cliente            INT UNSIGNED NOT NULL,
  id_cliente_membresia  INT UNSIGNED NULL,
  id_usuario            INT UNSIGNED NOT NULL COMMENT 'Usuario que registro el pago',
  fecha_pago            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  metodo_pago            ENUM('Efectivo','Tarjeta','Transferencia','Cheque') NOT NULL,
  monto_total            DECIMAL(10,2) NOT NULL CHECK (monto_total >= 0),
  numero_recibo          VARCHAR(30) NOT NULL UNIQUE,
  estado                 ENUM('Completado','Anulado') NOT NULL DEFAULT 'Completado',
  CONSTRAINT fk_pago_cliente   FOREIGN KEY (id_cliente)           REFERENCES clientes(id_cliente),
  CONSTRAINT fk_pago_climemb   FOREIGN KEY (id_cliente_membresia) REFERENCES cliente_membresia(id_cliente_membresia),
  CONSTRAINT fk_pago_usuario   FOREIGN KEY (id_usuario)           REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB;

CREATE INDEX idx_pagos_cliente ON pagos(id_cliente);

-- Detalle/desglose de conceptos dentro de un mismo pago
CREATE TABLE pagos_detalle (
  id_detalle_pago INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_pago         INT UNSIGNED NOT NULL,
  concepto        VARCHAR(120) NOT NULL,
  cantidad        SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  monto           DECIMAL(10,2) NOT NULL CHECK (monto >= 0),
  CONSTRAINT fk_pagodetalle_pago FOREIGN KEY (id_pago) REFERENCES pagos(id_pago) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
-- INVENTARIO: categorias, marcas, productos
-- =====================================================================

CREATE TABLE categorias (
  id_categoria INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre       VARCHAR(60) NOT NULL UNIQUE,
  descripcion  VARCHAR(255) NULL,
  estado       ENUM('Activo','Inactivo') NOT NULL DEFAULT 'Activo'
) ENGINE=InnoDB;

CREATE TABLE marcas (
  id_marca INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre   VARCHAR(60) NOT NULL UNIQUE,
  estado   ENUM('Activo','Inactivo') NOT NULL DEFAULT 'Activo'
) ENGINE=InnoDB;

CREATE TABLE productos (
  id_producto    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  codigo         VARCHAR(30)  NOT NULL UNIQUE,
  codigo_barras  VARCHAR(30)  NULL UNIQUE,
  nombre         VARCHAR(120) NOT NULL,
  descripcion    VARCHAR(255) NULL,
  id_categoria   INT UNSIGNED NOT NULL,
  id_marca       INT UNSIGNED NULL,
  precio_compra  DECIMAL(10,2) NOT NULL CHECK (precio_compra >= 0),
  precio_venta   DECIMAL(10,2) NOT NULL CHECK (precio_venta >= 0),
  stock          INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
  stock_minimo   INT NOT NULL DEFAULT 5,
  imagen         VARCHAR(255) NULL,
  estado         ENUM('Activo','Inactivo') NOT NULL DEFAULT 'Activo',
  CONSTRAINT fk_producto_categoria FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria),
  CONSTRAINT fk_producto_marca     FOREIGN KEY (id_marca)     REFERENCES marcas(id_marca)
) ENGINE=InnoDB;

CREATE INDEX idx_productos_categoria ON productos(id_categoria);

-- =====================================================================
-- PROVEEDORES Y COMPRAS
-- =====================================================================

CREATE TABLE proveedores (
  id_proveedor INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre       VARCHAR(120) NOT NULL,
  contacto     VARCHAR(80)  NULL,
  telefono     VARCHAR(20)  NULL,
  correo       VARCHAR(120) NULL,
  direccion    VARCHAR(255) NULL,
  estado       ENUM('Activo','Inactivo') NOT NULL DEFAULT 'Activo'
) ENGINE=InnoDB;

CREATE TABLE compras (
  id_compra    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_proveedor INT UNSIGNED NOT NULL,
  id_usuario   INT UNSIGNED NOT NULL,
  fecha        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  subtotal     DECIMAL(10,2) NOT NULL DEFAULT 0,
  impuesto     DECIMAL(10,2) NOT NULL DEFAULT 0,
  total        DECIMAL(10,2) NOT NULL DEFAULT 0,
  estado       ENUM('Pendiente','Recibida','Cancelada') NOT NULL DEFAULT 'Pendiente',
  CONSTRAINT fk_compra_proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor),
  CONSTRAINT fk_compra_usuario   FOREIGN KEY (id_usuario)   REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB;

CREATE TABLE compra_detalle (
  id_detalle_compra INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_compra      INT UNSIGNED NOT NULL,
  id_producto    INT UNSIGNED NOT NULL,
  cantidad       INT UNSIGNED NOT NULL CHECK (cantidad > 0),
  precio_compra  DECIMAL(10,2) NOT NULL CHECK (precio_compra >= 0),
  subtotal       DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
  CONSTRAINT fk_compradetalle_compra   FOREIGN KEY (id_compra)   REFERENCES compras(id_compra) ON DELETE CASCADE,
  CONSTRAINT fk_compradetalle_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
) ENGINE=InnoDB;

-- =====================================================================
-- POS: VENTAS
-- =====================================================================

CREATE TABLE ventas (
  id_venta   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  fecha      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_cliente INT UNSIGNED NULL COMMENT 'NULL permite venta a consumidor final sin registrar',
  id_usuario INT UNSIGNED NOT NULL COMMENT 'Cajero que proceso la venta',
  tipo_pago  ENUM('Contado','Credito') NOT NULL DEFAULT 'Contado',
  subtotal   DECIMAL(10,2) NOT NULL DEFAULT 0,
  descuento  DECIMAL(10,2) NOT NULL DEFAULT 0,
  impuesto   DECIMAL(10,2) NOT NULL DEFAULT 0,
  total      DECIMAL(10,2) NOT NULL DEFAULT 0,
  estado     ENUM('Completada','Anulada') NOT NULL DEFAULT 'Completada',
  CONSTRAINT fk_venta_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
  CONSTRAINT fk_venta_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB;

CREATE INDEX idx_ventas_cliente ON ventas(id_cliente);
CREATE INDEX idx_ventas_fecha   ON ventas(fecha);

CREATE TABLE venta_detalle (
  id_detalle  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_venta    INT UNSIGNED NOT NULL,
  id_producto INT UNSIGNED NOT NULL,
  cantidad    INT UNSIGNED NOT NULL CHECK (cantidad > 0),
  precio      DECIMAL(10,2) NOT NULL CHECK (precio >= 0),
  descuento   DECIMAL(10,2) NOT NULL DEFAULT 0,
  subtotal    DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
  CONSTRAINT fk_ventadetalle_venta    FOREIGN KEY (id_venta)    REFERENCES ventas(id_venta) ON DELETE CASCADE,
  CONSTRAINT fk_ventadetalle_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
) ENGINE=InnoDB;

-- =====================================================================
-- CUENTAS POR COBRAR Y ABONOS (ventas a credito)
-- =====================================================================

CREATE TABLE cuentas_cobrar (
  id_cuenta        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_venta         INT UNSIGNED NOT NULL UNIQUE,
  id_cliente       INT UNSIGNED NOT NULL,
  saldo            DECIMAL(10,2) NOT NULL CHECK (saldo >= 0),
  fecha_vencimiento DATE NOT NULL,
  estado           ENUM('Pendiente','Pagada','Vencida') NOT NULL DEFAULT 'Pendiente',
  CONSTRAINT fk_cuentacobrar_venta   FOREIGN KEY (id_venta)   REFERENCES ventas(id_venta),
  CONSTRAINT fk_cuentacobrar_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
) ENGINE=InnoDB;

CREATE TABLE abonos (
  id_abono   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_cuenta  INT UNSIGNED NOT NULL,
  id_usuario INT UNSIGNED NOT NULL COMMENT 'Usuario que registro el abono',
  fecha      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  monto      DECIMAL(10,2) NOT NULL CHECK (monto > 0),
  CONSTRAINT fk_abono_cuenta  FOREIGN KEY (id_cuenta)  REFERENCES cuentas_cobrar(id_cuenta),
  CONSTRAINT fk_abono_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
) ENGINE=InnoDB;

-- =====================================================================
-- CONFIGURACION DEL SISTEMA
-- =====================================================================

CREATE TABLE configuracion (
  id_configuracion INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  clave            VARCHAR(60)  NOT NULL UNIQUE,
  valor            VARCHAR(255) NOT NULL,
  descripcion      VARCHAR(255) NULL
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;
