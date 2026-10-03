import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_gate.dart';
import 'features/Purchasing/domain/purchase_order_repository.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/company/domain/repositories/company_repository.dart';
import 'features/company/presentation/cubit/company_cubit.dart';
import 'features/customers/domain/repositories/customer_repository.dart';
import 'features/dashboard/domain/dashboard_repository.dart';
import 'features/members/domain/repositories/member_repository.dart';
import 'features/permissions/domain/repositories/permission_repository.dart';
import 'features/permissions/presentation/cubit/permissions_cubit.dart';
import 'features/products/domain/repositories/product_repository.dart';
 import 'features/roles/domain/repositories/role_repository.dart';
import 'features/sales/domain/repositories/sales_invoice_repository.dart';
import 'features/stock/domain/repositories/stock_repository.dart';
 import 'features/supliers/domain/supplier_repository.dart';
import 'features/warehouses/domain/repositories/warehouse_repository.dart';
import 'core/layout/responsive.dart';
import 'core/theme/app_theme.dart';

class ErpApp extends StatelessWidget {
  const ErpApp({
    super.key,
    required this.authRepository,
    required this.companyRepository,
    required this.permissionRepository,
    required this.roleRepository,
    required this.memberRepository,
    required this.productRepository,
    required this.customerRepository,
    required this.warehouseRepository,
    required this.stockRepository,
    required this.salesInvoiceRepository,
    required this.dashboardRepository,
    required this.supplierRepository,
    required this.purchaseOrderRepository,
  });

  final AuthRepository authRepository;
  final CompanyRepository companyRepository;
  final PermissionRepository permissionRepository;
  final RoleRepository roleRepository;
  final MemberRepository memberRepository;
  final ProductRepository productRepository;
  final CustomerRepository customerRepository;
  final WarehouseRepository warehouseRepository;
  final StockRepository stockRepository;
  final SalesInvoiceRepository salesInvoiceRepository;
  final DashboardRepository dashboardRepository;
  final SupplierRepository supplierRepository;
  final PurchaseOrderRepository purchaseOrderRepository;

  @override
  Widget build(BuildContext context) {
    // Repositories are exposed so screens can create their own cubits
    // (context.read<RoleRepository>()). No DI package involved.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PermissionRepository>.value(value: permissionRepository),
        RepositoryProvider<RoleRepository>.value(value: roleRepository),
        RepositoryProvider<MemberRepository>.value(value: memberRepository),
        RepositoryProvider<ProductRepository>.value(value: productRepository),
        RepositoryProvider<CustomerRepository>.value(value: customerRepository),
        RepositoryProvider<WarehouseRepository>.value(value: warehouseRepository),
        RepositoryProvider<StockRepository>.value(value: stockRepository),
        RepositoryProvider<SalesInvoiceRepository>.value(value: salesInvoiceRepository),
        RepositoryProvider<DashboardRepository>.value(value: dashboardRepository),
        RepositoryProvider<SupplierRepository>.value(value: supplierRepository),
        RepositoryProvider<PurchaseOrderRepository>.value(value: purchaseOrderRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit(authRepository)),
          BlocProvider(create: (_) => CompanyCubit(companyRepository)),
          BlocProvider(create: (_) => PermissionsCubit(permissionRepository)),
        ],
        child: MaterialApp(
          title: 'ERP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system, // follows the phone's light/dark setting
          builder: (context, child) => AppViewport(child: child),
          home: const AppGate(),
        ),
      ),
    );
  }
}