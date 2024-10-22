class ProjectModel {
  final String id;
  final String? name;
  final String? clientName;
  final double? value;
  final double? size;
  final String? notes;
  final String? userId;
  final String? image;

  // Construtor
  ProjectModel({
    required this.id,
    this.name,
    this.clientName,
    this.value,
    this.size,
    this.notes,
    this.userId,
    this.image,
  });

  // Método fromMap corrigido para aceitar dois parâmetros: id e map
  factory ProjectModel.fromMap(String id, Map<String, dynamic> map) {
    return ProjectModel(
      id: id,
      name: map['name'] ?? 'Sem nome', // Fallback para o campo 'name'
      clientName:
          map['clientName'] ?? 'Sem cliente', // Fallback para 'clientName'
      value: map['value']?.toDouble(), // Pode ser null
      size: map['size']?.toDouble(), // Pode ser null
      notes: map['notes'] ?? '', // Fallback para string vazia
      userId: map['userId'] ?? '', // Fallback para string vazia
      image: map['image'] ?? '', // Fallback para string vazia
    );
  }

  // Método para converter o objeto em um Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'clientName': clientName,
      'value': value,
      'size': size,
      'notes': notes,
      'userId': userId,
      'image': image,
    };
  }
}
