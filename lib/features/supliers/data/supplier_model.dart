 import '../domain/supplier.dart';

class SupplierModel {
  SupplierModel._();

  static Supplier fromJson(Map<String, dynamic> j) => Supplier(
    id: j['id'] as String,
    name: j['name'] as String,
    phone: j['phone'] as String?,
    email: j['email'] as String?,
    address: j['address'] as String?,
    taxNumber: j['tax_number'] as String?,
    isActive: (j['is_active'] as bool?) ?? true,
  );

  static Map<String, dynamic> toJson(Supplier s) => {
    'name': s.name,
    'phone': s.phone,
    'email': s.email,
    'address': s.address,
    'tax_number': s.taxNumber,
    'is_active': s.isActive,
  };
}