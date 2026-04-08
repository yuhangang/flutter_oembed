/// Base exception type for all errors originating from the flutter_oembed library.
///
/// Use pattern matching on the sealed subtypes to handle specific error cases:
///
/// ```dart
/// try {
///   await EmbedService.getResult(param: param);
/// } on EmbedException catch (e) {
///   switch (e) {
///     case EmbedTimeoutException():  // ...
///     case EmbedNetworkException():  // ...
///     case EmbedNotFoundException(): // ...
///     // ...
///   }
/// }
/// ```
sealed class EmbedException implements Exception {
  const EmbedException();

  /// A human-readable description of the error.
  String get message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The oEmbed API returned a 404 or the content was not found.
class EmbedNotFoundException extends EmbedException {
  @override
  final String message;

  const EmbedNotFoundException(
      {this.message = 'Embed content not found (404).'});
}

/// The oEmbed API returned a 401/403 or the content requires credentials.
class EmbedRestrictedAccessException extends EmbedException {
  /// The HTTP status code, if available.
  final int? statusCode;

  @override
  final String message;

  const EmbedRestrictedAccessException({
    this.statusCode,
    this.message = 'Access to embed content is restricted.',
  });
}

/// A general API/HTTP error that does not fit the more specific types.
class EmbedApiException extends EmbedException {
  /// The HTTP status code, if available.
  final int? statusCode;

  /// The raw response body, if available.
  final String? responseBody;

  @override
  final String message;

  const EmbedApiException({
    this.statusCode,
    this.responseBody,
    this.message = 'An error occurred while fetching embed data.',
  });
}

/// The embed WebView or API call timed out.
class EmbedTimeoutException extends EmbedException {
  /// How long we waited before timing out.
  final Duration timeout;

  @override
  String get message => 'Embed load timed out after $timeout.';

  const EmbedTimeoutException({required this.timeout});
}

/// A network-level error (DNS resolution, socket, TLS).
class EmbedNetworkException extends EmbedException {
  /// The underlying error, typically a [SocketException] or [HttpException].
  final Object? cause;

  @override
  final String message;

  const EmbedNetworkException({
    this.cause,
    this.message = 'A network error occurred.',
  });
}

/// No oEmbed provider could be resolved for the given URL.
class EmbedProviderNotFoundException extends EmbedException {
  /// The URL that could not be matched to a provider.
  final String url;

  @override
  String get message => 'No oEmbed provider found for $url. '
      'Try enabling dynamic discovery or providing a manual rule.';

  const EmbedProviderNotFoundException({required this.url});
}

// ---------------------------------------------------------------------------
// Backwards-compatible aliases (deprecated)
// ---------------------------------------------------------------------------

/// @Deprecated Use [EmbedNotFoundException] instead.
@Deprecated('Use EmbedNotFoundException instead.')
typedef EmbedDataNotFoundException = EmbedNotFoundException;

/// @Deprecated Use [EmbedRestrictedAccessException] instead.
@Deprecated('Use EmbedRestrictedAccessException instead.')
typedef EmbedDataRestrictedAccessException = EmbedRestrictedAccessException;

/// @Deprecated Use [EmbedApiException] instead.
@Deprecated('Use EmbedApiException instead.')
typedef EmbedApisException = EmbedApiException;
