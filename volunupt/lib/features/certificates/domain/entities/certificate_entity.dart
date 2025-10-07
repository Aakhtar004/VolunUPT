class CertificateEntity {
  final String id;
  final String eventId;
  final String eventName;
  final DateTime issuedAt;
  final String fileUrl;

  const CertificateEntity({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.issuedAt,
    required this.fileUrl,
  });

  CertificateEntity copyWith({
    String? id,
    String? eventId,
    String? eventName,
    DateTime? issuedAt,
    String? fileUrl,
  }) {
    return CertificateEntity(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      issuedAt: issuedAt ?? this.issuedAt,
      fileUrl: fileUrl ?? this.fileUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CertificateEntity &&
        other.id == id &&
        other.eventId == eventId &&
        other.eventName == eventName &&
        other.issuedAt == issuedAt &&
        other.fileUrl == fileUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        eventId.hashCode ^
        eventName.hashCode ^
        issuedAt.hashCode ^
        fileUrl.hashCode;
  }
}