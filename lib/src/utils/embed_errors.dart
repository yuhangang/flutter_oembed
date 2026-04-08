abstract class EmbedException implements Exception {}

class EmbedDataNotFoundException implements EmbedException {}

class EmbedDataRestrictedAccessException implements EmbedException {}

class EmbedApisException implements EmbedException {
  final String? message;
  const EmbedApisException({this.message});

  @override
  String toString() => message ?? 'EmbedApisException';
}
