import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Páginas
import 'package:nutri_viking_app/Pages/onboarding.dart';
import 'package:nutri_viking_app/Pages/signin.dart';
import 'package:nutri_viking_app/Pages/singup.dart';
import 'package:nutri_viking_app/Pages/coach_home.dart';
import 'package:nutri_viking_app/Pages/client_home.dart';
import 'package:nutri_viking_app/Pages/create_diet_plan.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VikingFit',
      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (context) => const Onboarding(),
        '/login': (context) => const SignIn(),
        '/signup': (context) => const SingUp(),

        // Ruta a coach_home con ID recibido como argumento
        '/coach_home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return CoachHomeScreen(coachId: args);
          } else {
            return const Scaffold(
              body: Center(child: Text("Error al recibir ID de coach")),
            );
          }
        },

        // Ruta a user_home con ID recibido como argumento
        '/client_home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return ClientHomeScreen(userId: args);
          } else {
            return const Scaffold(
              body: Center(child: Text("Error al recibir ID de usuario")),
            );
          }
        },

        // Ruta a create_plan con dos argumentos: coachId y clientId
        '/create_plan': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, String>) {
            return CreateDietPlanScreen(
              coachId: args['coachId']!,
              clientId: args['clientId']!,
            );
          } else {
            return const Scaffold(
              body: Center(child: Text("Error al recibir datos del plan")),
            );
          }
        },
      },
      //home: const Onboarding(),
    );
  }
}
