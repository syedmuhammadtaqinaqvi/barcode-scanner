// Test file for Google ML Kit Barcode Scanner Flutter App
//
// Tests the core functionality of the barcode scanner application.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:barcode_scanner_app/main.dart';

void main() {
  group('Google ML Kit Barcode Scanner Tests', () {
    testWidgets('App launches and shows home screen', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const SmartScannerApp());

      // Verify that the home screen loads with the correct title.
      expect(find.text('Smart Scanner'), findsOneWidget);
      expect(find.text('ML Kit Scanner'), findsOneWidget);
      expect(find.text('Scan QR & Barcodes'), findsOneWidget);
    });

    testWidgets('Home screen shows all ML Kit features', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const SmartScannerApp());

      // Verify that all ML Kit features are displayed.
      expect(find.text('Scan QR & Barcodes'), findsOneWidget);
      expect(find.text('Face Detection'), findsOneWidget);
      expect(find.text('Face Mesh Detection'), findsOneWidget);
      expect(find.text('Text Recognition'), findsOneWidget);
    });

    testWidgets('Home screen shows feature highlights', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const SmartScannerApp());

      // Verify that feature highlights are shown.
      expect(find.text('Fast'), findsOneWidget);
      expect(find.text('Accurate'), findsOneWidget);
      expect(find.text('Secure'), findsOneWidget);
    });

    testWidgets('App has correct theme and styling', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const SmartScannerApp());

      // Verify the app uses Material Design 3.
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.useMaterial3, isTrue);
      expect(app.title, equals('Smart Scanner - ML Kit'));
    });
  });
}
