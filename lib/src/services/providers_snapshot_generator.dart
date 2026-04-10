import 'dart:convert';

import 'package:flutter_oembed/src/utils/embed_scheme_utils.dart';

const String kProvidersSnapshotSourceUrl = 'https://oembed.com/providers.json';

class GeneratedProviderRule {
  const GeneratedProviderRule({
    required this.providerName,
    required this.pattern,
    required this.endpoint,
  });

  final String providerName;
  final String pattern;
  final String endpoint;

  String get dedupeKey => '$providerName|$pattern|$endpoint';
}

Map<String, List<GeneratedProviderRule>> buildProvidersSnapshotIndex(
  List<dynamic> providers,
) {
  final index = <String, Map<String, GeneratedProviderRule>>{};

  for (final provider in providers) {
    if (provider is! Map<String, dynamic>) continue;

    final providerName = provider['provider_name'];
    final endpoints = provider['endpoints'];
    if (providerName is! String || endpoints is! List) continue;

    for (final endpointEntry in endpoints) {
      if (endpointEntry is! Map<String, dynamic>) continue;

      final endpoint = endpointEntry['url'];
      final schemes = endpointEntry['schemes'];
      if (endpoint is! String || schemes is! List) continue;

      for (final scheme in schemes) {
        if (scheme is! String) continue;
        final domainKey = _domainKeyFromScheme(scheme);
        if (domainKey == null) continue;

        final rule = GeneratedProviderRule(
          providerName: providerName,
          pattern: oembedSchemeToPattern(scheme),
          endpoint: endpoint,
        );

        final bucket = index.putIfAbsent(
          domainKey,
          () => <String, GeneratedProviderRule>{},
        );
        bucket[rule.dedupeKey] = rule;
      }
    }
  }

  final sortedDomains = index.keys.toList()..sort();
  return {
    for (final domain in sortedDomains)
      domain: (index[domain]!.values.toList()
        ..sort((a, b) {
          final byProvider = a.providerName.compareTo(b.providerName);
          if (byProvider != 0) return byProvider;
          final byPattern = a.pattern.compareTo(b.pattern);
          if (byPattern != 0) return byPattern;
          return a.endpoint.compareTo(b.endpoint);
        })),
  };
}

String generateProvidersSnapshotSource(
  String providersJson, {
  String sourceUrl = kProvidersSnapshotSourceUrl,
}) {
  final decoded = jsonDecode(providersJson);
  if (decoded is! List<dynamic>) {
    throw const FormatException(
      'Expected top-level providers.json payload to be a JSON array.',
    );
  }

  final index = buildProvidersSnapshotIndex(decoded);
  final buffer = StringBuffer()
    ..writeln('// GENERATED FILE — DO NOT EDIT BY HAND.')
    ..writeln('// Source: $sourceUrl (snapshot)')
    ..writeln('// Regenerate by running: dart tool/generate_providers.dart')
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln("import 'package:flutter_oembed/src/models/provider_rule.dart';")
    ..writeln()
    ..writeln(
      '/// A bundled snapshot of OEmbed providers marked for discovery.',
    )
    ..writeln('/// Indexed by domain for O(1) lookup performance.')
    ..writeln(
      'const Map<String, List<EmbedProviderRule>> kEmbedProvidersSnapshot = {',
    );

  for (final entry in index.entries) {
    buffer.writeln('  ${jsonEncode(entry.key)}: [');
    for (final rule in entry.value) {
      buffer.writeln('    EmbedProviderRule(');
      buffer.writeln('      providerName: ${jsonEncode(rule.providerName)},');
      buffer.writeln('      pattern: ${jsonEncode(rule.pattern)},');
      buffer.writeln('      endpoint: ${jsonEncode(rule.endpoint)},');
      buffer.writeln('    ),');
    }
    buffer.writeln('  ],');
  }

  buffer.writeln('};');
  return buffer.toString();
}

String? _domainKeyFromScheme(String scheme) {
  final normalized = scheme.startsWith('//') ? 'https:$scheme' : scheme;
  final uri = Uri.tryParse(normalized);
  final host = uri?.host.toLowerCase();
  if (host == null || host.isEmpty) return null;
  return host;
}
