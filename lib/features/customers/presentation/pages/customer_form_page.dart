import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/permissions/permission_keys.dart';
import '../../../../core/utils/validators.dart';
import '../../../permissions/presentation/widgets/permission_guard.dart';
import '../../domain/entities/customer.dart';
import '../cubit/customers_cubit.dart';
import '../cubit/customers_state.dart';

/// Create (customer == null) or edit a customer.
class CustomerFormPage extends StatefulWidget {
  const CustomerFormPage({super.key, this.customer});

  final Customer? customer;

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _tax;
  late final TextEditingController _credit;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _name = TextEditingController(text: c?.name);
    _phone = TextEditingController(text: c?.phone);
    _email = TextEditingController(text: c?.email);
    _address = TextEditingController(text: c?.address);
    _tax = TextEditingController(text: c?.taxNumber);
    _credit = TextEditingController(
      text: c == null || c.creditLimit == 0
          ? ''
          : (c.creditLimit == c.creditLimit.roundToDouble()
              ? c.creditLimit.toStringAsFixed(0)
              : '${c.creditLimit}'),
    );
    _isActive = c?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _address, _tax, _credit]) {
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

  String? _validateCredit(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return double.tryParse(v.trim()) == null ? 'Enter a valid number' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final customer = Customer(
      id: widget.customer?.id ?? '',
      name: _name.text.trim(),
      phone: _opt(_phone),
      email: _opt(_email),
      address: _opt(_address),
      taxNumber: _opt(_tax),
      creditLimit: double.tryParse(_credit.text.trim()) ?? 0,
      isActive: _isActive,
    );
    final ok = await context.read<CustomersCubit>().save(customer);
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canWrite = context.can(PermissionKeys.customersWrite);
    const gap = SizedBox(height: 16);
    const border = OutlineInputBorder();

    return BlocListener<CustomersCubit, CustomersState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              widget.customer == null ? 'New customer' : widget.customer!.name),
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
                decoration:
                    const InputDecoration(labelText: 'Name', border: border),
                validator: (v) => Validators.requiredField(v, label: 'Name'),
              ),
              gap,
              TextFormField(
                controller: _phone,
                enabled: canWrite,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'Phone', border: border),
              ),
              gap,
              TextFormField(
                controller: _email,
                enabled: canWrite,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(labelText: 'Email', border: border),
                validator: _validateEmail,
              ),
              gap,
              TextFormField(
                controller: _address,
                enabled: canWrite,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration:
                    const InputDecoration(labelText: 'Address', border: border),
              ),
              gap,
              TextFormField(
                controller: _tax,
                enabled: canWrite,
                decoration: const InputDecoration(
                    labelText: 'Tax number', border: border),
              ),
              gap,
              TextFormField(
                controller: _credit,
                enabled: canWrite,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                decoration: const InputDecoration(
                    labelText: 'Credit limit', border: border),
                validator: _validateCredit,
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
                  child: BlocBuilder<CustomersCubit, CustomersState>(
                    buildWhen: (p, c) => p.isBusy != c.isBusy,
                    builder: (context, state) => FilledButton(
                      onPressed: state.isBusy ? null : _save,
                      child: state.isBusy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save customer'),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
