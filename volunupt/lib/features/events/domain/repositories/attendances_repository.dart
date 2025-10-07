import '../entities/attendance_entity.dart';

abstract class AttendancesRepository {
  Future<List<AttendanceEntity>> getEventAttendances(String eventId);
  Future<List<AttendanceEntity>> getSessionAttendances(String eventId, String sessionId);
  Future<AttendanceEntity?> getAttendance(String eventId, String attendanceId);
  Future<void> recordAttendance(String eventId, AttendanceEntity attendance);
  Future<void> deleteAttendance(String eventId, String attendanceId);
}