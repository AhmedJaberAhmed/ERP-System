import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/error_view.dart';
import '../../../company/presentation/cubit/company_cubit.dart';
import '../../../permissions/domain/repositories/permission_repository.dart';
import '../../domain/entities/role.dart';
import '../../domain/repositories/role_repository.dart';
import '../cubit/roles_cubit.dart';
import '../cubit/roles_state.dart';
import 'role_form_page.dart';

class RolesPage extends StatelessWidget {
  const RolesPage({super.key});

  static Route<void> route(BuildContext context) {
    final companyId = context.read<CompanyCubit>().state.selected!.id;
    final roles = context.read<RoleRepository>();
    final permissions = context.read<PermissionRepository>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => RolesCubit(roles, permissions, companyId)..load(),
        child: const RolesPage(),
      ),
    );
  }

  void _openForm(BuildContext context, {Role? role}) {
    final cubit = context.read<RolesCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: RoleFormPage(role: role),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Role role) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete role?'),
        content: Text(
          'Delete "${role.name}"? Members must be moved to another role first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<RolesCubit>().deleteRole(role);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RolesCubit, RolesState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Roles')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(context),
          icon: const Icon(Icons.add),
          label: const Text('New role'),
        ),
        body: BlocBuilder<RolesCubit, RolesState>(
          builder: (context, state) {
            switch (state.status) {
              case RolesStatus.initial:
              case RolesStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case RolesStatus.failure:
                return ErrorView(
                  message: state.errorMessage,
                  onRetry: () => context.read<RolesCubit>().load(),
                );
              case RolesStatus.loaded:
                return RefreshIndicator(
                  onRefresh: () => context.read<RolesCubit>().load(silent: true),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: state.roles.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final role = state.roles[i];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(role.isSystem
                              ? Icons.shield_outlined
                              : Icons.badge_outlined),
                        ),
                        title: Text(role.name),
                        subtitle: Text(role.isSystem
                            ? 'System role · ${role.permissionKeys.length} permissions'
                            : '${role.permissionKeys.length} permissions'),
                        trailing: role.isSystem
                            ? const Icon(Icons.lock_outline)
                            : PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'delete') _confirmDelete(context, role);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                        onTap: () => _openForm(context, role: role),
                      );
                    },
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}
