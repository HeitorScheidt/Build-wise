import 'package:equatable/equatable.dart';

abstract class AddMemberEvent extends Equatable {
  const AddMemberEvent();

  @override
  List<Object?> get props => [];
}

// Evento para verificar o CEP
class CheckCEP extends AddMemberEvent {
  final String cep;

  CheckCEP(this.cep);

  @override
  List<Object?> get props => [cep];
}

// Evento para submeter os dados de criação de membro
class AddMemberSubmit extends AddMemberEvent {
  final String email;
  final String password;
  final String name;
  final String lastName;
  final String cep;
  final bool isClient;
  final List<String>?
      projectIds; // Alterado para aceitar uma lista de IDs de projetos
  final String userId;
  final String architectId;
  final String role; // Novo campo role
  // Novos parâmetros de endereço
  final String? address;
  final String? bairro;
  final String? logradouro;
  final String? cidade;
  final String? numero;

  AddMemberSubmit({
    required this.email,
    required this.password,
    required this.name,
    required this.lastName,
    required this.cep,
    required this.isClient,
    this.projectIds, // Aceita múltiplos projetos
    required this.userId,
    this.address, // Adicionando os parâmetros de endereço
    this.bairro,
    this.logradouro,
    this.cidade,
    this.numero,
    required this.architectId,
    required this.role, // Exige o campo role ao criar um membro
  });

  @override
  List<Object?> get props => [
        email,
        password,
        name,
        lastName,
        cep,
        isClient,
        projectIds,
        userId,
        address,
        bairro,
        logradouro,
        cidade,
        architectId,
        role, // Adiciona role aos props para comparação
        numero,
      ];
}
