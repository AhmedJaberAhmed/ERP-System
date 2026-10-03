import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/permissions/permission_keys.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../company/presentation/cubit/company_cubit.dart';
import '../../../permissions/presentation/widgets/permission_guard.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../cubit/customers_cubit.dart';
import '../cubit/customers_state.dart';
import 'customer_form_page.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  static Route<void> route(BuildContext context) {
    final company = context.read<CompanyCubit>().state.selected!;
    final repo = context.read<CustomerRepository>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => CustomersCubit(repo, company.id)..load(),
        child: const CustomersPage(),
      ),
    );
  }

  void _openForm(BuildContext context, {Customer? customer}) {
    final cubit = context.read<CustomersCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: CustomerFormPage(customer: customer),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Customer c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete customer?'),
        content: Text('Delete "${c.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && context.mounted) context.read<CustomersCubit>().delete(c);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomersCubit, CustomersState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Customers')),
        floatingActionButton: PermissionGuard(
          permission: PermissionKeys.customersWrite,
          child: FloatingActionButton.extended(
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add),
            label: const Text('New customer'),
          ),
        ),
        body: Column(
          children: [
            SearchField(
              hint: 'Search name, phone or email',
              onChanged: (q) => context.read<CustomersCubit>().search(q),
            ),
            Expanded(
              child: BlocBuilder<CustomersCubit, CustomersState>(
                builder: (context, state) {
                  switch (state.status) {
                    case CustomersStatus.initial:
                    case CustomersStatus.loading:
                      return const Center(child: CircularProgressIndicator());
                    case CustomersStatus.failure:
                      return ErrorView(
                        message: state.errorMessage,
                        onRetry: () => context.read<CustomersCubit>().load(),
                      );
                    case CustomersStatus.loaded:
                      if (state.customers.isEmpty) {
                        return Center(
                          child: Text(state.query.isEmpty
                              ? 'No customers yet.'
                              : 'No matches for "${state.query}".'),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () =>
                            context.read<CustomersCubit>().load(silent: true),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: state.customers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final c = state.customers[i];
                            final sub = [
                              if (c.phone != null && c.phone!.isNotEmpty) c.phone!,
                              if (c.email != null && c.email!.isNotEmpty) c.email!,
                              if (!c.isActive) 'Inactive',
                            ].join(' · ');
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(c.name.isEmpty
                                    ? '?'
                                    : c.name[0].toUpperCase()),
                              ),
                              title: Text(c.name),
                              subtitle: sub.isEmpty ? null : Text(sub),
                              trailing: PermissionGuard(
                                permission: PermissionKeys.customersDelete,
                                child: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'delete') _confirmDelete(context, c);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                        value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ),
                              onTap: () => _openForm(context, customer: c),
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
