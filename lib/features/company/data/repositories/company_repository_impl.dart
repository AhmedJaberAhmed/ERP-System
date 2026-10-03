import '../../domain/entities/company.dart';
import '../../domain/repositories/company_repository.dart';
import '../datasources/company_remote_data_source.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  CompanyRepositoryImpl(this._remote);

  final CompanyRemoteDataSource _remote;

  @override
  Future<List<Company>> getMyCompanies() => _remote.fetchMyCompanies();

  @override
  Future<String> createCompany({required String name, String currency = 'EGP'}) =>
      _remote.createCompany(name: name, currency: currency);
}
