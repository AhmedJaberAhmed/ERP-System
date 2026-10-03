import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  const Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.taxNumber,
    this.isActive = true,
  });

  /// Empty id means "not saved yet".
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxNumber;
  final bool isActive;

  bool get isNew => id.isEmpty;

  @override
  List<Object?> get props => [id, name, phone, email, address, taxNumber, isActive];
}