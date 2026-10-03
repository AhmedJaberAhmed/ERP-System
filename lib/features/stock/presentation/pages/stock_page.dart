import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../company/presentation/cubit/company_cubit.dart';
import '../../../warehouses/domain/repositories/warehouse_repository.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/repositories/stock_repository.dart';
import '../cubit/stock_cubit.dart';
import '../cubit/stock_state.dart';
import 'stock_detail_page.dart';

class StockPage extends StatelessWidget {
  const StockPage({super.key});

  static Route<void> route(BuildContext context) {
    final company = context.read<CompanyCubit>().state.selected!;
    final stock = context.read<StockRepository>();
    final warehouses = context.read<WarehouseRepository>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => StockCubit(stock, warehouses, company.id)..load(),
        child: const StockPage(),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, StockItem item) async {
    final cubit = context.read<StockCubit>();
    await Navigator.of(context).push(StockDetailPage.route(context, item));
    cubit.load(silent: true); // quantities may have changed
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StockCubit, StockState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Stock')),
        body: Column(
          children: [
            SearchField(
              hint: 'Search name, SKU or barcode',
              onChanged: (q) => context.read<StockCubit>().search(q),
            ),
            BlocBuilder<StockCubit, StockState>(
              buildWhen: (p, c) =>
                  p.warehouses != c.warehouses ||
                  p.warehouseId != c.warehouseId ||
                  p.lowOnly != c.lowOnly ||
                  p.items != c.items,
              builder: (context, state) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    if (state.warehouses.isNotEmpty)
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            value: state.warehouseId,
                            items: [
                              const DropdownMenuItem<String?>(
                                  value: null, child: Text('All warehouses')),
                              for (final w in state.warehouses)
                                DropdownMenuItem<String?>(
                                    value: w.id, child: Text(w.name)),
                            ],
                            onChanged: (v) =>
                                context.read<StockCubit>().selectWarehouse(v),
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.warning_amber_rounded, size: 18),
                      label: Text('Low stock (${state.lowCount})'),
                      selected: state.lowOnly,
                      onSelected: (_) => context.read<StockCubit>().toggleLowOnly(),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<StockCubit, StockState>(
                builder: (context, state) {
                  switch (state.status) {
                    case StockStatus.initial:
                    case StockStatus.loading:
                      return const Center(child: CircularProgressIndicator());
                    case StockStatus.failure:
                      return ErrorView(
                        message: state.errorMessage,
                        onRetry: () => context.read<StockCubit>().load(),
                      );
                    case StockStatus.loaded:
                      final items = state.visibleItems;
                      if (items.isEmpty) {
                        return Center(
                          child: Text(state.lowOnly
                              ? 'No low-stock products.'
                              : 'No tracked products found.'),
                        );
                      }
                      final scheme = Theme.of(context).colorScheme;
                      return RefreshIndicator(
                        onRefresh: () => context.read<StockCubit>().load(silent: true),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final it = items[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    it.isLow ? scheme.errorContainer : null,
                                child: Icon(
                                  it.isLow
                                      ? Icons.warning_amber_rounded
                                      : Icons.inventory_2_outlined,
                                  color: it.isLow ? scheme.error : null,
                                ),
                              ),
                              title: Text(it.name),
                              subtitle: Text(
                                it.minStock > 0
                                    ? '${it.sku} · min ${fmtQty(it.minStock)}'
                                    : it.sku,
                              ),
                              trailing: Text(
                                '${fmtQty(it.quantity)} ${it.unit}',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: it.isLow ? scheme.error : null,
                                    ),
                              ),
                              onTap: () => _openDetail(context, it),
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
