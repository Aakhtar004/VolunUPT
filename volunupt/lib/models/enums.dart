// Enums compartidos del sistema VolunUPT

// Estados de asistencia
enum AttendanceStatus { checkedIn, validated, absent }

// Métodos de registro de asistencia
enum AttendanceMethod { qrScan, manualList }

// Estados de sesión de asistencia
enum SessionStatus { active, closed, cancelled }

// Estados de eventos
enum EventStatus { borrador, publicado, completado, archivado }

// Tipo de programa (sesiones)
// unica: el programa tiene una sola sesión/actividad
// multiple: el programa agrupa varias sesiones/actividades
enum SessionType { unica, multiple }

// Roles de usuario
enum UserRole { estudiante, coordinador, administrador }