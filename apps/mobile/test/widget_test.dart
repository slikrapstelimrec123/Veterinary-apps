import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet_care_mobile/main.dart';

void main() {
  testWidgets('app starts with the configured shell', (tester) async {
    await tester.pumpWidget(VetCareApp(appLinks: AppLinks()));
    await tester.pump(const Duration(seconds: 3));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'Lappo');
    expect(app.debugShowCheckedModeBanner, isFalse);
  });
}
