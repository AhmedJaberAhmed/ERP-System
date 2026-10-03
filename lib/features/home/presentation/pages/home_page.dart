import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/permissions/permission_keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../company/domain/entities/company.dart';
import '../../../company/presentation/cubit/company_cubit.dart';
import '../../../customers/presentation/pages/customers_page.dart';

import '../../../dashboard/domain/dashboard_repository.dart';
import '../../../dashboard/presentation/dashboard_cubit.dart';
import '../../../dashboard/presentation/dashboard_section.dart';
import '../../../members/presentation/pages/members_page.dart';
import '../../../permissions/presentation/cubit/permissions_cubit.dart';
import '../../../permissions/presentation/cubit/permissions_state.dart';
import '../../../products/presentation/pages/products_page.dart';
import '../../../Purchasing/presentation/purchase_orders_page.dart';
import '../../../roles/presentation/pages/roles_page.dart';
import '../../../sales/presentation/pages/sales_invoices_page.dart';
import '../../../stock/presentation/pages/stock_page.dart';
import '../../../supliers/presentation/suppliers_page.dart';
import '../../../warehouses/presentation/pages/warehouses_page.dart';

class _Tile {
  const _Tile(this.label, this.icon, this.color, this.permission, this.onTap);

  final String label;
  final IconData icon;
  final Color color;
  final String permission;
  final VoidCallback onTap;
}

/// Dashboard + module tiles. Everything is hidden unless the user has the
/// matching permission.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final company = context.watch<CompanyCubit>().state.selected;
    final perms = context.watch<PermissionsCubit>().state;

    final tiles = <_Tile>[
      _Tile('Members', Icons.group_outlined, const Color(0xFF635BFF),PermissionKeys.membersManage,
              () => Navigator.of(context).push(MembersPage.route(context))),
      _Tile('Roles', Icons.admin_panel_settings_outlined, const Color(0xFF8E5CF6),PermissionKeys.rolesManage,
              () => Navigator.of(context).push(RolesPage.route(context))),
      _Tile('Products', Icons.inventory_2_outlined, const Color(0xFF2F7CF6),PermissionKeys.productsRead,
              () => Navigator.of(context).push(ProductsPage.route(context))),
      _Tile('Customers', Icons.people_outline, const Color(0xFF0EA5A4),PermissionKeys.customersRead,
              () => Navigator.of(context).push(CustomersPage.route(context))),
      _Tile('Suppliers', Icons.local_shipping_outlined, const Color(0xFFE8890C),PermissionKeys.suppliersRead,
              () => Navigator.of(context).push(SuppliersPage.route(context))),
      _Tile('Stock', Icons.inventory_outlined, const Color(0xFF12A150),PermissionKeys.stockLevelsRead,
              () => Navigator.of(context).push(StockPage.route(context))),
      _Tile('Warehouses', Icons.warehouse_outlined, const Color(0xFF8D6E63),PermissionKeys.warehousesRead,
              () => Navigator.of(context).push(WarehousesPage.route(context))),
      _Tile('Sales', Icons.receipt_long_outlined, const Color(0xFF4F46E5),PermissionKeys.salesInvoicesRead,
              () => Navigator.of(context).push(SalesInvoicesPage.route(context))),
      _Tile('Purchasing', Icons.shopping_cart_outlined, const Color(0xFFEC4899),PermissionKeys.purchaseOrdersRead,
              () => Navigator.of(context).push(PurchaseOrdersPage.route(context))),
    ].where((t) => perms.can(t.permission)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(company?.name ?? 'ERP'),
        actions: [
          IconButton(
            tooltip: 'Refresh permissions',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PermissionsCubit>().refresh(),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().signOut(),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          switch (perms.status) {
            case PermissionsStatus.initial:
            case PermissionsStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case PermissionsStatus.failure:
              return ErrorView(
                message: perms.errorMessage,
                onRetry: () => context.read<PermissionsCubit>().refresh(),
              );
            case PermissionsStatus.loaded:
              final c = company;
              final showDashboard =
                  c != null && perms.can(PermissionKeys.salesInvoicesRead);
              final content = _HomeContent(
                company: company,
                tiles: tiles,
                showDashboard: showDashboard,
              );
              if (!showDashboard) return content;
              return BlocProvider(
                key: ValueKey(c.id),
                create: (_) => DashboardCubit(
                  context.read<DashboardRepository>(),
                  c.id,
                  includeStock: perms.can(PermissionKeys.stockLevelsRead),
                )..load(),
                child: content,
              );
          }
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.company,
    required this.tiles,
    required this.showDashboard,
  });

  final Company? company;
  final List<_Tile> tiles;
  final bool showDashboard;

  @override
  Widget build(BuildContext context) {
    final size = Responsive.of(context);
    final wide = size == ScreenSize.expanded;

    final header = _CompanyHeader(company: company);
    final grid = _TileGrid(tiles: tiles, wide: wide);
    final dashboard = showDashboard ? const DashboardSection() : null;

    final Widget body;
    if (wide && dashboard != null) {
      // Tablet / desktop / web: dashboard on the left, shortcuts on the right.
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: dashboard),
          SizedBox(width: 340, child: grid),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dashboard != null) dashboard,
          grid,
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (showDashboard) await context.read<DashboardCubit>().load(silent: true);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 24 + MediaQuery.paddingOf(context).bottom),
        children: [header, body],
      ),
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader({required this.company});

  final Company? company;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = company?.name ?? '';
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                initial,
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: scheme.onPrimary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Role: ${company?.roleName ?? '-'} · ${company?.currency ?? '-'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles, required this.wide});

  final List<_Tile> tiles;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Your role has no access yet. Ask an admin to update it.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    return GridView.extent(
      // 2 columns on phones, 3-4 on tablets, 2 in the desktop side column.
      maxCrossAxisExtent: wide ? 160 : 190,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        for (final t in tiles)
          Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              onTap: t.onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: t.color.withAlpha(36),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(t.icon, size: 24, color: t.color),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
