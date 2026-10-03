import 'package:erb3/features/Purchasing/data/purchase_order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/guard_remote.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/search_filter.dart';
import '../domain/purchase_draft.dart';
import '../domain/purchase_order.dar.dart';


abstract class PurchaseOrderRemoteDataSource {
  Future<List<PurchaseOrder>> fetchOrders(
      String companyId, PurchaseStatus? status, String query);
  Future<PurchaseOrder> fetchOrder(String orderId);
  Future<String> saveDraft(String companyId, PurchaseDraft draft);
  Future<void> confirm(String orderId);
  Future<void> cancel(String orderId);
  Future<void> deleteDraft(String orderId);
}

class PurchaseOrderRemoteDataSourceImpl implements PurchaseOrderRemoteDataSource {
  PurchaseOrderRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const _limit = 100;

  static const _listColumns =
      'id, number, status, supplier_id, warehouse_id, order_date, subtotal, '
      'tax_total, total, note, suppliers(name)';

  static const _detailColumns =
      '*, suppliers(name), warehouses(name), '
      'purchase_order_items(product_id, quantity, unit_cost, tax_rate, '
      'products(name, sku, unit))';

  @override
  Future<List<PurchaseOrder>> fetchOrders(
      String companyId, PurchaseStatus? status, String query) =>
      guardRemote(() async {
        var req = _client
            .from('purchase_orders')
            .select(_listColumns)
            .eq('company_id', companyId);
        if (status != null) req = req.eq('status', status.name);
        final q = sanitizeSearch(query);
        if (q.isNotEmpty) req = req.ilike('number', '%$q%');
        final rows = await req.order('created_at', ascending: false).limit(_limit);
        return rows.map(PurchaseOrderModel.fromJson).toList();
      });

  @override
  Future<PurchaseOrder> fetchOrder(String orderId) => guardRemote(() async {
    final row = await _client
        .from('purchase_orders')
        .select(_detailColumns)
        .eq('id', orderId)
        .single();
    return PurchaseOrderModel.fromJson(row);
  });

  @override
  Future<String> saveDraft(String companyId, PurchaseDraft draft) =>
      guardRemote(() async {
        final id = await _client.rpc('save_purchase_draft', params: {
          'p_company': companyId,
          'p_order_id': draft.id,
          'p_supplier': draft.supplierId,
          'p_warehouse': draft.warehouseId,
          'p_order_date': fmtDate(draft.orderDate),
          'p_note': draft.note,
          'p_items': [
            for (final i in draft.items)
              {
                'product_id': i.productId,
                'quantity': i.quantity,
                'unit_cost': i.unitCost,
              },
          ],
        });
        return id as String;
      });

  @override
  Future<void> confirm(String orderId) => guardRemote(() async {
    await _client.rpc('confirm_purchase_order', params: {'p_order_id': orderId});
  });

  @override
  Future<void> cancel(String orderId) => guardRemote(() async {
    await _client.rpc('cancel_purchase_order', params: {'p_order_id': orderId});
  });

  @override
  Future<void> deleteDraft(String orderId) => guardRemote(() async {
    await _client.rpc('delete_purchase_draft', params: {'p_order_id': orderId});
  });
}