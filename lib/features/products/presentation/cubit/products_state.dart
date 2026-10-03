import 'package:equatable/equatable.dart';

import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';

enum ProductsStatus { initial, loading, loaded, failure }

class ProductsState extends Equatable {
  const ProductsState({
    this.status = ProductsStatus.initial,
    this.products = const [],
    this.categories = const [],
    this.query = '',
    this.isBusy = false,
    this.errorMessage,
  });

  final ProductsStatus status;
  final List<Product> products;
  final List<ProductCategory> categories;
  final String query;
  final bool isBusy;
  final String? errorMessage;

  /// errorMessage is cleared on every copy unless passed again.
  ProductsState copyWith({
    ProductsStatus? status,
    List<Product>? products,
    List<ProductCategory>? categories,
    String? query,
    bool? isBusy,
    String? errorMessage,
  }) =>
      ProductsState(
        status: status ?? this.status,
        products: products ?? this.products,
        categories: categories ?? this.categories,
        query: query ?? this.query,
        isBusy: isBusy ?? this.isBusy,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props =>
      [status, products, categories, query, isBusy, errorMessage];
}
