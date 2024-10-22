import 'package:build_wise/blocs/schedule/schedule_event.dart';
import 'package:build_wise/utils/colors.dart';
import 'package:build_wise/views/pages/cronograma_page.dart';
import 'package:build_wise/views/pages/dashboard_page.dart';
import 'package:build_wise/views/pages/project_page.dart';
import 'package:build_wise/views/pages/user_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build_wise/blocs/schedule/schedule_bloc.dart';
import 'package:build_wise/services/schedule_service.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class Bottomnav extends StatefulWidget {
  final int currentTabIndex;
  final Widget? child;

  const Bottomnav({super.key, this.currentTabIndex = 0, this.child});

  @override
  State<Bottomnav> createState() => _BottomnavState();
}

class _BottomnavState extends State<Bottomnav> {
  late int currentTabIndex;
  late List<Widget> pages;
  late Widget currentPage;
  late DashboardPage dashboard;
  late ProjectPage project;
  late UserProfilePage profile;

  @override
  void initState() {
    super.initState();
    currentTabIndex = widget.currentTabIndex;
    dashboard = DashboardPage();
    project = ProjectPage();
    profile = UserProfilePage();

    pages = [
      dashboard,
      project,
      Container(),
      profile,
    ];

    currentPage = widget.child ?? pages[currentTabIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        height: 56,
        backgroundColor: Colors.white,
        color: AppColors.primaryColor,
        animationDuration: const Duration(milliseconds: 500),
        onTap: (int index) {
          setState(() {
            currentTabIndex = index;
            if (index == 2) {
              final String userId = FirebaseAuth.instance.currentUser?.uid ??
                  'default_user_id'; // Use o `userId` correto aqui
              currentPage = BlocProvider(
                create: (context) => ScheduleBloc(ScheduleService())
                  ..add(LoadScheduleEntries(
                      userId)), // Carrega as entradas do cronograma
                child: CronogramaPage(userId: userId),
              );
            } else {
              currentPage = pages[index];
            }
          });
        },
        items: const [
          Icon(Icons.home_outlined, color: Colors.white),
          Icon(Icons.folder_outlined, color: Colors.white),
          Icon(Icons.calendar_today_outlined, color: Colors.white),
          Icon(Icons.person_outline, color: Colors.white),
        ],
      ),
      body: currentPage,
    );
  }
}
