import 'package:flutter/material.dart';
import 'package:flutter_oembed/flutter_oembed.dart';

class ExampleSettings {
  final String locale;
  final Brightness brightness;
  final bool scrollable;
  final bool showFooter;
  final Color? backgroundColor;

  // Provider-specific params
  final VimeoEmbedParams vimeoParams;
  final XEmbedParams xParams;
  final MetaEmbedParams metaParams;
  final SoundCloudEmbedParams soundCloudParams;
  final TikTokEmbedParams tiktokParams;
  final YoutubeEmbedParams youtubeParams;

  const ExampleSettings({
    this.locale = 'en',
    this.brightness = Brightness.light,
    this.scrollable = false,
    this.showFooter = false,
    this.backgroundColor,
    this.vimeoParams = const VimeoEmbedParams(),
    this.xParams = const XEmbedParams(
      dnt: true,
      chrome: ['noscrollbar', 'nofooter', 'noborders', 'transparent'],
    ),
    this.metaParams = const MetaEmbedParams(
      adaptContainerWidth: true,
      showFacepile: true,
      showPosts: true,
    ),
    this.soundCloudParams = const SoundCloudEmbedParams(),
    this.tiktokParams = const TikTokEmbedParams(),
    this.youtubeParams = const YoutubeEmbedParams(),
  });

  ExampleSettings copyWith({
    String? locale,
    Brightness? brightness,
    bool? scrollable,
    bool? showFooter,
    Color? backgroundColor,
    VimeoEmbedParams? vimeoParams,
    XEmbedParams? xParams,
    MetaEmbedParams? metaParams,
    SoundCloudEmbedParams? soundCloudParams,
    TikTokEmbedParams? tiktokParams,
    YoutubeEmbedParams? youtubeParams,
  }) {
    return ExampleSettings(
      locale: locale ?? this.locale,
      brightness: brightness ?? this.brightness,
      scrollable: scrollable ?? this.scrollable,
      showFooter: showFooter ?? this.showFooter,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      vimeoParams: vimeoParams ?? this.vimeoParams,
      xParams: xParams ?? this.xParams,
      metaParams: metaParams ?? this.metaParams,
      soundCloudParams: soundCloudParams ?? this.soundCloudParams,
      tiktokParams: tiktokParams ?? this.tiktokParams,
      youtubeParams: youtubeParams ?? this.youtubeParams,
    );
  }

  EmbedConfig toEmbedConfig() {
    return EmbedConfig(
      locale: locale,
      brightness: brightness,
      scrollable: scrollable,
    );
  }

  EmbedConstraints? get embedConstraints => null;
}

class ExampleSettingsController extends ChangeNotifier {
  ExampleSettings _settings = const ExampleSettings();

  ExampleSettings get settings => _settings;

  void updateSettings(ExampleSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  void updateGeneral({
    String? locale,
    Brightness? brightness,
    bool? scrollable,
    bool? showFooter,
    Color? backgroundColor,
  }) {
    _settings = _settings.copyWith(
      locale: locale,
      brightness: brightness,
      scrollable: scrollable,
      showFooter: showFooter,
      backgroundColor: backgroundColor,
    );
    notifyListeners();
  }

  void updateVimeo(VimeoEmbedParams params) {
    _settings = _settings.copyWith(vimeoParams: params);
    notifyListeners();
  }

  void updateX(XEmbedParams params) {
    _settings = _settings.copyWith(xParams: params);
    notifyListeners();
  }

  void updateMeta(MetaEmbedParams params) {
    _settings = _settings.copyWith(metaParams: params);
    notifyListeners();
  }

  void updateSoundCloud(SoundCloudEmbedParams params) {
    _settings = _settings.copyWith(soundCloudParams: params);
    notifyListeners();
  }

  void updateTikTok(TikTokEmbedParams params) {
    _settings = _settings.copyWith(tiktokParams: params);
    notifyListeners();
  }

  void updateYoutube(YoutubeEmbedParams params) {
    _settings = _settings.copyWith(youtubeParams: params);
    notifyListeners();
  }
}

class ExampleSettingsProvider
    extends InheritedNotifier<ExampleSettingsController> {
  const ExampleSettingsProvider({
    super.key,
    required super.notifier,
    required super.child,
  });

  static ExampleSettingsController of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ExampleSettingsProvider>();
    assert(provider != null, 'No ExampleSettingsProvider found in context');
    return provider!.notifier!;
  }
}
