import 'package:flutter_test/flutter_test.dart';
import 'package:thailaw/main.dart';
import 'package:hive/hive.dart';
import 'package:flutter/services.dart';

void main() {
  const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });

    Hive.init('.');
    await Hive.openBox('history_box');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App builds and displays main title', (WidgetTester tester) async {
    await tester.pumpWidget(const ThaiLawApp());
    await tester.pumpAndSettle();

    expect(find.text('วิเคราะห์กฎหมายไทย'), findsOneWidget);
  });
}
