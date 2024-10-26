class UserModel {
  final String id;
  final String email;
  final String name;
  final String lastName;
  final String cep;
  final String role;
  final String architectId;
  final String? address;
  final String? bairro;
  final String? logradouro;
  final String? cidade;
  final String? numero;
  final List<String> projectIds;
  final String? password; // Campo opcional para uso temporário na criação
  final bool emailVerified;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.lastName,
    required this.cep,
    required this.role,
    required this.architectId,
    this.address,
    this.bairro,
    this.logradouro,
    this.cidade,
    this.numero,
    this.projectIds = const [],
    this.password, // Inicializado como opcional
    this.emailVerified = false,
  });

  // Converte o modelo em um mapa para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'lastName': lastName,
      'cep': cep,
      'role': role,
      'architectId': architectId,
      'address': address,
      'bairro': bairro,
      'logradouro': logradouro,
      'cidade': cidade,
      'numero': numero,
      'projects': projectIds,
      'emailVerified': emailVerified,
    };
  }

  // Converte um mapa do Firestore para o modelo UserModel
  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      lastName: map['lastName'] ?? '',
      cep: map['cep'] ?? '',
      role: map['role'] ?? 'Cliente',
      architectId: map['architectId'] ?? '',
      address: map['address'],
      bairro: map['bairro'],
      logradouro: map['logradouro'],
      cidade: map['cidade'],
      numero: map['numero'],
      projectIds: List<String>.from(map['projects'] ?? []),
    );
  }
}
