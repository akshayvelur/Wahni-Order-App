import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wahniorderapp/widgets/quantity_input.dart';

void main() {
  group('QuantityInput Widget Audit Requirements', () {
    testWidgets('Renders initial quantity in TextField', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityInput(quantity: 5, onQuantityChanged: (_) {}),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('Plus button increments quantity', (tester) async {
      int updatedQuantity = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityInput(
              quantity: 3,
              onQuantityChanged: (qty) => updatedQuantity = qty,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();

      expect(updatedQuantity, 4);
    });

    testWidgets('Minus button decrements quantity', (tester) async {
      int updatedQuantity = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityInput(
              quantity: 3,
              onQuantityChanged: (qty) => updatedQuantity = qty,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();

      expect(updatedQuantity, 2);
    });

    testWidgets('Minus button at quantity 1 removes product (triggers 0)', (
      tester,
    ) async {
      int updatedQuantity = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityInput(
              quantity: 1,
              onQuantityChanged: (qty) => updatedQuantity = qty,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();

      expect(updatedQuantity, 0);
    });

    testWidgets('Directly typing zero removes product (triggers 0)', (
      tester,
    ) async {
      int updatedQuantity = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityInput(
              quantity: 4,
              onQuantityChanged: (qty) => updatedQuantity = qty,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '0');
      await tester.pump();

      expect(updatedQuantity, 0);
    });

    testWidgets('Empty input removes the product (triggers 0)', (tester) async {
      int updatedQuantity = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityInput(
              quantity: 4,
              onQuantityChanged: (qty) => updatedQuantity = qty,
            ),
          ),
        ),
      );

      // Clear text completely
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(updatedQuantity, 0);
    });

    testWidgets(
      'Only digits accepted: text, negative numbers, and decimals are rejected',
      (tester) async {
        int updatedQuantity = 5;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuantityInput(
                quantity: 5,
                onQuantityChanged: (qty) => updatedQuantity = qty,
              ),
            ),
          ),
        );

        // Try typing letters: 'abc'
        await tester.enterText(find.byType(TextField), 'abc');
        await tester.pump();
        // Text is stripped by FilteringTextInputFormatter.digitsOnly -> empty -> 0
        expect(find.text('abc'), findsNothing);

        // Try typing negative number: '-4'
        await tester.enterText(find.byType(TextField), '-4');
        await tester.pump();
        // Negative sign stripped -> only '4' accepted
        expect(find.text('-4'), findsNothing);
        expect(find.text('4'), findsOneWidget);
        expect(updatedQuantity, 4);

        // Try typing decimal number: '4.5'
        await tester.enterText(find.byType(TextField), '4.5');
        await tester.pump();
        // Decimal point stripped -> '45'
        expect(find.text('4.5'), findsNothing);
      },
    );

    testWidgets(
      'Focus remains stable and typed text is not overwritten during external rebuild while focused',
      (tester) async {
        int externalQuantity = 5;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                home: Scaffold(
                  body: Column(
                    children: [
                      QuantityInput(
                        quantity: externalQuantity,
                        onQuantityChanged: (_) {},
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            externalQuantity = 99; // external state update
                          });
                        },
                        child: const Text('External Rebuild'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );

        // Focus the text field
        await tester.tap(find.byType(TextField));
        await tester.pump();

        // Type '12'
        await tester.enterText(find.byType(TextField), '12');
        await tester.pump();
        expect(find.text('12'), findsOneWidget);

        // Trigger external rebuild while focused
        await tester.tap(find.text('External Rebuild'));
        await tester.pump();

        // While focused, typed text '12' is NOT overwritten by external 99
        expect(find.text('12'), findsOneWidget);
      },
    );
  });
}
