class ProjectModel {
  final String id;
  final String? architectId;
  final String? name;
  final String? clientName;
  final double? value;
  final double? size;
  final String? notes;
  final String? userId;
  final String? headerImageUrl; // Substituído de "image" para "headerImageUrl"
  final List<String>? employees; // Novo campo
  final List<String>? clients; // Novo campo

  // Construtor
  ProjectModel({
    required this.id,
    this.architectId,
    this.name,
    this.clientName,
    this.value,
    this.size,
    this.notes,
    this.userId,
    this.headerImageUrl, // Atualizado para "headerImageUrl"
    this.employees,
    this.clients,
  });

  // Método fromMap corrigido para aceitar dois parâmetros: id e map
  factory ProjectModel.fromMap(String id, Map<String, dynamic> map) {
    return ProjectModel(
      id: id,
      architectId: map['architectId'],
      name: map['name'] ?? 'Sem nome',
      clientName: map['clientName'] ?? 'Sem cliente',
      value: map['value']?.toDouble(),
      size: map['size']?.toDouble(),
      notes: map['notes'] ?? '',
      userId: map['userId'] ?? '',
      headerImageUrl:
          map['headerImageUrl'] ?? '', // Atualizado para "headerImageUrl"
      employees:
          map['employees'] != null ? List<String>.from(map['employees']) : [],
      clients: map['clients'] != null ? List<String>.from(map['clients']) : [],
    );
  }

  // Método para converter o objeto em um Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'architectId': architectId,
      'name': name,
      'clientName': clientName,
      'value': value,
      'size': size,
      'notes': notes,
      'userId': userId,
      'headerImageUrl': headerImageUrl, // Atualizado para "headerImageUrl"
      'employees': employees ?? [],
      'clients': clients ?? [],
    };
  }

  // Método copyWith para criar uma cópia do objeto com alterações específicas
  ProjectModel copyWith({
    String? id,
    String? architectId,
    String? name,
    String? clientName,
    double? value,
    double? size,
    String? notes,
    String? userId,
    String? headerImageUrl, // Atualizado para "headerImageUrl"
    List<String>? employees,
    List<String>? clients,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      architectId: architectId ?? this.architectId,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      value: value ?? this.value,
      size: size ?? this.size,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      headerImageUrl: headerImageUrl ??
          this.headerImageUrl, // Atualizado para "headerImageUrl"
      employees: employees ?? this.employees,
      clients: clients ?? this.clients,
    );
  }
}
