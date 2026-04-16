import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/logging/embed_logger.dart';
import 'package:flutter_oembed/src/models/configs/embed_config.dart';
import 'package:flutter_oembed/src/models/core/embed_constant.dart';
import 'package:flutter_oembed/src/models/core/embed_data.dart';
import 'package:flutter_oembed/src/models/core/embed_enums.dart';
import 'package:flutter_oembed/src/models/core/provider_rule.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';

class EmbedController extends ChangeNotifier {
  EmbedConfig? config;

  EmbedLoadingState loadingState = EmbedLoadingState.loading;
  bool didRetry = false;
  double? height;
  bool isVisible = true;
  Object? lastError;
  bool _isDisposed = false;
  int _embedRevision = 0;
  Timer? _timeoutTimer;
  Future<void> Function()? _pauseMediaHandler;
  Future<void> Function()? _resumeMediaHandler;
  Future<void> Function()? _muteMediaHandler;
  Future<void> Function()? _unmuteMediaHandler;
  Object? _contentKey;
  EmbedData? _embedData;
  EmbedProviderRule? _matchedProviderRule;

  /// Internal slot used by [EmbedWebView] to persist a driver across remounts.
  Object? _boundDriver;
  Object? _boundDriverContentKey;
  void Function()? _onDriverDispose;
  int get embedRevision => _embedRevision;
  EmbedData? get embedData => _embedData;
  EmbedProviderRule? get matchedProviderRule => _matchedProviderRule;

  EmbedLogger get _logger => config?.logger ?? const EmbedLogger.disabled();

  EmbedController({
    this.config,
  });

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _onDriverDispose?.call();
    _onDriverDispose = null;
    _boundDriver = null;
    _boundDriverContentKey = null;
    _unbindMediaControls();
    cancelLoadTimeout();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // State mutations
  // ---------------------------------------------------------------------------

  void setHeight(double newHeight) {
    if (_isDisposed) return;
    if (!newHeight.isFinite || newHeight <= 0) return;
    final currentHeight = height;
    final deltaThreshold = config?.heightUpdateDeltaThreshold ??
        kDefaultHeightUpdateDeltaThreshold;
    final shouldUpdate = currentHeight == null ||
        newHeight > currentHeight ||
        (currentHeight - newHeight).abs() >= deltaThreshold;
    if (shouldUpdate) {
      height = newHeight;
      notifyListeners();
    }
  }

  void updateConfig(EmbedConfig? value) {
    if (_isDisposed || EmbedConfig.runtimeEqualsNullable(config, value)) {
      return;
    }
    config = value;
    notifyListeners();
  }

  void setEmbedData(EmbedData? value) {
    if (_isDisposed || _embedData == value) return;
    _embedData = value;
    didRetry = false;
    lastError = null;
    if (loadingState != EmbedLoadingState.loading) {
      loadingState = EmbedLoadingState.loading;
    }
    notifyListeners();
  }

  void clearEmbedData() {
    setEmbedData(null);
  }

  void setMatchedProviderRule(EmbedProviderRule? value) {
    if (_isDisposed || identical(_matchedProviderRule, value)) return;
    _matchedProviderRule = value;
  }

  void synchronize({
    required Object contentKey,
    EmbedConfig? config,
    bool notify = true,
  }) {
    if (_isDisposed) return;

    final previousContentKey = _contentKey;
    final contentChanged = _contentKey != contentKey;
    final configChanged =
        !EmbedConfig.runtimeEqualsNullable(this.config, config);

    if (!contentChanged && !configChanged) {
      return;
    }

    _contentKey = contentKey;
    this.config = config;

    if (contentChanged || configChanged) {
      _disposeBoundDriver();
      _embedRevision++;
      _matchedProviderRule = null;
      _resetRuntimeStateForReload(
        clearEmbedData: contentChanged ? previousContentKey != null : true,
      );
    }

    if (notify) {
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

  void setLoadingState(
    EmbedLoadingState state, {
    Object? error,
  }) {
    if (_isDisposed) return;
    final nextError = switch (state) {
      EmbedLoadingState.loading || EmbedLoadingState.loaded => null,
      _ => error ?? lastError,
    };

    if (loadingState != state || lastError != nextError) {
      loadingState = state;
      lastError = nextError;
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
    if (_isDisposed) return;
    _timeoutTimer?.cancel();
    final timeout = config?.loadTimeout ?? kDefaultEmbedLoadTimeout;
    _timeoutTimer = Timer(timeout, () {
      if (!_isDisposed && loadingState != EmbedLoadingState.loaded) {
        _logger.warning('Embed load timed out after $timeout');
        setLoadingState(
          EmbedLoadingState.error,
          error: EmbedTimeoutException(timeout: timeout),
        );
      }
    });
  }

  void cancelLoadTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// Best-effort request to pause media for the attached embed.
  Future<void> pauseMedia() async {
    if (_isDisposed) return;
    await _pauseMediaHandler?.call();
  }

  /// Best-effort request to resume media for the attached embed.
  Future<void> resumeMedia() async {
    if (_isDisposed) return;
    await _resumeMediaHandler?.call();
  }

  /// Best-effort request to mute media for the attached embed.
  Future<void> muteMedia() async {
    if (_isDisposed) return;
    await _muteMediaHandler?.call();
  }

  /// Best-effort request to unmute media for the attached embed.
  Future<void> unmuteMedia() async {
    if (_isDisposed) return;
    await _unmuteMediaHandler?.call();
  }

  void bindMediaControls({
    required Future<void> Function() pause,
    required Future<void> Function() resume,
    required Future<void> Function() mute,
    required Future<void> Function() unmute,
  }) {
    if (_isDisposed) return;
    _pauseMediaHandler = pause;
    _resumeMediaHandler = resume;
    _muteMediaHandler = mute;
    _unmuteMediaHandler = unmute;
  }

  void unbindMediaControls() {
    if (_isDisposed) return;
    _unbindMediaControls();
  }

  void _unbindMediaControls() {
    _pauseMediaHandler = null;
    _resumeMediaHandler = null;
    _muteMediaHandler = null;
    _unmuteMediaHandler = null;
  }

  /// Internal: Gets the currently bound driver (usually an EmbedWebViewDriver).
  Object? get boundDriver => _boundDriver;
  Object? get boundDriverContentKey => _boundDriverContentKey;

  /// Internal: Binds a driver to this controller for persistence.
  void bindDriver(
    Object driver, {
    required Object contentKey,
    required void Function() onDispose,
  }) {
    if (_isDisposed) return;
    _onDriverDispose?.call();
    _boundDriver = driver;
    _boundDriverContentKey = contentKey;
    _onDriverDispose = onDispose;
  }

  /// Internal: Unbinds the current driver without necessarily disposing it.
  void unbindDriver() {
    _boundDriver = null;
    _boundDriverContentKey = null;
    _onDriverDispose = null;
  }

  void _resetRuntimeStateForReload({
    bool clearEmbedData = true,
  }) {
    cancelLoadTimeout();
    _unbindMediaControls();
    if (clearEmbedData) {
      _embedData = null;
    }
    loadingState = EmbedLoadingState.loading;
    didRetry = false;
    height = null;
    lastError = null;
  }

  void _disposeBoundDriver() {
    _onDriverDispose?.call();
    _onDriverDispose = null;
    _boundDriver = null;
    _boundDriverContentKey = null;
  }
}
