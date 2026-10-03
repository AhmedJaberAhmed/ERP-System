import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/company.dart';
import '../../domain/repositories/company_repository.dart';
import 'company_state.dart';

/// ViewModel for the user's companies and the active company.
class CompanyCubit extends Cubit<CompanyState> {
  CompanyCubit(this._repository) : super(const CompanyState());

  final CompanyRepository _repository;

  Future<void> loadMyCompanies() async {
    emit(const CompanyState(status: CompanyStatus.loading));
    try {
      final companies = await _repository.getMyCompanies();
      emit(CompanyState(
        status: CompanyStatus.loaded,
        companies: companies,
        selected: _resolveSelected(companies),
      ));
    } on Failure catch (e) {
      emit(CompanyState(status: CompanyStatus.failure, errorMessage: e.message));
    }
  }

  Future<void> createCompany({
    required String name,
    required String currency,
  }) async {
    emit(CompanyState(
      status: CompanyStatus.creating,
      companies: state.companies,
      selected: state.selected,
    ));
    try {
      final id = await _repository.createCompany(name: name, currency: currency);
      final companies = await _repository.getMyCompanies();
      emit(CompanyState(
        status: CompanyStatus.loaded,
        companies: companies,
        selected: _resolveSelected(companies, preferId: id),
      ));
    } on Failure catch (e) {
      emit(CompanyState(
        status: CompanyStatus.loaded,
        companies: state.companies,
        selected: state.selected,
        errorMessage: e.message,
      ));
    }
  }

  void selectCompany(Company company) {
    emit(CompanyState(
      status: CompanyStatus.loaded,
      companies: state.companies,
      selected: company,
    ));
  }

  /// Call on sign out so the next user starts clean.
  void reset() => emit(const CompanyState());

  Company? _resolveSelected(List<Company> companies, {String? preferId}) {
    if (companies.isEmpty) return null;
    final id = preferId ?? state.selected?.id;
    for (final company in companies) {
      if (company.id == id) return company;
    }
    return companies.first;
  }
}
