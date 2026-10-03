import 'package:erb3/features/Purchasing/presentation/pages/purchase_editor_page.dart';
import 'package:erb3/features/Purchasing/presentation/purchase_detail_page.dart';
import 'package:erb3/features/Purchasing/presentation/purchase_orders_cubit.dart';
import 'package:erb3/features/Purchasing/presentation/purchase_orders_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/permissions/permission_keys.dart';
import 'package:erb3/core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../company/presentation/cubit/company_cubit.dart';
import '../../permissions/presentation/widgets/permission_guard.dart';
import '../domain/purchase_order.dar.dart';
import '../domain/purchase_order_repository.dart';


Color purchaseStatusColor(PurchaseStatus s) => switch (s) {
  PurchaseStatus.draft => AppColors.neutral,
  PurchaseStatus.confirmed => AppColors.success,
  PurchaseStatus.cancelled => AppColors.danger,
};

class PurchaseOrdersPage extends StatelessWidget {
  const PurchaseOrdersPage({super.key});

  static Route<void> route(BuildContext context) {
    final company = context.read<CompanyCubit>().state.selected!;
    final repo = context.read<PurchaseOrderRepository>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => PurchaseOrdersCubit(repo, company.id)..load(),
        child: const PurchaseOrdersPage(),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, String orderId) async {
    final cubit = context.read<PurchaseOrdersCubit>();
    await Navigator.of(context).push(PurchaseDetailPage.route(context, orderId));
    cubit.load(silent: true);
  }

  Future<void> _create(BuildContext context) async {
    final cubit = context.read<PurchaseOrdersCubit>();
    final id = await Navigator.of(context).push<String>(PurchaseEditorPage.route(context));
    cubit.load(silent: true);
    // Straight to the saved draft so it can be confirmed.
    if (id != null && context.mounted) await _openDetail(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PurchaseOrdersCubit, PurchaseOrdersState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Purchase orders')),
        floatingActionButton: PermissionGuard(
          permission: PermissionKeys.purchaseOrdersWrite,
          child: FloatingActionButton.extended(
            onPressed: () => _create(context),
            icon: const Icon(Icons.add),
            label: const Text('New order'),
          ),
        ),
        body: Column(
          children: [
            SearchField(
              hint: 'Search order number',
              onChanged: (q) => context.read<PurchaseOrdersCubit>().search(q),
            ),
            BlocBuilder<PurchaseOrdersCubit, PurchaseOrdersState>(
              buildWhen: (p, c) => p.statusFilter != c.statusFilter,
              builder: (context, state) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: state.statusFilter == null,
                      onSelected: (_) =>
                          context.read<PurchaseOrdersCubit>().filterBy(null),
                    ),
                    for (final s in PurchaseStatus.values) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(s.label),
                        selected: state.statusFilter == s,
                        onSelected: (_) =>
                            context.read<PurchaseOrdersCubit>().filterBy(s),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<PurchaseOrdersCubit, PurchaseOrdersState>(
                builder: (context, state) {
                  switch (state.status) {
                    case PurchaseOrdersStatus.initial:
                    case PurchaseOrdersStatus.loading:
                      return const Center(child: CircularProgressIndicator());
                    case PurchaseOrdersStatus.failure:
                      return ErrorView(
                        message: state.errorMessage,
                        onRetry: () => context.read<PurchaseOrdersCubit>().load(),
                      );
                    case PurchaseOrdersStatus.loaded:
                      if (state.orders.isEmpty) {
                        return const Center(child: Text('No purchase orders found.'));
                      }
                      return RefreshIndicator(
                        onRefresh: () =>
                            context.read<PurchaseOrdersCubit>().load(silent: true),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: state.orders.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final o = state.orders[i];
                            return ListTile(
                              title: Text(o.number ?? 'Draft'),
                              subtitle: Text(
                                '${o.supplierName ?? 'No supplier'} · ${fmtDate(o.orderDate)}',
                              ),
                              trailing: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(fmtMoney(o.total),
                                      style: Theme.of(context).textTheme.titleSmall),
                                  const SizedBox(height: 2),
                                  StatusChip(o.status.label, purchaseStatusColor(o.status)),
                                ],
                              ),
                              onTap: () => _openDetail(context, o.id),
                            );
                          },
                        ),
                      );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}