import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:build_wise/views/pages/bottomnav.dart';

class ConfirmEmailPage extends StatefulWidget {
  final User user;

  ConfirmEmailPage({required this.user});

  @override
  _ConfirmEmailPageState createState() => _ConfirmEmailPageState();
}

class _ConfirmEmailPageState extends State<ConfirmEmailPage> {
  bool isVerified = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // Verificar email no início
    checkEmailVerified();
    // Iniciar a verificação periódica do email a cada 3 segundos
    timer =
        Timer.periodic(const Duration(seconds: 3), (_) => checkEmailVerified());
  }

  @override
  void dispose() {
    timer?.cancel(); // Cancela o timer quando a página é destruída
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload(); // Atualiza o status do usuário
      if (user.emailVerified) {
        setState(() {
          isVerified = true;
        });
        timer?.cancel(); // Cancela o timer se o email foi verificado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email verificado com sucesso!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Aguarda 1 segundo para exibir a mensagem de sucesso
        await Future.delayed(const Duration(seconds: 1));
        // Redireciona para a página principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Bottomnav()),
        );
      }
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await widget.user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email de verificação reenviado.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao reenviar o email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirme seu Email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Por favor, verifique o email enviado para ${widget.user.email}.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (!isVerified)
              ElevatedButton(
                onPressed: resendVerificationEmail,
                child: const Text('Reenviar Email de Verificação'),
              ),
          ],
        ),
      ),
    );
  }
}
