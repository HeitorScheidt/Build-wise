import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build_wise/blocs/cashflow/cashflow_event.dart';
import 'package:build_wise/blocs/cashflow/cashflow_state.dart';
import 'package:build_wise/services/cashflow_service.dart';
import 'package:build_wise/models/cashflow_model.dart';

class CashflowBloc extends Bloc<CashflowEvent, CashflowState> {
  final CashflowService cashflowService;

  CashflowBloc(this.cashflowService) : super(CashflowLoading()) {
    on<LoadCashflows>((event, emit) async {
      emit(CashflowLoading());
      try {
        final cashflowsStream =
            cashflowService.getCashflows(event.userId, event.projectId);
        await emit.forEach<List<Cashflow>>(cashflowsStream,
            onData: (cashflows) {
          print(
              "Cashflows loaded for userId: ${event.userId}, projectId: ${event.projectId}");
          return cashflows.isEmpty
              ? CashflowError("Pasta vazia")
              : CashflowLoaded(cashflows);
        }, onError: (_, __) {
          print("Error loading cashflows");
          return CashflowError("Failed to load cashflows");
        });
      } catch (e) {
        print("Exception: $e");
        emit(CashflowError("Failed to load cashflows: $e"));
      }
    });

    on<AddCashflow>((event, emit) async {
      try {
        print(
            "Adding cashflow for userId: ${event.userId}, projectId: ${event.projectId}");
        await cashflowService.addCashflow(
            event.userId, event.projectId, event.cashflow);
        print("Cashflow added successfully!");
        add(LoadCashflows(
            event.userId, event.projectId)); // Recarregar os dados
      } catch (e) {
        print("Error adding cashflow: $e");
        emit(CashflowError("Failed to add cashflow: $e"));
      }
    });

    on<UpdateCashflow>((event, emit) async {
      try {
        print(
            "Updating cashflow for userId: ${event.userId}, projectId: ${event.projectId}");
        await cashflowService.updateCashflow(
            event.userId, event.projectId, event.cashflow);
        print("Cashflow updated successfully!");
        add(LoadCashflows(
            event.userId, event.projectId)); // Recarregar os dados
      } catch (e) {
        print("Error updating cashflow: $e");
        emit(CashflowError("Failed to update cashflow: $e"));
      }
    });

    on<DeleteCashflow>((event, emit) async {
      try {
        print(
            "Deleting cashflow for userId: ${event.userId}, projectId: ${event.projectId}");
        await cashflowService.deleteCashflow(
            event.userId, event.projectId, event.cashflowId);
        print("Cashflow deleted successfully!");
        add(LoadCashflows(
            event.userId, event.projectId)); // Recarregar os dados
      } catch (e) {
        print("Error deleting cashflow: $e");
        emit(CashflowError("Failed to delete cashflow: $e"));
      }
    });
  }
}
