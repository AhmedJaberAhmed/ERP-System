import '../entities/customer.dart';

abstract class CustomerRepository {
  /// Matches name, phone or email (case-insensitive, partial).
  Future<List<Customer>> search(String companyId, {String query = ''});

  /// Inserts when [customer].isNew, otherwise updates.
  Future<void> save(String companyId, Customer customer);

  Future<void> delete(String customerId);
}
