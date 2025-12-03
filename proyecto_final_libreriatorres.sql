CREATE DATABASE IF NOT EXISTS librerialu;
USE librerialu;
-- Tabla autores 
CREATE TABLE autores (
id_autor INT AUTO_INCREMENT PRIMARY KEY,
nombre VARCHAR(80) NOT NULL
);
-- Tabla libros 
CREATE TABLE libros (
id_libro INT AUTO_INCREMENT PRIMARY KEY,
titulo VARCHAR(100) NOT NULL,
id_autor INT NOT NULL,
stock INT DEFAULT 0,
FOREIGN KEY (id_autor) REFERENCES autores(id_autor)
);
-- Tabla clientes
CREATE TABLE clientes ( 
id_cliente INT AUTO_INCREMENT PRIMARY KEY,
nombre VARCHAR(100) NOT NULL
);
-- Tabla ventas 
CREATE TABLE ventas ( 
id_venta INT AUTO_INCREMENT PRIMARY KEY,
id_cliente INT NOT NULL,
fecha DATE NOT NULL,
FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);
-- Tabla detall_ventas
CREATE TABLE detalle_ventas (
id_detalle INT AUTO_INCREMENT PRIMARY KEY,
id_venta INT NOT NULL,
id_libro INT NOT NULL,
cantidad SMALLINT UNSIGNED NOT NULL,
precio_unitario DECIMAL (8,2) NOT NULL,
FOREIGN KEY (id_venta) REFERENCES ventas(id_venta),
FOREIGN KEY (id_libro) REFERENCES libros(id_libro)
);
-- Insertar autores 
INSERT INTO autores (nombre) VALUES
('J.K. Rowling'),
('George Orwell');
-- Insertar libros 
INSERT INTO libros (titulo, id_autor, stock) VALUES 
('Harry Potter', 1, 10),
('1984', 2, 15);
-- Insertar clientes 
INSERT INTO clientes (nombre) VALUES 
('Juan Perez'),
('Ana Gomez');
-- Insertar ventas 
INSERT INTO ventas (id_cliente, fecha) VALUES 
(1, '2025-11-01'),
(2, '2025-11-02');
-- Insertar detalle de ventas
INSERT INTO detalle_ventas (id_venta, id_libro, cantidad, precio_unitario) VALUES
(1, 1, 2, 500.00),
(2, 2, 1, 700.00);
-- 1. Vista: historial de compras de cada cliente 
CREATE VIEW vw_historial_compras_clientes AS 
SELECT 
c.id_cliente,
c.nombre AS nombre_cliente,
v.id_venta,
v.fecha,
SUM(dv.cantidad) AS total_libros_comprados,
SUM(dv.cantidad * dv.precio_unitario) AS total_gastado
FROM clientes c
JOIN ventas v ON c.id_cliente = v.id_cliente 
JOIN detalle_ventas dv ON v.id_venta = dv.id_venta
GROUP BY c.id_cliente, v.id_venta, v.fecha;
-- 2. Vista: libros con stock bajo (menos de 5 unidades)
CREATE VIEW vw_libros_stock_bajo AS 
SELECT id_libro, titulo, stock 
FROM libros 
WHERE stock < 5;
-- 3. Vista: ventas realizadas por cada cliente 
CREATE VIEW vw_ventas_por_cliente AS 
SELECT 
c.nombre AS nombre_cliente, 
COUNT(v.id_venta) AS cantidad_ventas,
SUM(dv.cantidad * dv.precio_unitario) AS total_gastado
FROM clientes c
JOIN ventas v ON c.id_cliente = v.id_cliente
JOIN detalle_ventas dv ON v.id_venta = dv.id_venta
GROUP BY c.id_cliente;
-- 4. Vista; libros mas vendidos 
CREATE VIEW vw_libros_mas_vendidos AS 
SELECT 
l.titulo, 
SUM(dv.cantidad) AS total_vendidos
FROM detalle_ventas dv
JOIN libros l ON dv.id_libro = l.id_libro
GROUP BY dv.id_libro
ORDER BY total_vendidos DESC;
-- 5. Vista: detalle de las ventas (resumen general)
CREATE VIEW vw_detalle_ventas_resumen AS 
SELECT 
v.id_venta,
v.fecha,
c.nombre AS nombre_cliente,
l.titulo AS libro,
dv.cantidad,
dv.precio_unitario
FROM detalle_ventas dv
JOIN ventas v ON dv.id_venta = v.id_venta
JOIN clientes c ON v.id_cliente = c.id_cliente
JOIN libros l ON dv.id_libro = l.id_libro; 
DELIMITER $$
CREATE FUNCTION fn_nombre_autor_por_libro (libro_id INT)
RETURNS VARCHAR(80)
DETERMINISTIC 
BEGIN
DECLARE autor_nombre VARCHAR(80);
SELECT a.nombre INTO autor_nombre 
FROM autores a 
JOIN libros l ON a.id_autor = l.id_autor
WHERE l.id_libro = libro_id;
RETURN autor_nombre;
END$$
DELIMITER;
DELIMITER $$
CREATE FUNCTION fn_total_gastado_por_cliente (cliente_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN 
DECLARE total DECIMAL(10,2);
SELECT SUM(dv.cantidad * dv.precio_unitario) INTO total
FROM ventas v
JOIN detalle_ventas dv ON v.id_venta = dv.id_venta
WHERE v.id_cliente = cliente_id;
RETURN IFNULL(total, 0);
END$$
DELIMITER ; 
SELECT fn_nombre_autor_por_libro(1);
SELECT fn_total_gastado_por_cliente(1);
DELIMITER $$
CREATE PROCEDURE sp_insertar_venta(
IN cliente_id INT,
IN fecha_venta DATE,
OUT nueva_venta_id int
)
BEGIN 
INSERT INTO ventas (id_cliente, fecha) VALUES (cliente_id, fecha_venta);
SET neuva_venta_id = LAST_INSERT_ID();
END$$
DELIMITER ; 
DELIMITER $$
CREATE PROCEDURE sp_listar_ventas_cliente_fechas(
IN cliente_id INT,
IN fecha_inicio DATE,
IN fecha_fin date
)
BEGIN
SELECT v.id_venta, v.fecha, dv.id_lbro, dv.cantidad, dv.precio_unitario
FROM ventas ventas
JOIN detalle_ventas dv ON v.id_venta = dv.id_venta
WHERE v.id_cliente = cliente_id
AND v.fecha BETWEEN fecha_inicio AND fecha_fin;
END$$
DELIMITER ; 
CALL sp_insertar_venta(1, '2025-11-15', @nuevaVentaId);
SELECT @nuevaVentaId;
CALL sp_listar_ventas_cliente_fecha(1, '2025-11-01', '2025-12-01');
DELIMITER $$
CREATE TRIGGER trg_restaurar_stock_despues_venta
AFTER INSERT ON detalle_ventas
FOR EACH ROW
BEGIN
UPDATE libros
SET stock = stock - NEW.cantidad
WHERE id_libro = NEW.id_libro;
END$$
DELIMITER ; 
DELIMITER $$
CREATE TRIGGER trg_prevenir_sobreventa
BEFORE INSERT ON detall_ventas
FOR EACH ROW
BEGIN
IF (SELECT stock FROM libros WHERE id_libro = NEW.id_libro) < NEW.cantidad THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'No hay stock suficiente para realizar la venta' ;
END IF;
END$$
DELIMITER ; 
SELECT * FROM autores; 
SELECT * FROM libros;
SELECT * FROM clientes;
SELECT * FROM ventas;
SELECT * FROM detalle_ventas; 
INSERT INTO detalle_ventas (id_venta, id_libro, cantidad, precio_unitario) VALUES 
(3, 2, 2, 500.00),
(4, 5, 1, 700.00);
SELECT * FROM vw_historial_compras_clientes;
SELECT * FROM vw_ventas_por_cliente;
INSERT INTO ventas (id_cliente, fecha) VALUES 
(1, '2025-12-15'),
(2, '2025-12-16');
SELECT id_venta FROM ventas;
INSERT INTO detalle_ventas (id_venta, id_libro, cantidad, precio_unitario) VALUES
(1, 1, 2, 500.00),
(3, 2, 1, 600.00),
(5, 3, 2, 550.00),
(7, 4, 1, 700.00),
(9, 5, 2, 800.00),
(10, 6, 3, 450.00),
(12, 7, 1, 670.00),
(2, 8, 2, 520.00),
(4, 9, 1, 710.00),
(6, 10, 2, 640.00),
(8, 11, 1, 710.00),
(11, 12, 2, 900.00),
(13, 1, 1, 600.00);
SELECT * FROM vw_historial_compras_clientes;