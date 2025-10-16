BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "calendario" (
	"id_calendario"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"actividad"	TEXT,
	"date_activity"	DATE,
	"id_estudiante"	INTEGER,
	FOREIGN KEY("id_estudiante") REFERENCES "estudiantes"("id_estudiante")
);
CREATE TABLE IF NOT EXISTS "contacto_emergencia" (
	"id_contacto"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"nombre_contacto"	TEXT,
	"apellido_contacto"	TEXT,
	"telefono_contacto"	TEXT,
	"id_estudiante"	INTEGER,
	FOREIGN KEY("id_estudiante") REFERENCES "estudiantes"("id_estudiante")
);
CREATE TABLE IF NOT EXISTS "agenda_cita" (
	"id_agendacita"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"fecha_cita"	DATE,
	"motivo_cita"	TEXT,
	"confirmacion_cita"	BOOLEAN,
	"id_diagnostico"	INTEGER,
	"id_estudiante"	INTEGER,
	"id_bienestar"	INTEGER,
	FOREIGN KEY("id_bienestar") REFERENCES "bienestar"("id_bienestar"),
	FOREIGN KEY("id_diagnostico") REFERENCES "ia_diagnostico"("id_diagnostico"),
	FOREIGN KEY("id_estudiante") REFERENCES "estudiantes"("id_estudiante")
);
CREATE TABLE IF NOT EXISTS "ia_diagnostico" (
	"id_diagnostico"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"analisis"	TEXT,
	"puntos_importantes"	TEXT,
	"id_chatbot"	INTEGER,
	FOREIGN KEY("id_chatbot") REFERENCES "chatbot"("id_chatbot")
);
CREATE TABLE IF NOT EXISTS "chatbot" (
	"id_chatbot"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"id_estudiante"	INTEGER,
	"id_sesion"	INTEGER,
	FOREIGN KEY("id_sesion") REFERENCES "sesiones"("id_sesion"),
	FOREIGN KEY("id_estudiante") REFERENCES "estudiantes"("id_estudiante")
);
CREATE TABLE IF NOT EXISTS "sesiones" (
	"id_sesion"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"fecha_sesion"	DATE NOT NULL,
	"tiempo_sesion"	TIME NOT NULL,
	"id_estudiante_sesion"	INTEGER NOT NULL,
	FOREIGN KEY("id_estudiante_sesion") REFERENCES "estudiantes"("id_estudiante")
);
CREATE TABLE IF NOT EXISTS "bienestar" (
	"id_bienestar"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"nombre"	TEXT,
	"apellido"	TEXT,
	"telefono"	INTEGER,
	"correo"	TEXT,
	"id_sede"	INTEGER,
	FOREIGN KEY("id_sede") REFERENCES "sede"("id_sede")
);
CREATE TABLE IF NOT EXISTS "sede" (
	"id_sede"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"nombre_sede"	TEXT NOT NULL,
	"direccion_sede"	TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS "modulos_activos" (
	"id_modulo_activo"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"duracion_actividad"	TEXT,
	"resultados_actividad"	TEXT,
	"id_modulos"	INTEGER,
	FOREIGN KEY("id_modulos") REFERENCES "modulos"("id_modulos")
);
CREATE TABLE IF NOT EXISTS "modulos" (
	"id_modulos"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"nombre_modulo"	TEXT,
	"tipo_modulo"	TEXT,
	"descripcion_modulo"	TEXT
);
CREATE TABLE IF NOT EXISTS "usuario" (
	"id_usuario"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"nombre_usuario"	TEXT,
	"correo"	TEXT,
	"pass"	TEXT,
	"id_estudiante"	INTEGER,
	FOREIGN KEY("id_estudiante") REFERENCES "estudiantes"("id_estudiante")
);
CREATE TABLE IF NOT EXISTS "estudiantes" (
	"id_estudiante"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"nombre"	TEXT,
	"apellido"	TEXT,
	"correo"	TEXT
);
COMMIT;
