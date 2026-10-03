/// Keys must match rows in the `permissions` table.
class PermissionKeys {
  PermissionKeys._();

  static const companyManage = 'company.manage';
  static const rolesManage = 'roles.manage';
  static const membersManage = 'members.manage';

  static const productsRead = 'products.read';
  static const productsWrite = 'products.write';
  static const productsDelete = 'products.delete';
  static const productCategoriesRead = 'product_categories.read';
  static const customersRead = 'customers.read';
  static const customersWrite = 'customers.write';
  static const customersDelete = 'customers.delete';
  static const suppliersRead = 'suppliers.read';
  static const suppliersWrite = 'suppliers.write';
  static const suppliersDelete = 'suppliers.delete';
  static const stockLevelsRead = 'stock_levels.read';
  static const salesInvoicesRead = 'sales_invoices.read';
  static const purchaseOrdersRead = 'purchase_orders.read';
  static const purchaseOrdersWrite = 'purchase_orders.write';
  static const purchaseOrdersDelete = 'purchase_orders.delete';
  static const purchaseOrdersConfirm = 'purchase_orders.confirm';
  static const purchaseOrdersCancel = 'purchase_orders.cancel';
  static const auditLogRead = 'audit_log.read';

  static const warehousesRead = 'warehouses.read';
  static const warehousesWrite = 'warehouses.write';
  static const warehousesDelete = 'warehouses.delete';
  static const stockLevelsAdjust = 'stock_levels.adjust';
  static const stockMovementsRead = 'stock_movements.read';

  static const salesInvoicesWrite = 'sales_invoices.write';
  static const salesInvoicesDelete = 'sales_invoices.delete';
  static const salesInvoicesConfirm = 'sales_invoices.confirm';
  static const salesInvoicesCancel = 'sales_invoices.cancel';
  static const salesPaymentsWrite = 'sales_payments.write';
}