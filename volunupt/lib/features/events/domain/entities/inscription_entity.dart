class InscriptionEntity {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String status;

  const InscriptionEntity({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.status,
  });

  InscriptionEntity copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userName,
    String? status,
  }) {
    return InscriptionEntity(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      status: status ?? this.status,
    );
  }

  bool get isConfirmed => status == 'Confirmado';
  bool get isWaitingList => status == 'En lista de espera';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InscriptionEntity &&
        other.id == id &&
        other.eventId == eventId &&
        other.userId == userId &&
        other.userName == userName &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^ 
           eventId.hashCode ^
           userId.hashCode ^ 
           userName.hashCode ^ 
           status.hashCode;
  }
}