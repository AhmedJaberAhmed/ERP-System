import '../entities/company.dart';

abstract class CompanyRepository {
  /// Companies the signed-in user is an active member of.
  Future<List<Company>> getMyCompanies();

  /// Calls the `create_company` RPC and returns the new company id.
  Future<String> createCompany({required String name, String currency = 'EGP'});
}
