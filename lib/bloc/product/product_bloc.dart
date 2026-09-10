import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/product_api_service.dart';
import '../../data/repositories/product_repository.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repository;

  ProductBloc({ProductRepository? repository})
    : _repository = repository ?? ProductRepository(),
      super(const ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<RefreshProducts>(_onRefreshProducts);
    on<RetryProducts>(_onRetryProducts);
  }

  /// Handles initial loading:
  /// 1. Exposes cached products immediately if available.
  /// 2. Fetches fresh products from the API.
  /// 3. If API fails but cache was displayed, keeps cached products.
  /// 4. If no cache exists and API fails, emits failure state.
  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    final cached = _repository.getCachedProducts();
    if (cached.isNotEmpty) {
      emit(ProductSuccess(cached));
    } else {
      emit(const ProductLoading());
    }

    try {
      final products = await _repository.fetchFreshProducts();
      emit(ProductSuccess(products));
    } catch (error) {
      if (state is! ProductSuccess) {
        emit(ProductFailure(_mapErrorToMessage(error)));
      }
    }
  }

  /// Handles refresh:
  /// Fetches fresh products without flashing a fullscreen loader if products are already present.
  Future<void> _onRefreshProducts(
    RefreshProducts event,
    Emitter<ProductState> emit,
  ) async {
    if (state is! ProductSuccess) {
      emit(const ProductLoading());
    }

    try {
      final products = await _repository.fetchFreshProducts();
      emit(ProductSuccess(products));
    } catch (error) {
      if (state is! ProductSuccess) {
        emit(ProductFailure(_mapErrorToMessage(error)));
      }
    }
  }

  /// Handles retry after failure:
  /// Emits loading and attempts to fetch products again.
  Future<void> _onRetryProducts(
    RetryProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());

    try {
      final products = await _repository.fetchFreshProducts();
      emit(ProductSuccess(products));
    } catch (error) {
      final cached = _repository.getCachedProducts();
      if (cached.isNotEmpty) {
        emit(ProductSuccess(cached));
      } else {
        emit(ProductFailure(_mapErrorToMessage(error)));
      }
    }
  }

  String _mapErrorToMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return error?.toString() ??
        'An unexpected error occurred. Please try again.';
  }
}
