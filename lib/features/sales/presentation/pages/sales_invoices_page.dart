import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/permissions/permission_keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../company/presentation/cubit/company_cubit.dart';
import '../../../permissions/presentation/widgets/permission_guard.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/repositories/sales_invoice_repository.dart';
import '../cubit/invoices_cubit.dart';
import '../cubit/invoices_state.dart';
import 'invoice_detail_page.dart';
import 'invoice_editor_page.dart';

Color invoiceStatusColor(InvoiceStatus s) => switch (s) {
      InvoiceStatus.draft => AppColors.neutral,
      InvoiceStatus.confirmed => AppColors.info,
      InvoiceStatus.cancelled => AppColors.danger,
    };

Color paymentStatusColor(PaymentStatus s) => switch (s) {
      PaymentStatus.unpaid => AppColors.warning,
      PaymentStatus.partial => const Color(0xFFB7791F),
      PaymentStatus.paid => AppColors.success,
    };

class SalesInvoicesPage extends StatelessWidget {
  const SalesInvoicesPage({super.key});

  static Route<void> route(BuildContext context) {
    final company = context.read<CompanyCubit>().state.selected!;
    final repo = context.read<SalesInvoiceRepository>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => InvoicesCubit(repo, company.id)..load(),
        child: const SalesInvoicesPage(),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, String invoiceId) async {
    final cubit = context.read<InvoicesCubit>();
    await Navigator.of(context).push(InvoiceDetailPage.route(context, invoiceId));
    cubit.load(silent: true);
  }

  Future<void> _create(BuildContext context) async {
    final cubit = context.read<InvoicesCubit>();
    final id = await Navigator.of(context).push<String>(InvoiceEditorPage.route(context));
    cubit.load(silent: true);
    // Straight to the saved draft so it can be confirmed.
    if (id != null && context.mounted) await _openDetail(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InvoicesCubit, InvoicesState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Sales invoices')),
        floatingActionButton: PermissionGuard(
          permission: PermissionKeys.salesInvoicesWrite,
          child: FloatingActionButton.extended(
            onPressed: () => _create(context),
            icon: const Icon(Icons.add),
            label: const Text('New invoice'),
          ),
        ),
        body: Column(
          children: [
            SearchField(
              hint: 'Search invoice number',
              onChanged: (q) => context.read<InvoicesCubit>().search(q),
            ),
            BlocBuilder<InvoicesCubit, InvoicesState>(
              buildWhen: (p, c) => p.statusFilter != c.statusFilter,
              builder: (context, state) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: state.statusFilter == null,
                      onSelected: (_) => context.read<InvoicesCubit>().filterBy(null),
                    ),
                    for (final s in InvoiceStatus.values) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(s.label),
                        selected: state.statusFilter == s,
                        onSelected: (_) => context.read<InvoicesCubit>().filterBy(s),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<InvoicesCubit, InvoicesState>(
                builder: (context, state) {
                  switch (state.status) {
                    case InvoicesStatus.initial:
                    case InvoicesStatus.loading:
                      return const Center(child: CircularProgressIndicator());
                    case InvoicesStatus.failure:
                      return ErrorView(
                        message: state.errorMessage,
                        onRetry: () => context.read<InvoicesCubit>().load(),
                      );
                    case InvoicesStatus.loaded:
                      if (state.invoices.isEmpty) {
                        return const Center(child: Text('No invoices found.'));
                      }
                      return RefreshIndicator(
                        onRefresh: () => context.read<InvoicesCubit>().load(silent: true),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: state.invoices.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final inv = state.invoices[i];
                            return ListTile(
                              title: Text(inv.number ?? 'Draft'),
                              subtitle: Text(
                                '${inv.customerName ?? 'Walk-in customer'} · ${fmtDate(inv.invoiceDate)}',
                              ),
                              trailing: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(fmtMoney(inv.total),
                                      style: Theme.of(context).textTheme.titleSmall),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      StatusChip(inv.status.label,
                                          invoiceStatusColor(inv.status)),
                                      if (inv.isConfirmed) ...[
                                        const SizedBox(width: 4),
                                        StatusChip(inv.payStatus.label,
                                            paymentStatusColor(inv.payStatus)),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () => _openDetail(context, inv.id),
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
