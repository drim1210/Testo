import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testo/core/theme/app_theme.dart';
import 'package:testo/shared/widgets/app_button.dart';
import 'package:testo/shared/widgets/app_card.dart';

void main() {
  group('AppButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppButton(label: 'Test Button', onPressed: () {}),
          ),
        ),
      );
      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('shows loader when isLoading=true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: const AppButton(label: 'Loading', isLoading: true),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('disabled when onPressed=null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: const AppButton(label: 'Disabled'),
          ),
        ),
      );
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });

  group('AppCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: AppCard(child: Text('Card Content')),
          ),
        ),
      );
      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppCard(
              onTap: () => tapped = true,
              child: const Text('Tap me'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tap me'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
