import 'package:equatable/equatable.dart';

class QRData extends Equatable {
  final String engineerId;
  final String courseId;
  final String studentId;
  final DateTime timestamp;

  const QRData({
    required this.engineerId,
    required this.courseId,
    required this.studentId,
    required this.timestamp,
  });

  // Generar hash para QR
  String generateHash() {
    return 'QR_${engineerId}_${courseId}_${studentId}_${timestamp.millisecondsSinceEpoch}';
  }

  // Parsear desde hash
  static QRData? fromHash(String hash) {
    try {
      final parts = hash.split('_');
      if (parts.length >= 5 && parts[0] == 'QR') {
        return QRData(
          engineerId: parts[1],
          courseId: parts[2],
          studentId: parts[3],
          timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[4])),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  @override
  List<Object?> get props => [engineerId, courseId, studentId, timestamp];
}
