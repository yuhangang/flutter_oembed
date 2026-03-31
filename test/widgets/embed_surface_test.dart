import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_embed/src/models/embed_style.dart';
import 'package:flutter_embed/src/widgets/embed_surface.dart';

void main() {
  testWidgets('uses wrapperBuilder before borderRadius', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmbedSurface(
            style: EmbedStyle(
              wrapperBuilder: (context, child) {
                return Container(key: const Key('wrapper'), child: child);
              },
              borderRadius: BorderRadius.circular(16),
            ),
            childBuilder: (context) => const Text('content'),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('wrapper')), findsOneWidget);
    expect(find.byType(ClipRRect), findsNothing);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('applies borderRadius when no wrapperBuilder is provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmbedSurface(
            style: EmbedStyle(borderRadius: BorderRadius.circular(12)),
            childBuilder: (context) => const Text('content'),
          ),
        ),
      ),
    );

    expect(find.byType(ClipRRect), findsOneWidget);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('appends footer under the main child and forwards footerUrl', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmbedSurface(
            style: EmbedStyle(
              footerBuilder: (context, url) => Text('footer:$url'),
            ),
            footerUrl: 'https://example.com/post/1',
            childBuilder: (context) => const Text('content'),
          ),
        ),
      ),
    );

    expect(find.text('content'), findsOneWidget);
    expect(find.text('footer:https://example.com/post/1'), findsOneWidget);
    expect(find.byType(Column), findsOneWidget);
  });
}
