-- =====================================================================
-- APEX GYM - Usuario de aplicacion (bajo privilegio)
-- Ejecutar como root, DESPUES de schema.sql y seed.sql
-- Este usuario es el que usara el backend Node.js/Express para
-- conectarse a la base de datos (nunca usar root desde la aplicacion).
-- =====================================================================

CREATE USER IF NOT EXISTS 'apex_gym_app'@'localhost' IDENTIFIED BY 'PWIsgrdlvX6gjE3H';

GRANT SELECT, INSERT, UPDATE, DELETE ON apex_gym.* TO 'apex_gym_app'@'localhost';

FLUSH PRIVILEGES;

-- Nota: esta contrasena ya esta configurada en backend/.env
-- Puedes cambiarla en cualquier momento con:
--   ALTER USER 'apex_gym_app'@'localhost' IDENTIFIED BY 'tu_nueva_contrasena';
-- y actualizando DB_PASSWORD en backend/.env
