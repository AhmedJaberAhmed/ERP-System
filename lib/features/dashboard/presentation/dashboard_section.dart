import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erb3/core/theme/app_theme.dart';

import '../../../../core/utils/format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../company/presentation/cubit/company_cubit.dart';
import '../../sales/presentation/pages/invoice_detail_page.dart';
import '../domain/DashboardSummary.dart';
import 'dashboard_cubit.dart';
import 'dashboard_state.dart';


/// Needs a DashboardCubit above it in the tree.
class DashboardSection extends StatelessWidget {
  const DashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = context
        .select<CompanyCubit, String>((c) => c.state.selected?.currency ?? '');
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        switch (state.status) {
          case DashboardStatus.initial:
          case DashboardStatus.loading:
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          case DashboardStatus.failure:
            return ErrorView(
              message: state.errorMessage,
              onRetry: () => context.read<DashboardCubit>().load(),
            );
          case DashboardStatus.loaded:
            return _Loaded(
              data: state.data!,
              currency: currency,
              includeStock: context.read<DashboardCubit>().includeStock,
            );
        }
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.data,
    required this.currency,
    required this.includeStock,
  });

  final DashboardData data;
  final String currency;
  final bool includeStock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = data.summary;

    final kpis = <Widget>[
      _Kpi(
        icon: Icons.point_of_sale,
        color: theme.colorScheme.primary,
        label: "Today's sales",
        value: fmtMoney(s.todaySales),
        caption: '${s.todayInvoices} invoices · $currency',
      ),
      _Kpi(
        icon: Icons.hourglass_bottom,
        color: AppColors.warning,
        label: 'Unpaid',
        value: fmtMoney(s.unpaidTotal),
        caption: '${s.unpaidCount} invoices · $currency',
      ),
      if (includeStock)
        _Kpi(
          icon: Icons.warning_amber_rounded,
          color: s.lowStockCount > 0 ? AppColors.danger : AppColors.success,
          label: 'Low stock',
          value: '${s.lowStockCount}',
          caption: 'products',
        ),
    ];

    final maxRevenue = data.topProducts.fold<double>(
        0, (m, p) => p.revenue > m ? p.revenue : m);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              const gap = 12.0;
              final cols = (kpis.length == 3 && c.maxWidth >= 560) ? 3 : 2;
              final w = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [for (final k in kpis) SizedBox(width: w, child: k)],
              );
            },
          ),
          const SizedBox(height: 12),
          _Panel(
            title: 'Sales · last 7 days',
            child: _SalesBars(data.last7Days),
          ),
          _Panel(
            title: 'Top products · last 30 days',
            child: data.topProducts.isEmpty
                ? const _EmptyText('No sales yet')
                : Column(
              children: [
                for (final p in data.topProducts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(p.name,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            Text(fmtMoney(p.revenue),
                                style: theme.textTheme.titleSmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: maxRevenue == 0 ? 0 : p.revenue / maxRevenue,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('${fmtQty(p.quantity)} ${p.unit} sold',
                            style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _Panel(
            title: 'Unpaid invoices',
            child: data.unpaid.isEmpty
                ? const _EmptyText('Nothing unpaid')
                : Column(
              children: [
                for (final u in data.unpaid)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(u.number ?? 'Draft'),
                    subtitle: Text([
                      u.customerName ?? 'Walk-in customer',
                      if (u.dueDate != null) 'due ${fmtDate(u.dueDate!)}',
                    ].join(' · ')),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(fmtMoney(u.balance),
                            style: theme.textTheme.titleSmall),
                        if (u.isOverdue) const StatusChip('Overdue', AppColors.danger),
                      ],
                    ),
                    onTap: () async {
                      final cubit = context.read<DashboardCubit>();
                      await Navigator.of(context)
                          .push(InvoiceDetailPage.route(context, u.invoiceId));
                      cubit.load(silent: true);
                    },
                  ),
              ],
            ),
          ),
          if (includeStock)
            _Panel(
              title: 'Low stock',
              child: data.lowStock.isEmpty
                  ? const _EmptyText('All products are above their minimum')
                  : Column(
                children: [
                  for (final p in data.lowStock)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(p.name),
                      subtitle: Text(p.sku),
                      trailing: Text(
                        '${fmtQty(p.quantity)} / min ${fmtQty(p.minStock)} ${p.unit}',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: AppColors.danger),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withAlpha(38),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 2),
            Text(caption, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text),
  );
}

/// Simple bar chart, no chart package needed.
class _SalesBars extends StatelessWidget {
  const _SalesBars(this.days);

  final List<DailySales> days;

  static const _chartHeight = 120.0;
  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String _short(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxV = days.fold<double>(0, (m, d) => d.total > m ? d.total : m);
    return SizedBox(
      height: _chartHeight + 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in days)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(d.total > 0 ? _short(d.total) : '',
                      style: theme.textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Container(
                    height: maxV == 0
                        ? 2
                        : (d.total / maxV * _chartHeight)
                        .clamp(2.0, _chartHeight)
                        .toDouble(),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: d.total > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_names[d.day.weekday - 1], style: theme.textTheme.labelSmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}