CREATE TABLE detalle_ventas ( 
id_detalle INT AUTO_INCREMENT PRIMARY KEY,
id_venta INT NOT NULL,
id_libro INT NOT NULL,
cantidad SMALLINT UNSIGNED NOT NULL,
precio_unitario DECIMAL (8,2) NOT NULL,
FOREIGN KEY (id_venta) REFERENCES ventas(id_venta),
FOREIGN KEY (id_libro) REFERENCES libros(id_libro)
);
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
END;
$$
DELIMITER ;)
ALTER TABLE libros ADD COLUMN stock INT DEFAULT 0;
DELIMITER $$
CREATE TRIGGER trg_actualizar_stock
AFTER INSERT ON detalle_ventas
FOR EACH ROW 
BEGIN
UPDATE libros 
SET stock = stock - NEW.cantidad
WHERE id_libro = NEW.id_libro;
END;
$$
DELIMITER;
DELIMITER $$
CREATE PROCEDURE sp_insertar_venta(
IN cliente_id INT,
IN fecha_venta DATE,
INOUT nueva_venta_id INT 
)
BEGIN
INSERT INTO ventas (id_cliente, fecha) VALUES (cliente_id, fecha_venta);
SET nueva_venta_id = LAST_INSERT_ID();
END;
$$
DELIMITER ;
-- AUTOR 
INSERT INTO autores (nombre) VALUES (
