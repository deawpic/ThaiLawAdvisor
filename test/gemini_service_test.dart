import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:thailaw/services/gemini_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends http.BaseClient {
  int requestCount = 0;
  final int failWith429Count;
  final int failWith503Count;
  final int successStatusCode;
  final String successBody;

  MockHttpClient({
    this.failWith429Count = 0,
    this.failWith503Count = 0,
    this.successStatusCode = 200,
    this.successBody = '{"candidates":[{"content":{"parts":[{"text":"Mocked Gemini Response"}]}}], "usageMetadata": {"promptTokenCount": 100, "candidatesTokenCount": 50, "totalTokenCount": 150}}',
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestCount++;
    if (requestCount <= failWith429Count) {
      return http.StreamedResponse(
        Stream.value(utf8.encode('Too Many Requests')),
        429,
      );
    }
    if (requestCount <= failWith429Count + failWith503Count) {
      return http.StreamedResponse(
        Stream.value(utf8.encode('Service Unavailable')),
        503,
      );
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode(successBody)),
      successStatusCode,
    );
  }
}

void main() {
  const MethodChannel secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'read') {
        return 'mock-api-key';
      }
      return null;
    });
  });

  test('Exponential backoff retry with 429 status code', () async {
    final client = MockHttpClient(failWith429Count: 2); // Should fail 2 times and succeed on 3rd

    final result = await GeminiService.analyzeLegalSituation(
      'Test situation',
      'gemini-3.5-flash',
      client: client,
      initialDelay: Duration.zero,
    );

    expect(result.text, equals('Mocked Gemini Response'));
    expect(client.requestCount, equals(3)); // 2 retries + 1 initial
    expect(result.promptTokens, equals(100));
    expect(result.candidateTokens, equals(50));
    expect(result.totalTokens, equals(150));
  });

  test('Exponential backoff retry with 503 status code (transient)', () async {
    final client = MockHttpClient(failWith503Count: 2); // Should fail 2 times and succeed on 3rd

    final result = await GeminiService.analyzeLegalSituation(
      'Test situation',
      'gemini-3.5-flash',
      client: client,
      initialDelay: Duration.zero,
    );

    expect(result.text, equals('Mocked Gemini Response'));
    expect(client.requestCount, equals(3)); // 2 retries + 1 initial
    expect(result.promptTokens, equals(100));
    expect(result.candidateTokens, equals(50));
    expect(result.totalTokens, equals(150));
  });

  test('Persistent 503 status code fails after max retries', () async {
    final client = MockHttpClient(failWith503Count: 6); // Fails 6 times, max retries is 5 (6 total attempts)

    await expectLater(
      GeminiService.analyzeLegalSituation(
        'Test situation',
        'gemini-3.5-flash',
        client: client,
        initialDelay: Duration.zero,
      ),
      throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('API_ERROR_503'))),
    );

    expect(client.requestCount, equals(6)); // 1 initial + 5 retries = 6 total attempts
  });
}
