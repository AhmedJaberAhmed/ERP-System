import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/permission_labels.dart';
import '../../../../core/utils/validators.dart';
import '../../../permissions/domain/entities/permission.dart';
import '../../domain/entities/role.dart';
import '../cubit/roles_cubit.dart';
import '../cubit/roles_state.dart';

/// Create (role == null) or edit a role and its permissions.
class RoleFormPage extends StatefulWidget {
  const RoleFormPage({super.key, this.role});

  final Role? role;

  @override
  State<RoleFormPage> createState() => _RoleFormPageState();
}

class _RoleFormPageState extends State<RoleFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final Set<String> _selected;

  bool get _readOnly => widget.role?.isSystem ?? false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.role?.name);
    _selected = <String>{...?widget.role?.permissionKeys};
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Map<String, List<Permission>> _group(List<Permission> all) {
    final map = <String, List<Permission>>{};
    for (final p in all) {
      map.putIfAbsent(permissionGroup(p.key), () => []).add(p);
    }
    return map;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<RolesCubit>().saveRole(
          existing: widget.role,
          name: _name.text.trim(),
          permissionKeys: _selected,
        );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<RolesCubit>().state.allPermissions;
    final groups = _group(all);

    return BlocListener<RolesCubit, RolesState>(
      listenWhen: (p, c) => c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.role == null ? 'New role' : widget.role!.name),
          actions: [
            if (!_readOnly) ...[
              TextButton(
                onPressed: () =>
                    setState(() => _selected.addAll(all.map((p) => p.key))),
                child: const Text('All'),
              ),
              TextButton(
                onPressed: () => setState(_selected.clear),
                child: const Text('None'),
              ),
            ],
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_readOnly)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('System roles cannot be edited.'),
                ),
              TextFormField(
                controller: _name,
                enabled: !_readOnly,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Role name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => Validators.requiredField(v, label: 'Role name'),
              ),
              const SizedBox(height: 16),
              for (final entry in groups.entries)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Text(titleCase(entry.key)),
                    subtitle: Text(
                      '${entry.value.where((p) => _selected.contains(p.key)).length}'
                      ' / ${entry.value.length}',
                    ),
                    children: [
                      for (final p in entry.value)
                        CheckboxListTile(
                          value: _selected.contains(p.key),
                          title: Text(titleCase(permissionAction(p.key))),
                          subtitle: p.description == null ? null : Text(p.description!),
                          onChanged: _readOnly
                              ? null
                              : (v) => setState(() {
                                    if (v == true) {
                                      _selected.add(p.key);
                                    } else {
                                      _selected.remove(p.key);
                                    }
                                  }),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 72),
            ],
          ),
        ),
        bottomNavigationBar: _readOnly
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: BlocBuilder<RolesCubit, RolesState>(
                    buildWhen: (p, c) => p.isBusy != c.isBusy,
                    builder: (context, state) => FilledButton(
                      onPressed: state.isBusy ? null : _save,
                      child: state.isBusy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save role'),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
