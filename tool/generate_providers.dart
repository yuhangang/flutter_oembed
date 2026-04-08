import 'dart:convert';
import 'dart:io';

import 'package:flutter_oembed/src/services/providers_snapshot_generator.dart';

Future<void> main(List<String> args) async {
  final config = _parseArgs(args);
  final inputJson = await _readProvidersJson(config);
  final output = generateProvidersSnapshotSource(
    inputJson,
    sourceUrl: config.sourceUrl,
  );

  if (config.outputPath == null) {
    stdout.write(output);
    return;
  }

  final outputFile = File(config.outputPath!);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(output);
  stdout.writeln('Wrote ${outputFile.path}');
}

Future<String> _readProvidersJson(_GeneratorConfig config) async {
  if (config.inputPath != null) {
    return File(config.inputPath!).readAsString();
  }

  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(config.sourceUrl));
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Failed to download providers.json (${response.statusCode})',
        uri: Uri.parse(config.sourceUrl),
      );
    }
    return response.transform(utf8.decoder).join();
  } finally {
    client.close(force: true);
  }
}

_GeneratorConfig _parseArgs(List<String> args) {
  String? inputPath;
  String? outputPath =
      'lib/src/services/providers_snapshot.dart';
  var sourceUrl = kProvidersSnapshotSourceUrl;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    switch (arg) {
      case '--input':
        inputPath = _nextValue(args, ++i, '--input');
      case '--output':
        outputPath = _nextValue(args, ++i, '--output');
      case '--source-url':
        sourceUrl = _nextValue(args, ++i, '--source-url');
      case '--stdout':
        outputPath = null;
      case '--help':
      case '-h':
        _printUsage();
        exit(0);
      default:
        throw FormatException('Unknown argument: $arg');
    }
  }

  return _GeneratorConfig(
    inputPath: inputPath,
    outputPath: outputPath,
    sourceUrl: sourceUrl,
  );
}

String _nextValue(List<String> args, int index, String flag) {
  if (index >= args.length) {
    throw FormatException('Missing value for $flag');
  }
  return args[index];
}

void _printUsage() {
  stdout.writeln('Usage: dart tool/generate_providers.dart [options]');
  stdout.writeln();
  stdout.writeln('Options:');
  stdout.writeln(
    '  --input <path>       Read providers.json from a local file instead of the network.',
  );
  stdout.writeln(
    '  --output <path>      Write generated Dart to a file. Defaults to lib/src/services/providers_snapshot.dart.',
  );
  stdout.writeln(
    '  --source-url <url>   Override the source URL label written into the generated header.',
  );
  stdout.writeln('  --stdout             Print generated Dart to stdout.');
  stdout.writeln('  --help, -h           Show this help message.');
}

class _GeneratorConfig {
  const _GeneratorConfig({
    required this.inputPath,
    required this.outputPath,
    required this.sourceUrl,
  });

  final String? inputPath;
  final String? outputPath;
  final String sourceUrl;
}
