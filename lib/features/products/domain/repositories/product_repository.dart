import '../entities/product.dart';
import '../entities/product_category.dart';

abstract class ProductRepository {
  /// Matches name, SKU or barcode (case-insensitive, partial).
  Future<List<Product>> search(String companyId, {String query = ''});

  /// Exact barcode match, or null.
  Future<Product?> findByBarcode(String companyId, String barcode);

  Future<List<ProductCategory>> getCategories(String companyId);

  /// Inserts when [product].isNew, otherwise updates.
  Future<void> save(String companyId, Product product);

  Future<void> delete(String productId);
}
