import 'package:build_wise/models/cashflow_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build_wise/blocs/cashflow/cashflow_bloc.dart';
import 'package:build_wise/blocs/cashflow/cashflow_event.dart';

class CashflowItem extends StatelessWidget {
  final Cashflow cashflow;
  final String userId;
  final String projectId;
  final String role; // Receber o role
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  CashflowItem({
    required this.cashflow,
    required this.userId,
    required this.projectId,
    required this.role,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(cashflow.productName),
        subtitle: Text(cashflow.productDescription.isEmpty
            ? 'No Description'
            : cashflow.productDescription),
        trailing: role != 'Cliente' // Verificar role
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.edit), onPressed: onEdit),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      context
                          .read<CashflowBloc>()
                          .add(DeleteCashflow(userId, projectId, cashflow.id));
                      onDelete();
                    },
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
