class EventQrEntity {
  final String id;
  final String eventId;
  final String userId;
  final String qrCode;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime? usedAt;
  final String? scannedBy;

  const EventQrEntity({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.qrCode,
    required this.generatedAt,
    required this.expiresAt,
    this.isUsed = false,
    this.usedAt,
    this.scannedBy,
  });

  EventQrEntity copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? qrCode,
    DateTime? generatedAt,
    DateTime? expiresAt,
    bool? isUsed,
    DateTime? usedAt,
    String? scannedBy,
  }) {
    return EventQrEntity(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      qrCode: qrCode ?? this.qrCode,
      generatedAt: generatedAt ?? this.generatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isUsed: isUsed ?? this.isUsed,
      usedAt: usedAt ?? this.usedAt,
      scannedBy: scannedBy ?? this.scannedBy,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventQrEntity &&
        other.id == id &&
        other.eventId == eventId &&
        other.userId == userId &&
        other.qrCode == qrCode &&
        other.generatedAt == generatedAt &&
        other.expiresAt == expiresAt &&
        other.isUsed == isUsed &&
        other.usedAt == usedAt &&
        other.scannedBy == scannedBy;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      eventId,
      userId,
      qrCode,
      generatedAt,
      expiresAt,
      isUsed,
      usedAt,
      scannedBy,
    );
  }
}