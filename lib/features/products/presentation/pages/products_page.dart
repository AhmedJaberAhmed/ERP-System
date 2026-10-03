import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/permissions/permission_keys.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../company/presentation/cubit/company_cubit.dart';
import '../../../permissions/presentation/widgets/permission_guard.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../cubit/products_cubit.dart';
import '../cubit/products_state.dart';
import 'product_form_page.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  static Route<void> route(BuildContext context) {
    final company = context.read<CompanyCubit>().state.selected!;
    final repo = context.read<ProductRepository>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => ProductsCubit(repo, company.id)..load(),
        child: const ProductsPage(),
      ),
    );
  }

  void _openForm(BuildContext context, {Product? product}) {
    final cubit = context.read<ProductsCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: ProductFormPage(product: product),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Delete "${p.name}"?'),
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
    if (ok == true && context.mounted) context.read<ProductsCubit>().delete(p);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductsCubit, ProductsState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Products')),
        floatingActionButton: PermissionGuard(
          permission: PermissionKeys.productsWrite,
          child: FloatingActionButton.extended(
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add),
            label: const Text('New product'),
          ),
        ),
        body: Column(
          children: [
            SearchField(
              hint: 'Search name or SKU',
              onChanged: (q) => context.read<ProductsCubit>().search(q),
            ),
            Expanded(
              child: BlocBuilder<ProductsCubit, ProductsState>(
                builder: (context, state) {
                  switch (state.status) {
                    case ProductsStatus.initial:
                    case ProductsStatus.loading:
                      return const Center(child: CircularProgressIndicator());
                    case ProductsStatus.failure:
                      return ErrorView(
                        message: state.errorMessage,
                        onRetry: () => context.read<ProductsCubit>().load(),
                      );
                    case ProductsStatus.loaded:
                      if (state.products.isEmpty) {
                        return Center(
                          child: Text(state.query.isEmpty
                              ? 'No products yet.'
                              : 'No matches for "${state.query}".'),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () =>
                            context.read<ProductsCubit>().load(silent: true),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: state.products.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final p = state.products[i];
                            return ListTile(
                              leading: CircleAvatar(
                                  child: Icon(p.isActive
                                      ? Icons.inventory_2_outlined
                                      : Icons.block)),
                              title: Text(p.name),
                              subtitle: Text([
                                p.sku,
                                if (!p.isActive) 'Inactive',
                              ].join(' · ')),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(p.salePrice.toStringAsFixed(2),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall),
                                  PermissionGuard(
                                    permission: PermissionKeys.productsDelete,
                                    child: PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'delete') {
                                          _confirmDelete(context, p);
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete')),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _openForm(context, product: p),
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