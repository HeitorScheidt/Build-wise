import 'package:build_wise/models/cashflow_model.dart';

abstract class CashflowEvent {}

class LoadCashflows extends CashflowEvent {
  final String userId;
  final String projectId;

  LoadCashflows(this.userId, this.projectId);
}

class AddCashflow extends CashflowEvent {
  final String userId;
  final String projectId;
  final Cashflow cashflow;

  AddCashflow(this.userId, this.projectId, this.cashflow);
}

class UpdateCashflow extends CashflowEvent {
  final String userId;
  final String projectId;
  final Cashflow cashflow;

  UpdateCashflow(this.userId, this.projectId, this.cashflow);
}

class DeleteCashflow extends CashflowEvent {
  final String userId;
  final String projectId;
  final String cashflowId;

  DeleteCashflow(this.userId, this.projectId, this.cashflowId);
}
