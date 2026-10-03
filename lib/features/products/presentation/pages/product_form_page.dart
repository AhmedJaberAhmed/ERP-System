import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/permissions/permission_keys.dart';
import '../../../../core/utils/validators.dart';
import '../../../permissions/presentation/widgets/permission_guard.dart';
import '../../domain/entities/product.dart';
import '../cubit/products_cubit.dart';
import '../cubit/products_state.dart';

/// Create (product == null) or edit a product.
class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sku;
  late final TextEditingController _name;
  late final TextEditingController _unit;
  late final TextEditingController _cost;
  late final TextEditingController _price;
  late final TextEditingController _tax;
  late final TextEditingController _minStock;
  String? _categoryId;
  bool _trackStock = true;
  bool _isActive = true;

  static String _n(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _sku = TextEditingController(text: p?.sku);
    _name = TextEditingController(text: p?.name);
    _unit = TextEditingController(text: p?.unit ?? 'pcs');
    _cost = TextEditingController(text: p == null ? '' : _n(p.costPrice));
    _price = TextEditingController(text: p == null ? '' : _n(p.salePrice));
    _tax = TextEditingController(text: p == null ? '0' : _n(p.taxRate));
    _minStock = TextEditingController(text: p == null ? '0' : _n(p.minStock));
    _categoryId = p?.categoryId;
    _trackStock = p?.trackStock ?? true;
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final c in [_sku, _name, _unit, _cost, _price, _tax, _minStock]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  String? _validateNumber(String? v, {String label = 'Value', double? max}) {
    if (v == null || v.trim().isEmpty) return null; // treated as 0
    final n = double.tryParse(v.trim());
    if (n == null) return '$label must be a number';
    if (max != null && n > max) return '$label is too large';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final product = Product(
      id: widget.product?.id ?? '',
      sku: _sku.text.trim(),
      name: _name.text.trim(),
      categoryId: _categoryId,
      unit: _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
      costPrice: _num(_cost),
      salePrice: _num(_price),
      taxRate: _num(_tax),
      minStock: _num(_minStock),
      trackStock: _trackStock,
      isActive: _isActive,
    );
    final ok = await context.read<ProductsCubit>().save(product);
    if (ok && mounted) Navigator.of(context).pop();
  }

  static final _decimal = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
  static const _numKeyboard = TextInputType.numberWithOptions(decimal: true);

  @override
  Widget build(BuildContext context) {
    final canWrite = context.can(PermissionKeys.productsWrite);
    final categories = context.watch<ProductsCubit>().state.categories;
    // Guard against a category that is no longer in the list.
    final catValue =
    categories.any((c) => c.id == _categoryId) ? _categoryId : null;
    const gap = SizedBox(height: 16);

    InputDecoration deco(String label, {Widget? suffix}) => InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      suffixIcon: suffix,
    );

    return BlocListener<ProductsCubit, ProductsState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.product == null ? 'New product' : widget.product!.name),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                enabled: canWrite,
                textCapitalization: TextCapitalization.words,
                decoration: deco('Name'),
                validator: (v) => Validators.requiredField(v, label: 'Name'),
              ),
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sku,
                      enabled: canWrite,
                      textCapitalization: TextCapitalization.characters,
                      decoration: deco('SKU'),
                      validator: (v) => Validators.requiredField(v, label: 'SKU'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unit,
                      enabled: canWrite,
                      decoration: deco('Unit'),
                    ),
                  ),
                ],
              ),
              gap,
              if (categories.isNotEmpty) ...[
                DropdownButtonFormField<String?>(
                  value: catValue,
                  decoration: deco('Category'),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('No category')),
                    for (final c in categories)
                      DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: canWrite ? (v) => setState(() => _categoryId = v) : null,
                ),
                gap,
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cost,
                      enabled: canWrite,
                      keyboardType: _numKeyboard,
                      inputFormatters: _decimal,
                      decoration: deco('Cost price'),
                      validator: (v) => _validateNumber(v, label: 'Cost price'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      enabled: canWrite,
                      keyboardType: _numKeyboard,
                      inputFormatters: _decimal,
                      decoration: deco('Sale price'),
                      validator: (v) => _validateNumber(v, label: 'Sale price'),
                    ),
                  ),
                ],
              ),
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tax,
                      enabled: canWrite,
                      keyboardType: _numKeyboard,
                      inputFormatters: _decimal,
                      decoration: deco('Tax %'),
                      validator: (v) =>
                          _validateNumber(v, label: 'Tax rate', max: 999),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minStock,
                      enabled: canWrite,
                      keyboardType: _numKeyboard,
                      inputFormatters: _decimal,
                      decoration: deco('Min stock'),
                      validator: (v) => _validateNumber(v, label: 'Min stock'),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Track stock'),
                value: _trackStock,
                onChanged: canWrite ? (v) => setState(() => _trackStock = v) : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: canWrite ? (v) => setState(() => _isActive = v) : null,
              ),
              const SizedBox(height: 72),
            ],
          ),
        ),
        bottomNavigationBar: canWrite
            ? SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BlocBuilder<ProductsCubit, ProductsState>(
              buildWhen: (p, c) => p.isBusy != c.isBusy,
              builder: (context, state) => FilledButton(
                onPressed: state.isBusy ? null : _save,
                child: state.isBusy
                    ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save product'),
              ),
            ),
          ),
        )
            : null,
      ),
    );
  }
}