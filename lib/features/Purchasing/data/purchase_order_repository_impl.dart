

import 'package:erb3/features/Purchasing/data/purchase_order_remote_data_source.dart';

import '../domain/purchase_draft.dart';
import '../domain/purchase_order.dar.dart';
import '../domain/purchase_order_repository.dart';

class PurchaseOrderRepositoryImpl implements PurchaseOrderRepository {
  PurchaseOrderRepositoryImpl(this._remote);

  final PurchaseOrderRemoteDataSource _remote;

  @override
  Future<List<PurchaseOrder>> getOrders(
      String companyId, {
        PurchaseStatus? status,
        String query = '',
      }) =>
      _remote.fetchOrders(companyId, status, query);

  @override
  Future<PurchaseOrder> getOrder(String orderId) => _remote.fetchOrder(orderId);

  @override
  Future<String> saveDraft(String companyId, PurchaseDraft draft) =>
      _remote.saveDraft(companyId, draft);

  @override
  Future<void> confirm(String orderId) => _remote.confirm(orderId);

  @override
  Future<void> cancel(String orderId) => _remote.cancel(orderId);

  @override
  Future<void> deleteDraft(String orderId) => _remote.deleteDraft(orderId);
}