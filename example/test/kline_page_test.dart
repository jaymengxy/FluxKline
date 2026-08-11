import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flux_kline_example/pages/kline_page.dart';

void main() {
  testWidgets('renders the market-detail K-line layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(themeMode: ThemeMode.dark, home: KLinePage()),
    );
    await tester.pump();

    expect(find.text('BTC-USDC'), findsOneWidget);
    expect(find.text('Oracle Price'), findsOneWidget);
    expect(find.text('Order Book'), findsOneWidget);
    expect(find.text('Buy / Long'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
