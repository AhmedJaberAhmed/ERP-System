import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_data_source.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl(this._remote);

  final CustomerRemoteDataSource _remote;

  @override
  Future<List<Customer>> search(String companyId, {String query = ''}) =>
      _remote.search(companyId, query);

  @override
  Future<void> save(String companyId, Customer customer) =>
      _remote.save(companyId, customer);

  @override
  Future<void> delete(String customerId) => _remote.delete(customerId);
}
