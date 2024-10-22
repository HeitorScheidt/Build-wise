/*import 'package:build_wise/blocs/project/project_bloc.dart';
import 'package:build_wise/blocs/project/project_event.dart';
import 'package:build_wise/models/project_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AddProjectDialog extends StatelessWidget {
  final String userId;
  const AddProjectDialog({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController clientNameController = TextEditingController();
    TextEditingController valueController = TextEditingController();
    TextEditingController sizeController = TextEditingController();
    TextEditingController notesController = TextEditingController();

    return AlertDialog(
      title: const Text("Adicionar Projeto"),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: "Nome do Projeto"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: clientNameController,
              decoration: const InputDecoration(hintText: "Nome do Cliente"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(hintText: "Valor do Projeto"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: sizeController,
              decoration: const InputDecoration(hintText: "Metragem Quadrada"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(hintText: "Observações"),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text("Cancelar"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text("Adicionar"),
          onPressed: () {
            if (nameController.text.isNotEmpty &&
                clientNameController.text.isNotEmpty) {
              ProjectModel newProject = ProjectModel(
                id: '', // O Firestore vai gerar esse ID
                name: nameController.text,
                clientName: clientNameController.text,
                value: double.tryParse(valueController.text),
                size: double.tryParse(sizeController.text),
                notes: notesController.text,
                userId: userId,
              );

              // Dispara o evento de criação de projeto
              context.read<ProjectBloc>().add(
                  CreateProjectEvent(projectData: newProject, userId: userId));
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final value = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (value.isNotEmpty) {
      final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
      final newText = formatter.format(double.parse(value) / 100);
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
    return newValue;
  }
}

class MeterInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final value = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (value.isNotEmpty) {
      final double meters = double.parse(value);
      final newText = "${meters.toStringAsFixed(2)} m²";
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
    return newValue;
  }
}
*/