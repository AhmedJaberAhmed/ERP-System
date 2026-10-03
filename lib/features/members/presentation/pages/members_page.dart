import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../company/presentation/cubit/company_cubit.dart';
import '../../../roles/domain/entities/role.dart';
import '../../../roles/domain/repositories/role_repository.dart';
import '../../domain/entities/member.dart';
import '../../domain/repositories/member_repository.dart';
import '../cubit/members_cubit.dart';
import '../cubit/members_state.dart';

class MembersPage extends StatelessWidget {
  const MembersPage({super.key});

  static Route<void> route(BuildContext context) {
    final companyId = context.read<CompanyCubit>().state.selected!.id;
    final userId = context.read<AuthCubit>().state.user!.id;
    final members = context.read<MemberRepository>();
    final roles = context.read<RoleRepository>();
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => MembersCubit(members, roles, companyId, userId)..load(),
        child: const MembersPage(),
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final cubit = context.read<MembersCubit>();
    final result = await showDialog<({String email, String roleId})>(
      context: context,
      builder: (_) => _AddMemberDialog(roles: cubit.state.roles),
    );
    if (result == null) return;
    final ok = await cubit.addMember(email: result.email, roleId: result.roleId);
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Member added')));
    }
  }

  Future<void> _changeRole(BuildContext context, Member member) async {
    final cubit = context.read<MembersCubit>();
    final roleId = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Role for ${member.displayName}'),
        children: [
          for (final role in cubit.state.roles)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, role.id),
              child: Row(
                children: [
                  Expanded(child: Text(role.name)),
                  if (role.id == member.roleId) const Icon(Icons.check, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
    if (roleId == null || roleId == member.roleId) return;
    await cubit.changeRole(userId: member.userId, roleId: roleId);
  }

  Future<void> _toggleActive(BuildContext context, Member member) async {
    final cubit = context.read<MembersCubit>();
    final activate = !member.isActive;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(activate ? 'Activate member?' : 'Deactivate member?'),
        content: Text(activate
            ? '${member.displayName} will regain access.'
            : '${member.displayName} will lose access to this company.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(activate ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await cubit.setActive(userId: member.userId, isActive: activate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MembersCubit, MembersState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Members')),
        floatingActionButton: BlocBuilder<MembersCubit, MembersState>(
          buildWhen: (p, c) => p.status != c.status || p.isBusy != c.isBusy,
          builder: (context, state) => FloatingActionButton.extended(
            onPressed: state.status == MembersStatus.loaded && !state.isBusy
                ? () => _add(context)
                : null,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add member'),
          ),
        ),
        body: BlocBuilder<MembersCubit, MembersState>(
          builder: (context, state) {
            switch (state.status) {
              case MembersStatus.initial:
              case MembersStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case MembersStatus.failure:
                return ErrorView(
                  message: state.errorMessage,
                  onRetry: () => context.read<MembersCubit>().load(),
                );
              case MembersStatus.loaded:
                final me = context.read<MembersCubit>().currentUserId;
                return Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () =>
                          context.read<MembersCubit>().load(silent: true),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: state.members.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final m = state.members[i];
                          final isMe = m.userId == me;
                          final initial = m.displayName.isEmpty
                              ? '?'
                              : m.displayName[0].toUpperCase();
                          return Opacity(
                            opacity: m.isActive ? 1 : 0.5,
                            child: ListTile(
                              leading: CircleAvatar(child: Text(initial)),
                              title: Text(isMe ? '${m.displayName} (you)' : m.displayName),
                              subtitle: Text(
                                '${m.email}\n${m.roleName}${m.isActive ? '' : ' · Inactive'}',
                              ),
                              isThreeLine: true,
                              trailing: isMe
                                  ? null
                                  : PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'role') _changeRole(context, m);
                                        if (v == 'toggle') _toggleActive(context, m);
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'role',
                                          child: Text('Change role'),
                                        ),
                                        PopupMenuItem(
                                          value: 'toggle',
                                          child: Text(m.isActive ? 'Deactivate' : 'Activate'),
                                        ),
                                      ],
                                    ),
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

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog({required this.roles});

  final List<Role> roles;

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  late String? _roleId;

  @override
  void initState() {
    super.initState();
    // Prefer a non-system role as the default.
    final preferred = widget.roles.where((r) => !r.isSystem);
    _roleId = preferred.isNotEmpty
        ? preferred.first.id
        : (widget.roles.isNotEmpty ? widget.roles.first.id : null);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _roleId == null) return;
    Navigator.pop(context, (email: _email.text.trim(), roleId: _roleId!));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add member'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (must have an account)',
                border: OutlineInputBorder(),
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _roleId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final r in widget.roles)
                  DropdownMenuItem(value: r.id, child: Text(r.name)),
              ],
              onChanged: (v) => setState(() => _roleId = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
