import 'package:erb3/features/supliers/presentation/suppliers_cubit.dart';
import 'package:erb3/features/supliers/presentation/suppliers_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/search_field.dart';
import '../../company/presentation/cubit/company_cubit.dart';
import '../domain/supplier.dart';
import '../domain/supplier_repository.dart';


/// Search for a supplier. Pops with the chosen [Supplier].
class SupplierPickerPage extends StatelessWidget {
  const SupplierPickerPage({super.key});

  static Route<Supplier> route(BuildContext context) {
    final company = context.read<CompanyCubit>().state.selected!;
    final repo = context.read<SupplierRepository>();
    return MaterialPageRoute<Supplier>(
      builder: (_) => BlocProvider(
        create: (_) => SuppliersCubit(repo, company.id)..load(),
        child: const SupplierPickerPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select supplier')),
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
                    final suppliers = state.suppliers.where((s) => s.isActive).toList();
                    if (suppliers.isEmpty) {
                      return const Center(child: Text('No suppliers found.'));
                    }
                    return ListView.separated(
                      itemCount: suppliers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final s = suppliers[i];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(s.name.isEmpty ? '?' : s.name[0].toUpperCase()),
                          ),
                          title: Text(s.name),
                          subtitle: Text([
                            if (s.phone != null && s.phone!.isNotEmpty) s.phone!,
                            if (s.email != null && s.email!.isNotEmpty) s.email!,
                          ].join(' · ')),
                          onTap: () => Navigator.of(context).pop(s),
                        );
                      },
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}