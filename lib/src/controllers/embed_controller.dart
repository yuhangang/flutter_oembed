import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_oembed/src/models/social_embed_param.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/logging/embed_logger.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';

class EmbedController extends ChangeNotifier {
  final SocialEmbedParam param;
  final EmbedConfig? config;
  final EmbedData? preloadedData;

  EmbedLoadingState loadingState = EmbedLoadingState.loading;
  bool didRetry = false;
  double? height;
  bool isVisible = true;
  bool _isDisposed = false;
  Timer? _timeoutTimer;
  EmbedLogger get _logger => config?.logger ?? const EmbedLogger.disabled();

  EmbedController({
    required this.param,
    this.config,
    this.preloadedData,
  });

  @override
  void dispose() {
    _isDisposed = true;
    cancelLoadTimeout();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // State mutations
  // ---------------------------------------------------------------------------

  void setHeight(double newHeight) {
    if (_isDisposed) return;
    if (height != newHeight) {
      height = newHeight;
      notifyListeners();
    }
  }

  void updateVisibility(
    bool visible, {
    required void Function(bool) onVisibilityChange,
  }) {
    if (_isDisposed) return;
    if (isVisible != visible) {
      isVisible = visible;
      notifyListeners();
      onVisibilityChange(visible);
    }
  }

  void setLoadingState(EmbedLoadingState state) {
    if (_isDisposed) return;
    if (loadingState != state) {
      loadingState = state;
      notifyListeners();
    }
  }

  void setDidRetry() {
    if (_isDisposed) return;
    if (!didRetry) {
      didRetry = true;
      notifyListeners();
    }
  }

  void startLoadTimeout() {
    _timeoutTimer?.cancel();
    final timeout = config?.loadTimeout ?? const Duration(seconds: 20);
    _timeoutTimer = Timer(timeout, () {
      if (!_isDisposed && loadingState != EmbedLoadingState.loaded) {
        _logger.warning('Embed load timed out after $timeout for ${param.url}');
        setLoadingState(EmbedLoadingState.error);
      }
    });
  }

  void cancelLoadTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }
}
