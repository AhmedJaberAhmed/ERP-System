import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/permissions/permission_keys.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../company/presentation/cubit/company_cubit.dart';
import '../../../permissions/presentation/widgets/permission_guard.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/repositories/warehouse_repository.dart';
import '../cubit/warehouses_cubit.dart';
import '../cubit/warehouses_state.dart';

class WarehousesPage extends StatelessWidget {
  const WarehousesPage({super.key});

  static Route<void> route(BuildContext context) {
    final company = context.read<CompanyCubit>().state.selected!;
    final repo = context.read<WarehouseRepository>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => WarehousesCubit(repo, company.id)..load(),
        child: const WarehousesPage(),
      ),
    );
  }

  Future<void> _edit(BuildContext context, {Warehouse? warehouse}) async {
    final cubit = context.read<WarehousesCubit>();
    final result = await showDialog<Warehouse>(
      context: context,
      builder: (_) => _WarehouseDialog(warehouse: warehouse),
    );
    if (result != null) await cubit.save(result);
  }

  Future<void> _confirmDelete(BuildContext context, Warehouse w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete warehouse?'),
        content: Text('Delete "${w.name}"?'),
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
    if (ok == true && context.mounted) {
      context.read<WarehousesCubit>().delete(w);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canWrite = context.can(PermissionKeys.warehousesWrite);
    final canDelete = context.can(PermissionKeys.warehousesDelete);

    return BlocListener<WarehousesCubit, WarehousesState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Warehouses')),
        floatingActionButton: PermissionGuard(
          permission: PermissionKeys.warehousesWrite,
          child: FloatingActionButton.extended(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add),
            label: const Text('New warehouse'),
          ),
        ),
        body: BlocBuilder<WarehousesCubit, WarehousesState>(
          builder: (context, state) {
            switch (state.status) {
              case WarehousesStatus.initial:
              case WarehousesStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case WarehousesStatus.failure:
                return ErrorView(
                  message: state.errorMessage,
                  onRetry: () => context.read<WarehousesCubit>().load(),
                );
              case WarehousesStatus.loaded:
                if (state.warehouses.isEmpty) {
                  return const Center(child: Text('No warehouses yet.'));
                }
                return Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () => context.read<WarehousesCubit>().load(silent: true),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: state.warehouses.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final w = state.warehouses[i];
                          final hasMenu =
                              canWrite && (!w.isDefault && w.isActive) || canDelete;
                          return Opacity(
                            opacity: w.isActive ? 1 : 0.5,
                            child: ListTile(
                              leading: const CircleAvatar(
                                  child: Icon(Icons.warehouse_outlined)),
                              title: Row(
                                children: [
                                  Flexible(child: Text(w.name)),
                                  if (w.isDefault) ...[
                                    const SizedBox(width: 8),
                                    const StatusChip('Default', AppColors.brand),
                                  ],
                                  if (!w.isActive) ...[
                                    const SizedBox(width: 8),
                                    const StatusChip('Inactive', AppColors.neutral),
                                  ],
                                ],
                              ),
                              subtitle: (w.address == null || w.address!.isEmpty)
                                  ? null
                                  : Text(w.address!),
                              trailing: !hasMenu
                                  ? null
                                  : PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'default') {
                                          context.read<WarehousesCubit>().setDefault(w);
                                        }
                                        if (v == 'delete') _confirmDelete(context, w);
                                      },
                                      itemBuilder: (_) => [
                                        if (canWrite && !w.isDefault && w.isActive)
                                          const PopupMenuItem(
                                              value: 'default',
                                              child: Text('Make default')),
                                        if (canDelete)
                                          const PopupMenuItem(
                                              value: 'delete', child: Text('Delete')),
                                      ],
                                    ),
                              onTap: canWrite
                                  ? () => _edit(context, warehouse: w)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    if (state.isBusy) const LinearProgressIndicator(),
                  ],
                );
            }
          },
        ),
      ),
    );
  }
}

class _WarehouseDialog extends StatefulWidget {
  const _WarehouseDialog({this.warehouse});

  final Warehouse? warehouse;

  @override
  State<_WarehouseDialog> createState() => _WarehouseDialogState();
}

class _WarehouseDialogState extends State<_WarehouseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.warehouse?.name);
  late final TextEditingController _address =
      TextEditingController(text: widget.warehouse?.address);
  late bool _active = widget.warehouse?.isActive ?? true;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final w = widget.warehouse;
    final address = _address.text.trim();
    Navigator.pop(
      context,
      Warehouse(
        id: w?.id ?? '',
        name: _name.text.trim(),
        address: address.isEmpty ? null : address,
        isDefault: w?.isDefault ?? false,
        isActive: _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.warehouse == null ? 'New warehouse' : 'Edit warehouse'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Name', border: OutlineInputBorder()),
              validator: (v) => Validators.requiredField(v, label: 'Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                  labelText: 'Address (optional)', border: OutlineInputBorder()),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
