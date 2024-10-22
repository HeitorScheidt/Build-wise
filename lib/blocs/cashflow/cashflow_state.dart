import 'package:build_wise/models/cashflow_model.dart';

abstract class CashflowState {}

class CashflowLoading extends CashflowState {}

class CashflowLoaded extends CashflowState {
  final List<Cashflow> cashflows;
  CashflowLoaded(this.cashflows);
}

class CashflowError extends CashflowState {
  final String message;
  CashflowError(this.message);
}
