import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(this._repo, this._companyId) : super(const ProductsState());

  final ProductRepository _repo;
  final String _companyId;

  int _request = 0; // ignore out-of-order search responses

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: ProductsStatus.loading));
    final id = ++_request;
    try {
      final products = await _repo.search(_companyId, query: state.query);
      if (id != _request || isClosed) return;
      emit(state.copyWith(status: ProductsStatus.loaded, products: products));
      _loadCategoriesOnce();
    } on Failure catch (e) {
      if (id != _request || isClosed) return;
      final keep = silent && state.status == ProductsStatus.loaded;
      emit(state.copyWith(
        status: keep ? ProductsStatus.loaded : ProductsStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> search(String query) {
    emit(state.copyWith(query: query.trim()));
    return load(silent: true);
  }

  /// Returns the product for an exact barcode match, or null.
  /// Emits an error message on failure.
  Future<Product?> findByBarcode(String barcode) async {
    try {
      return await _repo.findByBarcode(_companyId, barcode);
    } on Failure catch (e) {
      emit(state.copyWith(errorMessage: e.message));
      return null;
    }
  }

  Future<bool> save(Product product) =>
      _run(() => _repo.save(_companyId, product));

  Future<bool> delete(Product product) => _run(() => _repo.delete(product.id));

  Future<bool> _run(Future<void> Function() action) async {
    emit(state.copyWith(isBusy: true));
    try {
      await action();
      final products = await _repo.search(_companyId, query: state.query);
      emit(state.copyWith(isBusy: false, products: products));
      return true;
    } on Failure catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: e.message));
      return false;
    }
  }

  // Categories are optional: a role without product_categories.read still works.
  Future<void> _loadCategoriesOnce() async {
    if (state.categories.isNotEmpty) return;
    try {
      final cats = await _repo.getCategories(_companyId);
      if (!isClosed) emit(state.copyWith(categories: cats));
    } on Failure {
      // ignore
    }
  }
}
