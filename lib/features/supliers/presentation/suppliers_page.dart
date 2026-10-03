import 'package:erb3/features/supliers/presentation/suppliers_cubit.dart';
import 'package:erb3/features/supliers/presentation/suppliers_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/permissions/permission_keys.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/search_field.dart';

import '../../company/presentation/cubit/company_cubit.dart';
import '../../permissions/presentation/widgets/permission_guard.dart';
import '../domain/supplier.dart';
import '../domain/supplier_repository.dart';
import 'supplier_form_page.dart';

class SuppliersPage extends StatelessWidget {
  const SuppliersPage({super.key});

  static Route<void> route(BuildContext context) {
    final company = context.read<CompanyCubit>().state.selected!;
    final repo = context.read<SupplierRepository>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => SuppliersCubit(repo, company.id)..load(),
        child: const SuppliersPage(),
      ),
    );
  }

  void _openForm(BuildContext context, {Supplier? supplier}) {
    final cubit = context.read<SuppliersCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: SupplierFormPage(supplier: supplier),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Supplier s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete supplier?'),
        content: Text('Delete "${s.name}"?'),
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
    if (ok == true && context.mounted) context.read<SuppliersCubit>().delete(s);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SuppliersCubit, SuppliersState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Suppliers')),
        floatingActionButton: PermissionGuard(
          permission: PermissionKeys.suppliersWrite,
          child: FloatingActionButton.extended(
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add),
            label: const Text('New supplier'),
          ),
        ),
        body: Column(
          children: [
            SearchField(
              hint: 'Search name, phone or email',
              onChanged: (q) => context.read<SuppliersCubit>().search(q),
            ),
            Expanded(
              child: BlocBuilder<SuppliersCubit, SuppliersState>(
                builder: (context, state) {
                  switch (state.status) {
                    case SuppliersStatus.initial:
                    case SuppliersStatus.loading:
                      return const Center(child: CircularProgressIndicator());
                    case SuppliersStatus.failure:
                      return ErrorView(
                        message: state.errorMessage,
                        onRetry: () => context.read<SuppliersCubit>().load(),
                      );
                    case SuppliersStatus.loaded:
                      if (state.suppliers.isEmpty) {
                        return Center(
                          child: Text(state.query.isEmpty
                              ? 'No suppliers yet.'
                              : 'No matches for "${state.query}".'),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () =>
                            context.read<SuppliersCubit>().load(silent: true),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: state.suppliers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final s = state.suppliers[i];
                            final sub = [
                              if (s.phone != null && s.phone!.isNotEmpty) s.phone!,
                              if (s.email != null && s.email!.isNotEmpty) s.email!,
                              if (!s.isActive) 'Inactive',
                            ].join(' · ');
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(s.name.isEmpty
                                    ? '?'
                                    : s.name[0].toUpperCase()),
                              ),
                              title: Text(s.name),
                              subtitle: sub.isEmpty ? null : Text(sub),
                              trailing: PermissionGuard(
                                permission: PermissionKeys.suppliersDelete,
                                child: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'delete') _confirmDelete(context, s);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                        value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ),
                              onTap: () => _openForm(context, supplier: s),
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