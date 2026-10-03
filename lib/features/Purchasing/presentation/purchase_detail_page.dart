import 'package:erb3/features/Purchasing/presentation/pages/purchase_editor_page.dart';
import 'package:erb3/features/Purchasing/presentation/purchase_detail_cubit.dart';
import 'package:erb3/features/Purchasing/presentation/purchase_detail_state.dart';
import 'package:erb3/features/permissions/presentation/widgets/permission_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/permissions/permission_keys.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/status_chip.dart';

import '../domain/purchase_order.dar.dart';
import '../domain/purchase_order_repository.dart';
import 'purchase_orders_page.dart' show purchaseStatusColor;

class PurchaseDetailPage extends StatelessWidget {
  const PurchaseDetailPage({super.key});

  static Route<void> route(BuildContext context, String orderId) {
    final repo = context.read<PurchaseOrderRepository>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => PurchaseDetailCubit(repo, orderId)..load(),
        child: const PurchaseDetailPage(),
      ),
    );
  }

  void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _ask(
      BuildContext context, {
        required String title,
        required String message,
        required String action,
      }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _edit(BuildContext context, PurchaseOrder order) async {
    final cubit = context.read<PurchaseDetailCubit>();
    final id = await Navigator.of(context)
        .push<String>(PurchaseEditorPage.route(context, existing: order));
    if (id != null) cubit.load(silent: true);
  }

  Future<void> _confirm(BuildContext context) async {
    final cubit = context.read<PurchaseDetailCubit>();
    final ok = await _ask(
      context,
      title: 'Confirm order?',
      message: 'The items will be added to stock and an order number assigned. '
          'A confirmed order can no longer be edited.',
      action: 'Confirm',
    );
    if (!ok) return;
    final done = await cubit.confirm();
    if (done && context.mounted) _snack(context, 'Order confirmed · stock updated');
  }

  Future<void> _cancel(BuildContext context) async {
    final cubit = context.read<PurchaseDetailCubit>();
    final ok = await _ask(
      context,
      title: 'Cancel order?',
      message: 'The received items will be removed from stock.',
      action: 'Cancel order',
    );
    if (!ok) return;
    final done = await cubit.cancel();
    if (done && context.mounted) _snack(context, 'Order cancelled');
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<PurchaseDetailCubit>();
    final ok = await _ask(
      context,
      title: 'Delete draft?',
      message: 'This draft will be permanently deleted.',
      action: 'Delete',
    );
    if (!ok) return;
    final done = await cubit.deleteDraft();
    if (done && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PurchaseDetailCubit, PurchaseDetailState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) => _snack(context, state.errorMessage!),
      builder: (context, state) {
        switch (state.status) {
          case PurchaseDetailStatus.initial:
          case PurchaseDetailStatus.loading:
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()),
            );
          case PurchaseDetailStatus.failure:
            return Scaffold(
              appBar: AppBar(),
              body: ErrorView(
                message: state.errorMessage,
                onRetry: () => context.read<PurchaseDetailCubit>().load(),
              ),
            );
          case PurchaseDetailStatus.loaded:
            return _buildLoaded(context, state, state.order!);
        }
      },
    );
  }

  Widget _buildLoaded(BuildContext context, PurchaseDetailState state, PurchaseOrder o) {
    final theme = Theme.of(context);
    final busy = state.isBusy;

    final canWrite = context.can(PermissionKeys.purchaseOrdersWrite);
    final canConfirm = context.can(PermissionKeys.purchaseOrdersConfirm);
    final canDelete = context.can(PermissionKeys.purchaseOrdersDelete);
    final canCancel = context.can(PermissionKeys.purchaseOrdersCancel);

    final actions = <Widget>[
      if (o.isDraft && canWrite)
        OutlinedButton.icon(
          onPressed: busy ? null : () => _edit(context, o),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit'),
        ),
      if (o.isDraft && canConfirm)
        FilledButton.icon(
          onPressed: busy ? null : () => _confirm(context),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Confirm'),
        ),
      if (o.isConfirmed && canCancel)
        OutlinedButton.icon(
          onPressed: busy ? null : () => _cancel(context),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancel order'),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(o.number ?? 'Draft order'),
        actions: [
          if (o.isDraft && canDelete)
            IconButton(
              tooltip: 'Delete draft',
              icon: const Icon(Icons.delete_outline),
              onPressed: busy ? null : () => _delete(context),
            ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => context.read<PurchaseDetailCubit>().load(silent: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: ListTile(
                    title: Text(o.number ?? 'Draft', style: theme.textTheme.titleLarge),
                    subtitle: Text(fmtDate(o.orderDate)),
                    trailing: StatusChip(o.status.label, purchaseStatusColor(o.status)),
                  ),
                ),
                _InfoRow(Icons.local_shipping_outlined, 'Supplier',
                    o.supplierName ?? 'No supplier'),
                _InfoRow(Icons.warehouse_outlined, 'Warehouse', o.warehouseName ?? '-'),
                if (o.note != null && o.note!.isNotEmpty)
                  _InfoRow(Icons.notes_outlined, 'Note', o.note!),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('Items', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                for (final it in o.items)
                  ListTile(
                    dense: true,
                    title: Text(it.productName),
                    subtitle: Text(
                        '${fmtMoney(it.unitCost)} × ${fmtQty(it.quantity)} ${it.unit}'),
                    trailing: Text(fmtMoney(it.lineTotal), style: theme.textTheme.titleSmall),
                  ),
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _TotalRow('Subtotal', fmtMoney(o.subtotal)),
                        _TotalRow('Tax', fmtMoney(o.taxTotal)),
                        const Divider(),
                        _TotalRow('Total', fmtMoney(o.total), bold: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (busy) const LinearProgressIndicator(),
        ],
      ),
      bottomNavigationBar: actions.isEmpty
          ? null
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: actions,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: Icon(icon),
    title: Text(label),
    subtitle: Text(value),
  );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}