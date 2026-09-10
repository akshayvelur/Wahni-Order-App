import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wahniorderapp/bloc/cart/cart_bloc.dart';
import 'package:wahniorderapp/bloc/cart/cart_event.dart';
import 'package:wahniorderapp/bloc/cart/cart_state.dart';
import 'package:wahniorderapp/data/datasources/local_database.dart';

void main() {
  late Directory tempDir;
  late Box productsBox;
  late Box cartBox;
  late LocalDatabase localDatabase;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cart_bloc_test_');
    Hive.init(tempDir.path);
    productsBox = await Hive.openBox(LocalDatabase.productsBoxName);
    cartBox = await Hive.openBox(LocalDatabase.cartBoxName);
    localDatabase = LocalDatabase(productsBox: productsBox, cartBox: cartBox);
  });

  tearDown(() async {
    await productsBox.close();
    await cartBox.close();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CartState Derived Values', () {
    test('calculates uniqueItems and totalQuantity correctly matching prompt example', () {
      // Prompt example: A = 5, B = 2, C = 1 -> uniqueItems = 3, totalQuantity = 8
      const state = CartState(quantities: {101: 5, 102: 2, 103: 1});

      expect(state.uniqueItems, 3);
      expect(state.totalQuantity, 8);
      expect(state.getQuantity(101), 5);
      expect(state.getQuantity(102), 2);
      expect(state.getQuantity(103), 1);
      expect(state.getQuantity(999), 0);
      expect(state.containsProduct(101), isTrue);
      expect(state.containsProduct(999), isFalse);
    });

    test('returns 0 for uniqueItems and totalQuantity when empty', () {
      const state = CartInitial();
      expect(state.uniqueItems, 0);
      expect(state.totalQuantity, 0);
      expect(state.quantities, isEmpty);
    });
  });

  group('CartBloc', () {
    test('initial state is CartInitial with empty quantities', () {
      final bloc = CartBloc(localDatabase: localDatabase);
      expect(bloc.state, const CartInitial());
      expect(bloc.state.quantities, isEmpty);
      bloc.close();
    });

    test('AddToCart sets quantity to 1 when product is not in cart and persists to Hive', () async {
      final bloc = CartBloc(localDatabase: localDatabase);

      expectLater(bloc.stream, emits(const CartLoaded({1: 1})));

      bloc.add(const AddToCart(1));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(localDatabase.getCartQuantity(1), 1);
      expect(localDatabase.getCartQuantities(), {1: 1});

      await bloc.close();
    });

    test('AddToCart increments quantity when product already exists without resetting', () async {
      final bloc = CartBloc(localDatabase: localDatabase);

      bloc.add(const AddToCart(1));
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const AddToCart(1));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.getQuantity(1), 2);
      expect(localDatabase.getCartQuantity(1), 2);

      bloc.add(const AddToCart(1));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.getQuantity(1), 3);
      expect(localDatabase.getCartQuantity(1), 3);

      await bloc.close();
    });

    test(
      'UpdateQuantity updates with positive integer and persists to Hive',
      () async {
        final bloc = CartBloc(localDatabase: localDatabase);

        bloc.add(const UpdateQuantity(productId: 5, quantity: 10));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(bloc.state.getQuantity(5), 10);
        expect(localDatabase.getCartQuantity(5), 10);

        await bloc.close();
      },
    );

    test(
      'UpdateQuantity with zero removes product from state and Hive',
      () async {
        final bloc = CartBloc(localDatabase: localDatabase);

        bloc.add(const AddToCart(2));
        await Future.delayed(const Duration(milliseconds: 50));
        expect(bloc.state.containsProduct(2), isTrue);

        bloc.add(const UpdateQuantity(productId: 2, quantity: 0));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(bloc.state.containsProduct(2), isFalse);
        expect(bloc.state.quantities, isEmpty);
        expect(localDatabase.getCartQuantity(2), 0);
        expect(localDatabase.getCartQuantities(), isEmpty);

        await bloc.close();
      },
    );

    test('UpdateQuantity with negative quantity removes product and never stores negative numbers', () async {
      final bloc = CartBloc(localDatabase: localDatabase);

      bloc.add(const AddToCart(3));
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const UpdateQuantity(productId: 3, quantity: -5));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.containsProduct(3), isFalse);
      expect(localDatabase.getCartQuantity(3), 0);
      expect(localDatabase.getCartQuantities().containsKey(3), isFalse);

      await bloc.close();
    });

    test(
      'RemoveFromCart removes product from in-memory state and Hive',
      () async {
        final bloc = CartBloc(localDatabase: localDatabase);

        bloc.add(const AddToCart(10));
        bloc.add(const AddToCart(20));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(bloc.state.uniqueItems, 2);

        bloc.add(const RemoveFromCart(10));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(bloc.state.containsProduct(10), isFalse);
        expect(bloc.state.containsProduct(20), isTrue);
        expect(bloc.state.uniqueItems, 1);
        expect(localDatabase.getCartQuantity(10), 0);
        expect(localDatabase.getCartQuantity(20), 1);

        await bloc.close();
      },
    );

    test('Cart restores completely after simulated app restart', () async {
      // 1. Session 1: Add items to cart
      final session1Bloc = CartBloc(localDatabase: localDatabase);
      session1Bloc.add(const UpdateQuantity(productId: 1, quantity: 5));
      session1Bloc.add(const UpdateQuantity(productId: 2, quantity: 2));
      session1Bloc.add(const UpdateQuantity(productId: 3, quantity: 1));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(session1Bloc.state.uniqueItems, 3);
      expect(session1Bloc.state.totalQuantity, 8);
      await session1Bloc.close();

      // 2. Simulate application termination: close Hive boxes
      await cartBox.close();

      // 3. Simulate new app launch: reopen boxes from storage
      final reopenedCartBox = await Hive.openBox(LocalDatabase.cartBoxName);
      final restoredDb = LocalDatabase(
        productsBox: productsBox,
        cartBox: reopenedCartBox,
      );

      // 4. Session 2: Launch CartBloc and dispatch LoadCart
      final session2Bloc = CartBloc(localDatabase: restoredDb);
      session2Bloc.add(const LoadCart());
      await Future.delayed(const Duration(milliseconds: 50));

      // 5. Verify restored state matches exactly
      expect(session2Bloc.state.uniqueItems, 3);
      expect(session2Bloc.state.totalQuantity, 8);
      expect(session2Bloc.state.getQuantity(1), 5);
      expect(session2Bloc.state.getQuantity(2), 2);
      expect(session2Bloc.state.getQuantity(3), 1);

      await session2Bloc.close();
      await reopenedCartBox.close();
      // Re-open for tearDown
      cartBox = await Hive.openBox(LocalDatabase.cartBoxName);
    });
  });
}
