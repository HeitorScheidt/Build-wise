import 'package:build_wise/blocs/cashflow/cashflow_bloc.dart';
import 'package:build_wise/blocs/cashflow/cashflow_event.dart';
import 'package:build_wise/models/cashflow_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashflowItem extends StatelessWidget {
  final Cashflow cashflow;
  final String userId; // Adicionando o userId
  final String projectId; // Adicionando o projectId
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CashflowItem({
    Key? key,
    required this.cashflow,
    required this.userId, // Recebendo o userId
    required this.projectId, // Recebendo o projectId
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        title: Text(cashflow.productName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('R\$ ${cashflow.productValue.toStringAsFixed(2)}'),
            Text(cashflow.productDescription.isNotEmpty
                ? cashflow.productDescription
                : 'No Description'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: onEdit, // Chamando o callback de edição
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                // Chamando o evento de exclusão com userId, projectId e cashflow.id corretos
                context.read<CashflowBloc>().add(
                      DeleteCashflow(userId, projectId, cashflow.id),
                    );
                onDelete(); // Opcionalmente, você pode chamar um callback após a exclusão
              },
            ),
          ],
        ),
      ),
    );
  }
}
