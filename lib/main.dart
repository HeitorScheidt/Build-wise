import 'package:build_wise/blocs/cashflow/cashflow_bloc.dart';
import 'package:build_wise/blocs/cashflow/cashflow_event.dart';
import 'package:build_wise/blocs/diary/work_diary_bloc.dart';
import 'package:build_wise/blocs/file/file_bloc.dart';
import 'package:build_wise/blocs/gallery/gallery_bloc.dart';
import 'package:build_wise/blocs/link/link_bloc.dart';
import 'package:build_wise/blocs/link/link_event.dart';
import 'package:build_wise/blocs/profile/profile_bloc.dart';
import 'package:build_wise/blocs/project/project_bloc.dart';
import 'package:build_wise/blocs/schedule/schedule_bloc.dart';
import 'package:build_wise/providers/user_role_provider.dart';
import 'package:build_wise/services/cashflow_service.dart';
import 'package:build_wise/services/file_service.dart';
import 'package:build_wise/services/gallery_service.dart';
import 'package:build_wise/services/link_service.dart';
import 'package:build_wise/services/profile_service.dart';
import 'package:build_wise/services/schedule_service.dart';
import 'package:build_wise/views/pages/bottomnav.dart';
import 'package:build_wise/views/pages/cashflow_page.dart';
import 'package:build_wise/views/pages/confirm_email_page.dart';
import 'package:build_wise/views/pages/cronograma_page.dart';
import 'package:build_wise/views/pages/dashboard_page.dart';
import 'package:build_wise/views/pages/gallery_page.dart';
import 'package:build_wise/views/pages/link_page.dart';
import 'package:build_wise/views/pages/login.dart';
import 'package:build_wise/views/pages/signup.dart';
import 'package:build_wise/views/pages/project_page.dart';
import 'package:build_wise/views/pages/work_diary_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart'; // Importação do provider
import 'package:build_wise/blocs/auth/auth_bloc.dart';
import 'package:build_wise/services/auth_service.dart';
import 'package:build_wise/services/project_service.dart';
import 'package:build_wise/services/work_diary_service.dart';
import 'package:build_wise/views/pages/folder_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => UserRoleProvider()), // Adicionado UserRoleProvider
        BlocProvider(
          create: (context) => AuthBloc(
            AuthService(),
          ),
        ),
        BlocProvider(
          create: (context) => ProjectBloc(ProjectService()),
        ),
        BlocProvider(
          create: (context) => WorkDiaryBloc(WorkDiaryService()),
        ),
        BlocProvider(
          create: (context) => FileBloc(FileService()),
        ),
        BlocProvider(
          create: (context) => GalleryBloc(GalleryService()),
        ),
        BlocProvider(
          create: (context) => CashflowBloc(
            CashflowService(),
          ),
        ),
        BlocProvider(
          create: (context) => ProfileBloc(
            ProfileService(),
          ), // Certifique-se de criar o ProfileBloc aqui
        ),
        BlocProvider(
          create: (context) => LinkBloc(LinkService()),
        ),
        BlocProvider(
          create: (context) => ScheduleBloc(ScheduleService()),
        ),
      ],
      child: MaterialApp(
        title: 'Build Wise',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const Login(),
          '/signup': (context) => const Signup(),
          '/dashboard': (context) => const DashboardPage(),
          '/bottomnav': (context) => const Bottomnav(),
          //'/project': (context) => const ProjectPage(),

          '/work_diary_page': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            return WorkDiaryPage(projectId: args['projectId']);
          },

          '/folder_page': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            return FolderPage(
                userId: args['userId'], projectId: args['projectId']);
          },

          '/gallery_page': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            return GalleryPage(
                userId: args['userId'], projectId: args['projectId']);
          },

          '/cashflow_page': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;

            return BlocProvider(
              create: (context) => CashflowBloc(
                CashflowService(),
              )..add(LoadCashflows(args['userId'], args['projectId'])),
              child: CashflowPage(
                userId: args['userId'],
                projectId: args['projectId'],
              ),
            );
          },

          '/confirm_email': (context) {
            final User user =
                ModalRoute.of(context)!.settings.arguments as User;
            return ConfirmEmailPage(user: user);
          },

          /* '/link_page': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            return BlocProvider(
              create: (context) => LinkBloc(
                LinkService(),
              )..add(LoadLinks(args['projectId'])), // Removi o userId
              child: LinkPage(
                projectId: args['projectId'],
              ),
            );
          },*/

          '/cronograma_page': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            return CronogramaPage(
              userId: args['userId'],
            );
          },
        },
      ),
    );
  }
}
