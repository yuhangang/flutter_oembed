import 'package:flutter/material.dart';
import 'package:flutter_oembed/src/models/core/embed_style.dart';
import 'package:flutter_oembed/src/widgets/lazy_embed_node.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets('resets visibility when the URL changes', (tester) async {
    final style = EmbedStyle(
      lazyLoadPlaceholderBuilder: (context) =>
          const Text('placeholder', key: Key('placeholder')),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LazyEmbedNode(
            url: 'https://example.com/post/1',
            isInitialVisible: true,
            style: style,
            child: const Text('child', key: Key('child')),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('child')), findsOneWidget);
    expect(find.byKey(const Key('placeholder')), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LazyEmbedNode(
            url: 'https://example.com/post/2',
            isInitialVisible: false,
            style: style,
            child: const Text('child', key: Key('child')),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('child')), findsNothing);
    expect(find.byKey(const Key('placeholder')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 60));
  });

  testWidgets('promotes visibility when initial visibility becomes true',
      (tester) async {
    final style = EmbedStyle(
      lazyLoadPlaceholderBuilder: (context) =>
          const Text('placeholder', key: Key('placeholder')),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LazyEmbedNode(
            url: 'https://example.com/post/1',
            isInitialVisible: false,
            style: style,
            child: const Text('child', key: Key('child')),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('placeholder')), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LazyEmbedNode(
            url: 'https://example.com/post/1',
            isInitialVisible: true,
            style: style,
            child: const Text('child', key: Key('child')),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('child')), findsOneWidget);
    expect(find.byKey(const Key('placeholder')), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 60));
  });
}
