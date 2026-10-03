import 'package:erb3/features/permissions/presentation/widgets/permission_guard.dart';
import 'package:erb3/features/supliers/presentation/suppliers_cubit.dart';
import 'package:erb3/features/supliers/presentation/suppliers_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/permissions/permission_keys.dart';
import '../../../../core/utils/validators.dart';
import '../domain/supplier.dart';


/// Create (supplier == null) or edit a supplier.
class SupplierFormPage extends StatefulWidget {
  const SupplierFormPage({super.key, this.supplier});

  final Supplier? supplier;

  @override
  State<SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<SupplierFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _tax;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    _name = TextEditingController(text: s?.name);
    _phone = TextEditingController(text: s?.phone);
    _email = TextEditingController(text: s?.email);
    _address = TextEditingController(text: s?.address);
    _tax = TextEditingController(text: s?.taxNumber);
    _isActive = s?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _address, _tax]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _opt(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  String? _validateEmail(String? v) =>
      (v == null || v.trim().isEmpty) ? null : Validators.email(v);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final supplier = Supplier(
      id: widget.supplier?.id ?? '',
      name: _name.text.trim(),
      phone: _opt(_phone),
      email: _opt(_email),
      address: _opt(_address),
      taxNumber: _opt(_tax),
      isActive: _isActive,
    );
    final ok = await context.read<SuppliersCubit>().save(supplier);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canWrite = context.can(PermissionKeys.suppliersWrite);
    const gap = SizedBox(height: 16);
    const border = OutlineInputBorder();

    return BlocListener<SuppliersCubit, SuppliersState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              widget.supplier == null ? 'New supplier' : widget.supplier!.name),
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
                decoration: const InputDecoration(labelText: 'Name', border: border),
                validator: (v) => Validators.requiredField(v, label: 'Name'),
              ),
              gap,
              TextFormField(
                controller: _phone,
                enabled: canWrite,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone', border: border),
              ),
              gap,
              TextFormField(
                controller: _email,
                enabled: canWrite,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: border),
                validator: _validateEmail,
              ),
              gap,
              TextFormField(
                controller: _address,
                enabled: canWrite,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Address', border: border),
              ),
              gap,
              TextFormField(
                controller: _tax,
                enabled: canWrite,
                decoration:
                const InputDecoration(labelText: 'Tax number', border: border),
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
            child: BlocBuilder<SuppliersCubit, SuppliersState>(
              buildWhen: (p, c) => p.isBusy != c.isBusy,
              builder: (context, state) => FilledButton(
                onPressed: state.isBusy ? null : _save,
                child: state.isBusy
                    ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save supplier'),
              ),
            ),
          ),
        )
            : null,
      ),
    );
  }
}