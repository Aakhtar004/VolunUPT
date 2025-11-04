import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String notificationId;
  final String userId; // Usuario destinatario
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? relatedEventId; // ID del evento relacionado (opcional)
  final String? relatedSubEventId; // ID del subevento relacionado (opcional)
  final String? actionUrl; // URL o ruta para acción (opcional)
  final Map<String, dynamic>? metadata; // Datos adicionales

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.relatedEventId,
    this.relatedSubEventId,
    this.actionUrl,
    this.metadata,
  });

  factory NotificationModel.fromSnapshot(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return NotificationModel(
      notificationId: snap.id,
      userId: snapshot['userId'] ?? '',
      title: snapshot['title'] ?? '',
      message: snapshot['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${snapshot['type']}',
        orElse: () => NotificationType.info,
      ),
      timestamp: (snapshot['timestamp'] as Timestamp).toDate(),
      isRead: snapshot['isRead'] ?? false,
      relatedEventId: snapshot['relatedEventId'],
      relatedSubEventId: snapshot['relatedSubEventId'],
      actionUrl: snapshot['actionUrl'],
      metadata: snapshot['metadata'] != null 
          ? Map<String, dynamic>.from(snapshot['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'relatedEventId': relatedEventId,
      'relatedSubEventId': relatedSubEventId,
      'actionUrl': actionUrl,
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({
    String? notificationId,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? relatedEventId,
    String? relatedSubEventId,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      relatedEventId: relatedEventId ?? this.relatedEventId,
      relatedSubEventId: relatedSubEventId ?? this.relatedSubEventId,
      actionUrl: actionUrl ?? this.actionUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum NotificationType {
  info,
  success,
  warning,
  error,
  event,
  certificate,
  registration,
  user,
  report,
  attendance,
  reminder,
}