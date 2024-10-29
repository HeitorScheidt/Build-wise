import 'package:build_wise/utils/colors.dart';
import 'package:flutter/material.dart';

class appWidget {
  static TextStyle boldLineTextFieldStyle() {
    return const TextStyle(
        color: AppColors.primaryColor,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        fontFamily: "Poppins");
  }

  static TextStyle normalTextFieldStyle() {
    return const TextStyle(
      fontSize: 16, // Tamanho padrão
      color: AppColors.primaryColor, // Cor do texto
      fontWeight: FontWeight.normal, // Peso do texto
    );
  }

  static TextStyle headerLineTextFieldStyle() {
    return const TextStyle(
        color: AppColors.primaryColor,
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
        fontFamily: "Poppins");
  }

  static TextStyle lightTextFieldStyle() {
    return const TextStyle(
        color: Colors.black38,
        fontSize: 15.0,
        fontWeight: FontWeight.w500,
        fontFamily: "Poppins");
  }

  static TextStyle semiBooldTextFieldStyle() {
    return const TextStyle(
        color: AppColors.primaryColor,
        fontSize: 18.0,
        fontWeight: FontWeight.w500,
        fontFamily: "Poppins");
  }

  static TextStyle projectTextFieldStyle() {
    return const TextStyle(
        color: AppColors.primaryColor,
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
        fontFamily: "Poppins");
  }
}
