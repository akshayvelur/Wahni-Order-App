import 'package:equatable/equatable.dart';

import '../../data/models/product_model.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any product event is dispatched.
class ProductInitial extends ProductState {
  const ProductInitial();
}

/// Loading state shown when products are being fetched.
class ProductLoading extends ProductState {
  const ProductLoading();
}

/// Success state containing the list of loaded products.
class ProductSuccess extends ProductState {
  final List<ProductModel> products;

  const ProductSuccess(this.products);

  @override
  List<Object?> get props => [products];
}

/// Failure state containing an error message.
class ProductFailure extends ProductState {
  final String message;

  const ProductFailure(this.message);

  @override
  List<Object?> get props => [message];
}
