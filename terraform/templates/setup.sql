
CREATE SCHEMA IF NOT EXISTS datapiitest

CREATE TABLE datapiitest.informaciontest (
    id INTEGER PRIMARY KEY,
    identification_number VARCHAR(20),
    full_name VARCHAR(100),
    email VARCHAR(100),
    phone_number VARCHAR(15),
    address VARCHAR(150),
    date_of_birth DATE,
    credit_card VARCHAR(16),
    comments VARCHAR(255)
)

INSERT INTO datapiitest.informaciontest (id,identification_number, full_name, email, phone_number, address, date_of_birth, credit_card, comments)
VALUES
(1,'CC1234567890', 'Juan Pérez', 'juan.perez@example.com', '+57 3001234567', 'Calle 123 #45-67, Bogotá', '1985-06-15', '4111111111111111', 'Usuario de prueba.'),
(2,'CC0987654321', 'María López', 'maria.lopez@example.com', '+57 3102345678', 'Carrera 45 #67-89, Medellín', '1990-11-22', '5500000000000004', 'Sin observaciones.'),
(3,'CC1122334455', 'Carlos Ramírez', 'carlos.ramirez@example.com', '+57 3203456789', 'Avenida 7 #89-12, Cali', '1978-03-10', '340000000000009', 'Cliente nuevo.'),
(4,'CC6677889900', 'Ana Gómez', 'ana.gomez@example.com', '+57 3009876543', 'Calle 89 #12-34, Barranquilla', '1992-08-25', '6011000990139424', 'Sin observaciones.'),
(5,'CC5544332211', 'Luis Torres', 'luis.torres@example.com', '+57 3058765432', 'Calle 100 #45-67, Cartagena', '1980-12-05', '378282246310005', 'Usuario frecuente.'),
(6,'CC1239876543', 'Gabriela Sánchez', 'gabriela.sanchez@example.com', '+57 3114567890', 'Carrera 32 #23-45, Bogotá', '1988-07-14', '4111111111111111', 'Sin comentarios.'),
(7,'CC9876543210', 'Tomás Herrera', 'tomas.herrera@example.com', '+57 3125678901', 'Calle 10 #56-78, Medellín', '1995-04-19', '5500000000000004', 'Registro temporal.'),
(8,'CC5432109876', 'Lucía Díaz', 'lucia.diaz@example.com', '+57 3136789012', 'Avenida 80 #90-23, Cali', '1987-01-30', '340000000000009', 'Cliente frecuente.'),
(9,'CC6789012345', 'Andrés Ruiz', 'andres.ruiz@example.com', '+57 3147890123', 'Calle 50 #60-70, Bucaramanga', '1991-10-07', '6011000990139424', 'Cliente VIP.'),
(10,'CC3456789012', 'Marta Vélez', 'marta.velez@example.com', '+57 3158901234', 'Calle 70 #40-50, Manizales', '1994-05-16', '378282246310005', 'Sin observaciones.'),
(11,'CC8765432109', 'Pedro Castillo', 'pedro.castillo@example.com', '+57 3169012345', 'Carrera 15 #45-80, Armenia', '1986-09-21', '4111111111111111', 'Cliente con historial limpio.'),
(12,'CC2109876543', 'Sofía Ortiz', 'sofia.ortiz@example.com', '+57 3170123456', 'Avenida 68 #100-30, Cali', '1993-02-14', '5500000000000004', 'Usuario inactivo.'),
(13,'CC6789012340', 'Camila Cárdenas', 'camila.cardenas@example.com', '+57 3181234567', 'Calle 5 #90-45, Bogotá', '1998-07-01', '340000000000009', 'Registro actualizado recientemente.');
