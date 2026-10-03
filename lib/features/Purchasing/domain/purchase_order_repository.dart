
import 'package:erb3/features/Purchasing/domain/purchase_draft.dart';
import 'package:erb3/features/Purchasing/domain/purchase_order.dar.dart';

abstract class PurchaseOrderRepository {
  /// Newest first. [query] matches the order number.
  Future<List<PurchaseOrder>> getOrders(
      String companyId, {
        PurchaseStatus? status,
        String query = '',
      });

  /// With items.
  Future<PurchaseOrder> getOrder(String orderId);

  /// Creates or updates a draft atomically. Returns the order id.
  Future<String> saveDraft(String companyId, PurchaseDraft draft);

  /// Adds the items to stock and assigns the order number.
  Future<void> confirm(String orderId);

  /// Confirmed orders only. Takes the stock back out.
  Future<void> cancel(String orderId);

  Future<void> deleteDraft(String orderId);
}