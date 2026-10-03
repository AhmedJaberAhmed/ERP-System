import 'package:equatable/equatable.dart';

class Permission extends Equatable {
  const Permission({required this.key, this.description});

  final String key;
  final String? description;

  @override
  List<Object?> get props => [key, description];
}
