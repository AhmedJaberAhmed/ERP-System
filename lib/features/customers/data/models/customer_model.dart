import '../../domain/entities/customer.dart';

class CustomerModel {
  CustomerModel._();

  static Customer fromJson(Map<String, dynamic> j) => Customer(
        id: j['id'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        address: j['address'] as String?,
        taxNumber: j['tax_number'] as String?,
        creditLimit: j['credit_limit'] == null
            ? 0
            : (j['credit_limit'] as num).toDouble(),
        isActive: (j['is_active'] as bool?) ?? true,
      );

  static Map<String, dynamic> toJson(Customer c) => {
        'name': c.name,
        'phone': c.phone,
        'email': c.email,
        'address': c.address,
        'tax_number': c.taxNumber,
        'credit_limit': c.creditLimit,
        'is_active': c.isActive,
      };
}
