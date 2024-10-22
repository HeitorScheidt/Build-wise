import 'package:equatable/equatable.dart';

class AddMemberState extends Equatable {
  final bool isLoading;
  final bool cepValid;
  final String? address;
  final String? bairro;
  final String? logradouro;
  final String? cidade;
  final String? numero;
  final String? errorMessage;
  final bool isSuccess; // Adicionando o campo isSuccess

  const AddMemberState({
    this.isLoading = false,
    this.cepValid = false,
    this.address,
    this.bairro,
    this.logradouro,
    this.cidade,
    this.numero,
    this.errorMessage,
    this.isSuccess = false, // Inicializando como falso
  });

  AddMemberState copyWith({
    bool? isLoading,
    bool? cepValid,
    String? address,
    String? bairro,
    String? logradouro,
    String? cidade,
    String? numero,
    String? errorMessage,
    bool? isSuccess, // Adicionando o campo isSuccess ao copyWith
  }) {
    return AddMemberState(
      isLoading: isLoading ?? this.isLoading,
      cepValid: cepValid ?? this.cepValid,
      address: address ?? this.address,
      bairro: bairro ?? this.bairro,
      logradouro: logradouro ?? this.logradouro,
      cidade: cidade ?? this.cidade,
      numero: numero ?? this.numero,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess, // Usando copyWith para isSuccess
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        cepValid,
        address,
        bairro,
        logradouro,
        cidade,
        numero,
        errorMessage,
        isSuccess, // Adicionando isSuccess ao props
      ];
}
