import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/company_cubit.dart';
import '../cubit/company_state.dart';

class CreateCompanyPage extends StatefulWidget {
  const CreateCompanyPage({super.key});

  @override
  State<CreateCompanyPage> createState() => _CreateCompanyPageState();
}

class _CreateCompanyPageState extends State<CreateCompanyPage> {
  static const _currencies = ['EGP', 'USD', 'EUR', 'SAR', 'AED'];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _currency = 'EGP';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CompanyCubit>().createCompany(
          name: _name.text.trim(),
          currency: _currency,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompanyCubit, CompanyState>(
      listenWhen: (prev, curr) =>
          curr.errorMessage != null && prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Set up your company'),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthCubit>().signOut(),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "You don't have a company yet. Create one to get started. "
                        "You'll be its Owner with full access.",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.words,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Company name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            Validators.requiredField(v, label: 'Company name'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _currency,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final c in _currencies)
                            DropdownMenuItem(value: c, child: Text(c)),
                        ],
                        onChanged: (v) => setState(() => _currency = v ?? 'EGP'),
                      ),
                      const SizedBox(height: 24),
                      BlocBuilder<CompanyCubit, CompanyState>(
                        buildWhen: (p, c) => p.isCreating != c.isCreating,
                        builder: (context, state) => FilledButton(
                          onPressed: state.isCreating ? null : _submit,
                          child: state.isCreating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Create company'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
