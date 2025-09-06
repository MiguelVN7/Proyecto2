-- Script para crear base de datos de desarrollo con datos de ejemplo
-- Ejecutar este script para inicializar la BD en equipos de desarrollo

-- Tabla de reportes con datos de ejemplo
CREATE TABLE IF NOT EXISTS reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    image_path TEXT NOT NULL,
    location_lat REAL NOT NULL,
    location_lng REAL NOT NULL,
    address TEXT,
    waste_type TEXT NOT NULL,
    severity TEXT NOT NULL,
    description TEXT,
    reporter_name TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Insertar datos de ejemplo para desarrollo
INSERT INTO reports (image_path, location_lat, location_lng, address, waste_type, severity, description, reporter_name) VALUES
('uploads/ejemplo1.jpg', 19.4326, -99.1332, 'Centro Histórico, CDMX', 'plastico', 'alto', 'Acumulación de botellas plásticas en vía pública', 'Usuario Demo'),
('uploads/ejemplo2.jpg', 19.4284, -99.1276, 'Alameda Central, CDMX', 'organico', 'medio', 'Restos de comida en área verde', 'Usuario Demo'),
('uploads/ejemplo3.jpg', 19.4320, -99.1330, 'Zócalo, CDMX', 'electronico', 'alto', 'Dispositivos electrónicos abandonados', 'Usuario Demo'),
('uploads/ejemplo4.jpg', 19.4290, -99.1280, 'Bellas Artes, CDMX', 'papel', 'bajo', 'Papeles dispersos en banqueta', 'Usuario Demo');

-- Verificar que se insertaron los datos
SELECT COUNT(*) as total_reportes FROM reports;
SELECT 'Base de datos inicializada correctamente con ' || COUNT(*) || ' reportes de ejemplo' as mensaje FROM reports;
