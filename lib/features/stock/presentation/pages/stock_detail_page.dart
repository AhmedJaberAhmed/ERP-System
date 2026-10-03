import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/permissions/permission_keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../company/presentation/cubit/company_cubit.dart';
import '../../../permissions/presentation/cubit/permissions_cubit.dart';
import '../../../permissions/presentation/widgets/permission_guard.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/entities/warehouse_stock.dart';
import '../../domain/repositories/stock_repository.dart';
import '../cubit/stock_detail_cubit.dart';
import '../cubit/stock_detail_state.dart';

class StockDetailPage extends StatelessWidget {
  const StockDetailPage({super.key, required this.item});

  final StockItem item;

  static Route<void> route(BuildContext context, StockItem item) {
    final company = context.read<CompanyCubit>().state.selected!;
    final repo = context.read<StockRepository>();
    final canMoves =
        context.read<PermissionsCubit>().state.can(PermissionKeys.stockMovementsRead);
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => StockDetailCubit(
          repo,
          company.id,
          item.productId,
          canViewMovements: canMoves,
        )..load(),
        child: StockDetailPage(item: item),
      ),
    );
  }

  Future<void> _adjust(BuildContext context) async {
    final cubit = context.read<StockDetailCubit>();
    final result = await showDialog<({String warehouseId, double delta, String? note})>(
      context: context,
      builder: (_) => _AdjustDialog(levels: cubit.state.levels, unit: item.unit),
    );
    if (result == null) return;
    final ok = await cubit.adjust(
      warehouseId: result.warehouseId,
      delta: result.delta,
      note: result.note,
    );
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Stock updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StockDetailCubit, StockDetailState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: Scaffold(
        appBar: AppBar(title: Text(item.name)),
        floatingActionButton: PermissionGuard(
          permission: PermissionKeys.stockLevelsAdjust,
          child: BlocBuilder<StockDetailCubit, StockDetailState>(
            buildWhen: (p, c) => p.status != c.status || p.isBusy != c.isBusy,
            builder: (context, state) => FloatingActionButton.extended(
              onPressed: state.status == StockDetailStatus.loaded && !state.isBusy
                  ? () => _adjust(context)
                  : null,
              icon: const Icon(Icons.tune),
              label: const Text('Adjust stock'),
            ),
          ),
        ),
        body: BlocBuilder<StockDetailCubit, StockDetailState>(
          builder: (context, state) {
            switch (state.status) {
              case StockDetailStatus.initial:
              case StockDetailStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case StockDetailStatus.failure:
                return ErrorView(
                  message: state.errorMessage,
                  onRetry: () => context.read<StockDetailCubit>().load(),
                );
              case StockDetailStatus.loaded:
                final scheme = Theme.of(context).colorScheme;
                final low = item.minStock > 0 && state.total <= item.minStock;
                return Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () =>
                          context.read<StockDetailCubit>().load(silent: true),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 96),
                        children: [
                          Card(
                            margin: const EdgeInsets.all(16),
                            child: ListTile(
                              title: Text(
                                '${fmtQty(state.total)} ${item.unit}',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: low ? scheme.error : null,
                                    ),
                              ),
                              subtitle: Text(
                                [
                                  item.sku,
                                  if (item.minStock > 0)
                                    'Alert at ${fmtQty(item.minStock)}',
                                  if (low) 'LOW STOCK',
                                ].join(' · '),
                              ),
                            ),
                          ),
                          const _SectionTitle('By warehouse'),
                          for (final l in state.levels)
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.warehouse_outlined),
                              title: Text(l.warehouseName),
                              trailing: Text('${fmtQty(l.quantity)} ${item.unit}'),
                            ),
                          if (context.read<StockDetailCubit>().canViewMovements) ...[
                            const _SectionTitle('Recent movements'),
                            if (state.movements.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No movements yet.'),
                              ),
                            for (final m in state.movements)
                              ListTile(
                                dense: true,
                                leading: Icon(
                                  m.quantity >= 0
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: m.quantity >= 0 ? AppColors.success : scheme.error,
                                ),
                                title: Text('${m.label} · ${m.warehouseName}'),
                                subtitle: Text([
                                  fmtDateTime(m.createdAt),
                                  if (m.note != null && m.note!.isNotEmpty) m.note!,
                                ].join(' · ')),
                                trailing: Text(
                                  '${m.quantity > 0 ? '+' : ''}${fmtQty(m.quantity)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: m.quantity >= 0 ? AppColors.success : scheme.error,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    if (state.isBusy) const LinearProgressIndicator(),
                  ],
                );
            }
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}

class _AdjustDialog extends StatefulWidget {
  const _AdjustDialog({required this.levels, required this.unit});

  final List<WarehouseStock> levels;
  final String unit;

  @override
  State<_AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends State<_AdjustDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _note = TextEditingController();
  late String? _warehouseId =
      widget.levels.isNotEmpty ? widget.levels.first.warehouseId : null;
  bool _add = true;

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _warehouseId == null) return;
    final q = parseNum(_qty.text)!;
    final note = _note.text.trim();
    Navigator.pop(context, (
      warehouseId: _warehouseId!,
      delta: _add ? q : -q,
      note: note.isEmpty ? null : note,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust stock'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _warehouseId,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Warehouse', border: OutlineInputBorder()),
                items: [
                  for (final l in widget.levels)
                    DropdownMenuItem(
                      value: l.warehouseId,
                      child: Text('${l.warehouseName} (${fmtQty(l.quantity)})'),
                    ),
                ],
                onChanged: (v) => setState(() => _warehouseId = v),
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Add')),
                  ButtonSegment(value: false, label: Text('Remove')),
                ],
                selected: {_add},
                onSelectionChanged: (s) => setState(() => _add = s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qty,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Quantity (${widget.unit})',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = parseNum(v ?? '');
                  if (n == null || n <= 0) return 'Enter a quantity above 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                decoration: const InputDecoration(
                    labelText: 'Note (optional)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Apply')),
      ],
    );
  }
}
