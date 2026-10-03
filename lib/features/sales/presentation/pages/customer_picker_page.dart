import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../company/presentation/cubit/company_cubit.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/domain/repositories/customer_repository.dart';
import '../../../customers/presentation/cubit/customers_cubit.dart';
import '../../../customers/presentation/cubit/customers_state.dart';

/// Search for a customer. Pops with the chosen [Customer].
class CustomerPickerPage extends StatelessWidget {
  const CustomerPickerPage({super.key});

  static Route<Customer> route(BuildContext context) {
    final company = context.read<CompanyCubit>().state.selected!;
    final repo = context.read<CustomerRepository>();
    return MaterialPageRoute<Customer>(
      builder: (_) => BlocProvider(
        create: (_) => CustomersCubit(repo, company.id)..load(),
        child: const CustomerPickerPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select customer')),
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
                    final customers = state.customers.where((c) => c.isActive).toList();
                    if (customers.isEmpty) {
                      return const Center(child: Text('No customers found.'));
                    }
                    return ListView.separated(
                      itemCount: customers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final c = customers[i];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase()),
                          ),
                          title: Text(c.name),
                          subtitle: Text([
                            if (c.phone != null && c.phone!.isNotEmpty) c.phone!,
                            if (c.email != null && c.email!.isNotEmpty) c.email!,
                          ].join(' · ')),
                          onTap: () => Navigator.of(context).pop(c),
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
