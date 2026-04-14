import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_oembed/src/models/social_embed_param.dart';
import 'package:flutter_oembed/src/models/embed_constant.dart';
import 'package:flutter_oembed/src/models/embed_enums.dart';
import 'package:flutter_oembed/src/models/embed_data.dart';
import 'package:flutter_oembed/src/logging/embed_logger.dart';
import 'package:flutter_oembed/src/models/embed_config.dart';
import 'package:flutter_oembed/src/utils/embed_errors.dart';

class EmbedController extends ChangeNotifier {
  SocialEmbedParam param;
  EmbedConfig? config;
  EmbedData? preloadedData;

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
  Future<void> Function(Duration position)? _seekMediaHandler;

  /// Internal slot used by [EmbedWebView] to persist a driver across remounts.
  Object? _boundDriver;
  void Function()? _onDriverDispose;
  int get embedRevision => _embedRevision;

  EmbedLogger get _logger => config?.logger ?? const EmbedLogger.disabled();

  EmbedController({
    required this.param,
    this.config,
    this.preloadedData,
  });

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _onDriverDispose?.call();
    _onDriverDispose = null;
    _boundDriver = null;
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

  void synchronize({
    required SocialEmbedParam param,
    EmbedConfig? config,
    EmbedData? preloadedData,
  }) {
    if (_isDisposed) return;

    final paramChanged = this.param != param;
    final preloadedDataChanged = this.preloadedData != preloadedData;
    final configChanged =
        !EmbedConfig.runtimeEqualsNullable(this.config, config);

    if (!paramChanged && !preloadedDataChanged && !configChanged) {
      return;
    }

    this.param = param;
    this.preloadedData = preloadedData;
    this.config = config;

    if (paramChanged || preloadedDataChanged) {
      _disposeBoundDriver();
      _embedRevision++;
      _resetRuntimeStateForReload();
    }

    notifyListeners();
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
        _logger.warning('Embed load timed out after $timeout for ${param.url}');
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

  /// Best-effort request to seek media for the attached embed.
  Future<void> seekMediaTo(Duration position) async {
    if (_isDisposed) return;
    await _seekMediaHandler?.call(position);
  }

  void bindMediaControls({
    required Future<void> Function() pause,
    required Future<void> Function() resume,
    required Future<void> Function() mute,
    required Future<void> Function() unmute,
    required Future<void> Function(Duration position) seekTo,
  }) {
    if (_isDisposed) return;
    _pauseMediaHandler = pause;
    _resumeMediaHandler = resume;
    _muteMediaHandler = mute;
    _unmuteMediaHandler = unmute;
    _seekMediaHandler = seekTo;
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
    _seekMediaHandler = null;
  }

  /// Internal: Gets the currently bound driver (usually an EmbedWebViewDriver).
  Object? get boundDriver => _boundDriver;

  /// Internal: Binds a driver to this controller for persistence.
  void bindDriver(Object driver, {required void Function() onDispose}) {
    if (_isDisposed) return;
    _onDriverDispose?.call();
    _boundDriver = driver;
    _onDriverDispose = onDispose;
  }

  /// Internal: Unbinds the current driver without necessarily disposing it.
  void unbindDriver() {
    _boundDriver = null;
    _onDriverDispose = null;
  }

  void _resetRuntimeStateForReload() {
    cancelLoadTimeout();
    _unbindMediaControls();
    loadingState = EmbedLoadingState.loading;
    didRetry = false;
    height = null;
    lastError = null;
  }

  void _disposeBoundDriver() {
    _onDriverDispose?.call();
    _onDriverDispose = null;
    _boundDriver = null;
  }
}
