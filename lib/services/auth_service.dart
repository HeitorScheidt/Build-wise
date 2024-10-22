import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Função para validar o formato do email
  bool _isEmailValid(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // Função para verificar se a senha é forte (mínimo de 8 caracteres, letra maiúscula, minúscula e caractere especial)
  bool _isPasswordStrong(String password) {
    final passwordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  // Cadastro com email e senha com verificação e envio de email de confirmação
  Future<User?> signUpWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      if (!_isEmailValid(email)) {
        throw Exception('O email fornecido é inválido.');
      }

      if (!_isPasswordStrong(password)) {
        throw Exception(
            'A senha fornecida é fraca. Utilize ao menos 8 caracteres, uma letra maiúscula, uma minúscula e um caractere especial.');
      }

      // Verificando no Firestore se o email já existe
      var emailCheck = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (emailCheck.docs.isNotEmpty) {
        throw Exception('Este email já está cadastrado no Firestore.');
      }

      // Criando o usuário com email e senha
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      await user?.updateDisplayName(
          name); // Definindo o nome do usuário no FirebaseAuth

      // Armazenando os dados do usuário no Firestore
      await _firestore.collection('users').doc(user?.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Enviar email de verificação
      await user?.sendEmailVerification();

      return user;
    } catch (e) {
      print('Erro ao criar conta: $e');
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        throw Exception(
            'Este email já está cadastrado no Firebase Authentication.');
      }
      throw Exception(e.toString());
    }
  }

  // Função para confirmar a verificação de email
  Future<bool> isEmailVerified(User user) async {
    await user.reload();
    return user.emailVerified;
  }

  // Função para login
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        if (!await isEmailVerified(user)) {
          throw Exception('Verifique seu e-mail antes de fazer login.');
        }
        return user;
      } else {
        throw Exception('Usuário não encontrado.');
      }
    } catch (e) {
      print('Erro ao fazer login: $e');
      throw Exception('Erro ao fazer login. Verifique suas credenciais.');
    }
  }

  // Função para logout
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Método para obter o nome do usuário atual
  Future<String?> getUserName(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc['name']; // Obtendo o nome do Firestore
    }
    return null;
  }
}
