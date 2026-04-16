import 'package:equatable/equatable.dart';

const _unsetConstraintValue = Object();

/// Optional height constraints for a single embed instance.
///
/// Width still comes from the parent layout. This model only governs how the
/// package derives and clamps the rendered embed height.
class EmbedConstraints extends Equatable {
  final double? preferredHeight;
  final double? minHeight;
  final double? maxHeight;

  const EmbedConstraints({
    this.preferredHeight,
    this.minHeight,
    this.maxHeight,
  })  : assert(
          preferredHeight == null || preferredHeight >= 0,
          'preferredHeight must be non-negative',
        ),
        assert(
          minHeight == null || minHeight >= 0,
          'minHeight must be non-negative',
        ),
        assert(
          maxHeight == null || maxHeight >= 0,
          'maxHeight must be non-negative',
        ),
        assert(
          minHeight == null || maxHeight == null || minHeight <= maxHeight,
          'minHeight must be less than or equal to maxHeight',
        );

  @override
  List<Object?> get props => [preferredHeight, minHeight, maxHeight];

  EmbedConstraints copyWith({
    Object? preferredHeight = _unsetConstraintValue,
    Object? minHeight = _unsetConstraintValue,
    Object? maxHeight = _unsetConstraintValue,
  }) {
    return EmbedConstraints(
      preferredHeight: identical(preferredHeight, _unsetConstraintValue)
          ? this.preferredHeight
          : _toNullableDouble(preferredHeight),
      minHeight: identical(minHeight, _unsetConstraintValue)
          ? this.minHeight
          : _toNullableDouble(minHeight),
      maxHeight: identical(maxHeight, _unsetConstraintValue)
          ? this.maxHeight
          : _toNullableDouble(maxHeight),
    );
  }

  double clampHeight(double height) {
    final min = minHeight ?? 0.0;
    final max = maxHeight ?? double.infinity;
    return height.clamp(min, max).toDouble();
  }

  static double? _toNullableDouble(Object? value) {
    if (value == null) return null;
    return (value as num).toDouble();
  }
}
