import 'package:equatable/equatable.dart';

class Warehouse extends Equatable {
  const Warehouse({
    required this.id,
    required this.name,
    this.address,
    this.isDefault = false,
    this.isActive = true,
  });

  /// Empty id means "not saved yet".
  final String id;
  final String name;
  final String? address;
  final bool isDefault;
  final bool isActive;

  bool get isNew => id.isEmpty;

  @override
  List<Object?> get props => [id, name, address, isDefault, isActive];
}
