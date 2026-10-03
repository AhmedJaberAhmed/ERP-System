import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../../../core/permissions/permission_keys.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../company/presentation/cubit/company_cubit.dart';
import '../../../permissions/presentation/widgets/permission_guard.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/repositories/sales_invoice_repository.dart';
import '../../pdf/invoice_pdf.dart';
import '../cubit/invoice_detail_cubit.dart';
import '../cubit/invoice_detail_state.dart';
import 'invoice_editor_page.dart';
import 'sales_invoices_page.dart' show invoiceStatusColor, paymentStatusColor;

class InvoiceDetailPage extends StatelessWidget {
  const InvoiceDetailPage({super.key});

  static Route<void> route(BuildContext context, String invoiceId) {
    final repo = context.read<SalesInvoiceRepository>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => InvoiceDetailCubit(repo, invoiceId)..load(),
        child: const InvoiceDetailPage(),
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

  Future<void> _edit(BuildContext context, SalesInvoice inv) async {
    final cubit = context.read<InvoiceDetailCubit>();
    final id = await Navigator.of(context)
        .push<String>(InvoiceEditorPage.route(context, existing: inv));
    if (id != null) cubit.load(silent: true);
  }

  Future<void> _confirm(BuildContext context) async {
    final cubit = context.read<InvoiceDetailCubit>();
    final ok = await _ask(
      context,
      title: 'Confirm invoice?',
      message: 'Stock will be deducted and an invoice number assigned. '
          'A confirmed invoice can no longer be edited.',
      action: 'Confirm',
    );
    if (!ok) return;
    final done = await cubit.confirm();
    if (done && context.mounted) _snack(context, 'Invoice confirmed');
  }

  Future<void> _cancel(BuildContext context) async {
    final cubit = context.read<InvoiceDetailCubit>();
    final ok = await _ask(
      context,
      title: 'Cancel invoice?',
      message: 'The stock will be returned to the warehouse.',
      action: 'Cancel invoice',
    );
    if (!ok) return;
    final done = await cubit.cancel();
    if (done && context.mounted) _snack(context, 'Invoice cancelled');
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<InvoiceDetailCubit>();
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

  Future<void> _pay(BuildContext context, SalesInvoice inv) async {
    final cubit = context.read<InvoiceDetailCubit>();
    final r = await showDialog<({double amount, PaymentMethod method, String? reference})>(
      context: context,
      builder: (_) => _PaymentDialog(balance: inv.balance),
    );
    if (r == null) return;
    final done = await cubit.addPayment(
      amount: r.amount,
      method: r.method,
      reference: r.reference,
    );
    if (done && context.mounted) {
      final paid = cubit.state.invoice?.payStatus == PaymentStatus.paid;
      _snack(context,
          paid ? 'Payment recorded · invoice fully paid' : 'Payment recorded');
    }
  }

  Future<void> _printPdf(BuildContext context, SalesInvoice inv) async {
    final company = context.read<CompanyCubit>().state.selected;
    try {
      await Printing.layoutPdf(
        name: '${inv.number ?? 'invoice'}.pdf',
        onLayout: (_) => InvoicePdf.build(
          inv,
          companyName: company?.name ?? '',
          currency: company?.currency ?? '',
        ),
      );
    } catch (_) {
      if (context.mounted) _snack(context, 'Could not create the PDF');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvoiceDetailCubit, InvoiceDetailState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) => _snack(context, state.errorMessage!),
      builder: (context, state) {
        final inv = state.invoice;
        switch (state.status) {
          case InvoiceDetailStatus.initial:
          case InvoiceDetailStatus.loading:
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()),
            );
          case InvoiceDetailStatus.failure:
            return Scaffold(
              appBar: AppBar(),
              body: ErrorView(
                message: state.errorMessage,
                onRetry: () => context.read<InvoiceDetailCubit>().load(),
              ),
            );
          case InvoiceDetailStatus.loaded:
            return _buildLoaded(context, state, inv!);
        }
      },
    );
  }

  Widget _buildLoaded(BuildContext context, InvoiceDetailState state, SalesInvoice inv) {
    final theme = Theme.of(context);
    final busy = state.isBusy;

    final canWrite = context.can(PermissionKeys.salesInvoicesWrite);
    final canConfirm = context.can(PermissionKeys.salesInvoicesConfirm);
    final canDelete = context.can(PermissionKeys.salesInvoicesDelete);
    final canCancel = context.can(PermissionKeys.salesInvoicesCancel);
    final canPay = context.can(PermissionKeys.salesPaymentsWrite);

    final actions = <Widget>[
      if (inv.isDraft && canWrite)
        OutlinedButton.icon(
          onPressed: busy ? null : () => _edit(context, inv),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit'),
        ),
      if (inv.isDraft && canConfirm)
        FilledButton.icon(
          onPressed: busy ? null : () => _confirm(context),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Confirm'),
        ),
      if (inv.isConfirmed && inv.payStatus != PaymentStatus.paid && canPay)
        FilledButton.icon(
          onPressed: busy ? null : () => _pay(context, inv),
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Record payment'),
        ),
      if (inv.isConfirmed && inv.paidAmount == 0 && canCancel)
        OutlinedButton.icon(
          onPressed: busy ? null : () => _cancel(context),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancel invoice'),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(inv.number ?? 'Draft invoice'),
        actions: [
          if (inv.isConfirmed)
            IconButton(
              tooltip: 'Print / save PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: busy ? null : () => _printPdf(context, inv),
            ),
          if (inv.isDraft && canDelete)
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
            onRefresh: () => context.read<InvoiceDetailCubit>().load(silent: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: ListTile(
                    title: Text(inv.number ?? 'Draft', style: theme.textTheme.titleLarge),
                    subtitle: Text(fmtDate(inv.invoiceDate)),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        StatusChip(inv.status.label, invoiceStatusColor(inv.status)),
                        if (inv.isConfirmed)
                          StatusChip(inv.payStatus.label, paymentStatusColor(inv.payStatus)),
                      ],
                    ),
                  ),
                ),
                _InfoRow(Icons.person_outline, 'Customer', inv.customerName ?? 'Walk-in customer'),
                _InfoRow(Icons.warehouse_outlined, 'Warehouse', inv.warehouseName ?? '-'),
                if (inv.dueDate != null)
                  _InfoRow(Icons.event_busy_outlined, 'Due date', fmtDate(inv.dueDate!)),
                if (inv.note != null && inv.note!.isNotEmpty)
                  _InfoRow(Icons.notes_outlined, 'Note', inv.note!),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text('Items', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                for (final it in inv.items)
                  ListTile(
                    dense: true,
                    title: Text(it.productName),
                    subtitle: Text([
                      '${fmtMoney(it.unitPrice)} × ${fmtQty(it.quantity)} ${it.unit}',
                      if (it.discount > 0) 'discount ${fmtMoney(it.discount)}',
                    ].join(' · ')),
                    trailing: Text(fmtMoney(it.lineTotal), style: theme.textTheme.titleSmall),
                  ),
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _TotalRow('Subtotal', fmtMoney(inv.subtotal)),
                        if (inv.discount > 0)
                          _TotalRow('Discount', '-${fmtMoney(inv.discount)}'),
                        _TotalRow('Tax', fmtMoney(inv.taxTotal)),
                        const Divider(),
                        _TotalRow('Total', fmtMoney(inv.total), bold: true),
                        if (inv.isConfirmed) ...[
                          _TotalRow('Paid', fmtMoney(inv.paidAmount)),
                          _TotalRow('Balance', fmtMoney(inv.balance), bold: true),
                        ],
                      ],
                    ),
                  ),
                ),
                if (inv.payments.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Text('Payments', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  for (final p in inv.payments)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.payments_outlined),
                      title: Text(p.method.label),
                      subtitle: Text([
                        fmtDateTime(p.paidAt),
                        if (p.reference != null && p.reference!.isNotEmpty) p.reference!,
                      ].join(' · ')),
                      trailing: Text(fmtMoney(p.amount), style: theme.textTheme.titleSmall),
                    ),
                ],
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

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.balance});

  final double balance;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount =
  TextEditingController(text: fmtMoney(widget.balance));
  final _reference = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final ref = _reference.text.trim();
    Navigator.pop(context, (
    amount: parseNum(_amount.text)!,
    method: _method,
    reference: ref.isEmpty ? null : ref,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record payment'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (balance ${fmtMoney(widget.balance)})',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = parseNum(v ?? '');
                  if (n == null || n <= 0) return 'Enter an amount above 0';
                  if (round2(n) > round2(widget.balance)) return 'More than the balance';
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _amount.text = fmtMoney(widget.balance),
                  child: const Text('Pay full balance'),
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<PaymentMethod>(
                value: _method,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Method', border: OutlineInputBorder()),
                items: [
                  for (final m in PaymentMethod.values)
                    DropdownMenuItem(value: m, child: Text(m.label)),
                ],
                onChanged: (v) => setState(() => _method = v ?? PaymentMethod.cash),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reference,
                decoration: const InputDecoration(
                    labelText: 'Reference (optional)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}