// /lib/services/address_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddressService {
  static Future<Map<String, String>> fetchAddress(String cep) async {
    final url = Uri.parse('https://viacep.com.br/ws/$cep/json/');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map;
      if (data.containsKey('erro') && data['erro'] == true) {
        return {'isValid': 'false'};
      } else {
        return {
          'isValid': 'true',
          'street': data['logradouro'] ?? '',
          'neighborhood': data['bairro'] ?? '',
          'city': data['localidade'] ?? '',
          'state': data['uf'] ?? '',
        };
      }
    } else {
      return {'isValid': 'false'};
    }
  }
}
