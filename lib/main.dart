import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'features/Purchasing/data/purchase_order_remote_data_source.dart';
import 'features/Purchasing/data/purchase_order_repository_impl.dart';
import 'features/Purchasing/domain/purchase_order_repository.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/company/data/datasources/company_remote_data_source.dart';
import 'features/company/data/repositories/company_repository_impl.dart';
import 'features/company/domain/repositories/company_repository.dart';
import 'features/customers/data/datasources/customer_remote_data_source.dart';
import 'features/customers/data/repositories/customer_repository_impl.dart';
import 'features/customers/domain/repositories/customer_repository.dart';

import 'features/dashboard/data/dashboard_remote_data_source.dart';
import 'features/dashboard/data/dashboard_repository_impl.dart';
import 'features/dashboard/domain/dashboard_repository.dart';
import 'features/members/data/datasources/member_remote_data_source.dart';
import 'features/members/data/repositories/member_repository_impl.dart';
import 'features/members/domain/repositories/member_repository.dart';
import 'features/permissions/data/datasources/permission_remote_data_source.dart';
import 'features/permissions/data/repositories/permission_repository_impl.dart';
import 'features/permissions/domain/repositories/permission_repository.dart';
import 'features/products/data/datasources/product_remote_data_source.dart';
import 'features/products/data/repositories/product_repository_impl.dart';
import 'features/products/domain/repositories/product_repository.dart';

import 'features/roles/data/datasources/role_remote_data_source.dart';
import 'features/roles/data/repositories/role_repository_impl.dart';
import 'features/roles/domain/repositories/role_repository.dart';
import 'features/sales/data/datasources/sales_invoice_remote_data_source.dart';
import 'features/sales/data/repositories/sales_invoice_repository_impl.dart';
import 'features/sales/domain/repositories/sales_invoice_repository.dart';
import 'features/stock/data/datasources/stock_remote_data_source.dart';
import 'features/stock/data/repositories/stock_repository_impl.dart';
import 'features/stock/domain/repositories/stock_repository.dart';

import 'features/supliers/data/supplier_remote_data_source.dart';
import 'features/supliers/data/supplier_repository_impl.dart';
import 'features/supliers/domain/supplier_repository.dart';
import 'features/warehouses/data/datasources/warehouse_remote_data_source.dart';
import 'features/warehouses/data/repositories/warehouse_repository_impl.dart';
import 'features/warehouses/domain/repositories/warehouse_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  final client = Supabase.instance.client;

  // Manual wiring (composition root): data source -> repository impl.
  final AuthRepository authRepository =
  AuthRepositoryImpl(AuthRemoteDataSourceImpl(client));
  final CompanyRepository companyRepository =
  CompanyRepositoryImpl(CompanyRemoteDataSourceImpl(client));
  final PermissionRepository permissionRepository =
  PermissionRepositoryImpl(PermissionRemoteDataSourceImpl(client));
  final RoleRepository roleRepository =
  RoleRepositoryImpl(RoleRemoteDataSourceImpl(client));
  final MemberRepository memberRepository =
  MemberRepositoryImpl(MemberRemoteDataSourceImpl(client));
  final ProductRepository productRepository =
  ProductRepositoryImpl(ProductRemoteDataSourceImpl(client));
  final CustomerRepository customerRepository =
  CustomerRepositoryImpl(CustomerRemoteDataSourceImpl(client));
  final WarehouseRepository warehouseRepository =
  WarehouseRepositoryImpl(WarehouseRemoteDataSourceImpl(client));
  final StockRepository stockRepository =
  StockRepositoryImpl(StockRemoteDataSourceImpl(client));
  final SalesInvoiceRepository salesInvoiceRepository =
  SalesInvoiceRepositoryImpl(SalesInvoiceRemoteDataSourceImpl(client));
  final DashboardRepository dashboardRepository =
  DashboardRepositoryImpl(DashboardRemoteDataSourceImpl(client));
  final SupplierRepository supplierRepository =
  SupplierRepositoryImpl(SupplierRemoteDataSourceImpl(client));
  final PurchaseOrderRepository purchaseOrderRepository =
  PurchaseOrderRepositoryImpl(PurchaseOrderRemoteDataSourceImpl(client));

  runApp(ErpApp(
    authRepository: authRepository,
    companyRepository: companyRepository,
    permissionRepository: permissionRepository,
    roleRepository: roleRepository,
    memberRepository: memberRepository,
    productRepository: productRepository,
    customerRepository: customerRepository,
    warehouseRepository: warehouseRepository,
    stockRepository: stockRepository,
    salesInvoiceRepository: salesInvoiceRepository,
    dashboardRepository: dashboardRepository,
    supplierRepository: supplierRepository,
    purchaseOrderRepository: purchaseOrderRepository,
  ));
}