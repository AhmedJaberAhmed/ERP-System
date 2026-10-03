import 'package:equatable/equatable.dart';

 import '../domain/DashboardSummary.dart';

enum DashboardStatus { initial, loading, loaded, failure }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.data,
    this.errorMessage,
  });

  final DashboardStatus status;
  final DashboardData? data;
  final String? errorMessage;

  /// errorMessage is cleared on every copy unless passed again.
  DashboardState copyWith({
    DashboardStatus? status,
    DashboardData? data,
    String? errorMessage,
  }) =>
      DashboardState(
        status: status ?? this.status,
        data: data ?? this.data,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, data, errorMessage];
}