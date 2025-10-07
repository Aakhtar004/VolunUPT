class FirestoreIndexException implements Exception {
  final String message;
  final String? indexUrl;

  const FirestoreIndexException({
    required this.message,
    this.indexUrl,
  });

  @override
  String toString() => 'FirestoreIndexException: $message';
}

class FirestoreException implements Exception {
  final String message;
  final String? code;

  const FirestoreException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'FirestoreException: $message';
}