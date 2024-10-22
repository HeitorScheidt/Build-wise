import 'package:build_wise/utils/colors.dart';
import 'package:build_wise/utils/styles.dart';
import 'package:build_wise/views/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build_wise/blocs/auth/auth_bloc.dart';
import 'package:build_wise/blocs/auth/auth_event.dart';
import 'package:build_wise/blocs/auth/auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importação necessária

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Adiciona essa linha para evitar o overflow
      body: SingleChildScrollView(
        // Adiciona scroll para evitar problemas com o teclado
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) async {
            if (state is AuthSignUpSuccess) {
              // Após o sucesso no cadastro, obtenha o usuário atual do Firebase
              User? user = FirebaseAuth.instance.currentUser;

              // Verifique se o usuário foi recuperado com sucesso
              if (user != null) {
                Navigator.pushReplacementNamed(
                  context,
                  '/confirm_email',
                  arguments:
                      user, // Passa o objeto User para a rota de confirmação
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ocorreu um erro ao tentar obter o usuário.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } else if (state is AuthFailure) {
              // Exibe mensagem de erro em laranja
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.error,
                    style: const TextStyle(color: Colors.orange),
                  ),
                  backgroundColor: Colors.white,
                ),
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
                          AppColors.secondaryColor
                        ])),
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
                            topRight: Radius.circular(40))),
                    child: const Text(""),
                  ),
                  Container(
                    margin:
                        const EdgeInsets.only(top: 60.0, left: 20, right: 20),
                    child: Column(
                      children: [
                        Center(
                          child: Image.asset(
                            "assets/images/logo-branco.png",
                            width: MediaQuery.of(context).size.width / 1.7,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Material(
                          elevation: 5.0,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            height: MediaQuery.of(context).size.height / 1.6,
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20)),
                            child: Column(
                              children: [
                                const SizedBox(height: 30),
                                Text(
                                  "Sign up",
                                  style: appWidget.headerLineTextFieldStyle(),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                      hintText: "Name",
                                      hintStyle:
                                          appWidget.semiBooldTextFieldStyle(),
                                      prefixIcon:
                                          const Icon(Icons.person_outlined)),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: emailController,
                                  decoration: InputDecoration(
                                      hintText: "Email",
                                      hintStyle:
                                          appWidget.semiBooldTextFieldStyle(),
                                      prefixIcon:
                                          const Icon(Icons.email_outlined)),
                                ),
                                const SizedBox(height: 20),
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
                                      )),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: confirmPasswordController,
                                  obscureText: !isConfirmPasswordVisible,
                                  decoration: InputDecoration(
                                      hintText: "Confirm Password",
                                      hintStyle:
                                          appWidget.semiBooldTextFieldStyle(),
                                      prefixIcon:
                                          const Icon(Icons.password_outlined),
                                      suffixIcon: IconButton(
                                        icon: Icon(isConfirmPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off),
                                        onPressed: () {
                                          setState(() {
                                            isConfirmPasswordVisible =
                                                !isConfirmPasswordVisible;
                                          });
                                        },
                                      )),
                                ),
                                const SizedBox(height: 30),
                                Material(
                                  elevation: 5.0,
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    onTap: () {
                                      if (passwordController.text ==
                                          confirmPasswordController.text) {
                                        context.read<AuthBloc>().add(
                                              AuthSignUpRequested(
                                                  emailController.text,
                                                  passwordController.text,
                                                  nameController.text),
                                            );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Passwords do not match',
                                              style: TextStyle(
                                                  color: Colors.orange),
                                            ),
                                            backgroundColor: Colors.white,
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      width: 200,
                                      decoration: BoxDecoration(
                                          color: AppColors.primaryColor,
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: const Center(
                                        child: Text(
                                          "SIGN UP",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18.0,
                                              fontFamily: "Poppins1",
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
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
                                    builder: (context) => const Login()));
                          },
                          child: Text(
                            "Already have an account? Login",
                            style: appWidget.semiBooldTextFieldStyle(),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
