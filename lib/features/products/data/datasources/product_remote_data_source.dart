import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/guard_remote.dart';
import '../../../../core/utils/search_filter.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<Product>> search(String companyId, String query);
  Future<Product?> findByBarcode(String companyId, String barcode);
  Future<List<ProductCategory>> fetchCategories(String companyId);
  Future<void> save(String companyId, Product product);
  Future<void> delete(String productId);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  ProductRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const _limit = 100;

  @override
  Future<List<Product>> search(String companyId, String query) =>
      guardRemote(() async {
        var req = _client.from('products').select().eq('company_id', companyId);
        final q = sanitizeSearch(query);
        if (q.isNotEmpty) {
          req = req.or('name.ilike.%$q%,sku.ilike.%$q%,barcode.ilike.%$q%');
        }
        final rows = await req.order('name').limit(_limit);
        return rows.map(ProductModel.fromJson).toList();
      });

  @override
  Future<Product?> findByBarcode(String companyId, String barcode) =>
      guardRemote(() async {
        final rows = await _client
            .from('products')
            .select()
            .eq('company_id', companyId)
            .eq('barcode', barcode)
            .limit(1);
        return rows.isEmpty ? null : ProductModel.fromJson(rows.first);
      });

  @override
  Future<List<ProductCategory>> fetchCategories(String companyId) =>
      guardRemote(() async {
        final rows = await _client
            .from('product_categories')
            .select('id, name')
            .eq('company_id', companyId)
            .order('name');
        return rows.map(ProductModel.categoryFromJson).toList();
      });

  @override
  Future<void> save(String companyId, Product product) => guardRemote(() async {
        try {
          final data = ProductModel.toJson(product);
          if (product.isNew) {
            await _client.from('products').insert({...data, 'company_id': companyId});
          } else {
            await _client.from('products').update(data).eq('id', product.id);
          }
        } on PostgrestException catch (e) {
          if (e.code == '23505') throw const Failure('This SKU already exists.');
          rethrow;
        }
      });

  @override
  Future<void> delete(String productId) => guardRemote(() async {
        try {
          await _client.from('products').delete().eq('id', productId);
        } on PostgrestException catch (e) {
          if (e.code == '23503') {
            throw const Failure(
                'This product is used in documents. Deactivate it instead.');
          }
          rethrow;
        }
      });
}
