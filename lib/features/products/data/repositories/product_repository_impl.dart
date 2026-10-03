import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remote);

  final ProductRemoteDataSource _remote;

  @override
  Future<List<Product>> search(String companyId, {String query = ''}) =>
      _remote.search(companyId, query);

  @override
  Future<Product?> findByBarcode(String companyId, String barcode) =>
      _remote.findByBarcode(companyId, barcode.trim());

  @override
  Future<List<ProductCategory>> getCategories(String companyId) =>
      _remote.fetchCategories(companyId);

  @override
  Future<void> save(String companyId, Product product) =>
      _remote.save(companyId, product);

  @override
  Future<void> delete(String productId) => _remote.delete(productId);
}
