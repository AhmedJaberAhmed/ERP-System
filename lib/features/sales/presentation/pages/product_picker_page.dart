import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/search_field.dart';
import '../../../company/presentation/cubit/company_cubit.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../products/presentation/cubit/products_cubit.dart';
import '../../../products/presentation/cubit/products_state.dart';

/// Search for a product. Pops with the chosen [Product].
class ProductPickerPage extends StatelessWidget {
  const ProductPickerPage({super.key, this.showCost = false});

  /// When true the list shows the cost price instead of the sale price.
  /// Used by the purchasing flow.
  final bool showCost;

  static Route<Product> route(BuildContext context, {bool showCost = false}) {
    final company = context.read<CompanyCubit>().state.selected!;
    final repo = context.read<ProductRepository>();
    return MaterialPageRoute<Product>(
      builder: (_) => BlocProvider(
        create: (_) => ProductsCubit(repo, company.id)..load(),
        child: ProductPickerPage(showCost: showCost),
      ),
    );
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
        appBar: AppBar(title: const Text('Add product')),
        body: Column(
          children: [
            SearchField(
              hint: 'Search name, SKU or barcode',
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
                      final products = state.products.where((p) => p.isActive).toList();
                      if (products.isEmpty) {
                        return const Center(child: Text('No products found.'));
                      }
                      return ListView.separated(
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final p = products[i];
                          return ListTile(
                            leading: const CircleAvatar(
                                child: Icon(Icons.inventory_2_outlined)),
                            title: Text(p.name),
                            subtitle: Text(p.sku),
                            trailing: Text(
                                fmtMoney(showCost ? p.costPrice : p.salePrice),
                                style: Theme.of(context).textTheme.titleSmall),
                            onTap: () => Navigator.of(context).pop(p),
                          );
                        },
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