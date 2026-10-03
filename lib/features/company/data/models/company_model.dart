import '../../domain/entities/company.dart';

class CompanyModel extends Company {
  const CompanyModel({
    required super.id,
    required super.name,
    required super.currency,
    super.roleName,
  });

  /// Row shape from:
  /// company_members.select('roles(name), companies(id, name, currency)')
  factory CompanyModel.fromMemberRow(Map<String, dynamic> row) {
    final company = row['companies'] as Map<String, dynamic>;
    final role = row['roles'] as Map<String, dynamic>?;
    return CompanyModel(
      id: company['id'] as String,
      name: company['name'] as String,
      currency: (company['currency'] as String).trim(),
      roleName: role?['name'] as String?,
    );
  }
}
