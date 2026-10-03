import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.taxNumber,
    this.creditLimit = 0,
    this.isActive = true,
  });

  /// Empty id means "not saved yet".
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxNumber;
  final double creditLimit;
  final bool isActive;

  bool get isNew => id.isEmpty;

  @override
  List<Object?> get props =>
      [id, name, phone, email, address, taxNumber, creditLimit, isActive];
}
