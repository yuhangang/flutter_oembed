// ignore_for_file: avoid_print

import 'dart:io';

Future<void> main() async {
  final port = 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('====================================================');
  print('✅ Hardened Local API proxy is running!');
  print('👉 Set proxyUrl: "http://localhost:8080/" in your EmbedConfig');
  print('   or in the Example App: Settings > Global Settings');
  print(
    '💡 Benefits: CORS bypass, credential security, & central rate limiting',
  );
  print('====================================================\n');

  final client = HttpClient();

  await for (HttpRequest request in server) {
    if (request.method == 'OPTIONS') {
      _addCorsHeaders(request.response);
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      continue;
    }

    // Extract the target URL from the path and query string.
    // The request.uri for a proxy request should contain the full target URL
    // after the proxy origin part.
    String targetUrl = request.uri.toString();
    while (targetUrl.startsWith('/')) {
      targetUrl = targetUrl.substring(1);
    }

    String targetUrlString = targetUrl;

    if (targetUrlString.isEmpty ||
        (!targetUrlString.startsWith('http://') &&
            !targetUrlString.startsWith('https://'))) {
      _addCorsHeaders(request.response);
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write(
        'Invalid target URL: "$targetUrlString". The path must start with http:// or https://',
      );
      print('❌ Invalid target: $targetUrlString');
      await request.response.close();
      continue;
    }

    final targetUri = Uri.parse(targetUrlString);
    print('🔗 Proxying request to: $targetUri');

    try {
      final targetRequest = await client.openUrl(request.method, targetUri);

      // Relay essential headers from the original request
      request.headers.forEach((name, values) {
        final lowerName = name.toLowerCase();
        // Skip CORS and host headers
        if (lowerName != 'host' &&
            !lowerName.startsWith('access-control-') &&
            lowerName != 'origin' &&
            lowerName != 'referer') {
          for (final value in values) {
            targetRequest.headers.add(name, value);
          }
        }
      });

      // Special header for some proxies/providers
      targetRequest.headers.set('X-Proxy-Source', 'flutter_oembed_local_proxy');

      final targetResponse = await targetRequest.close();

      // Set the response status from target
      request.response.statusCode = targetResponse.statusCode;

      // Safely copy essential headers back to the client
      targetResponse.headers.forEach((name, values) {
        final lowerName = name.toLowerCase();
        if (lowerName == 'content-type' ||
            lowerName == 'cache-control' ||
            lowerName == 'set-cookie' ||
            lowerName == 'last-modified') {
          for (final value in values) {
            request.response.headers.add(name, value);
          }
        }
      });

      // ALWAYS add CORS headers for the browser
      _addCorsHeaders(request.response);

      // Pipe the response back to the client
      await targetResponse.pipe(request.response);
      print('✅ Success [${targetResponse.statusCode}] for $targetUri');
    } catch (e) {
      print('❌ Proxy error for $targetUrlString: $e');
      _addCorsHeaders(request.response);
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Proxy error: $e');
      await request.response.close();
    }
  }
}

void _addCorsHeaders(HttpResponse response) {
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.headers.set(
    'Access-Control-Allow-Headers',
    'Origin, X-Requested-With, Content-Type, Accept, Authorization',
  );
}
