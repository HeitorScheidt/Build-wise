import 'package:build_wise/utils/colors.dart';
import 'package:build_wise/utils/styles.dart';
import 'package:build_wise/views/pages/signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build_wise/blocs/auth/auth_bloc.dart';
import 'package:build_wise/blocs/auth/auth_event.dart';
import 'package:build_wise/blocs/auth/auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Adiciona essa linha para evitar o overflow
      body: SingleChildScrollView(
        // Adiciona scroll para evitar problemas com o teclado
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) async {
            if (state is AuthSuccess) {
              User? user = FirebaseAuth.instance.currentUser;

              // Verifique se o email foi verificado
              if (user != null && !user.emailVerified) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Por favor, verifique seu email antes de fazer login.',
                      style: TextStyle(color: Colors.orange),
                    ),
                    backgroundColor: Colors.white,
                  ),
                );
                await FirebaseAuth.instance
                    .signOut(); // Faz o logout automático
              } else {
                Navigator.pushReplacementNamed(context, '/bottomnav');
              }
            } else if (state is AuthFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            }
          },
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Container(
              child: Stack(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 2.5,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.topRight,
                        colors: [
                          AppColors.primaryColor,
                          AppColors.secondaryColor,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height / 2),
                    height: MediaQuery.of(context).size.height / 2,
                    width: MediaQuery.of(context).size.width,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Text(""),
                  ),
                  Container(
                    margin:
                        const EdgeInsets.only(top: 60.0, left: 20, right: 20),
                    child: Column(
                      children: [
                        Center(
                          child: Image.asset(
                            "assets/images/logo-branco.png",
                            width: MediaQuery.of(context).size.width / 1.5,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Material(
                          elevation: 5.0,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            height: MediaQuery.of(context).size.height / 1.8,
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 30),
                                Text(
                                  "LogIn",
                                  style: appWidget.headerLineTextFieldStyle(),
                                ),
                                TextField(
                                  controller: emailController,
                                  decoration: InputDecoration(
                                    hintText: "Email",
                                    hintStyle:
                                        appWidget.semiBooldTextFieldStyle(),
                                    prefixIcon:
                                        const Icon(Icons.email_outlined),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                TextField(
                                  controller: passwordController,
                                  obscureText: !isPasswordVisible,
                                  decoration: InputDecoration(
                                    hintText: "Password",
                                    hintStyle:
                                        appWidget.semiBooldTextFieldStyle(),
                                    prefixIcon:
                                        const Icon(Icons.password_outlined),
                                    suffixIcon: IconButton(
                                      icon: Icon(isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off),
                                      onPressed: () {
                                        setState(() {
                                          isPasswordVisible =
                                              !isPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  alignment: Alignment.topRight,
                                  child: Text(
                                    "Forgot Password?",
                                    style: appWidget.semiBooldTextFieldStyle(),
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Material(
                                  elevation: 5.0,
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    onTap: () {
                                      context.read<AuthBloc>().add(
                                            AuthLoginRequested(
                                              emailController.text,
                                              passwordController.text,
                                            ),
                                          );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      width: 200,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "LOGIN",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18.0,
                                            fontFamily: "Poppins1",
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Adiciona botões de login social
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Signup(),
                              ),
                            );
                          },
                          child: Text(
                            "Don't have an account? Sign up",
                            style: appWidget.semiBooldTextFieldStyle(),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<String> getGitHubToken() async {
    // Função que obtém o token do GitHub através do OAuth
    return 'your_github_token_here'; // Deve ser implementado de acordo com o fluxo OAuth do GitHub
  }
}
