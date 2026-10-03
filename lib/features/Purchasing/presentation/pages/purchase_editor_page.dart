import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/format.dart';
import '../../../company/presentation/cubit/company_cubit.dart';
import '../../../products/domain/entities/product.dart';
import '../../../sales/presentation/pages/product_picker_page.dart';

import '../../../supliers/domain/supplier.dart';
import '../../../supliers/presentation/supplier_picker_page.dart';
import '../../../warehouses/domain/repositories/warehouse_repository.dart';
import '../../domain/purchase_item.dart';
import '../../domain/purchase_order.dar.dart';
import '../../domain/purchase_order_repository.dart';
import '../purchase_editor_cubit.dart';
import '../purchase_editor_state.dart';


/// Create or edit a draft purchase order. Pops with the saved order id.
class PurchaseEditorPage extends StatefulWidget {
  const PurchaseEditorPage({super.key, this.isEdit = false});

  final bool isEdit;

  static Route<String> route(BuildContext context, {PurchaseOrder? existing}) {
    final company = context.read<CompanyCubit>().state.selected!;
    final orders = context.read<PurchaseOrderRepository>();
    final warehouses = context.read<WarehouseRepository>();
    return MaterialPageRoute<String>(
      builder: (_) => BlocProvider(
        create: (_) => PurchaseEditorCubit(
          orders,
          warehouses,
          company.id,
          existing: existing,
        )..init(),
        child: PurchaseEditorPage(isEdit: existing != null),
      ),
    );
  }

  @override
  State<PurchaseEditorPage> createState() => _PurchaseEditorPageState();
}

class _PurchaseEditorPageState extends State<PurchaseEditorPage> {
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(
        text: context.read<PurchaseEditorCubit>().state.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickSupplier() async {
    final cubit = context.read<PurchaseEditorCubit>();
    final s = await Navigator.of(context).push<Supplier>(SupplierPickerPage.route(context));
    if (s != null) cubit.setSupplier(s.id, s.name);
  }

  Future<void> _addProduct() async {
    final cubit = context.read<PurchaseEditorCubit>();
    final p = await Navigator.of(context)
        .push<Product>(ProductPickerPage.route(context, showCost: true));
    if (p != null) cubit.addProduct(p);
  }

  Future<void> _pickDate() async {
    final cubit = context.read<PurchaseEditorCubit>();
    final picked = await showDatePicker(
      context: context,
      initialDate: cubit.state.orderDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) cubit.setOrderDate(picked);
  }

  Future<void> _editItem(int index, PurchaseItem item) async {
    final cubit = context.read<PurchaseEditorCubit>();
    final r = await showDialog<({double quantity, double unitCost})>(
      context: context,
      builder: (_) => _ItemDialog(item: item),
    );
    if (r != null) {
      cubit.updateItem(index, quantity: r.quantity, unitCost: r.unitCost);
    }
  }

  Future<void> _save() async {
    final id = await context.read<PurchaseEditorCubit>().save();
    if (id != null && mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PurchaseEditorCubit>();

    return BlocConsumer<PurchaseEditorCubit, PurchaseEditorState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (context, s) {
        final title = widget.isEdit ? 'Edit draft' : 'New purchase order';
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
                leading: const Icon(Icons.local_shipping_outlined),
                title: const Text('Supplier'),
                subtitle: Text(s.supplierName ?? 'No supplier'),
                trailing: s.supplierId == null
                    ? const Icon(Icons.chevron_right)
                    : IconButton(
                  tooltip: 'Remove supplier',
                  icon: const Icon(Icons.clear),
                  onPressed: cubit.clearSupplier,
                ),
                onTap: _pickSupplier,
              ),
              if (s.warehouses.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonFormField<String>(
                    value: s.warehouseId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Receive into warehouse',
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
                title: const Text('Order date'),
                subtitle: Text(fmtDate(s.orderDate)),
                onTap: _pickDate,
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

  final PurchaseItem item;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      '${fmtMoney(item.unitCost)} × ${fmtQty(item.quantity)} ${item.unit}',
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

  final PurchaseItem item;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qty =
  TextEditingController(text: fmtQty(widget.item.quantity));
  late final TextEditingController _cost =
  TextEditingController(text: fmtQty(widget.item.unitCost));

  @override
  void dispose() {
    _qty.dispose();
    _cost.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (
    quantity: parseNum(_qty.text)!,
    unitCost: parseNum(_cost.text)!,
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
                controller: _cost,
                keyboardType: decimal,
                decoration: const InputDecoration(
                  labelText: 'Unit cost',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = parseNum(v ?? '');
                  return (n == null || n < 0) ? 'Enter a valid cost' : null;
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