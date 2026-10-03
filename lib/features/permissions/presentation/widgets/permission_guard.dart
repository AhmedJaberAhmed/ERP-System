import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/permissions_cubit.dart';

extension PermissionContext on BuildContext {
  /// Rebuilds the calling widget when this permission changes.
  /// Use inside build(): `if (context.can(PermissionKeys.productsRead)) ...`
  bool can(String permission) => select<PermissionsCubit, bool>(
        (cubit) => cubit.state.can(permission),
      );
}

/// Shows [child] only if the user has [permission], otherwise [fallback].
class PermissionGuard extends StatelessWidget {
  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  final String permission;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context) =>
      context.can(permission) ? child : fallback;
}
