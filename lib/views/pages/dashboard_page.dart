import 'package:firebase_auth/firebase_auth.dart';
import 'package:build_wise/services/auth_service.dart'; // Supondo que você tenha um serviço de autenticação para outras funcionalidades
import 'package:build_wise/utils/colors.dart';
import 'package:build_wise/utils/helpers.dart';
import 'package:build_wise/utils/styles.dart';
import 'package:build_wise/views/pages/details.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService(); // Instância do AuthService
  User? currentUser; // Armazena o usuário atual
  bool projeto = false,
      tarefas = false,
      cronograma = false,
      materiais = false; // Variáveis de estado

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    // Obtendo o usuário atual diretamente do FirebaseAuth
    setState(() {
      currentUser = FirebaseAuth.instance.currentUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<String?>(
        future: _authService
            .getUserName(currentUser?.uid ?? ''), // Pegando o nome do usuário
        builder: (context, snapshot) {
          String userName = snapshot.data ?? 'Usuário Anônimo';

          String greetingMessage = AppHelpers.getGreetingMessage(userName);
          return Container(
            margin: const EdgeInsets.only(top: 40.0, left: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(greetingMessage,
                        style: appWidget.boldLineTextFieldStyle()),
                  ],
                ),
                const SizedBox(height: 12.0),
                Text("Dashboard,", style: appWidget.headerLineTextFieldStyle()),
                Text("Gerencie Seus Projetos Rapidamente,",
                    style: appWidget.lightTextFieldStyle()),
                const SizedBox(height: 20.0),
                Container(
                  margin: const EdgeInsets.only(right: 16.0),
                  child: showItem(),
                ),
                const SizedBox(height: 24.0),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Details()));
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          child: Material(
                            elevation: 5.0,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              color: Colors.white, // Definindo o fundo branco
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.asset(
                                      "assets/images/project_default_header.jpg",
                                      height: 200,
                                      width: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Text("Casa bell",
                                      style:
                                          appWidget.semiBooldTextFieldStyle()),
                                  Text("uma casa confortavel",
                                      style: appWidget.lightTextFieldStyle()),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Container(
                        margin: const EdgeInsets.all(4),
                        child: Material(
                          elevation: 5.0,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            color: Colors.white, // Definindo o fundo branco
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    "assets/images/project_default_header.jpg",
                                    height: 200,
                                    width: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Text("Room Nicole",
                                    style: appWidget.semiBooldTextFieldStyle()),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text("um Quarto Delicado",
                                    style: appWidget.lightTextFieldStyle()),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.only(right: 20.0),
                  child: Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      color: Colors.white, // Definindo o fundo branco
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipOval(
                            child: Image.asset(
                              "assets/images/teste.jpg",
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  width: MediaQuery.of(context).size.width / 2,
                                  child: Text("Simone Aparecida",
                                      style:
                                          appWidget.semiBooldTextFieldStyle())),
                              const SizedBox(height: 5.0),
                              Container(
                                width: MediaQuery.of(context).size.width / 2,
                                child: Text("Ajuste do telhado do projeto 3",
                                    style: appWidget.lightTextFieldStyle()),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget showItem() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              projeto = true;
              tarefas = false;
              cronograma = false;
              materiais = false;
            });
          },
          child: Material(
            elevation: 5.0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                  color: projeto
                      ? AppColors.primaryColor
                      : Colors.white, // Definindo o fundo branco
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                "assets/images/predio-comercial.png",
                height: 40,
                width: 40,
                fit: BoxFit.cover,
                color: projeto ? Colors.white : AppColors.primaryColor,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              projeto = false;
              tarefas = true;
              cronograma = false;
              materiais = false;
            });
          },
          child: Material(
            elevation: 5.0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                  color: tarefas
                      ? AppColors.primaryColor
                      : Colors.white, // Definindo o fundo branco
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                "assets/images/lista-de-controle.png",
                height: 40,
                width: 40,
                fit: BoxFit.cover,
                color: tarefas ? Colors.white : AppColors.primaryColor,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              projeto = false;
              tarefas = false;
              cronograma = true;
              materiais = false;
            });
          },
          child: Material(
            elevation: 5.0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                  color: cronograma
                      ? AppColors.primaryColor
                      : Colors.white, // Definindo o fundo branco
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                "assets/images/data-limite.png",
                height: 40,
                width: 40,
                fit: BoxFit.cover,
                color: cronograma ? Colors.white : AppColors.primaryColor,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              projeto = false;
              tarefas = false;
              cronograma = false;
              materiais = true;
            });
          },
          child: Material(
            elevation: 5.0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                  color: materiais
                      ? AppColors.primaryColor
                      : Colors.white, // Definindo o fundo branco
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                "assets/images/caminhao-de-entrega.png",
                height: 40,
                width: 40,
                fit: BoxFit.cover,
                color: materiais ? Colors.white : AppColors.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
