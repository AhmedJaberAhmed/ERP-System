import 'package:equatable/equatable.dart';

import '../../domain/entities/company.dart';

enum CompanyStatus { initial, loading, loaded, creating, failure }

class CompanyState extends Equatable {
  const CompanyState({
    this.status = CompanyStatus.initial,
    this.companies = const [],
    this.selected,
    this.errorMessage,
  });

  final CompanyStatus status;
  final List<Company> companies;
  final Company? selected;
  final String? errorMessage;

  bool get isCreating => status == CompanyStatus.creating;

  @override
  List<Object?> get props => [status, companies, selected, errorMessage];
}
