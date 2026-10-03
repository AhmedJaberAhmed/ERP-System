import 'package:equatable/equatable.dart';

class Company extends Equatable {
  const Company({
    required this.id,
    required this.name,
    required this.currency,
    this.roleName,
  });

  final String id;
  final String name;
  final String currency;

  /// The current user's role in this company (e.g. Owner).
  final String? roleName;

  @override
  List<Object?> get props => [id, name, currency, roleName];
}
