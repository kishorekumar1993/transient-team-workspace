class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error']);

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error']);

  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Authentication error']);

  @override
  String toString() => message;
}
