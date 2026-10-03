import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/company/presentation/cubit/company_cubit.dart';
import 'features/company/presentation/cubit/company_state.dart';
import 'features/company/presentation/pages/create_company_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/permissions/presentation/cubit/permissions_cubit.dart';

/// Decides what to show: Login -> Create company -> Home.
class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  @override
  void initState() {
    super.initState();
    // App launched with an existing session.
    if (context.read<AuthCubit>().state.status == AuthStatus.authenticated) {
      context.read<CompanyCubit>().loadMyCompanies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        final companyCubit = context.read<CompanyCubit>();
        if (state.status == AuthStatus.authenticated) {
          companyCubit.loadMyCompanies();
        } else if (state.status == AuthStatus.unauthenticated) {
          companyCubit.reset();
          context.read<PermissionsCubit>().reset();
          // Close any pushed screens (members, roles...) after sign out.
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        buildWhen: (prev, curr) =>
            (prev.status == AuthStatus.authenticated) !=
            (curr.status == AuthStatus.authenticated),
        builder: (context, auth) {
          if (auth.status != AuthStatus.authenticated) return const LoginPage();
          return const _CompanyGate();
        },
      ),
    );
  }
}

class _CompanyGate extends StatelessWidget {
  const _CompanyGate();

  @override
  Widget build(BuildContext context) {
    // Whenever the active company changes, load the user's permissions for it.
    return BlocListener<CompanyCubit, CompanyState>(
      listenWhen: (prev, curr) => prev.selected?.id != curr.selected?.id,
      listener: (context, state) {
        final permissions = context.read<PermissionsCubit>();
        final selected = state.selected;
        if (selected == null) {
          permissions.reset();
        } else {
          permissions.load(selected.id);
        }
      },
      child: BlocBuilder<CompanyCubit, CompanyState>(
        builder: (context, state) {
          switch (state.status) {
            case CompanyStatus.initial:
            case CompanyStatus.loading:
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            case CompanyStatus.failure:
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.errorMessage ?? 'Could not load your company.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () =>
                              context.read<CompanyCubit>().loadMyCompanies(),
                          child: const Text('Retry'),
                        ),
                        TextButton(
                          onPressed: () => context.read<AuthCubit>().signOut(),
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            case CompanyStatus.loaded:
            case CompanyStatus.creating:
              return state.selected == null
                  ? const CreateCompanyPage()
                  : const HomePage();
          }
        },
      ),
    );
  }
}
