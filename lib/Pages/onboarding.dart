import 'package:flutter/material.dart';
import 'package:nutri_viking_app/Pages/signin.dart';
import 'package:nutri_viking_app/Pages/singup.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffd17a0f), Color(0xff00d687), Color(0xff00a0b7)],
            begin: Alignment.topLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/iconstart.png",
              color: Colors.white,
              height: 90,
              width: 90,
              fit: BoxFit.cover,
            ),
            Text(
              "Viking Fitness",
              style: TextStyle(color: Colors.white, fontSize: 30.0),
            ),
            SizedBox(height: 80.0),
            Text(
              "¡Bienvenido!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 38.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 40.0),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignIn()),
                );
              },
              child: Container(
                padding: EdgeInsets.only(top: 12.0, bottom: 12.0),
                margin: EdgeInsets.only(left: 30.0, right: 30.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white60, width: 2.0),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    "Iniciar Sesión",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40.0),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SingUp()),
                );
              },
              child: Container(
                padding: EdgeInsets.only(top: 12.0, bottom: 12.0),
                margin: EdgeInsets.only(left: 30.0, right: 30.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    "Registrarse",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 25.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height / 8),
            Text(
              "Redes Sociales",
              style: TextStyle(color: Colors.white, fontSize: 20.0),
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Image.asset(
                    "assets/googlemaps.png",
                    height: 40,
                    width: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 20.0),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Image.asset(
                    "assets/facebook.png",
                    height: 40,
                    width: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 20.0),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Image.asset(
                    "assets/instagram.png",
                    height: 40,
                    width: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      "Developed by Jose Prado",
                      style: TextStyle(
                        color: const Color.fromARGB(255, 51, 44, 44),
                        fontSize: 14,
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
