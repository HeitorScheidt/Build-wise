import 'package:build_wise/blocs/cashflow/cashflow_bloc.dart';
import 'package:build_wise/blocs/cashflow/cashflow_event.dart';
import 'package:build_wise/blocs/cashflow/cashflow_state.dart';
import 'package:build_wise/models/cashflow_model.dart';
import 'package:build_wise/utils/colors.dart';
import 'package:build_wise/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashflowPage extends StatelessWidget {
  final String userId;
  final String projectId;

  CashflowPage({required this.userId, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cashflow', style: appWidget.headerLineTextFieldStyle()),
      ),
      body: BlocBuilder<CashflowBloc, CashflowState>(
        builder: (context, state) {
          if (state is CashflowLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is CashflowLoaded) {
            final cashflows = state.cashflows;
            return ListView.builder(
              itemCount: cashflows.length,
              itemBuilder: (context, index) {
                final cashflow = cashflows[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  padding: EdgeInsets.all(12.0), // Diminui o padding
                  decoration: BoxDecoration(
                    color: AppColors.secondaryColor, // Tom mais claro de azul
                    borderRadius:
                        BorderRadius.circular(10.0), // Diminuindo a borda
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.4), // Mais elevado
                        spreadRadius: 2,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cashflow.productName,
                            style: appWidget
                                .boldLineTextFieldStyle(), // Nome do produto
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            'R\$ ${cashflow.productValue.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppColors.primaryColor.withOpacity(0.8),
                              fontSize: 18.0, // Menor que o nome
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            cashflow.productDescription,
                            style: TextStyle(
                              color: AppColors.primaryColor.withOpacity(0.6),
                              fontSize: 16.0, // Menor ainda que o valor
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit,
                                  color: AppColors.primaryColor),
                              onPressed: () {
                                _showEditCashflowDialog(
                                    context, userId, projectId, cashflow);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete,
                                  color: AppColors.primaryColor),
                              onPressed: () {
                                context.read<CashflowBloc>().add(DeleteCashflow(
                                    userId, projectId, cashflow.id));
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          } else if (state is CashflowError) {
            return Center(child: Text(state.message));
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCashflowDialog(context, userId, projectId);
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: AppColors.primaryColor,
        shape: CircleBorder(), // Tornando o botão 100% arredondado
      ),
    );
  }

  void _showAddCashflowDialog(
      BuildContext context, String userId, String projectId) {
    final _productNameController = TextEditingController();
    final _productValueController = TextEditingController();
    final _productDescriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Cashflow Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _productNameController,
                decoration: InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: _productValueController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Product Value'),
              ),
              TextField(
                controller: _productDescriptionController,
                decoration: InputDecoration(labelText: 'Product Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final productName = _productNameController.text;
                final productValue =
                    double.tryParse(_productValueController.text) ?? 0.0;
                final productDescription = _productDescriptionController.text;

                if (productName.isNotEmpty && productDescription.isNotEmpty) {
                  context.read<CashflowBloc>().add(
                        AddCashflow(
                          userId,
                          projectId,
                          Cashflow(
                            id: DateTime.now().toString(),
                            productName: productName,
                            productValue: productValue,
                            productDescription: productDescription,
                          ),
                        ),
                      );
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCashflowDialog(BuildContext context, String userId,
      String projectId, Cashflow cashflow) {
    final _productNameController =
        TextEditingController(text: cashflow.productName);
    final _productValueController =
        TextEditingController(text: cashflow.productValue.toString());
    final _productDescriptionController =
        TextEditingController(text: cashflow.productDescription);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Cashflow Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _productNameController,
                decoration: InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: _productValueController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Product Value'),
              ),
              TextField(
                controller: _productDescriptionController,
                decoration: InputDecoration(labelText: 'Product Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final productName = _productNameController.text;
                final productValue =
                    double.tryParse(_productValueController.text) ?? 0.0;
                final productDescription = _productDescriptionController.text;

                if (productName.isNotEmpty && productDescription.isNotEmpty) {
                  context.read<CashflowBloc>().add(
                        UpdateCashflow(
                          userId,
                          projectId,
                          Cashflow(
                            id: cashflow.id,
                            productName: productName,
                            productValue: productValue,
                            productDescription: productDescription,
                          ),
                        ),
                      );
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
