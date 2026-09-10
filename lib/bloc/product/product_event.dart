import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered to load products on app/screen startup.
class LoadProducts extends ProductEvent {
  const LoadProducts();
}

/// Event triggered when the user initiates a pull-to-refresh or explicit refresh.
class RefreshProducts extends ProductEvent {
  const RefreshProducts();
}

/// Event triggered when retrying to load products after a failure.
class RetryProducts extends ProductEvent {
  const RetryProducts();
}
