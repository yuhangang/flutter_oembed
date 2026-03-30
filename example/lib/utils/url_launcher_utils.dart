import 'package:url_launcher/url_launcher.dart';

/// Opens a [url] in an external application.
Future<void> openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
