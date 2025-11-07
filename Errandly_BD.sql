-- 1. ROLES
CREATE TABLE Rol (
    Id_Rol INT PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL UNIQUE -- Ejemplo: 'Cliente', 'Mandadero', 'Administrador'
);

-- 2. UNIVERSIDAD (RNF-06: Escalabilidad)
CREATE TABLE Universidad (
    Id_universidad INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Ubicacion VARCHAR(255)
);

/*
 * ----------------------------------------------------
 * SECCIÓN 2: TABLAS DE USUARIOS Y AUTENTICACIÓN
 * Incluye la validación de estudiantes para Mandaderos (RF-02).
 * ----------------------------------------------------
 */

-- 3. USUARIO
CREATE TABLE Usuario (
    Id_usuario INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Correo VARCHAR(150) NOT NULL UNIQUE,
    Contrasena VARCHAR(255) NOT NULL, -- Almacenar hash de la contraseña (RNF-03)
    Direccion VARCHAR(255),
    
    -- Claves Foráneas
    Id_Rol INT NOT NULL,
    Id_universidad INT,
    
    -- Campos de Verificación para Mandaderos (RF-02, RNF-09)
    Correo_Institucional VARCHAR(150) UNIQUE,
    Estado_Verificacion ENUM('Pendiente', 'Verificado', 'Rechazado') DEFAULT 'Pendiente', 
    Fecha_Registro DATETIME,

    -- Restricciones
    FOREIGN KEY (Id_Rol) REFERENCES Rol(Id_Rol),
    FOREIGN KEY (Id_universidad) REFERENCES Universidad(Id_universidad)
);

/*
 * ----------------------------------------------------
 * SECCIÓN 3: TABLAS DE RECOMPENSAS (RF-09)
 * ----------------------------------------------------
 */

-- 4. RECOMPENSA_PUNTOS (Define los niveles o tipos de recompensa)
CREATE TABLE Recompensa_puntos (
    Id_recompensas INT PRIMARY KEY,
    Nivel VARCHAR(50) NOT NULL,
    Puntos_requeridos INT NOT NULL,
    Descripcion_Beneficio VARCHAR(255)
);

-- 5. HISTORICO_PUNTOS (Para la trazabilidad de puntos ganados por los Mandaderos)
CREATE TABLE Historico_Puntos (
    Id_Historico INT PRIMARY KEY,
    Id_Mandadero INT NOT NULL, 
    Puntos_Obtenidos INT NOT NULL,
    Razon VARCHAR(100) NOT NULL, -- Ej: 'Mandado completado', 'Bono semanal'
    Fecha DATETIME NOT NULL,
    
    FOREIGN KEY (Id_Mandadero) REFERENCES Usuario(Id_usuario)
);

/*
 * ----------------------------------------------------
 * SECCIÓN 4: TABLAS DE TRANSACCIÓN (MANDADO Y PAGO)
 * Implementa el flujo de trabajo (RF-03, RF-04) y el cálculo de comisiones (RF-08).
 * ----------------------------------------------------
 */

-- 6. MANDADO (La entidad principal de la transacción)
CREATE TABLE Mandado (
    Id_mandado INT PRIMARY KEY,
    Id_Cliente INT NOT NULL, -- Usuario que publica/solicita
    Id_Mandadero INT, -- Usuario que acepta/ejecuta (Puede ser NULL inicialmente)
    
    Descripcion TEXT NOT NULL,
    Costos DECIMAL(10, 2) NOT NULL, -- Costo del producto/servicio comprado
    Tarifa_Servicio DECIMAL(10, 2) NOT NULL, -- Lo que se le paga al mandadero por el servicio
    
    -- Estatus para seguimiento en tiempo real (RF-06)
    Estatus ENUM('Publicado', 'Aceptado', 'En_Ruta_Recoleccion', 'En_Ruta_Entrega', 'Finalizado', 'Cancelado') NOT NULL DEFAULT 'Publicado',
    Fecha_Creacion DATETIME NOT NULL,
    Fecha_Fin DATETIME,
    
    Ubicacion_Recoleccion VARCHAR(255) NOT NULL,
    Ubicacion_Entrega VARCHAR(255) NOT NULL,
    
    FOREIGN KEY (Id_Cliente) REFERENCES Usuario(Id_usuario),
    FOREIGN KEY (Id_Mandadero) REFERENCES Usuario(Id_usuario)
);

-- 7. PAGO (RF-07: Pago integrado y desglose financiero)
CREATE TABLE Pago (
    Id_pago INT PRIMARY KEY,
    Id_mandado INT NOT NULL UNIQUE, -- Relación 1 a 1 con Mandado
    
    Monto_Total_Cliente DECIMAL(10, 2) NOT NULL, -- Monto total cobrado al cliente
    Monto_Comision_App DECIMAL(10, 2) NOT NULL, -- Comisión para la plataforma (RF-08)
    Monto_Ganancia_Mandadero DECIMAL(10, 2) NOT NULL, -- Ganancia neta para el estudiante (RF-08)
    
    Estado ENUM('Pendiente', 'Procesado', 'Fallido') NOT NULL,
    Metodo VARCHAR(50), -- Ej: 'Tarjeta', 'Transferencia'
    Fecha DATETIME NOT NULL,
    
    FOREIGN KEY (Id_mandado) REFERENCES Mandado(Id_mandado)
);

/*
 * ----------------------------------------------------
 * SECCIÓN 5: TABLAS DE COMUNICACIÓN Y FEEDBACK
 * ----------------------------------------------------
 */

-- 8. CHAT (RF-05: Comunicación directa Cliente-Mandadero)
CREATE TABLE Chat (
    Id_chat INT PRIMARY KEY,
    Id_mandado INT NOT NULL, -- El chat pertenece a un mandado específico
    Id_Emisor INT NOT NULL,
    Mensaje TEXT NOT NULL,
    Fecha_envio DATETIME NOT NULL,
    
    FOREIGN KEY (Id_mandado) REFERENCES Mandado(Id_mandado),
    FOREIGN KEY (Id_Emisor) REFERENCES Usuario(Id_usuario)
);

-- 9. CALIFICACION (RF-10: Calificación bidireccional)
CREATE TABLE Calificacion (
    Id_calificacion INT PRIMARY KEY,
    Id_mandado INT NOT NULL UNIQUE, 
    
    -- Calificación del Cliente al Mandadero
    Calificacion_Mandadero INT CHECK (Calificacion_Mandadero BETWEEN 1 AND 5),
    Comentario_Cliente TEXT,
    
    -- Calificación del Mandadero al Cliente (Para reputación)
    Calificacion_Cliente INT CHECK (Calificacion_Cliente BETWEEN 1 AND 5),
    Comentario_Mandadero TEXT,
    
    Fecha DATETIME NOT NULL,
    
    FOREIGN KEY (Id_mandado) REFERENCES Mandado(Id_mandado)
);
