import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build_wise/blocs/cashflow/cashflow_bloc.dart';
import 'package:build_wise/blocs/cashflow/cashflow_event.dart';
import 'package:build_wise/blocs/cashflow/cashflow_state.dart';
import 'package:build_wise/models/cashflow_model.dart';
import 'package:build_wise/services/user_service.dart';
import 'package:build_wise/utils/colors.dart';
import 'package:build_wise/utils/styles.dart';
import 'package:flutter/material.dart';

class CashflowPage extends StatefulWidget {
  final String projectId;
  final String userId;

  CashflowPage({required this.projectId, required this.userId});

  @override
  _CashflowPageState createState() => _CashflowPageState();
}

class _CashflowPageState extends State<CashflowPage> {
  String? role;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final userRole = await UserService().getUserRole();
    setState(() {
      role = userRole;
    });
    context
        .read<CashflowBloc>()
        .add(LoadCashflows(widget.userId, widget.projectId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Cashflow', style: appWidget.headerLineTextFieldStyle()),
      ),
      body: role == null
          ? Center(child: CircularProgressIndicator())
          : BlocBuilder<CashflowBloc, CashflowState>(
              builder: (context, state) {
                if (state is CashflowLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is CashflowLoaded) {
                  final cashflows = state.cashflows;
                  if (cashflows.isEmpty) {
                    return Center(child: Text('Pasta vazia'));
                  }
                  return ListView.builder(
                    itemCount: cashflows.length,
                    itemBuilder: (context, index) {
                      final cashflow = cashflows[index];
                      return Container(
                        margin: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        padding: EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.4),
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
                                  style: appWidget.boldLineTextFieldStyle(),
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  'R\$ ${cashflow.productValue.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color:
                                        AppColors.primaryColor.withOpacity(0.8),
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  cashflow.productDescription,
                                  style: TextStyle(
                                    color:
                                        AppColors.primaryColor.withOpacity(0.6),
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            if (role != 'Cliente')
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
                                            context,
                                            widget.userId,
                                            widget.projectId,
                                            cashflow);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          color: AppColors.primaryColor),
                                      onPressed: () {
                                        context.read<CashflowBloc>().add(
                                            DeleteCashflow(widget.userId,
                                                widget.projectId, cashflow.id));
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
      floatingActionButton: role != 'Cliente'
          ? FloatingActionButton(
              onPressed: () {
                _showAddCashflowDialog(
                    context, widget.userId, widget.projectId);
              },
              child: Icon(Icons.add, color: Colors.white),
              backgroundColor: AppColors.primaryColor,
              shape: CircleBorder(),
            )
          : null,
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
