import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/format.dart';
import '../../../company/presentation/cubit/company_cubit.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../warehouses/domain/repositories/warehouse_repository.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/repositories/sales_invoice_repository.dart';
import '../cubit/invoice_editor_cubit.dart';
import '../cubit/invoice_editor_state.dart';
import 'customer_picker_page.dart';
import 'product_picker_page.dart';

/// Create or edit a draft invoice. Pops with the saved invoice id.
class InvoiceEditorPage extends StatefulWidget {
  const InvoiceEditorPage({super.key, this.isEdit = false});

  final bool isEdit;

  static Route<String> route(BuildContext context, {SalesInvoice? existing}) {
    final company = context.read<CompanyCubit>().state.selected!;
    final invoices = context.read<SalesInvoiceRepository>();
    final warehouses = context.read<WarehouseRepository>();
    final products = context.read<ProductRepository>();
    return MaterialPageRoute<String>(
      builder: (_) => BlocProvider(
        create: (_) => InvoiceEditorCubit(
          invoices,
          warehouses,
          products,
          company.id,
          existing: existing,
        )..init(),
        child: InvoiceEditorPage(isEdit: existing != null),
      ),
    );
  }

  @override
  State<InvoiceEditorPage> createState() => _InvoiceEditorPageState();
}

class _InvoiceEditorPageState extends State<InvoiceEditorPage> {
  late final TextEditingController _discount;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final s = context.read<InvoiceEditorCubit>().state;
    _discount = TextEditingController(text: s.discount > 0 ? fmtQty(s.discount) : '');
    _note = TextEditingController(text: s.note ?? '');
  }

  @override
  void dispose() {
    _discount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickCustomer() async {
    final cubit = context.read<InvoiceEditorCubit>();
    final c = await Navigator.of(context).push<Customer>(CustomerPickerPage.route(context));
    if (c != null) cubit.setCustomer(c.id, c.name);
  }

  Future<void> _addProduct() async {
    final cubit = context.read<InvoiceEditorCubit>();
    final p = await Navigator.of(context).push<Product>(ProductPickerPage.route(context));
    if (p != null) cubit.addProduct(p);
  }

  Future<void> _pickDate({required bool due}) async {
    final cubit = context.read<InvoiceEditorCubit>();
    final s = cubit.state;
    final initial = due ? (s.dueDate ?? s.invoiceDate) : s.invoiceDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    if (due) {
      cubit.setDueDate(picked);
    } else {
      cubit.setInvoiceDate(picked);
    }
  }

  Future<void> _editItem(int index, InvoiceItem item) async {
    final cubit = context.read<InvoiceEditorCubit>();
    final r = await showDialog<({double quantity, double unitPrice, double discount})>(
      context: context,
      builder: (_) => _ItemDialog(item: item),
    );
    if (r != null) {
      cubit.updateItem(index,
          quantity: r.quantity, unitPrice: r.unitPrice, discount: r.discount);
    }
  }

  Future<void> _save() async {
    final id = await context.read<InvoiceEditorCubit>().save();
    if (id != null && mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InvoiceEditorCubit>();

    return BlocConsumer<InvoiceEditorCubit, InvoiceEditorState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (context, s) {
        final title = widget.isEdit ? 'Edit draft' : 'New invoice';
        if (s.isLoading) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Customer'),
                subtitle: Text(s.customerName ?? 'Walk-in customer'),
                trailing: s.customerId == null
                    ? const Icon(Icons.chevron_right)
                    : IconButton(
                        tooltip: 'Remove customer',
                        icon: const Icon(Icons.clear),
                        onPressed: cubit.clearCustomer,
                      ),
                onTap: _pickCustomer,
              ),
              if (s.warehouses.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonFormField<String>(
                    value: s.warehouseId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Warehouse',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.warehouse_outlined),
                    ),
                    items: [
                      for (final w in s.warehouses)
                        DropdownMenuItem(value: w.id, child: Text(w.name)),
                    ],
                    onChanged: cubit.setWarehouse,
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('Invoice date'),
                subtitle: Text(fmtDate(s.invoiceDate)),
                onTap: () => _pickDate(due: false),
              ),
              ListTile(
                leading: const Icon(Icons.event_busy_outlined),
                title: const Text('Due date (optional)'),
                subtitle: Text(s.dueDate == null ? 'Not set' : fmtDate(s.dueDate!)),
                trailing: s.dueDate == null
                    ? null
                    : IconButton(
                        tooltip: 'Clear due date',
                        icon: const Icon(Icons.clear),
                        onPressed: () => cubit.setDueDate(null),
                      ),
                onTap: () => _pickDate(due: true),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Items (${s.items.length})',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _addProduct,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
              ),
              if (s.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No items yet. Tap Add to pick a product.')),
                ),
              for (var i = 0; i < s.items.length; i++)
                _ItemCard(
                  item: s.items[i],
                  onEdit: () => _editItem(i, s.items[i]),
                  onRemove: () => cubit.removeItem(i),
                  onMinus: () => cubit.changeQuantity(i, -1),
                  onPlus: () => cubit.changeQuantity(i, 1),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _discount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Invoice discount (amount)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => cubit.setDiscount(parseNum(v) ?? 0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: cubit.setNote,
                ),
              ),
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _TotalRow('Subtotal', fmtMoney(s.subtotal)),
                      if (s.discount > 0) _TotalRow('Discount', '-${fmtMoney(s.discount)}'),
                      _TotalRow('Tax', fmtMoney(s.taxTotal)),
                      const Divider(),
                      _TotalRow('Total', fmtMoney(s.total), bold: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: s.isSaving ? null : _save,
                icon: s.isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save draft'),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.onEdit,
    required this.onRemove,
    required this.onMinus,
    required this.onPlus,
  });

  final InvoiceItem item;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      '${fmtMoney(item.unitPrice)} × ${fmtQty(item.quantity)} ${item.unit}',
      if (item.discount > 0) 'discount ${fmtMoney(item.discount)}',
      if (item.taxRate > 0) 'tax ${fmtQty(item.taxRate)}%',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(item.productName, style: theme.textTheme.titleSmall)),
                  IconButton(
                    tooltip: 'Remove',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onRemove,
                  ),
                ],
              ),
              Text(details, style: theme.textTheme.bodySmall),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton.outlined(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove),
                    onPressed: onMinus,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('${fmtQty(item.quantity)} ${item.unit}'),
                  ),
                  IconButton.outlined(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add),
                    onPressed: onPlus,
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(fmtMoney(item.lineTotal), style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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

class _ItemDialog extends StatefulWidget {
  const _ItemDialog({required this.item});

  final InvoiceItem item;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qty =
      TextEditingController(text: fmtQty(widget.item.quantity));
  late final TextEditingController _price =
      TextEditingController(text: fmtQty(widget.item.unitPrice));
  late final TextEditingController _discount = TextEditingController(
      text: widget.item.discount > 0 ? fmtQty(widget.item.discount) : '');

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    _discount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (
      quantity: parseNum(_qty.text)!,
      unitPrice: parseNum(_price.text)!,
      discount: parseNum(_discount.text) ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    const decimal = TextInputType.numberWithOptions(decimal: true);
    return AlertDialog(
      title: Text(widget.item.productName),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _qty,
                keyboardType: decimal,
                decoration: InputDecoration(
                  labelText: 'Quantity (${widget.item.unit})',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = parseNum(v ?? '');
                  return (n == null || n <= 0) ? 'Enter a quantity above 0' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: decimal,
                decoration: const InputDecoration(
                  labelText: 'Unit price',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = parseNum(v ?? '');
                  return (n == null || n < 0) ? 'Enter a valid price' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discount,
                keyboardType: decimal,
                decoration: const InputDecoration(
                  labelText: 'Line discount (amount)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return null;
                  final d = parseNum(v!);
                  final q = parseNum(_qty.text) ?? 0;
                  final p = parseNum(_price.text) ?? 0;
                  if (d == null || d < 0) return 'Enter a valid discount';
                  if (d > q * p) return 'Discount exceeds the line total';
                  return null;
                },
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
