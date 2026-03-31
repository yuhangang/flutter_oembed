/// Converts an OEmbed wildcard scheme into a regex pattern string.
///
/// OEmbed schemes use `*` as a wildcard.
/// Example: `https://www.23hq.com/*/photo/*` -> `^https?://www\.23hq\.com/.*/photo/.*$`
String oembedSchemeToPattern(String scheme) {
  // 1. Escape regex special characters: . ? / + { } [ ] ( ) ^ $ | \
  // We don't escape * yet because we'll replace it with .*
  String pattern = scheme
      .replaceAll(r'\', r'\\')
      .replaceAll(r'.', r'\.')
      .replaceAll(r'?', r'\?')
      .replaceAll(r'/', r'\/')
      .replaceAll(r'+', r'\+')
      .replaceAll(r'{', r'\{')
      .replaceAll(r'}', r'\}')
      .replaceAll(r'[', r'\[')
      .replaceAll(r']', r'\]')
      .replaceAll(r'(', r'\(')
      .replaceAll(r')', r'\)')
      .replaceAll(r'^', r'\^')
      .replaceAll(r'$', r'\$')
      .replaceAll(r'|', r'\|');

  // 2. Replace wildcard * with .*
  pattern = pattern.replaceAll(r'*', r'.*');

  // 3. Make protocol flexible (handle http vs https)
  if (pattern.startsWith(r'https?:\/\/')) {
    // Already handled or generic
  } else if (pattern.startsWith(r'https:\/\/')) {
    pattern = pattern.replaceFirst(r'https:\/\/', r'https?:\/\/');
  } else if (pattern.startsWith(r'http:\/\/')) {
    pattern = pattern.replaceFirst(r'http:\/\/', r'https?:\/\/');
  } else if (pattern.startsWith(r'\/\/')) {
     pattern = pattern.replaceFirst(r'\/\/', r'https?:\/\/');
  }

  return '^$pattern';
}
