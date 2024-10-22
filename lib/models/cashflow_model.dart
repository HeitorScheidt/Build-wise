class Cashflow {
  final String id;
  final String productName;
  final double productValue;
  final String productDescription;

  Cashflow({
    required this.id,
    required this.productName,
    required this.productValue,
    required this.productDescription,
  });

  // Métodos toMap e fromMap para serialização com Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productName': productName,
      'productValue': productValue,
      'productDescription': productDescription,
    };
  }

  static Cashflow fromMap(Map<String, dynamic> map, String id) {
    return Cashflow(
      id: id,
      productName: map['productName'],
      productValue: map['productValue'],
      productDescription: map['productDescription'],
    );
  }
}
