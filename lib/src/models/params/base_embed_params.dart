import 'package:equatable/equatable.dart';

/// Base class for all platform-specific embed parameters.
///
/// This provides a common interface for converting typed parameters
/// into a [Map<String, String>] suitable for query string generation.
abstract class BaseEmbedParams extends Equatable {
  const BaseEmbedParams();

  /// Converts the parameters to a map of strings for query parameters.
  Map<String, String> toMap();

  @override
  List<Object?> get props => [];
}
