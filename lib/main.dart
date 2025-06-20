import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        /*'/coach_home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return CoachHomeScreen(coachId: args);
          } else {
            return const Scaffold(
              body: Center(child: Text("Error al recibir ID de coach")),
            );
          }
        },*/
        '/coach_home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;

          if (args is String) {
            // Guarda el ID para futuras recargas
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('coachId', args);
            });
            return CoachHomeScreen(coachId: args);
          }

          // Si no hay argumentos, intenta cargar el ID guardado
          return FutureBuilder<String?>(
            future: SharedPreferences.getInstance().then(
              (prefs) => prefs.getString('coachId'),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              return snapshot.hasData
                  ? CoachHomeScreen(coachId: snapshot.data!)
                  : const Scaffold(
                    body: Center(child: Text("ID no encontrado")),
                  );
            },
          );
        },

        // Ruta a user_home con ID recibido como argumento
        /*'/client_home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return ClientHomeScreen(userId: args);
          } else {
            return const Scaffold(
              body: Center(child: Text("Error al recibir ID de usuario")),
            );
          }
        },*/
        '/client_home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;

          if (args is String) {
            // Guarda el ID para futuras recargas
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('userId', args);
            });
            return ClientHomeScreen(userId: args);
          }

          // Si no hay argumentos, intenta cargar el ID guardado
          return FutureBuilder<String?>(
            future: SharedPreferences.getInstance().then(
              (prefs) => prefs.getString('userId'),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              return snapshot.hasData
                  ? ClientHomeScreen(userId: snapshot.data!)
                  : const Scaffold(
                    body: Center(child: Text("ID no encontrado")),
                  );
            },
          );
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
