class LinkModel {
  String id; // Remover o final para permitir alterações
  final String roomName;
  final String linkUrl;

  LinkModel({required this.id, required this.roomName, required this.linkUrl});

  // Conversão de e para o Firestore
  factory LinkModel.fromFirestore(Map<String, dynamic> data, String id) {
    return LinkModel(
      id: id,
      roomName: data['roomName'],
      linkUrl: data['linkUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomName': roomName,
      'linkUrl': linkUrl,
    };
  }
}
