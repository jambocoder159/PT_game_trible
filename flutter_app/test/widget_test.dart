import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match3_puzzle/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots into the initialization shell', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const Match3App());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
